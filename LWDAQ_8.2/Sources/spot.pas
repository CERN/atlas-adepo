{
Routines to Locate Bright Spots in Images
Copyright (C) 2004-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University

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
}

unit spot;

interface

uses
	utils,images,transforms,image_manip;

const
	spot_missing_string='-1 -1 0 0 0';
	spot_missing_bounds_string='-1 -1 -1 -1';
	spot_decreasing_total_intensity=1;
	spot_increasing_x=2;
	spot_increasing_y=3;
	spot_decreasing_x=4;
	spot_decreasing_y=5;
	spot_decreasing_max_intensity=6;
	spot_decreasing_size=7;
	spot_use_centroid=1;
	spot_use_ellipse=2;
	spot_use_vertical_line=3;
	max_num_spots=100; {only rare, over-exposed images have more}
	
type
	spot_type=record
		valid:boolean;
		color_code:integer;{color code used to mark pixels in overlay}
		x:real;{location in x (um) or orientation (mrad)}
		y:real;{location in y (um) or orientation (mrad)}
		accuracy:real;{um estimate of position accuracy}
		threshold:integer;{intensity threshold for noise and background}
		position_xy:xy_point_type;{position in image coordinates, units um}
		position_ij:ij_point_type;{position in ccd coordinates, units pixels}
		bounds:ij_rectangle_type;{boundries enclosing spot}
		num_pixels:integer;{number of pixels above threshold in bounds}
		sum_intensity:integer;{sum of net intensities of pixels in bounds}
		max_intensity:integer;{max intensity in bounds}
		min_intensity:integer;{min intensity in bounds}
		pixel_size_um:real;{width of pixels in um}
		ellipse:xy_ellipse_type;{ellipse for elliptical fitting}
	end;
	spot_ptr_type=^spot_type;
	spot_list_type(length:integer)=record
		ip:image_ptr_type;{for convenience of analysis}
		num_valid_spots:integer;{spots 1 to num_valid_spots are valid}
		num_requested_spots:integer;{spots looked for by image analysis}
		spots:array [1..length] of spot_type;
	end;
	spot_list_ptr_type=^spot_list_type;

procedure spot_centroid(ip:image_ptr_type;var spot:spot_type);
procedure spot_ellipse(ip:image_ptr_type;var spot:spot_type);
procedure spot_vertical_line(ip:image_ptr_type;var spot:spot_type);
procedure spot_list_display_bounds(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);
procedure spot_list_display_vertical_lines(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);
procedure spot_list_display_crosses(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);
procedure spot_list_display_ellipses(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);
function spot_list_find(ip:image_ptr_type;
	num_spots:integer;command:short_string;pixel_size_um:real):spot_list_ptr_type;
procedure spot_list_merge(ip:image_ptr_type;slp:spot_list_ptr_type;command:short_string);
procedure spot_list_sort(slp:spot_list_ptr_type;sort_code:integer);
function spot_eccentricity(s:spot_type):real;
function new_spot_list_ptr(length:integer):spot_list_ptr_type;
procedure dispose_spot_list_ptr(slp:spot_list_ptr_type);
function string_from_spot(c:spot_type):short_string;
function string_from_spot_list(slp:spot_list_ptr_type):short_string;
function bounds_string_from_spot_list(slp:spot_list_ptr_type):short_string;
function intensity_string_from_spot_list(slp:spot_list_ptr_type):short_string;


implementation
	
const	
	max_stack_depth=2000; {for spot_list_find and do_pixel}

var
	current_stack_depth:integer; {for spot_list_find and do_pixel}

{
	new_spot_list_ptr creates a new spot list with "length"
	entries.
}
function new_spot_list_ptr(length:integer):spot_list_ptr_type;

var
	slp:spot_list_ptr_type;
	spot_num:integer;
	
begin
	new_spot_list_ptr:=nil;
	if length<=0 then length:=1;
	new(slp,length);
	if slp=nil then exit;
	inc_num_outstanding_ptrs(sizeof(slp^),CurrentRoutineName);
	with slp^ do begin
		num_valid_spots:=0;
		num_requested_spots:=0;
		for spot_num:=1 to length do 
			spots[spot_num].valid:=false;
	end;
	new_spot_list_ptr:=slp;
end;

{
	dispose_spot_list_ptr disposes of a spot list.
}
procedure dispose_spot_list_ptr(slp:spot_list_ptr_type);

begin
	if slp=nil then exit;
	dec_num_outstanding_ptrs(sizeof(slp^),CurrentRoutineName);
	dispose(slp);
end;

{
	spot_centroid subtracts a threshold from the intensity within the spot
	bounds and determines the intensity centroid of the resulting pixels. The
	routine ignores pixels whose intensity is below threshold. The centroid
	position is in image coordinates, with units microns. If the spot consists
	only of pixel (0,0) and the pixels are 10 microns, the spot position will be
	(5,5) in microns. The top left corner of pixel (0,0) is the orgin of image
	coordinates. The spot sensitivity is in microns per threshold count
	calculated at the specified threshold. The routine takes as input a
	spot_type and alters the x, y, num_pixels, sum_intensity, max_intensity,
	min_intensity, and valid fields to represent the result of the
	centroid-finding calculation.
}
procedure spot_centroid(ip:image_ptr_type;var spot:spot_type);

const
	threshold_step=1;
	
var
	i,j,sum,max,min,sum_i,sum_j,step_sum,step_sum_i,step_sum_j:longint;
	count,net_intensity:longint;
	step_position_xy:xy_point_type;
	
begin
	if not spot.valid then exit;
	if ip=nil then exit;
	count:=0;
	sum:=0;sum_i:=0;sum_j:=0;
	max:=black_intensity;min:=white_intensity;
	step_sum:=0;step_sum_i:=0;step_sum_j:=0;
	with spot,spot.bounds do begin
		for j:=top to bottom do begin
			for i:=left to right do begin
				net_intensity:=ip^.intensity[j,i]-threshold;
				if net_intensity>0 then begin
					inc(count);
					sum:=sum+net_intensity;
					sum_i:=sum_i+i*net_intensity;
					sum_j:=sum_j+j*net_intensity;
				end;
				net_intensity:=ip^.intensity[j,i]-threshold-threshold_step;
				if net_intensity>0 then begin
					step_sum:=step_sum+net_intensity;
					step_sum_i:=step_sum_i+i*net_intensity;
					step_sum_j:=step_sum_j+j*net_intensity;
				end;
				if ip^.intensity[j,i]>max then max:=ip^.intensity[j,i];
				if ip^.intensity[j,i]<min then min:=ip^.intensity[j,i];
			end;
		end;
		step_position_xy.x:=(step_sum_i/step_sum)+ccd_origin_x;
		step_position_xy.y:=(step_sum_j/step_sum)+ccd_origin_y;

		position_xy.x:=(sum_i/sum)+ccd_origin_x;
		position_xy.y:=(sum_j/sum)+ccd_origin_y;
		position_ij.i:=round(sum_i/sum);
		position_ij.j:=round(sum_j/sum);
		x:=pixel_size_um*position_xy.x;
		y:=pixel_size_um*position_xy.y;
		accuracy:=xy_length(xy_scale(
			xy_difference(step_position_xy,position_xy),
			pixel_size_um/threshold_step));
		num_pixels:=count;
		sum_intensity:=sum;
		max_intensity:=max;
		min_intensity:=min;

		valid:=not math_error(accuracy)
			and not math_error(position_xy.x)
			and not math_error(position_xy.y);
	end;
end;

{
	spot_vertical_line fits a line to the pixels in an image with overlay color
	equal to color_code. It sets spot.x to the intercept of this wire with the
	top edge of the CCD in um, and spot.y to the anti-clockwise rotation of the wire 
	in mrad.
}
procedure spot_vertical_line(ip:image_ptr_type;var spot:spot_type);

const
	max_pixels=10000;
	
var
	i,j,pixel_num:integer;
	gp:xyz_graph_ptr_type;
	slope,intercept,residual:real;

begin
	if not spot.valid then exit;
	if ip=nil then exit;
	
	gp:=new_xyz_graph(max_pixels);
	
	pixel_num:=0;
	gp^[pixel_num].z:=ignore_remaining_data;
	with spot.bounds do begin
		for j:=top to bottom do begin
			for i:=left to right do begin
				if (ip^.overlay[j,i]=spot.color_code) and (pixel_num<max_pixels-1) then begin
					with gp^[pixel_num] do begin
						x:=j+ccd_origin_y;
						y:=i+ccd_origin_x;
						z:=ip^.intensity[j,i];
					end;
					inc(pixel_num);
					gp^[pixel_num].z:=ignore_remaining_data;
				end;
			end;
		end;
	end;

	weighted_straight_line_fit(gp,slope,intercept,residual);
	dispose_xyz_graph(gp);

	if math_error(slope) 
			or math_error(intercept) 
			or math_error(residual) then begin
		spot.valid:=false;
		exit;
	end;
	
	with spot do begin
		x:=intercept*pixel_size_um;
		y:=slope*mrad_per_rad;
		if pixel_num>0 then
			accuracy:=residual*pixel_size_um/sqrt(pixel_num)
		else
			accuracy:=0;
	end;
end;

{
	spot_ellipse fits an ellipse to the border of a spot, and returns
	the coordinates of the center of the ellipse. It fills in the fields
	of the ellipse record in the spot.
}
procedure spot_ellipse(ip:image_ptr_type;var spot:spot_type);

const
	num_parameters=5;
	max_iterations=40;
	bounds_extra=5;
	
	{
		border_match returns true iff point p is on the border of the
		specified ellipse, and is also on the border of the spot defined
		by spot.threshold.
	}
	function border_match(p:ij_point_type;e:xy_ellipse_type):boolean;
	const
		image_border=2;
	var 
		i_min,i_max,j_min,j_max,i,j:integer;
		s:real;
		q:ij_point_type;
		on_image,on_fit:boolean;
	begin
		on_image:=false;
		on_fit:=false;
		s:=xy_separation(i_from_c(p),e.a)+xy_separation(i_from_c(p),e.b);
		if (s<=e.axis_length) 
			and (s>=e.axis_length-image_border) 
			and (ip^.intensity[p.j,p.i]>spot.threshold) then begin
			with ip^.analysis_bounds do begin
				if p.i>left then i_min:=p.i-1 else i_min:=left;
				if p.i<right then i_max:=p.i+1 else i_max:=right;
				if p.j>top then j_min:=p.j-1 else j_min:=top;
				if p.j<bottom then j_max:=p.j+1 else j_max:=bottom;
			end;
			for q.i:=i_min to i_max do begin
				for q.j:=j_min to j_max do begin
					if (xy_separation(i_from_c(q),e.a)
						+xy_separation(i_from_c(q),e.b))
						>e.axis_length then
						on_fit:=true;
					if (ip^.intensity[q.j,q.i]<=spot.threshold) then
						on_image:=true;
				end;
			end;
		end;
		border_match:=on_fit and on_image;
	end;

	{
		The error function we provide for the simplex fitter counts the number
		of pixels in the image analysis bounds that are on the border of the
		spot in the image and also on the border of the ellipse defined by
		vertex "v". The error is the negative of the number of border-coincident
		pixels. We took the idea for border-coincidence from "Robust Ellipse
		Detection by Fitting Randomly Selected Edge Patches" by Watcharin
		Kaewapichai, and Pakorn Kaewtrakulpong. We don't use their method, but
		we take from it the one idea of matching edge pixels to determine
		fitness of the ellipse.
	}
	function error(v:simplex_vertex_type):real;
	var
		fitness:real;
		p:ij_point_type;
		pp:xy_point_type;
		e:xy_ellipse_type;
	begin
		fitness:=0;
		with e do begin
			a.x:=v[1];
			a.y:=v[2];
			b.x:=v[3];
			b.y:=v[4];
			axis_length:=v[5];
		end;
		for p.i:=ip^.analysis_bounds.left to ip^.analysis_bounds.right do 
			for p.j:=ip^.analysis_bounds.top to ip^.analysis_bounds.bottom do
				if border_match(p,e) then
					fitness:=fitness+1;
		error:=-fitness;
	end;

var
	simplex:simplex_type(num_parameters);
	saved_bounds:ij_rectangle_type;
	i:integer;
	
begin
	if not spot.valid then exit;
	if ip=nil then exit;
{
	We start with an ellipse that fills the spot bounds.
}
	spot.ellipse:=xy_rectangle_ellipse(i_from_c_rectangle(spot.bounds));
{
	Set up the simplex we use with the simplex fitter. We assign the initial
	ellipse fields to the first vertex of the simplex, and construct the 
	simplex from there.
}
	with simplex,spot.ellipse do begin
		vertices[1,1]:=a.x;
		vertices[1,2]:=a.y;
		vertices[1,3]:=b.x;
		vertices[1,4]:=b.y;
		vertices[1,5]:=axis_length;
		construct_size:=1;
		done_counter:=0;
		max_done_counter:=2;
	end;
	simplex_construct(simplex,error);	
{
	Reduce the image's analysis boundaries to the small boundary around the
	spot, but add bounds_extra pixels on all sides to help the fitter.
}
	saved_bounds:=ip^.analysis_bounds;
	ip^.analysis_bounds:=spot.bounds;
	with ip^.analysis_bounds do begin
		left:=left-bounds_extra;
		if left<saved_bounds.left then left:=saved_bounds.left;
		right:=right+bounds_extra;
		if right>saved_bounds.right then right:=saved_bounds.right;
		top:=top-bounds_extra;
		if top<saved_bounds.top then top:=saved_bounds.top;
		bottom:=bottom+bounds_extra;
		if bottom>saved_bounds.bottom then bottom:=saved_bounds.bottom;
	end;
{
	Apply the simplex fitter, one step at a time until it's done or we
	have exceeded the maximum number of iterations.
}
	i:=0;
	repeat
		simplex_step(simplex,error);
		inc(i);
	until (simplex.done_counter>=simplex.max_done_counter) or (i>max_iterations);
{
	Restore the image bounds.
}
	ip^.analysis_bounds:=saved_bounds;
{
	Fill the spot ellipse with the fitted values, determine the ellipse center and 
	adjust the spot position accordingly. We estimate the fitting error by dividing
	the pixel size by the square root of the number of border pixels.
}
	with simplex,spot do begin
		ellipse.a.x:=vertices[1,1];
		ellipse.a.y:=vertices[1,2];
		ellipse.b.x:=vertices[1,3];
		ellipse.b.y:=vertices[1,4];
		ellipse.axis_length:=vertices[1,5];
		position_xy:=xy_scale(xy_sum(ellipse.a,ellipse.b),one_half);
		position_ij:=c_from_i(position_xy);
		x:=position_xy.x*pixel_size_um;
		y:=position_xy.y*pixel_size_um;
		accuracy:=pixel_size_um/sqrt(-error(vertices[1]));
	end;	
end;

{
	spot_eccentricity returns the elliptic eccentricity of a spot, which is its
	maximum length divided by its minimum width.
}
function spot_eccentricity(s:spot_type):real;

var
	e:real;
	
begin
	if not s.valid then begin
		spot_eccentricity:=0;
		exit;
	end;
	
	with s do begin
		with bounds do begin 
			e:=(right-left)/(bottom-top);
			if e<1 then e:=1/e;
			e:=e*((right-left)*(bottom-top)*pi/4)/num_pixels;
		end;
	end;
	spot_eccentricity:=e;
end;

{
	string_from_spot returns a string expressing the
	most prominent elements of a spot record.
}
function string_from_spot(c:spot_type):short_string;

var  
	s:short_string;

begin
	if c.valid then
		with c,c.bounds do
			writestr(s,x:4:2,' ',y:4:2,' ',
				num_pixels:1,' ',max_intensity:1,' ',
				accuracy:5:3,' ',threshold:1)
	else 
		writestr(s,spot_missing_string,' ',c.threshold:1);
	string_from_spot:=s;
end;

{
	string_from_spot_list returns a string made by concatinating the
	string_from_spots for all the spots in the list.
}
function string_from_spot_list(slp:spot_list_ptr_type):short_string;

var
	spot_num:integer;
	s:short_string;
	
begin
	if slp=nil then exit;
	s:='';
	for spot_num:=1 to slp^.num_requested_spots do begin 
		writestr(s,s,string_from_spot(slp^.spots[spot_num]));
		if spot_num<slp^.num_requested_spots then writestr(s,s,' ');
	end;
	string_from_spot_list:=s;
end;

{
	bounds_string_from_spot_list returns a string made by the bounds of
	all spots in a list. The bounds are given as left, right, top, bottom of 
	each rectangle.
}
function bounds_string_from_spot_list(slp:spot_list_ptr_type):short_string;

var
	spot_num:integer;
	s:short_string;
	
begin
	if slp=nil then exit;
	s:='';
	for spot_num:=1 to slp^.num_requested_spots do begin
		if slp^.spots[spot_num].valid then
			with slp^.spots[spot_num].bounds do
				writestr(s,s,left:1,' ',top:1,' ',right:1,' ',bottom:1)
		else
			writestr(s,s,spot_missing_bounds_string);
		if spot_num<slp^.length then writestr(s,s,' ');
	end;
	bounds_string_from_spot_list:=s;
end;

{
	intensity_string_from_spot_list returns a string containing the intensity
	of each spot in a list.
}
function intensity_string_from_spot_list(slp:spot_list_ptr_type):short_string;

var
	spot_num:integer;
	s:short_string;
	
begin
	if slp=nil then exit;
	s:='';
	for spot_num:=1 to slp^.num_requested_spots do begin
		if slp^.spots[spot_num].valid then
			writestr(s,s,slp^.spots[spot_num].sum_intensity:1)
		else
			writestr(s,s,-1);
		if spot_num<slp^.length then writestr(s,s,' ');
	end;
	intensity_string_from_spot_list:=s;
end;

{
	spot_list_sort sorts a spot list in order of decreasing
	intensity, increasing x-coordinate, increasing y-coordinate, 
	decreasing x-coordinate or decreasing y-coordinate, depending
	upon sort_code. The routine always sorts the spots into valid
	spots first and invalid spots last, before it applies any other
	criteria for sorting.
}
procedure spot_list_sort(slp:spot_list_ptr_type;
	sort_code:integer);
	
const
	max_num_swaps=1000;
	
var
	temp_spot:spot_type;
	spot_num,num_swaps:integer;
	no_swaps,swap_now:boolean;
	
begin
	if slp=nil then exit;
	num_swaps:=0;
	repeat
		no_swaps:=true;
		with slp^ do begin
			for spot_num:=1 to num_valid_spots-1 do begin
				case sort_code of
					spot_decreasing_total_intensity: swap_now:=
						spots[spot_num].sum_intensity < spots[spot_num+1].sum_intensity;
					spot_increasing_x: swap_now:=
						spots[spot_num].x > spots[spot_num+1].x;
					spot_increasing_y: swap_now:=
						spots[spot_num].y > spots[spot_num+1].y;
					spot_decreasing_x: swap_now:=
						spots[spot_num].x < spots[spot_num+1].x;
					spot_decreasing_y: swap_now:=
						spots[spot_num].y < spots[spot_num+1].y;
					spot_decreasing_max_intensity: swap_now:=
						spots[spot_num].max_intensity < spots[spot_num+1].max_intensity;
					spot_decreasing_size: swap_now:=
						spots[spot_num].num_pixels < spots[spot_num+1].num_pixels;
					otherwise swap_now:=false;
				end;
				if (not spots[spot_num].valid) and (spots[spot_num+1].valid) then
					swap_now:=true;
				if swap_now then begin
					temp_spot:=spots[spot_num];
					spots[spot_num]:=spots[spot_num+1];
					spots[spot_num+1]:=temp_spot;
					no_swaps:=false;
					inc(num_swaps);
				end;
			end;
		end;
	until no_swaps or (num_swaps>max_num_swaps);
end;

{
	do_pixel takes as input a spot list pointer and the coordinates of
	a pixel in an image. The spot list provides a pointer to the image
	and a list of spots. The last valid spot in the list is the one
	do_pixel operates upon. do_pixel checks to see if pixel (i,j) in
	the image has intensity above the threshold specified in the spot
	record. Pixel (i,j) is the pixel in the i'th column and j'th row.
	If this pixel is above threshold and has not yet been marked as
	belonging to any spot, do_pixel adds the pixel to the spot by
	setting the pixel's image overlay value equal to the spot's color
	code. After adding the pixel to the spot, do_pixel calls itself
	upon all the pixel's neighbors. These neighbors will always
	include the pixels above, below, to the left, and to the right of
	the pixel. If kitty_corner is true, the neighbors will also
	include the four other diagonal neighbor pixels. By these
	recursive calls, if the threshold is lower than the average image
	intensity, we can end up with spots that contain an entire image.
	We protect against stack overflow by limiting the depth of recursion
	for do_pixel, and we make sure that we are able to get almost all
	the spot in almost all cases by proceeding in a clockwise manner
	when we call do_pixel on a pixel's neighbors. Because our spot
	finding routine scans through an image from top to bottom and left
	to right until it finds the first pixel of a spot, we proceed
	from top-left, to top, to top-right, and so on to bottom-left
	and left when we call do_pixel.
}
procedure do_pixel(slp:spot_list_ptr_type;j,i:integer);

var 
	net_intensity:integer;

begin
	if slp=nil then exit;
	if current_stack_depth<max_stack_depth then begin
		inc(current_stack_depth);
		with slp^ do begin
			with ip^,ip^.analysis_bounds,spots[num_valid_spots] do begin
				if (intensity[j,i]>threshold) and (overlay[j,i]=clear_color) then begin
					inc(num_pixels);
					overlay[j,i]:=color_code;
					
					if j>bounds.bottom then bounds.bottom:=j;
					if j<bounds.top then bounds.top:=j;
					if i>bounds.right then bounds.right:=i;
					if i<bounds.left then bounds.left:=i;
					
					if (i<right) then do_pixel(slp,j,i+1);
					if (j<bottom) and (i<right) then do_pixel(slp,j+1,i+1);
					if (j<bottom) then do_pixel(slp,j+1,i);
					if (j<bottom) and (i>left) then do_pixel(slp,j+1,i-1);
					if (i>left) then do_pixel(slp,j,i-1);
					if (j>top) and (i>left) then do_pixel(slp,j-1,i-1);
					if (j>top) then do_pixel(slp,j-1,i);
					if (j>top) and (i<right) then do_pixel(slp,j-1,i+1);
				end;
			end;
		end;
		dec(current_stack_depth);
	end;
end;

{
	spot_list_find finds multiple spots in an image and records them in a
	spot_list_type, which the calling process must dispose of itself. The
	routine uses the image overlay to mark the spots its finds. It clears the
	overlay at the start of execution. The color black (0) is reserved for
	pixels below threshold. The color white (255) is reserved for pixels above
	threshold that are not part of a valid spot. The spots in the spot list each
	have their own boundries, each boundary being the minimum ij_rectangle_type
	that encloses the spot, plus a minimum border assigned by the spot_centroid
	procedure. The routine starts by finding as many valid spots as it can. A
	spot is any collection of adjacent pixels that are above the threshold
	specified by the command string. The routine checks each spot to see if it
	passes the criteria for width, height, and eccentricity that may have been
	specified in the command string. If the spot does not qualify,
	spot_list_find changes the color of its pixels to white and rejects the
	spot. The routine sorts all qualifying spots in order of descending
	intensity and then eliminates all but the num_spots brightest spots. The
	routine leaves its markings in the overlay afterwards, which is how we can
	use the overlay to see which pixels it has used.
}
function spot_list_find(ip:image_ptr_type;
	num_spots:integer;
	command:short_string;
	pixel_size_um:real):spot_list_ptr_type;

const
	percent_unit=100;
	
var 
	min_pixels,threshold,fraction:integer;
	i,j,ii,jj:integer;
	color_code,spot_num:integer;
	slp,slp_final:spot_list_ptr_type;
	ccd_origin:xy_point_type;
	temp_spot:spot_type;
	no_swaps,okay:boolean;
	spot:spot_type;
	word:short_string;
	max_eccentricity:real;
	
begin
{
	Set spot_list_find to nil in case we abort.
}
	spot_list_find:=nil;
	if ip=nil then exit;
	if num_spots>max_num_spots then begin
		report_error('num_spots>max_num_spots in '+CurrentRoutineName+'.');
		exit;
	end;
{
	Decode the command string. First we read the threshold, then we look for a
	valid threshold qualifier. We read the minimum number of pixels in each spot
	and the maximum eccentricity.
}
	threshold:=read_integer(command);
	word:=read_word(command);
	if word='%' then 
		threshold:=
			round((1-threshold/percent_unit)*image_minimum(ip)
			+threshold/percent_unit*image_maximum(ip))
	else if word='#' then
		threshold:=
			round((1-threshold/percent_unit)*image_average(ip)
			+threshold/percent_unit*image_maximum(ip))
	else if word='*' then 
		threshold:=threshold
	else if word='$' then 
		threshold:=round(image_average(ip)+threshold)
	else command:=word+' '+command;
	
	min_pixels:=read_integer(command);
	if min_pixels<1 then min_pixels:=1;
	max_eccentricity:=read_real(command);
	if max_eccentricity<1 then max_eccentricity:=0;
{
	It's okay to pass empty strings to read_integer and read_real, but if 
	we passed a non-numeric, non-empty string, these routines will have recorded
	and error, and we should now quit with this error before we run into trouble.
}
	if error_string<>'' then exit;
{
	Assign a new spot list to hold our maximum number of 
	spots.
}
	slp:=new_spot_list_ptr(max_num_spots);
	if slp=nil then begin
		report_error('Failed to allocate for slp in '+CurrentRoutineName+'.');
		exit;
	end;
	slp^.ip:=ip;
	for spot_num:=1 to max_num_spots do
		slp^.spots[spot_num].threshold:=threshold;
{
	Clear the image overlay so we can use it to mark pixels as belonging to
	the spots.
}	
	clear_overlay(ip);
{
	Proceed through the entire image, calling do_pixel each time we find a pixel
	unmarked in the overlay whose intensity is above the threshold. Each time we call
	do_pixel we assume the routine gathers all the light spot's pixels together.
}
	with ip^,ip^.analysis_bounds do begin
		for j:=top to bottom do begin
			for i:=left to right do begin
				if (intensity[j,i]>threshold) 
						and (overlay[j,i]=clear_color)
						and (slp^.num_valid_spots<slp^.length) then begin
					with slp^ do begin
						inc(num_valid_spots);
						current_stack_depth:=0;
						spots[num_valid_spots].pixel_size_um:=pixel_size_um;
						with spots[num_valid_spots] do begin
							color_code:=overlay_color_from_integer(num_valid_spots);
							bounds.left:=ip^.analysis_bounds.right;
							bounds.right:=ip^.analysis_bounds.left;
							bounds.top:=ip^.analysis_bounds.bottom;
							bounds.bottom:=ip^.analysis_bounds.top;
							num_pixels:=0;
						end;
						do_pixel(slp,j,i);
						with spots[num_valid_spots] do begin
							valid:=true;
							if num_pixels<min_pixels then valid:=false;
							if (max_eccentricity<>0) then
								if (spot_eccentricity(spots[num_valid_spots])>max_eccentricity) then 
									valid:=false;
							if (not valid) and (num_pixels>0) then begin
								for jj:=bounds.top to bounds.bottom do
									for ii:=bounds.left to bounds.right do
										if ip^.overlay[jj,ii]=color_code then
											ip^.overlay[jj,ii]:=white_color;
							end;
						end;
						if spots[num_valid_spots].valid then
							spot_centroid(ip,spots[num_valid_spots])
						else 
							dec(num_valid_spots);
					end;
				end;
			end;
		end;
	end;
{
	Sort the spots in order of decreasing intensity.
}
	spot_list_sort(slp,spot_decreasing_total_intensity);
{
	If we have more than enough valid spots, remove the excess
	by setting num_valid_spots equal to the number of requested spots.
}
	if slp^.num_valid_spots>num_spots then slp^.num_valid_spots:=num_spots;
{
	Record the number of spots requested in the spot list.
}
	slp^.num_requested_spots:=num_spots;
{
	Return the list. The list may have fewer than num_spots valid entries.
	The routine that uses the spot list must check the valid flag on each 
	spot before using it.
}
	spot_list_find:=slp;
end;

{
	spot_list_merge combines separate spots that may be part of the same
	feature. For example, suppose we are looking at a near-vertical stripe in an
	image. When the stripe is bright enough, it forms one connected set of
	pixels, and therefore one spot. But when the stripe is dim, it may fragment
	into separate spots. We call spot_list_merge with the "vertical" command,
	and we merge these separates spots into one spot whose pixels are not
	connected, but which represent the same image feature.
	
	The merge routine does not pay attention to the num_valid_spots value 
	stored in the spot list pointer. Instead, it compares all valid spots to
	all other valid spots, looking for possible merges. 
	
	When the routine merges two spots, it changes the color of all the pixels
	in the overlay corresponding to the second spot so that they are the same
	as the overlay color of the first spot. The routine expands the bounds 
	rectangle to include all the pixels.
	
	NOTE: At the moment, only vertical merging is supported.
}
procedure spot_list_merge(ip:image_ptr_type;slp:spot_list_ptr_type;command:short_string);

var
	a,b,i,j:integer;
	la,lb:xy_line_type;
	count:integer;
	
begin
	if slp=nil then exit;
	if ip=nil then exit;
	
	if command<>'vertical' then begin
		report_error('Only vertical merging is supported in spot_list_merge');
		exit;
	end;
	
	with slp^ do begin
		for a:=1 to max_num_spots do
			spot_vertical_line(ip,spots[a]);
	
		for a:=1 to max_num_spots-1 do begin
			if spots[a].valid then begin
				with spots[a],la do begin
					a.x:=x/pixel_size_um+bounds.top*y/mrad_per_rad;
					a.y:=bounds.top;
					b.x:=x/pixel_size_um+bounds.bottom*y/mrad_per_rad;
					b.y:=bounds.bottom;
				end;	
				for b:=a+1 to max_num_spots do begin
					if spots[b].valid then begin
						with spots[b],lb do begin
							a.x:=x/pixel_size_um+bounds.top*y/mrad_per_rad;
							a.y:=bounds.top;
							b.x:=x/pixel_size_um+bounds.bottom*y/mrad_per_rad;
							b.y:=bounds.bottom;
						end;
						if ij_line_crosses_rectangle(
								c_from_i_line(la),spots[b].bounds) 
							and ij_line_crosses_rectangle(
								c_from_i_line(lb),spots[a].bounds) then begin
							count:=0;
							with spots[b].bounds do begin
								for j:=top to bottom do begin
									for i:=left to right do begin
										if ip^.overlay[j,i]=spots[b].color_code then begin
											ip^.overlay[j,i]:=spots[a].color_code;
											inc(count);
										end;
									end;
								end;
							end;
							spots[b].valid:=false;
							spots[a].bounds:=
								ij_combine_rectangles(spots[a].bounds,spots[b].bounds);
							spots[a].num_pixels:=
								spots[a].num_pixels+spots[b].num_pixels;
							spots[a].sum_intensity:=
								spots[a].sum_intensity+spots[b].sum_intensity;
							if spots[a].max_intensity<spots[b].max_intensity then
								spots[a].max_intensity:=spots[b].max_intensity;
							if spots[a].min_intensity>spots[b].min_intensity then
								spots[a].min_intensity:=spots[b].min_intensity;
						end;
					end;
				end;
			end;
		end;
	end;	
	spot_list_sort(slp,spot_decreasing_total_intensity);
end;

{
	spot_list_display_bounds displays the bounds of a list of spots.
}
procedure spot_list_display_bounds(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);

const
	min_square_width=10;
	extent=min_square_width div 2;
	
var
	spot_num:integer;
	r:ij_rectangle_type;
	
begin
	if slp=nil then exit;
	for spot_num:=1 to slp^.num_valid_spots do begin
		r:=slp^.spots[spot_num].bounds;
		with r,slp^.spots[spot_num].position_ij do begin
			if abs(right-left)<min_square_width then begin
				right:=i+extent;
				left:=i-extent;
			end;
			if abs(bottom-top)<min_square_width then begin
				bottom:=j+extent;
				top:=j-extent;
			end;
		end;
		display_ccd_rectangle(ip,r,color);
	end;
end;

{
	spot_list_display_crosses displays crosses on a list of spots.
}
procedure spot_list_display_crosses(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);

var
	spot_num:integer;
	
begin
	if slp=nil then exit;
	for spot_num:=1 to slp^.num_valid_spots do
		display_ccd_cross(ip,slp^.spots[spot_num].position_ij,color);
end;

{
	spot_list_display_vertical_lines displays vertical lines.
}
procedure spot_list_display_vertical_lines(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);

var
	spot_num:integer;
	i_line:xy_line_type;
	
begin
	if slp=nil then exit;
	for spot_num:=1 to slp^.num_valid_spots do begin
		with slp^.spots[spot_num] do begin
			i_line.a.x:=x/pixel_size_um+bounds.top*y/mrad_per_rad;
			i_line.a.y:=bounds.top;
			i_line.b.x:=x/pixel_size_um+bounds.bottom*y/mrad_per_rad;
			i_line.b.y:=bounds.bottom;
			display_ccd_line(ip,c_from_i_line(i_line),color);
		end;
	end;
end;

{
	spot_list_display_ellipses displays ellipses in the bounds of a list of
	spots.
}
procedure spot_list_display_ellipses(ip:image_ptr_type;slp:spot_list_ptr_type;
	color:integer);

var
	spot_num,count:integer;
	saved_bounds:ij_rectangle_type;
	
begin
	if slp=nil then exit;
	saved_bounds:=ip^.analysis_bounds;
	for spot_num:=1 to slp^.num_valid_spots do begin
		with slp^.spots[spot_num] do begin
			ip^.analysis_bounds:=bounds;
			display_ccd_ellipse(ip,c_from_i_ellipse(ellipse),color);
		end;
	end;
	ip^.analysis_bounds:=saved_bounds;
end;	

{
	initialization does nothing.
}
initialization 

{
	finalization does nothing.
}
finalization 

end.