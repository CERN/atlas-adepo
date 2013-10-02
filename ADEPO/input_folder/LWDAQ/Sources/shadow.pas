unit shadow;
{
Routines for for Detecting One-Dimensional Shadows in Images.
Copyright (C) 2002, 2007 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

These routines are effective at finding wire shadows or dark images of
wires against bright backgrounds, provided that the shadows are not
sharp. Sharp- edged shadows have uniform darkness from one edge to the
other, and these routines rely upon there being a minimum of intensity
near the center of the shadow or image. We used them to good effect
with dim x-ray images of muon tubes for the ATLAS experiment. They
performed well with severely out-of-focus images we obtained from an
optical Wire Position Sensor. But they do not perform well with image
from a well-focused Wire Position Sensor. We detect poor performance
by varying the min_shadow_separation parameter and watching how the
measured wire position changes. Suppose the wire shadow is 200 um
wide, and we set the minimum separation to 400 um. The shadow-finding
routines will put a box 400 um wide around the wire shadow and fit a
notch profile to the shadow. The notch is 200 um wide (half the width
of the box). The shadow-finding performs well if the measured position
does not move by more than a pixel as we incrase the minimum
separation from 400 um to 1000 um. This is the case for de-fucused
images with uniform background intensity, but not true for sharp images with
varying background intensity.
}

interface

uses
	utils,transforms,images,image_manip;

const {for shadow types}
	max_num_shadows=10;
	wire_name='wire';
	tube_left_outer_name='left_outer_edge';
	tube_right_outer_name='right_outer_edge';
	tube_left_inner_name='left_inner_edge';
	tube_right_inner_name='right_inner_edge';
	shadow_invalid_string='invalid';
	shadow_list_invalid_string='invalid';

type {for shadow list}
	shadow_type=record
		rotation:real;{radians anticlockwize from vertical}
		position:real;{micrometers to right of ccd reference point}	
		pixel_position:integer;{closest column or row}
		shadow_name:short_string;{gives the type of shadow}
	end;{record}
	shadow_ptr_type=^shadow_type;
	shadow_list_type=record
		valid:boolean;{for error tracking}
		pixel_size_um:real;{size of ccd pixels perpendicular to shadows}
		horizontal_shadows:boolean;{shadows run horizontally in image}
		ccd_reference_pixel:ij_point_type;{reference pixel in ccd}
		min_shadow_separation:real;{micrometers}
		num_shadows:integer;{number of shadows specified for the image}
		shadows:array [1..max_num_shadows] of shadow_type;
	end;{record}

function shadow_list_from_string(var s:short_string):shadow_list_type;
function string_from_shadow_list(shadow_list:shadow_list_type):short_string;
function string_from_shadows(shadow_list:shadow_list_type):short_string;
procedure shadow_locate_approximate(ip:image_ptr_type;
	var shadow_list:shadow_list_type);
procedure shadow_locate_accurate(ip:image_ptr_type;
	var shadow_list:shadow_list_type;show_fitting:boolean);

implementation

const {for ascent stages}
	stage_1_iteration_threshold=20;{correlation units}
	stage_1_x_step=10;{um}
	stage_1_rotation_step=3;{mrads}

	stage_2_iteration_threshold=20;{correlation units}
	stage_2_x_step=1;{um}
	stage_2_rotation_step=0.3;{mrads}

	stage_3_iteration_threshold=20;{correlation units}
	stage_3_x_step=0.1;{um}
	stage_3_rotation_step=0.03;{mrads}

var {for correlating function}
	notch_pattern_extent:real=20;{pixels}
	notch_pattern_scale:real=1;
	edge_pattern_extent:real=40;{pixels}
	edge_pattern_scale:real=1;
	
const {for rough shadow location and marking}
	area_color=green_color;
	profile_color=red_color;
	profile_derivative_color=yellow_color;
	isolation_threshold_color=blue_color;
	max_num_threshold_steps=30;

const {for ascent algorithm}
	random_start_range=0.1;{fraction of fitting area}
	nominal_rotation=0;{mrad}
	rotation_max=100;{mrad}
	show_profile=true;
	show_profile_threshold=true;
	show_profile_derivative=true;

type {for correlation}
	pattern_type=record
		valid:boolean;{valid pattern}
		padding:array [1..7] of byte; {force origin field to eight-byte boundary}
		origin:xy_point_type; {pattern coordinate origin in image coordinates}
		rotation:real; {radians}
		pattern_x_width:real; {scaling factor going from pattern x to image}
		pattern_y_width:real; {scaling factor going from pattern y to image}
		formula:function(point:xy_point_type):real
	end;
	pattern_ptr_type=^pattern_type;
	fit_type = record 
		pattern:pattern_type;
		area:ij_rectangle_type;
		x_step,rotation_step:real;
		correlation,amplitude,average:real;
		show_fitting:boolean;
	end;

{
}
function shadow_list_from_string(var s:short_string):shadow_list_type;
		
var
	shadow_list:shadow_list_type;
	shadow_num:integer;
	
begin 
	if (s=shadow_invalid_string) then shadow_list.valid:=false
	else with shadow_list do begin
		valid:=true;
		pixel_size_um:=read_integer(s);
		horizontal_shadows:=read_boolean(s);
		ccd_reference_pixel.i:=read_integer(s);
		ccd_reference_pixel.j:=read_integer(s);
		min_shadow_separation:=read_real(s);
		num_shadows:=read_integer(s);
		if (num_shadows>max_num_shadows) or (num_shadows<0) then valid:=false
		else for shadow_num:=1 to num_shadows do
			shadows[shadow_num].shadow_name:=read_word(s);
	end;
	shadow_list_from_string:=shadow_list;
end;

{
}
function string_from_shadow_list(shadow_list:shadow_list_type):short_string;
		
var
	shadow_num:integer;
	s:short_string;
	
begin 
	string_from_shadow_list:=shadow_list_invalid_string;
	if not shadow_list.valid then exit;
	
	with shadow_list do begin
		writestr(s,pixel_size_um:1:1,' ',string_from_boolean(horizontal_shadows),' ',
			ccd_reference_pixel.i:1,' ',ccd_reference_pixel.j:1,' ',
			min_shadow_separation:1:1,' ',
			num_shadows:1);
		for shadow_num:=1 to num_shadows do
			writestr(s,s,' ',shadows[shadow_num].shadow_name);
	end;
	string_from_shadow_list:=s;
end;

{
}
function string_from_shadows(shadow_list:shadow_list_type):short_string;

var
	shadow_num:integer;
	s:short_string;

begin
	if not shadow_list.valid then exit;
	s:='';
	for shadow_num:=1 to shadow_list.num_shadows do
		with shadow_list.shadows[shadow_num] do
			writestr(s,s,position:1:2,' ',rotation*mrad_per_rad:1:3,' ');
	string_from_shadows:=s;
end;

{
	random_start_pattern returns random pattern parameters to act as a 
	starting point for the fitting process. 
}
function random_start_pattern(var fit:fit_type):pattern_type;

var 
	p:pattern_type;
	ir:xy_rectangle_type;
	
function delta:real;
begin delta:=(random_0_to_1-one_half)/one_half; end;

begin 
	ir:=i_from_c_rectangle(fit.area);
	with p do begin
		origin.x:=
			(ir.left+ir.right)*one_half
			+delta*random_start_range*(ir.right-ir.left)*one_half;
		origin.y:=
			(ir.top+ir.bottom)*one_half
			+delta*random_start_range*(ir.bottom-ir.top)*one_half;
		rotation:=0;
		pattern_x_width:=1;
		pattern_y_width:=1;
	end;
	random_start_pattern:=p;
end; 

{
	notch_pattern returns a straight-edged notch function
	extending notch_pattern_extent on either side of the
	y-axis.
}
function notch_pattern(point:xy_point_type):real;

begin 
	if abs(point.x)>notch_pattern_extent then 
		notch_pattern:=
			notch_pattern_scale
	else 
		notch_pattern:=
			notch_pattern_scale*abs(point.x)/notch_pattern_extent;
end;

{
	right_edge_pattern returns a right-edge function.
}
function right_edge_pattern(point:xy_point_type):real;

begin 
	if (point.x>0) and (point.x<edge_pattern_extent) then 
		right_edge_pattern:=
			+edge_pattern_scale;
	if (point.x<=0) and (point.x>-edge_pattern_extent) then 
		right_edge_pattern:=
			-edge_pattern_scale;
end;

{
	left_edge_pattern returns a left edge pattern.
}
function left_edge_pattern(point:xy_point_type):real;

begin 
	if (point.x>0) and (point.x<edge_pattern_extent) then 
		left_edge_pattern:=
			-edge_pattern_scale;
	if (point.x<=0) and (point.x>-edge_pattern_extent) then 
		left_edge_pattern:=
			+edge_pattern_scale;
end;

{
}
procedure shadow_display_pattern(ip:image_ptr_type;
	pp:pattern_ptr_type;color:overlay_pixel_type);

const
	extent=1000;{pixels}

var
	pattern_line:xy_line_type;
		
begin
	with pattern_line do begin
		a.x:=0;
		a.y:=extent;
		b.x:=0;
		b.y:=-extent;
	end;
	display_ccd_line(ip,c_from_i_line(i_from_p_line(pattern_line,pp)),color);
end;

{
	shadow_locate_approximate determines the column fields of all the shadow
	in the shadow list.
}
procedure shadow_locate_approximate (ip:image_ptr_type;
	var shadow_list:shadow_list_type);

var 
	min_separation:integer;
	threshold,threshold_step:real;
	i,j,k,l:integer;
	left_i,right_i:integer;
	shadow_num:integer;
	notch_index,right_edge_index,left_edge_index:integer;
	notch_list,right_edge_list,left_edge_list:shadow_list_type;
	profile_ptr,derivative_ptr:x_graph_ptr_type;
	graph_ptr:xy_graph_ptr_type;
	rms_residual,slope,intercept:real;
	profile_max,profile_min,derivative_max,derivative_min:real;
	ccd_line:ij_line_type;
	
begin 
{
	check the input data
}
	shadow_list.valid:=false;
	if not valid_image_ptr(ip) then exit;
	if not valid_analysis_bounds(ip) then begin
		report_error('invalid analysis bounds in '+CurrentRoutineName+'.');
		exit;
	end;
{
	calculate the minimun distance between shadows
}
	min_separation:=round(shadow_list.min_shadow_separation/shadow_list.pixel_size_um);
{
	count each type of shadow expected in image.
}
	notch_list.num_shadows:=0;
	right_edge_list.num_shadows:=0;
	left_edge_list.num_shadows:=0;
	for shadow_num:=1 to shadow_list.num_shadows do begin
		with shadow_list.shadows[shadow_num] do begin
			shadow_name:=strip_spaces(shadow_name);
			if shadow_name=wire_name then begin
				inc(notch_list.num_shadows);
				inc(right_edge_list.num_shadows);
				inc(left_edge_list.num_shadows);
			end;
			if shadow_name=tube_right_inner_name then
				inc(notch_list.num_shadows);
			if shadow_name=tube_left_inner_name then
				inc(notch_list.num_shadows);
			if shadow_name=tube_right_outer_name then
				inc(right_edge_list.num_shadows);
			if shadow_name=tube_left_outer_name then 
				inc(left_edge_list.num_shadows);
			if shadow_name='' then begin
				report_error('shadow_name="" in '+CurrentRoutineName+'.');
				exit;
			end;
		end;
	end;
{
	obtain a horizontal profile by summing each column in 
	ip^.analysis_bounds.
}	
	profile_ptr:=image_profile_row(ip);
{
	find the minimum and maximum values of the profile.
}	
	profile_max:=min_intensity;
	profile_min:=max_intensity;
	with ip^.analysis_bounds do begin
		for i:=left to right do begin
			if profile_max<profile_ptr^[i-left] then profile_max:=profile_ptr^[i-left];
			if profile_min>profile_ptr^[i-left] then profile_min:=profile_ptr^[i-left];
		end;
	end;
{
	display profile.
}	
	if show_profile then 
		display_profile_row(ip,profile_ptr,profile_color);
{
	calculate slope of profile.
}
	with ip^.analysis_bounds do begin
		graph_ptr:=new_xy_graph(right-left+1);
		for i:=left to right do begin
			graph_ptr^[i-left].x:=i;
			graph_ptr^[i-left].y:=profile_ptr^[i-left];
		end;
		straight_line_fit(graph_ptr,slope,intercept,rms_residual);
		dispose_xy_graph(graph_ptr);
	end;
{
	calculate horizontal derivative-of-intensity profile.
}
	with ip^.analysis_bounds do begin
		derivative_ptr:=new_x_graph(right-left+1);
		derivative_max:=min_intensity;
		derivative_min:=max_intensity;
		for i:=left to right do begin
			if i=left then 
				derivative_ptr^[i-left]:=
					profile_ptr^[i-left+1]-profile_ptr^[i-left];
			if (i>left) and (i<right) then 
				derivative_ptr^[i-left]:=
					(profile_ptr^[i-left+1]-profile_ptr^[i-left-1])*one_half;
			if i=right then 
				derivative_ptr^[i-left]:=
					profile_ptr^[i-left]-profile_ptr^[i-left-1];
			if derivative_max<derivative_ptr^[i-left] then 
				derivative_max:=derivative_ptr^[i-left];
			if derivative_min>derivative_ptr^[i-left] then 
				derivative_min:=derivative_ptr^[i-left];
		end;
	end;
{
	display derivative.
}
	if show_profile_derivative then 
		display_profile_row(ip,derivative_ptr,profile_derivative_color);
{
	find the notch-like shadow by looking at the profile.
}
	threshold:=profile_min;
	threshold_step:=(profile_max-profile_min)/max_num_threshold_steps;
	with ip^.analysis_bounds do begin
		repeat
			i:=left;
			notch_index:=0;
			while (i<=right) and (notch_index<notch_list.num_shadows) do begin
				if profile_ptr^[i-left]<(threshold+(i-left)*slope) then begin
					inc(notch_index);
					left_i:=i;
					right_i:=i;
					repeat 
						inc(right_i);
					until (right_i>=right) or
						(profile_ptr^[right_i-left]>(threshold+(right_i-left)*slope));	
					i:=(left_i+right_i) div 2;
					notch_list.shadows[notch_index].pixel_position:=i;
					i:=left_i+min_separation;
				end;
				i:=i+1;
			end;
			threshold:=threshold+threshold_step;
		until (notch_index=notch_list.num_shadows) or (threshold>profile_max);
	end;
	
	if notch_index<notch_list.num_shadows then begin
		report_error('notch_index<notch_list.num_shadows in '+CurrentRoutineName+'.');
		exit;
	end;
{
	display threshold line used to isolate notches
}
	if show_profile_threshold then begin
		with ccd_line,ip^.analysis_bounds do begin
			a.i:=left;
			a.j:=bottom-round(
					(bottom-top)
					*(threshold-profile_min)
					/(profile_max-profile_min));
			b.i:=right;
			b.j:=bottom-round(
					(bottom-top)
					*(threshold+slope*(right-left)-profile_min)
					/(profile_max-profile_min));
		end;
		display_ccd_line(ip,ccd_line,isolation_threshold_color);
	end;
{
	find the right-edge-like shadow by looking at the maxima of the derivative profile.
}
	threshold:=derivative_max;
	threshold_step:=(derivative_max-derivative_min)/max_num_threshold_steps;
	with ip^.analysis_bounds do begin
		repeat
			i:=left;
			right_edge_index:=0;
			while (i<=right) and (right_edge_index<right_edge_list.num_shadows) do begin
				if derivative_ptr^[i-left]>threshold then begin
					inc(right_edge_index);
					left_i:=i;
					right_i:=i;
					repeat 
						right_i:=right_i+1;
					until (right_i>=right) or
						(derivative_ptr^[right_i-left]<threshold);				
					i:=(left_i+right_i) div 2;
					right_edge_list.shadows[right_edge_index].pixel_position:=i;
					i:=left_i+min_separation;
				end;
				i:=i+1;
			end;
			threshold:=threshold-threshold_step;
		until (right_edge_index=right_edge_list.num_shadows) or (threshold<=derivative_min);
	end;
		
	if right_edge_index<right_edge_list.num_shadows then begin
		report_error('right_edge_index<right_edge_list.num_shadows in '+CurrentRoutineName+'.');
		exit;
	end;
{
	find the left-edge-like shadow by looking at the minima of the derivative profile.
}	
	threshold:=derivative_min;
	threshold_step:=(derivative_max-derivative_min)/max_num_threshold_steps;
	with ip^.analysis_bounds do begin
		repeat
			i:=left;
			left_edge_index:=0;
			while (i<=right) and (left_edge_index<left_edge_list.num_shadows) do begin
				if derivative_ptr^[i-left]<threshold then begin
					inc(left_edge_index);
					left_i:=i;
					right_i:=i;
					repeat 
						right_i:=right_i+1;
					until (right_i>=right) or
						(derivative_ptr^[right_i-left]>threshold);				
					i:=(left_i+right_i) div 2;
					left_edge_list.shadows[left_edge_index].pixel_position:=i;
					i:=left_i+min_separation;
				end;
				i:=i+1;
			end;
			threshold:=threshold+threshold_step;
		until (left_edge_index=left_edge_list.num_shadows) or (threshold>=derivative_max);
	end;
		
	if left_edge_index<left_edge_list.num_shadows then begin
		report_error('left_edge_index<left_edge_list.num_shadows in '+CurrentRoutineName+'.');
		exit;
	end;
{
	dispose of the profile and derivative arrays.
}
	dispose_x_graph(profile_ptr);
	dispose_x_graph(derivative_ptr);
{
	assemble shadow_list out of notch_list, right_edge_list, and left_edge_list.
}
	notch_index:=1;
	right_edge_index:=1;
	left_edge_index:=1;
	with shadow_list do begin
		for shadow_num:=1 to num_shadows do begin
			with shadows[shadow_num] do begin
				if shadow_name=wire_name then begin
					pixel_position:=notch_list.shadows[notch_index].pixel_position;
					inc(notch_index);
					inc(right_edge_index);
					inc(left_edge_index);
				end;
				if shadow_name=tube_right_inner_name then begin
					pixel_position:=notch_list.shadows[notch_index].pixel_position;
					inc(notch_index);
				end;
				if shadow_name=tube_left_inner_name then begin
					pixel_position:=notch_list.shadows[notch_index].pixel_position;
					inc(notch_index);
				end;
				if shadow_name=tube_right_outer_name then begin
					pixel_position:=right_edge_list.shadows[right_edge_index].pixel_position;
					inc(right_edge_index);
				end;
				if shadow_name=tube_left_outer_name then begin
					pixel_position:=left_edge_list.shadows[left_edge_index].pixel_position;
					inc(left_edge_index);
				end;
				position:=(pixel_position-ccd_reference_pixel.i)*pixel_size_um;
				rotation:=0;
			end;
		end;
	end;
{
	Done.
}
	shadow_list.valid:=true;
end; 

{
	correlate calculates a real number proportional to the average
	product of pattern and pixel values within a region of the display
	window. The region and the pattern function are specified by fit.
	To reduce aliasing and edge effects, the correlate function
	subtracts the average_intensity in the fitting region from the
	image intensity before multiplication. The result of the
	correlation is returned in the fit parameter.
}
procedure correlate(ip:image_ptr_type;var fit:fit_type);

var
	ipt:xy_point_type;
	ir:xy_rectangle_type;
	cpt:ij_point_type;
	pp:xy_point_type;
	counter:integer;
	sum:real;
	
begin 
	if not valid_image_ptr(ip) then exit;
	counter:=0;
	sum:=0;
	ir:=i_from_c_rectangle(fit.area);
	for cpt.j:=fit.area.top to fit.area.bottom do begin
		for cpt.i:=fit.area.left to fit.area.right do begin
			pp:=p_from_i(i_from_c(cpt),@fit.pattern);
			sum:=sum 
				+fit.pattern.formula(pp)
				*(ip^.intensity[cpt.j,cpt.i]-fit.average);
			inc(counter);
		end;
	end;
	if counter=0 then 
		fit.correlation:=0
	else 
		fit.correlation:=sum/(counter*fit.amplitude);
end;

{
	pattern_gradient returns the normalized gradient of the correlation
	function in parameter space. The result is passed back as a variable
	of pattern_type. The parameter entries in the pattern indicate the 
	component of the normalized gradient in that direction in the parameter
	space.
}
function pattern_gradient(ip:image_ptr_type;var fit:fit_type):pattern_type;

var
	origin_x_up,origin_x_down,
	rotation_up,rotation_down:real;
	f:fit_type;
	changes:pattern_type;
	norm:real;

begin 
	f:=fit;
	f.pattern.origin.x:=f.pattern.origin.x+fit.x_step;
	correlate(ip,f);
	origin_x_up:=f.correlation;

	f:=fit;
	f.pattern.origin.x:=f.pattern.origin.x-fit.x_step;
	correlate(ip,f);
	origin_x_down:=f.correlation;

	f:=fit;
	f.pattern.rotation:=f.pattern.rotation+fit.rotation_step;
	correlate(ip,f);
	rotation_up:=f.correlation;

	f:=fit;
	f.pattern.rotation:=f.pattern.rotation-fit.rotation_step;
	correlate(ip,f);
	rotation_down:=f.correlation;
	
	with changes do begin
		origin.y:=0;
		pattern_y_width:=1;
		pattern_x_width:=1;
		origin.x:=origin_x_up-origin_x_down;
		rotation:=rotation_up-rotation_down;
		norm:=sqrt(sqr(origin.x)+sqr(rotation));
		origin.x:=origin.x/norm;
		rotation:=rotation/norm;
	end;
		
	pattern_gradient:=changes;
end;

{
	step_up changes the parameters of a fit in an attempt to maximise
	the correlation function by steepest ascent along the corellation 
	gradient.
}
function step_up(ip:image_ptr_type;var fit:fit_type):fit_type;

var
	new_fit:fit_type;
	changes:pattern_type;

begin 
	changes:=pattern_gradient(ip,fit);
	new_fit:=fit;
	new_fit.pattern.origin.x:=fit.pattern.origin.x+changes.origin.x*fit.x_step;
	new_fit.pattern.rotation:=fit.pattern.rotation+changes.rotation*fit.rotation_step;               
	step_up:=new_fit;
end;

{
	ascend applies the step_up function recursively until the
	correlation of the fit parameter is stable to within +-
	the threshold.
}
procedure ascend(ip:image_ptr_type;var fit:fit_type;limit:integer);

const
	correlation_array_length=5;

var
	old_fit:fit_type;
	index:integer;
	display_bounds:ij_rectangle_type;
	
begin 
	for index:=1 to limit do begin
		old_fit:=fit;
		fit:=step_up(ip,old_fit);
		if fit.show_fitting then begin
			shadow_display_pattern(ip,@old_fit.pattern,clear_color);
			shadow_display_pattern(ip,@fit.pattern,blue_color);
			gui_draw(ip^.name);
		end;
	end;
end;

{
	shadow_locate_accurate uses a steepest ascent algorithm to maximize
	the correlation between shadow in an image and patterns specified
	by the shadow_list.  The shadow list must contain the approximate
	location of the features, as it does after shadow_locate_approximate.
}
procedure shadow_locate_accurate(ip:image_ptr_type;
	var shadow_list:shadow_list_type;show_fitting:boolean);

const
	line_construction_offset=100;
	
var 
	shadow_num:integer;
	area_half_width:integer;
	reference_row,shadow_line:xy_line_type;
	fit:fit_type;
	cp,reference_pixel:ij_point_type;
	pp:xy_point_type;
	reference_point,shadow_point:xy_point_type;
	saved_bounds:ij_rectangle_type;
	nip:image_ptr_type;
	i,j,n:integer;
	intercept,slope,rms_residual,min:real;
	g:xyz_graph_ptr_type;

begin
{
	check the input parameters
}
	shadow_list.valid:=false;
	if not valid_image_ptr(ip) then exit;
{
	determine the width of the rectangle in which correlation is calculated
}
	area_half_width:=round(
		one_half*shadow_list.min_shadow_separation
		/shadow_list.pixel_size_um);
{
	if we're using a rotated image, rotate the ccd reference pixel
}
	if shadow_list.horizontal_shadows then begin
		reference_pixel.i:=shadow_list.ccd_reference_pixel.j;
		reference_pixel.j:=ip^.j_size-1-shadow_list.ccd_reference_pixel.i;
	end 
	else reference_pixel:=shadow_list.ccd_reference_pixel;
{
	transform the reference pixel and row into image coordinates
}
	reference_point:=i_from_c(reference_pixel);
	reference_row.a:=reference_point;
	reference_row.b.y:=reference_point.y;
	reference_row.b.x:=reference_point.x+line_construction_offset;
{
	decide if we should show the fitting procedure.
}
	fit.show_fitting:=show_fitting;
{
	refine the measurement of each shadow location in turn
}		
	for shadow_num:=1 to shadow_list.num_shadows do begin
		with shadow_list.shadows[shadow_num] do begin
			with fit.area do begin
				left:=pixel_position-area_half_width;
				right:=pixel_position+area_half_width;
				top:=ip^.analysis_bounds.top;
				bottom:=ip^.analysis_bounds.bottom;
			end;
			display_ccd_rectangle(ip,fit.area,area_color);
		
			fit.pattern:=random_start_pattern(fit);

			fit.pattern.formula:=notch_pattern;
			notch_pattern_extent:=area_half_width*one_half;
			if shadow_name=tube_right_outer_name then begin
				fit.pattern.formula:=right_edge_pattern;
				edge_pattern_extent:=area_half_width;
			end;
			if shadow_name=tube_left_outer_name then begin
				fit.pattern.formula:=left_edge_pattern;
				edge_pattern_extent:=area_half_width;
			end;
			
			saved_bounds:=ip^.analysis_bounds;
			ip^.analysis_bounds:=fit.area;
			fit.average:=image_average(ip);
			fit.amplitude:=image_amplitude(ip);
			ip^.analysis_bounds:=saved_bounds;

			mark_time('Wire '+string_from_integer(shadow_num,1)+' Stage 1',
				CurrentRoutineName);
			fit.x_step:=stage_1_x_step/shadow_list.pixel_size_um;
			fit.rotation_step:=stage_1_rotation_step/mrad_per_rad;
			ascend(ip,fit,stage_2_iteration_threshold);
		
			mark_time('Wire '+string_from_integer(shadow_num,1)+' Stage 2',
				CurrentRoutineName);
			fit.x_step:=stage_2_x_step/shadow_list.pixel_size_um;
			fit.rotation_step:=stage_2_rotation_step/mrad_per_rad;
			ascend(ip,fit,stage_2_iteration_threshold);

			mark_time('Wire '+string_from_integer(shadow_num,1)+' Stage 3',
				CurrentRoutineName);
			fit.x_step:=stage_3_x_step/shadow_list.pixel_size_um;
			fit.rotation_step:=stage_3_rotation_step/mrad_per_rad;
			ascend(ip,fit,stage_3_iteration_threshold);

			shadow_display_pattern(ip,@fit.pattern,orange_color);

			with shadow_line do begin
				pp.x:=0;
				pp.y:=0;
				a:=i_from_p(pp,@fit.pattern);
				pp.x:=0;
				pp.y:=line_construction_offset;
				b:=i_from_p(pp,@fit.pattern);
			end;
			shadow_point:=xy_line_line_intersection(shadow_line,reference_row);
			position:=shadow_list.pixel_size_um*(shadow_point.x-reference_point.x);
			rotation:=fit.pattern.rotation;
		end;
	end;

	shadow_list.valid:=true;
end; 

end.