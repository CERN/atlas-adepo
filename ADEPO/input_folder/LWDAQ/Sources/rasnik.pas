{
	Routines for Rasnik Image Analysis 
	Copyright (C) 2004-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
	
	This program is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or (at
	your option) any later version.
	
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
	USA.
	
	Please note that RASNIK is a trademark of the NIKHEF laboratory in
	Holland. NIKHEF holds the patent on the chessboard-like mask pattern
	that the following code analyzes.
	
	For a web page describing this code, see:
	
	http://alignment.hep.brandeis.edu/Devices/RASNIK/
}

unit rasnik;

interface

uses
	utils,images,transforms,image_manip;

const	
{
	The number of squares betweeen the rows and columns of code squares
	in a rasnik mask.
}
	rasnik_code_pitch=9;

{
	We specify the maximum and minimum number of squares across the
	image width. From these we determine the maximum extent of the
	rasnik pattern, in square widths, from the pattern origin, which
	lies as close as the analysis can place it to the center of the 
	analysis bounds.
}
	rasnik_min_squares_across=8; {squares}
	rasnik_max_squares_across=200; {squares}
	rasnik_min_pixels_per_square=2.5; {pixels}
{
	In its initial stages, the analysis divides an image into slices.
	It finds rasnik square edges in each slice, and draws lines from
	each edge in one slice to the nearest edge in its neighboring
	slice. (You can see the slices when you turn on show_fitting.) If
	the mask is rotated, and the slices are far apart, it is possible
	for the nearest edge in the neighboring slice to correspond to a
	different edge in the mask. The greater the rotation, the more
	slices the analysis must take in order to get the initial pattern
	position, magnification and orientation. We have found empirically
	that the maximum rotation in radians it approximately equal to
	rasnik_num_slices*square_width/analysis_bounds_width/4. For
	example, if the square width is 10 pixels and the image analysis
	bounds are 300 pixels wide, we can measure a rotation of up to
	+-70 mrad with rasnik_num_slices = 8. Half of the execution time
	of the rasnik analysis is occupied by the slices. If you reduce
	rasnik_num_slices to 3, you will reduce the execution time by 40%,
	but you will be able to tolerate only +-25 mrad rotations.
}
	rasnik_num_slices=8;
{
	The rasnik_invalid_string will be used to represent and invalid
	rasnik result when the result must be represented as a string.
}
	rasnik_invalid_string='ERROR: Rasnik analysis failed.';
{
	We define codes that identify the orientation
	of the rasnik mask in the image. The nominal orientation
	is when the x-code increases left to right, and the
	y-code increases bottom to top, as in the x-y 
	coordinates defined in the mask. The z-coordinate
	is perpendicular to these two. There are four possible
	orientation only, because we cannot distinguish between
	x and y codes. They represent coordinates in the mask,
	but they do not tell us which coordinate they represent.
}
	rasnik_mask_orientation_nominal=1;
	rasnik_mask_orientation_rotated_y=2;
	rasnik_mask_orientation_rotated_x=3;
	rasnik_mask_orientation_rotated_z=4;
	rasnik_try_all_orientations=0;
{
	Here we define reference codes that tell the rasnik analysis
	which point in the image it should project back into the 
	mask to obtain the rasnik measurement. We can specify our 
	own reference point in image coordinates if we pass code
	number three.
}
	rasnik_reference_top_left_corner=0;
	rasnik_reference_center_analysis_bounds=1;
	rasnik_reference_center_ccd=2;
	rasnik_reference_image_point=3;

type
	rasnik_square_type=record
		center_pp:xy_point_type; {center of square in pattern coordinates}
		center_intensity:real; {average intensity of central region}
		center_whiteness:real; {whiteness score, >0 for white, <=0 for black}
		pivot_correlation:integer; {number of agreeing pivot squares}
		x_code,y_code:integer; {the column and line codes for the pivot square}
		display_outline:ij_rectangle_type; {a rectange for square marking}
		is_a_valid_square:boolean; {within the analysis boundaries}
		is_a_code_square:boolean; {out of parity with the chessboard}
		is_a_pivot_square:boolean; {at intersection of code line and column}
		padding:array [1..13] of byte; {ample padding to eight-byte boundary}
	end;
	rasnik_square_ptr_type=^rasnik_square_type;
	rasnik_square_array_type(extent:integer)=
		array [-extent..extent,-extent..extent] of rasnik_square_type;
	rasnik_square_array_ptr_type=^rasnik_square_array_type;
{
	rasnik_pattern_type defines a rasnik mask pattern superimposed upon
	an image. The origin of the pattern is the top-left corner of a square 
	in the rasnik pattern. Our analysis tries to choose a square towards
	the center of the image, but any square in the image could provide the
	origin.
}
	rasnik_pattern_type=record {based upon pattern_type of image_types}
		valid:boolean;{most recent analysis yielded valid output}
		padding:array [1..7] of byte;{force origin to eight-byte boundary}
		origin:xy_point_type;{pattern coordinate origin in image coordinates}
		rotation:real;{radians anticlockwize wrt image coords}
		pattern_x_width,pattern_y_width:real;{square width in pixels along pattern coords}
		image_x_width,image_y_width:real;{square separation in pixels along image coords}
		error:real;{pixels rms in image}
		extent:integer;{extent of pattern from center of analysis bounds}
		mask_orientation:integer;{integer indicating orientation of mask}
		x_code_direction,y_code_direction:integer;{directions of code increment}
		analysis_center_cp:ij_point_type;{ccd coords of analysis bounds center}
		analysis_width:real;{diagnonal width of anlysis bounds}
		squares:rasnik_square_array_ptr_type;{array of rasnik squares}
		more_padding:array [1..4] of byte;{force end to eight-byte boundary}
	end;
	rasnik_pattern_ptr_type=^rasnik_pattern_type;
	rasnik_type=record
		valid:boolean;{no problems encountered during analysis}
		padding:array [1..7] of byte;{force mask_point to eight-byte boundary}
		mask_point:xy_point_type;{point in mask, um}
		magnification_x,magnification_y:real;{magnification along pattern coords}
		rotation:real;{radians anticlockwize in image}
		error:real;{um rms in mask}
		mask_orientation:integer;{orientation chosen by analysis}
		reference_code:integer;{reference code used to obtain reference point}
		reference_point:xy_point_type;{point in image, um from top-left corner}
		square_size_um:real;{width of mask squares}
		pixel_size_um:real;{width of a sensor pixel in um}
	end;
	rasnik_ptr_type=^rasnik_type;

function new_rasnik_pattern:rasnik_pattern_ptr_type;
	attribute (name='New_Rasnik_Pattern');
procedure dispose_rasnik_pattern(pp:rasnik_pattern_ptr_type);
	attribute (name='Dispose_Rasnik_Pattern');
procedure rasnik_adjust_pattern_parity(ip:image_ptr_type;pp:rasnik_pattern_ptr_type);
	attribute (name='Rasnik_Adjust_Pattern_Parity');
procedure rasnik_analyze_code(pp:rasnik_pattern_ptr_type;orientation_code:integer);
	attribute (name='Rasnik_Analyze_Code');
procedure rasnik_display_pattern(ip:image_ptr_type;pp:rasnik_pattern_ptr_type;
	mark_valid:boolean);
procedure rasnik_display_reference_point(ip:image_ptr_type;
	reference_code:integer;reference_x,reference_y:real;
	pixel_size_um:real);
function rasnik_find_pattern(iip,jip:image_ptr_type;show_fitting:boolean)
	:rasnik_pattern_ptr_type;
	attribute (name='Rasnik_Find_Pattern');
procedure rasnik_refine_pattern(pp:rasnik_pattern_ptr_type;
	iip,jip:image_ptr_type;show_fitting:boolean);
	attribute (name='Rasnik_Refine_Pattern');
function rasnik_from_pattern(ip:image_ptr_type;
	pp:rasnik_pattern_ptr_type;
	reference_code:integer;
	reference_x,reference_y:real;
	square_size_um,pixel_size_um:real):rasnik_ptr_type;
	attribute (name='Rasnik_From_Pattern');
procedure rasnik_identify_code_squares(ip:image_ptr_type;
	pp:rasnik_pattern_ptr_type);
	attribute (name='Rasnik_Identify_Code_Squares');
procedure rasnik_identify_pattern_squares(ip:image_ptr_type;
	pp:rasnik_pattern_ptr_type);
	attribute (name='Rasnik_Identify_Pattern_Squares');
function rasnik_mask_position(pp:rasnik_pattern_ptr_type;
	reference_point:xy_point_type;
	square_size_um,pixel_size_um:real):xy_point_type;
function rasnik_pattern_from_string(s:short_string):rasnik_pattern_ptr_type;
function rasnik_from_string(s:short_string):rasnik_type;
function rasnik_reference_point(ip:image_ptr_type;reference_code:integer;
	reference_x,reference_y:real;pixel_size_um:real):xy_point_type;
function rasnik_shift_reference_point(rasnik:rasnik_type;
	new_reference_point:xy_point_type):rasnik_type;
procedure rasnik_simulated_image(ip:image_ptr_type;command:short_string);
function string_from_rasnik_pattern(pp:rasnik_pattern_ptr_type):short_string;
function string_from_rasnik(rp:rasnik_ptr_type):short_string;

{
	Interface for C programs. The routines declared with the "attribute" key word
	above are also for use with C programs.
}
function new_rasnik:rasnik_ptr_type;
	attribute (name='New_Rasnik');
procedure dispose_rasnik(rp:rasnik_ptr_type);
	attribute (name='Dispose_Rasnik');
function rasnik_analyze_image(ip:image_ptr_type;
	orientation_code,reference_code:integer;
	reference_x,reference_y,square_size_um,pixel_size_um:real):rasnik_ptr_type;
	attribute (name='Rasnik_Analyze_Image');
function rasnik_analyze_file(file_name:CString;
	orientation_code,reference_code:integer;
	reference_x,reference_y,square_size_um,pixel_size_um:real):rasnik_ptr_type;
	attribute (name='Rasnik_Analyze_File');
procedure rasnik_get_square(sp:rasnik_square_ptr_type;
	sap:rasnik_square_array_ptr_type;a,b:integer);
	attribute (name='Rasnik_Get_Square');
procedure rasnik_put_square(sp:rasnik_square_ptr_type;
	sap:rasnik_square_array_ptr_type;a,b:integer);
	attribute (name='Rasnik_Put_Square');

implementation

const 
	{
		We limit the size of the pattern in memory with the help of the
		maximum number of squares permitted across the width and height 
		of the analysis boundaries.
	}
	rasnik_max_pattern_extent=rasnik_max_squares_across div 2;
	off_screen=rasnik_max_pattern_extent;
	{
		When we identify code squares, we save time, and avoid most problems
		with dust, if we concentrate upon a central region of the square, 
		where contrast is always brightest. Here we define a default fractional
		width for this central region, and put limits on the number of pixels
		on either side of the center pixel that we will use for calculating
		the center intensity. Another advantage of using only the center of
		a squares is that we can accept code squares that are overlapping the
		edge of the analysis boundaries.
	}
	square_center_offset=one_half;
	square_center_fraction=0.1;
	max_square_center_extent=10;
	min_square_center_extent=0;
	{
		For clarity, we define constants for the value of the x and y codes
		at the origin of the mask, and we specify the exact location of this 
		origin also: it is not at a corner of the origin pivot square, but
		at the center.
	}
	mask_origin_x_code=0;
	mask_origin_y_code=0;
	mask_origin_offset=one_half;
	{
		Code squares are those that are white when a chessboard square would
		be black, or black when a chessboard square would be white. When we
		detect them, we score the whitness of each square on a scale of 
		-1 to +1 where -1 is certainly black and +1 is certainly white. The
		following constant determines the threshold of whiteness we use to
		decide that a square is out of parity. 
	}
	min_whiteness=0.1;
	{
		When we find the period of the chessboard pattern, we set some
		limits on what this period can be, so as to help us reject 
		noise and other faulty images more quickly. The slices are the
		strips across the derivative image that we use to obtain the
		square pitch. These must be thick enough to provide a clear 
		periodic signal in the average column intensity of the strip,
		but narrow enough to avoid a rotated chessboard from having no
		apparent periodicity in the slice direction.
	}
	min_periods_per_profile=rasnik_code_pitch-2;
	min_slice_thickness=20;{in pixels}
	max_slice_thickness=50;{in pixels}
	
{
	new_rasnik allocates space for a new rasnik_type and initializes its
	contents.
}
function new_rasnik:rasnik_ptr_type;

var
	rp:rasnik_ptr_type;
	
begin
	new(rp);
	if rp=nil then begin
		report_error('Failed to allocate space for new_rasnik.');
		new_rasnik:=nil;
		exit;
	end;
	
	inc_num_outstanding_ptrs(sizeof(rp^),CurrentRoutineName);
	with rp^ do begin
		valid:=false;
		mask_point.x:=0;
		mask_point.y:=0;
		magnification_x:=1;
		magnification_y:=1;
		rotation:=0;
		error:=0;
		mask_orientation:=0;
		reference_code:=0;
		reference_point.x:=0;
		reference_point.y:=0;
		square_size_um:=10;
		pixel_size_um:=10;
	end;
	new_rasnik:=rp;
end;

{
	dispose_rasnik disposes of a rasnik type.
}
procedure dispose_rasnik(rp:rasnik_ptr_type);

begin
	if rp=nil then exit;
	dec_num_outstanding_ptrs(sizeof(rp^),CurrentRoutineName);
	dispose(rp);
end;

{
	new_rasnik_square_array allocates space for a new rasnik_square_array_type.
}
function new_rasnik_square_array(extent:integer):rasnik_square_array_ptr_type;

var
	sp:rasnik_square_array_ptr_type;
	b,c:integer;
	
begin
	sp:=new(rasnik_square_array_ptr_type,extent);
	inc_num_outstanding_ptrs(sizeof(sp^),CurrentRoutineName);
	for b:=-extent to extent do begin
		for c:=-extent to extent do begin
			with sp^[b,c] do begin
				is_a_valid_square:=false;
				is_a_code_square:=false;
				is_a_pivot_square:=false;
				x_code:=0;
				y_code:=0;
			end;
		end;
	end;
	new_rasnik_square_array:=sp;
end;

{
	dispose_rasnik_square_array disposes of a rasnik_square_array.
}
procedure dispose_rasnik_square_array(sp:rasnik_square_array_ptr_type);

begin
	if sp=nil then exit;
	dec_num_outstanding_ptrs(sizeof(sp^),CurrentRoutineName);
	dispose(sp);
end;

{
	rasnik_get_square copies element sap^.[a,b] to sp^, and so allows
	non-Pascal programs to read elements from a rasnik square array. We 
	cannot duplicate the square array reliably in other languages because
	it is a schema type particular to Pascal.
}
procedure rasnik_get_square(sp:rasnik_square_ptr_type;
	sap:rasnik_square_array_ptr_type;a,b:integer);

begin
	if sp=nil then exit;
	if sap=nil then exit;
	if (abs(a)>sap^.extent) or (abs(b)>sap^.extent) then begin
		report_error('square index out of bounds in '+CurrentRoutineName+'.');
		exit;	
	end;
	sp^:=sap^[a,b];
end;

{
	rasnik_put_square does the opposite of rasnik_get_square.
}
procedure rasnik_put_square(sp:rasnik_square_ptr_type;
	sap:rasnik_square_array_ptr_type;a,b:integer);

begin
	if sp=nil then exit;
	if sap=nil then exit;
	if (abs(a)>sap^.extent) or (abs(b)>sap^.extent) then begin
		report_error('square index out of bounds in '+CurrentRoutineName+'.');
		exit;	
	end;
	sap^[a,b]:=sp^;
end;


{
	new_rasnik_pattern allocates space for a new rasnik_pattern_type and 
	initializes its contents. It does not assign space for a square array.
	We wait until we know the extent of the square pattern before we create
	the square array. A large square array when there are few squares in the
	image will slow down processing unecessarily.
}
function new_rasnik_pattern:rasnik_pattern_ptr_type;

var
	pp:rasnik_pattern_ptr_type;

begin
	new(pp);
	inc_num_outstanding_ptrs(sizeof(pp^),CurrentRoutineName);
	with pp^ do begin
		origin.x:=0;
		origin.y:=0;
		rotation:=0;
		image_x_width:=10;
		image_y_width:=10;
		pattern_x_width:=10;
		pattern_y_width:=10;
		mask_orientation:=0;
		valid:=false;
		extent:=0;
		squares:=nil;
		error:=0;
		analysis_width:=pattern_x_width*extent;
		x_code_direction:=0;
		y_code_direction:=0;
		analysis_center_cp.i:=0;
		analysis_center_cp.j:=0;
	end;
	new_rasnik_pattern:=pp;
end;

{
	dispose_rasnik_pattern disposes of a rasnik pattern type.
}
procedure dispose_rasnik_pattern(pp:rasnik_pattern_ptr_type);

begin
	if pp=nil then exit;
	if pp^.squares<>nil then dispose_rasnik_square_array(pp^.squares);
	dec_num_outstanding_ptrs(sizeof(pp^),CurrentRoutineName);
	dispose(pp);
end;

{
	string_from_rasnik_pattern returns a string expressing the
	most prominent elements of a pattern record.
}
function string_from_rasnik_pattern(pp:rasnik_pattern_ptr_type):short_string;

var 
	s:short_string;

begin
	string_from_rasnik_pattern:=rasnik_invalid_string;
	if pp=nil then exit;
	if not pp^.valid then exit;

	with pp^ do
		writestr(s,origin.x:5:3,' ',origin.y:5:3,' ',pattern_x_width:5:3,' ',
			pattern_y_width:5:3,' ',rotation*mrad_per_rad:5:3,' ',error:5:3,' ',
			extent:1);
	string_from_rasnik_pattern:=s;
end;

{
	rasnik_pattern_from_string reads in pattern elements from a string.
}
function rasnik_pattern_from_string(s:short_string):rasnik_pattern_ptr_type;

var
	pp:rasnik_pattern_ptr_type;
	
begin
	pp:=new_rasnik_pattern;
	with pp^ do begin
		readstr(s,origin.x,origin.y,pattern_x_width,pattern_y_width,rotation,error,extent);
		rotation:=rotation/mrad_per_rad;
		pp^.valid:=true;
	end;
	rasnik_pattern_from_string:=pp;
end;

{
	rasnik_from_string reads in rasnik elements from a string. It's not clear how
	we can decide if a rasnik string is valid, but we check three of the rasnik
	elements, and if they are reasonable, we assume the string was valid.
}
function rasnik_from_string(s:short_string):rasnik_type;

var
	r:rasnik_type;
	
begin
	if (s=rasnik_invalid_string) then r.valid:=false
	else with r do begin
		readstr(s,mask_point.x,mask_point.y,magnification_x,
		magnification_y,rotation,error,square_size_um,pixel_size_um,
		mask_orientation,reference_code,reference_point.x,reference_point.y);
		rotation:=rotation/mrad_per_rad;
		if (mask_orientation>0) and (magnification_x>0) and (magnification_y>0) 
			then valid:=true;
	end;
	rasnik_from_string:=r;
end;

{
	string_from_rasnik returns a string expressing the
	most prominent elements of a rasnik record. Note that we
	change the units of rotation from radians to milliradians.
}
function string_from_rasnik(rp:rasnik_ptr_type):short_string;

var  
	s:short_string;

begin
	string_from_rasnik:=rasnik_invalid_string;
	if rp=nil then exit;
	if not rp^.valid then exit;

	with rp^ do
		writestr(s,mask_point.x:4:2,' ',mask_point.y:4:2,' ',magnification_x:8:6,' ',
			magnification_y:8:6,' ',rotation*mrad_per_rad:5:3,' ',error:5:3,' ',
			square_size_um:3:1,' ',pixel_size_um:3:1,' ',mask_orientation:1,' ',
			reference_code:1,' ',reference_point.x:3:1,' ',reference_point.y:3:1);
	string_from_rasnik:=s;
end;

{
	rasnik_display_pattern displays a rasnik_pattern_type on an image by
	means of lines along the square edges. The procedure expects the 
	specified image to be the one from which the pattern was calculated by
	a routine such as rasnik_refine_pattern.
}
procedure rasnik_display_pattern(ip:image_ptr_type;pp:rasnik_pattern_ptr_type;
	mark_valid:boolean);

const
	line_color=green_color;
	code_mark_color=yellow_color;
	pivot_mark_color=red_color;
	valid_mark_color=blue_color;
	
var
	pattern_line:xy_line_type;
	line_num,x_num,y_num:integer;
	display_rectangle:ij_rectangle_type;
	ccd_line:ij_line_type;

begin
	if not valid_image_ptr(ip) then exit;
	if pp=nil then exit;
	if not valid_analysis_bounds(ip) then exit;

	for line_num:=-pp^.extent to pp^.extent do begin
		with pattern_line,pp^ do begin
			a.x:=line_num;
			a.y:=-pp^.extent;
			b.x:=line_num;
			b.y:=pp^.extent;
		end;
		display_ccd_line(ip,
			c_from_i_line(i_from_p_line(pattern_line,pp)),
			line_color);
			
		with pattern_line,pp^ do begin
			a.x:=-pp^.extent;
			a.y:=line_num;
			b.x:=pp^.extent;
			b.y :=line_num;
		end;
		display_ccd_line(ip,
			c_from_i_line(i_from_p_line(pattern_line,pp)),
			line_color);
	end;
	
	if pp^.squares<>nil then begin
		for x_num:=-pp^.extent to pp^.extent do begin
			for y_num:=-pp^.extent to pp^.extent do begin
				with pp^.squares^[x_num,y_num] do begin
					if is_a_valid_square then begin
						if mark_valid then 
							display_ccd_rectangle(
								ip,display_outline,valid_mark_color);
						if is_a_code_square then begin
							if is_a_pivot_square then
								display_ccd_rectangle(
									ip,display_outline,pivot_mark_color)
							else
								display_ccd_rectangle(
									ip,display_outline,code_mark_color);
						end;
					end;
				end;
			end;
		end;
	end;
end;

{
	profile_by_fourier calculates an approximate value for the period and offset
	of the fundamental component of a periodic image profile. The routine
	assumes that the profile has been smoothed off at the ends with a window
	function. A secondary function of this routine is to detect a profile that
	looks nothing like a rasnik pattern. The fourier spectrum of a rasnik
	pattern has a distinct peak at the square frequency. This routine makes sure
	that the peak frequency amplitude is at least a factor of min_peak_ratio
	times greater than the average amplitude of the spectrum. The peak ratio for
	a sharp rasnik image is between 20 and 40. For a blurred image with nine
	squares across, the ratio is still 10. When we allow the exposure time to
	drop until we can barely see any sign of the pattern, even with image
	intensification, the peak ratio is 3.0.
}
procedure profile_by_fourier(profile_ptr:x_graph_ptr_type;
	var period,offset:real);

const
	min_peak_ratio=3.0;
	
var
	max_amplitude,sum_amplitude:real;
	ft:xy_graph_ptr_type;
	dp:x_graph_ptr_type;
	k,n,p2s,np,k_min,k_max:integer;
	message:short_string;
	
begin
{
	Check the input.
}
	period:=0;
	offset:=0;
	if profile_ptr=nil then exit;
	if profile_ptr^.num_points<=1 then begin
		report_error('profile_ptr^.num_points<=1 in '+CurrentRoutineName+'.');
		exit;
	end;
{
	Determine the smallest power of two that is greater than or equal to the
	number of points in the profile that we wish to transform. We can submit
	only graphs containing a number of points that is a perfect power of two.
}
	p2s:=1;
	np:=profile_ptr^.num_points;
	while (p2s <= np) do p2s:=p2s*2;
{
	Create a new graph with this power of two number of points. Fill the graph
	with points from the profile until we run out of profile points. After that,
	fill the remainder with the final value of the original profile. This final 
	value should be equal to the average value, because we expect the profile to
	be smoothed off at the ends with a window function before it is passed in.
}
	dp:=new_x_graph(p2s);	
	for n:=0 to np-1 do dp^[n]:=profile_ptr^[n];
	for n:=np to p2s-1 do dp^[n]:=profile_ptr^[np-1];
{
	Determine the minimum and maximum frequency components that we will consider
	as the potential square frequency.
}
	k_min:=round(dp^.num_points/profile_ptr^.num_points*rasnik_min_squares_across)+1;
	k_max:=round(dp^.num_points/rasnik_min_pixels_per_square)-1;
{
	Calculate the fast fourier transform of the extended graph.
}
	ft:=fft_real(dp);
	dispose_x_graph(dp);
	if ft=nil then exit;
{
	Find the peak in the transform, subject to the constraint that we cannot have
	too few squares in our profile, nor can the period be too small.
}
	max_amplitude:=0;
	sum_amplitude:=0;
	period:=0;
	offset:=0;
	for k:=k_min to k_max do begin
		sum_amplitude:=sum_amplitude+ft^[k].x;
		if (ft^[k].x>max_amplitude) then begin
			max_amplitude:=ft^[k].x;
			period:=p2s/k;
			offset:=-ft^[k].y*period/2/pi;
			if offset<0 then offset:=offset+period;
		end;
	end;
{
	Check that the peak is consistent with a rasnik pattern.
}
	message:='';
	if max_amplitude=0 then
		message:='No intensity variation'
	else if k_min=k_max then 
		message:='No viable square size'
	else if max_amplitude<min_peak_ratio*sum_amplitude/(k_max-k_min) then
		message:='No periodic pattern';
{
	This code we leave commented out until we want to take a look at the
	fourier transform of the slices. We use the message string to cause the
	analysis to abort.
}
{
	for k:=0 to ft^.num_points-1 do begin
		writestr(debug_string,k:1,' ',p2s/k:1:4,' ',ft^[k].x:1:4);
		gui_writeln(debug_string);
	end;
	message:='Analysis aborted after displaying spectrum';
}
{
	If we have encountered a problem, set the period to zero.
}
	if message<>'' then begin
		period:=0;
		report_error(message+' in '+CurrentRoutineName+'.');
	end;
{
	Dispose of the transform and we're done.
}
	dispose_xy_graph(ft);
end;

{
	profile_by_maxima uses an approximate value of the period of a profile to
	obtain a more accurate period, and an offset, by least squares fit to the
	locations of the maxima. The message contains informatin about any problems
	the routine encountered. When the period passed to the routine is zero, the
	routine constructs a filtered profile, but does not re-calculate the period.
	If the period it calculates from the maxima is too far from the initial value,
	the routine rejects its own value and returns zero period to indicate failure.
}
procedure profile_by_maxima(profile_ptr:x_graph_ptr_type;
	var period,offset:real;
	var filtered_ptr:x_graph_ptr_type);

const
	feature_extent=2;
	min_num_features=4;
	max_num_features=1000;
	extent_fraction=0.75;
	step_tolerance=0.2;
	max_period_scale=0.8;
	max_fraction=0.5;

var
	feature_list_ptr:xyz_graph_ptr_type;
	profile_index,num_features:integer;
	feature_index,previous_valid_feature_index:integer;
	first_good_feature_index,band_pass_extent:integer;
	a,b:integer;
	g,h,residual,step:real;
	band_pass_started,good:boolean;
	message:short_string;
	initial_period,initial_offset:real;
	max_filtered:real;
	
	function start_up_band_pass_filter(index:integer;period:real):real;
	var k:integer;sum,T:real;	
	begin
		T:=2+4*round((period-2)/4);
		a:=(round(T)-2) div 4;
		b:=3*a+1;
		g:=1/T;
		h:=-1/(2*T);
		sum:=0;
		for k:=index-b to index-a-1 do sum:=sum+profile_ptr^[k]*h; 
		for k:=index-a to index+a do sum:=sum+profile_ptr^[k]*g;
		for k:=index+a+1 to index+b do sum:=sum+profile_ptr^[k]*h;
		start_up_band_pass_filter:=sum;
	end;

	function band_pass_filter(index:integer):real;
	begin
		band_pass_filter:=filtered_ptr^[index-1]
			-h*profile_ptr^[index-b-1]
			+(h-g)*profile_ptr^[index-a-1]
			-(h-g)*profile_ptr^[index+a]
			+h*profile_ptr^[index+b];
	end;

begin
	if profile_ptr=nil then exit;
	initial_period:=period;
	initial_offset:=offset;
{
	Generate a band-pass filtered profile.
}
	filtered_ptr:=new_x_graph(profile_ptr^.num_points);
	band_pass_extent:=trunc(period*extent_fraction)+1;
	for profile_index:=band_pass_extent to profile_ptr^.num_points-band_pass_extent-1 do begin
		if profile_index=band_pass_extent then
			filtered_ptr^[profile_index]:=
				start_up_band_pass_filter(profile_index,period)
		else 
			filtered_ptr^[profile_index]:=
				band_pass_filter(profile_index)
	end;
{
	Fill in the leading and trailing entries in the filtered profile
	with end values.
}
	for profile_index:=0 to band_pass_extent-1 do begin
		filtered_ptr^[profile_index]:=
			filtered_ptr^[band_pass_extent];
	end;
	for profile_index:=filtered_ptr^.num_points-band_pass_extent 
			to filtered_ptr^.num_points-1 do begin
		filtered_ptr^[profile_index]:=
			filtered_ptr^[filtered_ptr^.num_points-band_pass_extent-1];
	end;
{
	The average intensity of the filtered profile will be close to zero. The
	maximum intensity gives us a scale with which to compare the height of the
	profile maxima.
}
	max_filtered:=0;
	for profile_index:=band_pass_extent+feature_extent+1 
			to filtered_ptr^.num_points-1-band_pass_extent-feature_extent-1 do
		if filtered_ptr^[profile_index]>max_filtered then
			max_filtered:=filtered_ptr^[profile_index];
{
	Record the maxima of band-pass filtered profile in the feature array
}
	feature_list_ptr:=new_xyz_graph(max_num_features);
	num_features:=0;
	for profile_index:=band_pass_extent+feature_extent+1 
			to filtered_ptr^.num_points-1-band_pass_extent-feature_extent-1 do begin
		if (filtered_ptr^[profile_index]>filtered_ptr^[profile_index-1]) 
			and (filtered_ptr^[profile_index]>filtered_ptr^[profile_index-1-1]) 
			and (filtered_ptr^[profile_index]>filtered_ptr^[profile_index+1]) 
			and (filtered_ptr^[profile_index]>filtered_ptr^[profile_index+1+1]) 
			and (filtered_ptr^[profile_index]>max_filtered*max_fraction) then begin
			if num_features<max_num_features then begin 
				with feature_list_ptr^[num_features] do begin
					y:=profile_index;
					z:=1;
					if num_features=0 then x:=0
					else x:=feature_list_ptr^[num_features-1].x
							+round((y-feature_list_ptr^[num_features-1].y)/period);
				end;
				inc(num_features);
			end;
		end;
	end;
{
	Eliminate degenerate features
}
	for feature_index:=0 to num_features-1 do begin
		if feature_index>0 then
			if (feature_list_ptr^[feature_index].x=feature_list_ptr^[feature_index-1].x) then
				feature_list_ptr^[feature_index].z:=0;
		if feature_index<num_features-1-1 then
			if (feature_list_ptr^[feature_index].x=feature_list_ptr^[feature_index+1].x) then
				feature_list_ptr^[feature_index].z:=0;
	end;
{
	Find the first good feature in the feature list. Ulrich Landgraf fixed our
	detection of good features by making sure that a good feature is not a
	degenerate feature. Pierre-Franois Giraud corrected our indexing, pointing
	out that we have to stop when feature_index+1=num_features, or else we
	cannot look ahead by one feature to check our period.
}
	feature_index:=0;
	good:=false;
	while (not good) and (feature_index+1<num_features) do begin 
		step:=(feature_list_ptr^[feature_index+1].y-feature_list_ptr^[feature_index].y)/period;
		good:=(abs(step-round(step))<step_tolerance) and
					(feature_list_ptr^[feature_index].z<>0);
		if not good then begin
			feature_list_ptr^[feature_index].z:=0;
			inc(feature_index);
		end;
	end;
	if good then first_good_feature_index:=feature_index
	else first_good_feature_index:=0;
	feature_list_ptr^[first_good_feature_index].x:=0;
{
	Correct the x-values of remaining features, and eliminate any features that
	appear to be out of place. 
}
	previous_valid_feature_index:=first_good_feature_index;
	for feature_index:=first_good_feature_index+1 to num_features-1 do begin
		with feature_list_ptr^[feature_index] do begin
			if z<>0 then begin
				step:=(y-feature_list_ptr^[previous_valid_feature_index].y)/period;
				if (abs(step-round(step))>step_tolerance) then begin
					z:=0;
				end else begin
					x:=feature_list_ptr^[previous_valid_feature_index].x+round(step);
					previous_valid_feature_index:=feature_index;
				end;
			end;
		end;
	end;
{
	Mark feature list so weighted_straight_line_fit ignores unused features.
}
	if num_features<max_num_features then
		feature_list_ptr^[num_features].z:=ignore_remaining_data;
{
	Get profile period and offset using least-squares fit. We won't do this 
	unless the period passed into the routine was non-zero.
}
	if initial_period<>0 then
		weighted_straight_line_fit(feature_list_ptr,period,offset,residual);
{
	Dispose of feature arrray.
}
	dispose_xyz_graph(feature_list_ptr);
{
	Check the period and offset.
}
	message:='';
	if num_features<min_num_features then
		message:='Too few features'
	else if period>filtered_ptr^.num_points/rasnik_min_squares_across then 
		message:='Period too large'
	else if period<rasnik_min_pixels_per_square then 
		message:='Period too small'
	else if (not (period>=0)) and (not (period<=0)) then
		message:='Period undefined'
	else if offset>filtered_ptr^.num_points then 
		message:='Offset too large and positive'
	else if offset<-filtered_ptr^.num_points then 
		message:='Offset too large and negative'
	else if (not (offset>=0)) and (not (offset<=0)) then
		message:='Offset undefined'
	else if (initial_period/period < max_period_scale) 
		or (period/initial_period < max_period_scale) then
		message:='Period too far from initial value';
{
	Set period to zero if we have detected a problem.
}
	if message<>'' then period:=0;
end;

{
	rasnik_find_pattern uses the i- and j-direction derivatives of a 
	mask image to determine the approximate location of the mask pattern.  
	The derivatives are specified by iip and jip. If only one of the i- or 
	j-derivatives is valid, we calculate in only the i- or j-directions. In 
	all cases, the routine picks a pattern origin close to the center of the 
	analysis bounds.
}
function rasnik_find_pattern(iip,jip:image_ptr_type;show_fitting:boolean)
	:rasnik_pattern_ptr_type;

const
	modulo_tolerance=0.5;
	image_fraction=1;
	good_color=yellow_color;
	bad_color=red_color;
	profile_color=green_color;
	bounds_color=blue_color;
	max_tilt_per_extent=rasnik_num_slices div 4; {square-widths per extent}
	max_distortion=1.5;
	window_extent=10;
	
var
	profile_ptr,filtered_profile_ptr:x_graph_ptr_type;
	slice_num,num_points:integer;
	bad_slice:boolean;
	slice_top,slice_bottom,slice_left,slice_right,slice_step,slice_width,slice_height:real;
	offsets_ptr:x_graph_ptr_type;
	data_ptr:xy_graph_ptr_type;
	slope_i,slope_j,residual_i,residual_j,offset_i,offset_j,period_i,period_j:real;
	sum,period,ave_period,offset:real;
	original_i_bounds,original_j_bounds:ij_rectangle_type;
	x_line,y_line:xy_line_type;
	ccd_line:ij_line_type;
	pp:rasnik_pattern_ptr_type;
	ccd_center_offset:real;
	ex,ey:integer;
	
begin
	rasnik_find_pattern:=nil;
	if (not valid_image_ptr(iip)) and (not valid_image_ptr(jip)) then begin
		report_error('Both gradient images are invalid in '
			+CurrentRoutineName+'.');
		exit;
	end;

	if valid_image_ptr(iip) then begin
		original_i_bounds:=iip^.analysis_bounds;
		offsets_ptr:=new_x_graph(rasnik_num_slices);
		data_ptr:=new_xy_graph(rasnik_num_slices);

		with original_i_bounds do begin
			slice_height:=(bottom-top+1) div rasnik_num_slices;
			if slice_height<min_slice_thickness then slice_height:=min_slice_thickness;
			if slice_height>max_slice_thickness then slice_height:=max_slice_thickness;
			slice_step:=(bottom-top-slice_height)/(rasnik_num_slices-1);
			slice_width:=(right-left)*image_fraction;
			slice_left:=left+(right-left-slice_width)*one_half;
			slice_right:=slice_left+slice_width;
			iip^.analysis_bounds.left:=round(slice_left);
			iip^.analysis_bounds.right:=round(slice_right);
		end;
		
		period_i:=0;
		for slice_num:=0 to rasnik_num_slices-1 do begin
			with iip^.analysis_bounds do begin
				top:=original_i_bounds.top+round((slice_num)*slice_step);
				bottom:=top+round(slice_height);
				num_points:=right-left+1;
				profile_ptr:=image_profile_row(iip);
				if profile_ptr=nil then exit;
				window_function(profile_ptr,window_extent);
				if show_fitting then begin
					display_ccd_rectangle(iip,iip^.analysis_bounds,bounds_color);
					display_profile_row(iip,profile_ptr,profile_color);
				end;
				if slice_num=0 then profile_by_fourier(profile_ptr,period,offset);
				profile_by_maxima(profile_ptr,period,offset,filtered_profile_ptr);
				if show_fitting then begin
					if period>0 then display_profile_row(iip,filtered_profile_ptr,good_color)
					else display_profile_row(iip,filtered_profile_ptr,bad_color);
				end;
				if period=0 then profile_by_fourier(profile_ptr,period,offset);
				period_i:=period_i+period;
				offsets_ptr^[slice_num]:=offset+left;
				data_ptr^[slice_num].x:=(top+bottom)*one_half;
				dispose_x_graph(filtered_profile_ptr);
				dispose_x_graph(profile_ptr);
				if period=0 then break;
			end;
		end;
		if show_fitting then begin
			gui_draw(iip^.name);
			gui_wait('Filtered intensity profile in horizontal slices.');
		end;
		if period=0 then begin
			dispose_xy_graph(data_ptr);
			dispose_x_graph(offsets_ptr);
			exit;
		end;
		
		period_i:=period_i/rasnik_num_slices;
	
		for slice_num:=1 to rasnik_num_slices-1 do begin
			while offsets_ptr^[slice_num]-offsets_ptr^[slice_num-1]
					>period_i*modulo_tolerance do begin
				offsets_ptr^[slice_num]:=offsets_ptr^[slice_num]-period_i;
			end;
			while offsets_ptr^[slice_num]-offsets_ptr^[slice_num-1]
					<-period_i*modulo_tolerance do begin
				offsets_ptr^[slice_num]:=offsets_ptr^[slice_num]+period_i;
			end;
		end;

		for slice_num:=0 to rasnik_num_slices-1 do
			data_ptr^[slice_num].y:=offsets_ptr^[slice_num];
		
		straight_line_fit(data_ptr,slope_i,offset_i,residual_i);
		
		dispose_xy_graph(data_ptr);
		dispose_x_graph(offsets_ptr);
		iip^.analysis_bounds:=original_i_bounds;
	end;

	if valid_image_ptr(jip) then begin
		original_j_bounds:=jip^.analysis_bounds;
		original_i_bounds:=iip^.analysis_bounds;
		offsets_ptr:=new_x_graph(rasnik_num_slices);
		data_ptr:=new_xy_graph(rasnik_num_slices);
	
		with original_j_bounds do begin
			slice_width:=(right-left+1) div rasnik_num_slices;
			if slice_width<min_slice_thickness then slice_width:=min_slice_thickness;
			if slice_width>max_slice_thickness then slice_width:=max_slice_thickness;
			slice_step:=(right-left-slice_width)/(rasnik_num_slices-1);
			slice_height:=(bottom-top)*image_fraction;
			slice_top:=top+(bottom-top-slice_height)*one_half;
			slice_bottom:=slice_top+slice_height;
			jip^.analysis_bounds.top:=round(slice_top);
			jip^.analysis_bounds.bottom:=round(slice_bottom);
		end;
		
		period_j:=0;
		for slice_num:=0 to rasnik_num_slices-1 do begin
			with jip^.analysis_bounds do begin
				left:=original_j_bounds.left+round((slice_num)*slice_step);
				right:=left+round(slice_width);
				num_points:=bottom-top+1;
				profile_ptr:=image_profile_column(jip);
				if profile_ptr=nil then exit;
				window_function(profile_ptr,window_extent);
				if show_fitting then begin
					display_ccd_rectangle(jip,jip^.analysis_bounds,bounds_color);
					display_profile_column(jip,profile_ptr,profile_color);
				end;
				if slice_num=0 then profile_by_fourier(profile_ptr,period,offset);
				profile_by_maxima(profile_ptr,period,offset,filtered_profile_ptr);
				if show_fitting then begin
					if period>0 then display_profile_column(jip,filtered_profile_ptr,good_color)
					else display_profile_column(jip,filtered_profile_ptr,bad_color);
				end;
				if period=0 then profile_by_fourier(profile_ptr,period,offset);
				period_j:=period_j+period;
				offsets_ptr^[slice_num]:=offset+top;
				data_ptr^[slice_num].x:=(right+left)*one_half;
				dispose_x_graph(filtered_profile_ptr);
				dispose_x_graph(profile_ptr);
				if period=0 then break;
			end;
		end;
		if show_fitting then begin
			gui_draw(jip^.name);
			gui_wait('Raw and filtered profiles in vertical slices.');
		end;
		if period=0 then begin
			dispose_xy_graph(data_ptr);
			dispose_x_graph(offsets_ptr);
			exit;
		end;
	
		period_j:=period_j/rasnik_num_slices;
	
		for slice_num:=1 to rasnik_num_slices-1 do begin
			while offsets_ptr^[slice_num]-offsets_ptr^[slice_num-1]
					>period_j*modulo_tolerance do begin
				offsets_ptr^[slice_num]:=offsets_ptr^[slice_num]-period_j;
			end;
			while offsets_ptr^[slice_num]-offsets_ptr^[slice_num-1]
					<-period_j*modulo_tolerance do begin
				offsets_ptr^[slice_num]:=offsets_ptr^[slice_num]+period_j;
			end;
		end;

		for slice_num:=0 to rasnik_num_slices-1 do begin
			data_ptr^[slice_num].y:=offsets_ptr^[slice_num];
		end;
			
		straight_line_fit(data_ptr,slope_j,offset_j,residual_j);
		
		dispose_xy_graph(data_ptr);
		dispose_x_graph(offsets_ptr);
		jip^.analysis_bounds:=original_j_bounds;
	end;

	pp:=new_rasnik_pattern;
	if valid_image_ptr(iip) and valid_image_ptr(jip) then begin
		with iip^.analysis_bounds do 
			ccd_center_offset:=
				(right+left)*one_half-slope_i*(bottom-top)*one_half;
		while (offset_i-ccd_center_offset)<=-period_i*one_half do offset_i:=offset_i+period_i;
		while (offset_i-ccd_center_offset)>period_i*one_half do offset_i:=offset_i-period_i;
		
		with jip^.analysis_bounds do 
			ccd_center_offset:=
				(top+bottom)*one_half-slope_j*(right-left)*one_half;
		while (offset_j-ccd_center_offset)<=-period_j*one_half do offset_j:=offset_j+period_j;
		while (offset_j-ccd_center_offset)>period_j*one_half do offset_j:=offset_j-period_j;
		
		with pp^ do begin
			with y_line do begin
				a.x:=offset_i+ccd_origin_x;
				a.y:=ccd_origin_y;
				b.x:=a.x+off_screen*slope_i;
				b.y:=a.y+off_screen;
			end;
			with x_line do begin
				a.y:=offset_j+ccd_origin_y;
				a.x:=ccd_origin_x;
				b.y:=a.y+off_screen*slope_j;
				b.x:=a.x+off_screen;
			end;
			origin:=xy_line_line_intersection(y_line,x_line);
			rotation:=arctan((slope_i-slope_j)*one_half);
			image_x_width:=period_i;
			image_y_width:=period_j;
			pattern_x_width:=image_x_width*cos(rotation);
			pattern_y_width:=image_y_width*cos(rotation);
			if (pattern_x_width > max_distortion * pattern_y_width) or
				(pattern_x_width < max_distortion / pattern_y_width) then begin
				report_error('Pattern x and y widths do not agree in '
					+CurrentRoutineName+'.');
				exit;
			end;
			error:=(residual_i+residual_j)/sqrt(rasnik_num_slices);
			with analysis_center_cp,iip^.analysis_bounds do begin
				i:=round((left+right)*one_half);
				j:=round((bottom+top)*one_half);
				analysis_width:=sqrt(sqr(right-left)+sqr(bottom-top));
			end;
			with iip^.analysis_bounds do begin
				ex:=round((right-left)/image_x_width*one_half)+max_tilt_per_extent;
				ey:=round((bottom-top)/image_y_width*one_half)+max_tilt_per_extent;
			end;
			if ex>ey then extent:=ex
			else extent:=ey;
			if extent>rasnik_max_pattern_extent then
				extent:=rasnik_max_pattern_extent;
		end;
	end;
	
	if valid_image_ptr(iip) and (not valid_image_ptr(jip)) then begin
		with iip^.analysis_bounds do ccd_center_offset:=(right+left)*one_half;
		while (offset_i-ccd_center_offset)<=-period_i*one_half do offset_i:=offset_i+period_i;
		while (offset_i-ccd_center_offset)>period_i*one_half do offset_i:=offset_i-period_i;
		with pp^ do begin
			origin.x:=offset_i+ccd_origin_x;
			origin.y:=ccd_origin_y;
			rotation:=arctan(slope_i);
			image_x_width:=period_i;
			image_y_width:=0;
			pattern_x_width:=image_x_width*cos(rotation);
			pattern_y_width:=image_y_width*cos(rotation);
			error:=(residual_i)/sqrt(rasnik_num_slices);
			with analysis_center_cp,iip^.analysis_bounds do begin
				i:=round((left+right)*one_half);
				j:=round((bottom+top)*one_half);
				analysis_width:=sqrt(sqr(right-left)+sqr(bottom-top));
			end;
			with iip^.analysis_bounds do 
				extent:=round((right-left)/pp^.image_x_width*one_half)+max_tilt_per_extent;
			if extent>rasnik_max_pattern_extent then
				extent:=rasnik_max_pattern_extent;
		end;
	end;

	if (not valid_image_ptr(iip)) and valid_image_ptr(jip) then begin
		with jip^.analysis_bounds do ccd_center_offset:=(top+bottom)*one_half;
		while (offset_j-ccd_center_offset)<=-period_j*one_half do offset_j:=offset_j+period_j;
		while (offset_j-ccd_center_offset)>period_j*one_half do offset_j:=offset_j-period_j;
		with pp^ do begin
			origin.x:=ccd_origin_x;
			origin.y:=offset_j+ccd_origin_y;
			rotation:=arctan(slope_j);
			image_x_width:=0;
			image_y_width:=period_j;
			pattern_x_width:=image_x_width*cos(rotation);
			pattern_y_width:=image_y_width*cos(rotation);
			error:=(residual_j)/sqrt(rasnik_num_slices);
			with analysis_center_cp,jip^.analysis_bounds do begin
				i:=round((left+right)*one_half);
				j:=round((bottom+top)*one_half);
				analysis_width:=sqrt(sqr(right-left)+sqr(bottom-top));
			end;
			with jip^.analysis_bounds do 
				extent:=round((bottom-top)/pp^.image_y_width*one_half)+max_tilt_per_extent;
			if extent>rasnik_max_pattern_extent then
				extent:=rasnik_max_pattern_extent;
		end;
	end;
	
	pp^.valid:=true;
	rasnik_find_pattern:=pp;	
end;

{
	rasnik_refine_pattern calls rasnik_find_pattern and then refines
	the pattern returned by the approximate routine using the i- and j-
	direction derivatives. If only one of the i- or j-derivatives is valid,
	we do not abort, but calculate in only the i- or j-directions. In all
	cases, the routine picks a pattern origin close to the center of the 
	analysis bounds.
}
procedure rasnik_refine_pattern(pp:rasnik_pattern_ptr_type;
	iip,jip:image_ptr_type;show_fitting:boolean);

const
	line_clearance=0.4;
	line_data_size=20000;
	min_num_points_per_line=100;
	min_num_lines=2;
	sigma_cut=2;
	num_residual_cuts=1;
	num_slope_cuts=1;
	line_color=yellow_color;
	large_period=2000;
	show_pixels_used=false;

type
	line_type=record 
		slope,intercept,residual:real;
		image_line:xy_line_type;
		distance_to_next_line:real;
		valid:boolean;
	end;

var
	pp1,pp2:xy_point_type;
	ip,pattern_origin_point:xy_point_type;
	start_point,end_point,cp:ij_point_type;
	center_line,temp_line:xy_line_type;
	start_line,end_line,scan_line,ccd_line:ij_line_type;
	pattern_positive,first_line:boolean;
	graph_ptr:xyz_graph_ptr_type;
	num_points,point_num,new_num_points:integer;
	i,j,line_num,cut_num,count,total_num_lines,num_valid_lines:integer;
	line:array [-rasnik_max_pattern_extent..rasnik_max_pattern_extent] of line_type;
	sum,average,stdev:real;
	slope_i,slope_j,residual_i,residual_j,offset_i,offset_j,period_i,period_j:real;
	reference_line_i,reference_line_j:xy_line_type;
	ccd_center_offset,scan_slope,scan_width,scan_intercept:real;

begin
	if (pp=nil) then exit;
	if not pp^.valid then exit;

	pp^.valid:=false;
	
	if valid_image_ptr(iip) or valid_image_ptr(jip) then begin
		with pp^ do begin
			if pattern_y_width=0 then begin
				pattern_y_width:=off_screen/rasnik_code_pitch;
				image_y_width:=pattern_y_width;
			end;
			if pattern_x_width=0 then begin
				pattern_x_width:=off_screen/rasnik_code_pitch;
				image_x_width:=pattern_x_width;
			end;
		end;
	end;	

	total_num_lines:=0;

	if valid_image_ptr(iip) then begin 
		num_valid_lines:=0;
		if show_fitting then clear_overlay(iip);
		ip.x:=0;ip.y:=0;pp1:=p_from_i(ip,pp);
		ip.x:=1;ip.y:=0;pp2:=p_from_i(ip,pp);
		pattern_positive:=(pp2.x>pp1.x);
		for line_num:=-pp^.extent to pp^.extent do 
			with line[line_num] do begin
				line[line_num].valid:=false;
				slope:=0;
				intercept:=0;
			end;
	
		graph_ptr:=new_xyz_graph(line_data_size+1);
		if graph_ptr=nil then begin
			report_error('Failed to allocate graph_ptr in '+CurrentRoutineName+'.');
			exit;
		end;

		for line_num:=-pp^.extent to pp^.extent do begin
			with center_line,pp^ do begin
				a.x:=line_num;
				a.y:=pp^.extent;
				b.x:=line_num;
				b.y:=-pp^.extent;
			end;	
			if ij_line_crosses_rectangle(
				c_from_i_line(i_from_p_line(center_line,pp)),
					iip^.analysis_bounds) then begin
				with temp_line do begin
					a.x:=(line_num-line_clearance);
					a.y:=pp^.extent;
					b.x:=(line_num-line_clearance);
					b.y:=-pp^.extent;
				end;
				if pattern_positive then 
					start_line:=c_from_i_line(i_from_p_line(temp_line,pp))
				else 
					end_line:=c_from_i_line(i_from_p_line(temp_line,pp));
	
				with temp_line do begin
					a.x:=(line_num+line_clearance);
					a.y:=pp^.extent;
					b.x:=(line_num+line_clearance);
					b.y:=-pp^.extent;
				end;
				if pattern_positive then 
					end_line:=c_from_i_line(i_from_p_line(temp_line,pp))
				else 
					start_line:=c_from_i_line(i_from_p_line(temp_line,pp));
				
				with scan_line do begin 
					a.i:=0;
					a.j:=iip^.analysis_bounds.top;
					b.i:=1;
					b.j:=iip^.analysis_bounds.top;
				end;

				start_point:=ij_line_line_intersection(start_line,scan_line);
				end_point:=ij_line_line_intersection(end_line,scan_line);
				scan_width:=end_point.i-start_point.i;
				with start_line do scan_slope:=(b.i-a.i)/(b.j-a.j);
				scan_intercept:=start_point.i;

				num_points:=0;
				for j:=iip^.analysis_bounds.top to iip^.analysis_bounds.bottom do begin
					start_point.i:=round(scan_intercept
						+(j-iip^.analysis_bounds.top)*scan_slope);
					end_point.i:=round(start_point.i+scan_width);	
					with iip^.analysis_bounds do begin
						if start_point.i<left then start_point.i:=left;
						if end_point.i>right then end_point.i:=right;
					end;

					for i:=start_point.i to end_point.i do begin
						if (num_points>=line_data_size) then break;
						cp.i:=i;cp.j:=j;
						ip:=i_from_c(cp);
						with graph_ptr^[num_points] do begin
							x:=ip.y;
							y:=ip.x;
							z:=iip^.intensity[j,i];
						end;
						inc(num_points);
					end;
				end;

				with line[line_num] do begin
					if (num_points>min_num_points_per_line) then begin
						graph_ptr^[num_points].z:=ignore_remaining_data;
						weighted_straight_line_fit(graph_ptr,slope,intercept,residual);
						if math_error(slope) or math_error(intercept) then continue;

						for point_num:=1 to num_points do 
							with graph_ptr^[point_num-1] do 
								if abs(y-slope*x-intercept)>=sigma_cut*residual then z:=0
								else if show_fitting and show_pixels_used then begin
									ip.x:=y;ip.y:=x;
									cp:=c_from_i(ip);
									display_ccd_pixel(iip,cp,iip^.intensity[cp.j,cp.i]);
								end;														

						weighted_straight_line_fit(graph_ptr,slope,intercept,residual);
						if math_error(slope) or math_error(intercept) then continue;

						valid:=true;
						inc(num_valid_lines);

						with image_line,pp^ do begin
							a.y:=pp^.origin.y+pp^.extent*image_y_width;
							a.x:=slope*a.y+intercept;
							b.y:=pp^.origin.y-pp^.extent*image_y_width;
							b.x:=slope*b.y+intercept;
						end;
					end;
				end;
			end;
		end;
		
		dispose_xyz_graph(graph_ptr);
		
		if math_error(line[line_num].slope) 
			or math_error(line[line_num].intercept) then begin
			report_error('Math error fitting to edge pixels in '+CurrentRoutineName+'.');
			exit;
		end;
		
		for cut_num:=1 to num_residual_cuts do begin
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+line[line_num].residual;
					count:=count+1;	
				end;
			if (count<min_num_lines) then begin
				report_error('Too few edges in '+CurrentRoutineName+'.');
				exit;
			end;
			average:=sum/count;
		
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+sqr(line[line_num].residual-average);
					count:=count+1;	
				end;
			stdev:=sqrt(sum/count);
	
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then
					if (abs(line[line_num].residual-average)>sigma_cut*stdev) then begin
						line[line_num].valid:=false;
					end;
		end;
	
		for cut_num:=1 to num_slope_cuts do begin
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+line[line_num].slope;
					count:=count+1;	
				end;
			if (count<min_num_lines) then begin
				report_error('Too few edges in '+CurrentRoutineName+'.');
				exit;
			end;
			average:=sum/count;
		
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+sqr(line[line_num].slope-average);
					count:=count+1;	
				end;
			stdev:=sqrt(sum/count);
	
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then
					if (abs(line[line_num].slope-average)>sigma_cut*stdev) then begin
						line[line_num].valid:=false;
					end;
		end;
	
		if show_fitting then begin
			for line_num:=-pp^.extent to pp^.extent do begin
				with line[line_num] do begin
					if valid then begin
						ccd_line:=c_from_i_line(image_line);
						display_ccd_line(iip,ccd_line,line_color);
					end;
				end;
			end;
		end;
	
		sum:=0;
		count:=0;
		for line_num:=-pp^.extent to pp^.extent do
			if line[line_num].valid then begin
				sum:=sum+line[line_num].slope;
				count:=count+1;	
			end;
		if (count<min_num_lines) then begin
			report_error('Too few edges in '+CurrentRoutineName+'.');
			exit;
		end;
		average:=sum/count;
		slope_i:=average;

		graph_ptr:=new_xyz_graph(line_data_size);
		num_points:=0;
		first_line:=true;
		for line_num:=-pp^.extent to pp^.extent do begin
			if line[line_num].valid then begin
				if first_line then begin
					with graph_ptr^[num_points] do begin
						y:=line[line_num].intercept;
						x:=0;
						z:=1;
					end;
					first_line:=false;
				end
				else begin
					with graph_ptr^[num_points] do begin
						y:=line[line_num].intercept;
						x:=round((y-graph_ptr^[0].y)/pp^.image_x_width);
						z:=1;
					end;
				end;
				inc(num_points);
			end
		end;
		graph_ptr^[num_points].z:=ignore_remaining_data;
		weighted_straight_line_fit(graph_ptr,period_i,offset_i,residual_i);
		dispose_xyz_graph(graph_ptr);
		if (num_points<min_num_lines) then begin
			report_error('Too few edges in '+CurrentRoutineName+'.');
			exit;
		end;
		if math_error(period_i) or math_error(offset_i) then begin
			report_error('Math error fitting edges in '+CurrentRoutineName+'.');
			exit;
		end;
		total_num_lines:=total_num_lines+num_points;
		if show_fitting then begin
			gui_draw(iip^.name);
			gui_wait('Accepted vertical pattern edges.');
		end;
		if period_i<rasnik_min_pixels_per_square then begin
			report_error('Found period_i<rasnik_min_pixels_per_square in '
				+CurrentRoutineName+'.');
			exit;
		end;
	end else begin
		period_i:=large_period;
		offset_i:=0;
		slope_i:=0;
	end;

	if valid_image_ptr(jip) then begin 
		num_valid_lines:=0;	
		if show_fitting then clear_overlay(jip);
		ip.x:=0;ip.y:=0;pp1:=p_from_i(ip,pp);
		ip.x:=0;ip.y:=1;pp2:=p_from_i(ip,pp);
		pattern_positive:=(pp2.y>pp1.y);
		for line_num:=-pp^.extent to pp^.extent do 
			with line[line_num] do begin
				line[line_num].valid:=false;
				slope:=0;
				intercept:=0;
			end;
		
		graph_ptr:=new_xyz_graph(line_data_size+1);
		if graph_ptr=nil then begin
			report_error('Failed to allocate graph_ptr in '+CurrentRoutineName+'.');
			exit;
		end;

		for line_num:=-pp^.extent to pp^.extent do begin
			with center_line,pp^ do begin
				a.y:=line_num;
				a.x:=pp^.extent;
				b.y:=line_num;
				b.x:=-pp^.extent;
			end;	
			if ij_line_crosses_rectangle(
					c_from_i_line(i_from_p_line(center_line,pp)),
					jip^.analysis_bounds) then begin

				with temp_line do begin
					a.y:=(line_num-line_clearance);
					a.x:=pp^.extent;
					b.y:=(line_num-line_clearance);
					b.x:=-pp^.extent;
				end;
				if pattern_positive then 
					start_line:=c_from_i_line(i_from_p_line(temp_line,pp))
				else 
					end_line:=c_from_i_line(i_from_p_line(temp_line,pp));
	
				with temp_line do begin
					a.y:=(line_num+line_clearance);
					a.x:=pp^.extent;
					b.y:=(line_num+line_clearance);
					b.x:=-pp^.extent;
				end;
				if pattern_positive then 
					end_line:=c_from_i_line(i_from_p_line(temp_line,pp))
				else 
					start_line:=c_from_i_line(i_from_p_line(temp_line,pp));
				
				with scan_line do begin 
					a.i:=jip^.analysis_bounds.left;
					a.j:=0;
					b.i:=jip^.analysis_bounds.left;
					b.j:=1;
				end;

				start_point:=ij_line_line_intersection(start_line,scan_line);
				end_point:=ij_line_line_intersection(end_line,scan_line);
				scan_width:=end_point.j-start_point.j;
				with start_line do scan_slope:=(b.j-a.j)/(b.i-a.i);
				scan_intercept:=start_point.j;
											
				num_points:=0;
				for i:=jip^.analysis_bounds.left to jip^.analysis_bounds.right do begin
					start_point.j:=round(scan_intercept
						+(i-iip^.analysis_bounds.left)*scan_slope);
					end_point.j:=round(start_point.j+scan_width);	
					with jip^.analysis_bounds do begin
						if start_point.j<top then start_point.j:=top;
						if end_point.j>bottom then end_point.j:=bottom;
					end;
	
					for j:=start_point.j to end_point.j do begin
						if (num_points>=line_data_size) then break;
						cp.i:=i;cp.j:=j;
						ip:=i_from_c(cp);
						with graph_ptr^[num_points] do begin
							x:=ip.x;
							y:=ip.y;
							z:=jip^.intensity[j,i];
						end;
						inc(num_points);
					end;
				end;

				with line[line_num] do begin				
					if (num_points>min_num_points_per_line) then begin
						graph_ptr^[num_points].z:=ignore_remaining_data;
						weighted_straight_line_fit(graph_ptr,slope,intercept,residual);
						if math_error(slope) or math_error(intercept) then continue;

						for point_num:=1 to num_points do 
							with graph_ptr^[point_num-1] do 
								if abs(y-slope*x-intercept)>=sigma_cut*residual then z:=0
								else if show_fitting and show_pixels_used then begin
									ip.x:=x;ip.y:=y;
									cp:=c_from_i(ip);
									display_ccd_pixel(jip,cp,jip^.intensity[cp.j,cp.i]);
								end;		
								
						weighted_straight_line_fit(graph_ptr,slope,intercept,residual);
						if math_error(slope) or math_error(intercept) then continue;

						valid:=true;
						inc(num_valid_lines);

						with image_line,pp^ do begin
							a.x:=pp^.origin.x+pp^.extent*image_x_width;
							a.y:=slope*a.x+intercept;
							b.x:=pp^.origin.x-pp^.extent*image_x_width;
							b.y:=slope*b.x+intercept;
						end;
					end;
				end;
			end;		
		end;
		
		dispose_xyz_graph(graph_ptr);

		if math_error(line[line_num].slope) 
			or math_error(line[line_num].intercept) then begin
			report_error('Math error fitting pixels in '+CurrentRoutineName+'.');
			exit;
		end;
		
		for cut_num:=1 to num_residual_cuts do begin
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+line[line_num].residual;
					count:=count+1;	
				end;
			if (count<min_num_lines) then begin
				report_error('Too few edges in '+CurrentRoutineName+'.');
				exit;
			end;
			average:=sum/count;
		
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+sqr(line[line_num].residual-average);
					count:=count+1;	
				end;
			stdev:=sqrt(sum/count);
	
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then
					if (abs(line[line_num].residual-average)>sigma_cut*stdev) then begin
						line[line_num].valid:=false;
					end;
		end;
	
		for cut_num:=1 to num_slope_cuts do begin
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+line[line_num].slope;
					count:=count+1;	
				end;
			if (count<min_num_lines) then begin
				report_error('Too few edges in '+CurrentRoutineName+'.');
				exit;
			end;
			average:=sum/count;
		
			sum:=0;
			count:=0;
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then begin
					sum:=sum+sqr(line[line_num].slope-average);
					count:=count+1;	
				end;
			stdev:=sqrt(sum/count);
	
			for line_num:=-pp^.extent to pp^.extent do
				if line[line_num].valid then
					if (abs(line[line_num].slope-average)>sigma_cut*stdev) then begin
						line[line_num].valid:=false;
					end;
		end;
	
		if show_fitting then begin
			for line_num:=-pp^.extent to pp^.extent do begin
				with line[line_num] do begin
					if valid then begin
						ccd_line:=c_from_i_line(image_line);
						display_ccd_line(jip,ccd_line,line_color);
					end;
				end;
			end;
		end;
	
		sum:=0;
		count:=0;
		for line_num:=-pp^.extent to pp^.extent do
			if line[line_num].valid then begin
				sum:=sum+line[line_num].slope;
				count:=count+1;	
			end;
		if (count<min_num_lines) then begin
			report_error('Too few edges in '+CurrentRoutineName+'.');
			exit;
		end;
		average:=sum/count;
		slope_j:=average;
		
		graph_ptr:=new_xyz_graph(line_data_size);
		num_points:=0;
		first_line:=true;
		for line_num:=-pp^.extent to pp^.extent do begin
			if line[line_num].valid then begin
				if first_line then begin
					with graph_ptr^[num_points] do begin
						y:=line[line_num].intercept;
						x:=0;
						z:=1;
					end;
					first_line:=false;
				end
				else begin
					with graph_ptr^[num_points] do begin
						y:=line[line_num].intercept;
						x:=round((y-graph_ptr^[0].y)/pp^.image_y_width);
						z:=1;
					end;
				end;
				inc(num_points);
			end
		end;
		graph_ptr^[num_points].z:=ignore_remaining_data;
		weighted_straight_line_fit(graph_ptr,period_j,offset_j,residual_j);
		dispose_xyz_graph(graph_ptr);
		if (num_points<min_num_lines) then begin
			report_error('Too few edges in '+CurrentRoutineName+'.');
			exit;
		end;
		if math_error(period_j) or math_error(offset_j) then begin
			report_error('Math error fitting edges in '+CurrentRoutineName+'.');
			exit;
		end;
		total_num_lines:=total_num_lines+num_points;
		if show_fitting then begin
			gui_draw(jip^.name);
			gui_wait('Accepted horizontal pattern edges.');
		end;
		if period_j<rasnik_min_pixels_per_square then begin
			report_error('Found period_j<rasnik_min_pixels_per_square in '
				+CurrentRoutineName+'.');
			exit;
		end;
	end else begin
		period_j:=large_period;
		offset_j:=0;
		slope_j:=0;
	end;

	if valid_image_ptr(iip) and valid_image_ptr(jip) then begin
		with iip^.analysis_bounds do 
			ccd_center_offset:=
				(right+left)*one_half-slope_i*(bottom-top)*one_half;
		while (offset_i-ccd_center_offset)<=-period_i*one_half do offset_i:=offset_i+period_i;
		while (offset_i-ccd_center_offset)>period_i*one_half do offset_i:=offset_i-period_i;
		
		with jip^.analysis_bounds do 
			ccd_center_offset:=
				(top+bottom)*one_half-slope_j*(right-left)*one_half;
		while (offset_j-ccd_center_offset)<=-period_j*one_half do offset_j:=offset_j+period_j;
		while (offset_j-ccd_center_offset)>period_j*one_half do offset_j:=offset_j-period_j;
	end;

	if valid_image_ptr(iip) and not valid_image_ptr(jip) then begin
		with iip^.analysis_bounds do ccd_center_offset:=(right+left)*one_half;
		while (offset_i-ccd_center_offset)<=-period_i*one_half do offset_i:=offset_i+period_i;
		while (offset_i-ccd_center_offset)>period_i*one_half do offset_i:=offset_i-period_i;
	end;

	if not valid_image_ptr(iip) and valid_image_ptr(jip) then begin
		with jip^.analysis_bounds do ccd_center_offset:=(top+bottom)*one_half;
		while (offset_j-ccd_center_offset)<=-period_j*one_half do offset_j:=offset_j+period_j;
		while (offset_j-ccd_center_offset)>period_j*one_half do offset_j:=offset_j-period_j;
	end;

	with reference_line_i do begin
		a.y:=pp^.extent*period_j;
		a.x:=slope_i*a.y+offset_i;
		b.y:=-pp^.extent*period_j;
		b.x:=slope_i*b.y+offset_i;
	end;
	
	with reference_line_j do begin
		a.x:=pp^.extent*period_i;
		a.y:=slope_j*a.x+offset_j;
		b.x:=-pp^.extent*period_i;
		b.y:=slope_j*b.x+offset_j;
	end;
	
	pattern_origin_point:=xy_line_line_intersection(reference_line_i,reference_line_j);

	if valid_image_ptr(iip) and valid_image_ptr(jip) then begin
		with pp^ do begin
			origin.x:=pattern_origin_point.x;
			origin.y:=pattern_origin_point.y;
			rotation:=arctan((slope_i-slope_j)*one_half);
			image_x_width:=period_i;
			image_y_width:=period_j;
			pattern_x_width:=image_x_width*cos(rotation);
			pattern_y_width:=image_y_width*cos(rotation);
			error:=sqrt((sqr(residual_i)+sqr(residual_j))/total_num_lines);
		end;
	end;
	
	if valid_image_ptr(iip) and (not valid_image_ptr(jip)) then begin
		with pp^ do begin
			origin.x:=pattern_origin_point.x;
			origin.y:=pattern_origin_point.y;
			rotation:=arctan(slope_i);
			image_x_width:=period_i;
			image_y_width:=0;
			pattern_x_width:=image_x_width*cos(rotation);
			pattern_y_width:=image_y_width*cos(rotation);
			error:=sqrt(sqr(residual_i)/total_num_lines);
		end;
	end;
	
	if (not valid_image_ptr(iip)) and valid_image_ptr(jip) then begin
		with pp^ do begin
			origin.x:=pattern_origin_point.x;
			origin.y:=pattern_origin_point.y;
			rotation:=arctan(slope_j);
			image_x_width:=0;
			image_y_width:=period_j;
			pattern_x_width:=image_x_width*cos(rotation);
			pattern_y_width:=image_y_width*cos(rotation);
			error:=sqrt(sqr(residual_j)/total_num_lines);
		end;
	end;
	
	pp^.valid:=true;
end;

{
	rasnik_adjust_pattern_parity adjusts pp^ so that the square (0,0), which is
	centered at (0.5,0.5) in pattern coordinates, is nominally white. When we
	say 'nominally' white, we mean it would be white if the pattern were a
	simple chess board. Square (0,0) may in fact be black, in which case it is a
	code square. Once the pattern parity is adjusted, any square (x_num,y_num)
	for which the sum x_num + y_num is odd should be black unless it is a code
	square, and any for which the sum is even should be white unless it is a
	code square.
}
procedure rasnik_adjust_pattern_parity(ip:image_ptr_type;pp:rasnik_pattern_ptr_type);

var
	x_num,y_num,min_num,max_num:integer;
	p,new_pattern_origin:xy_point_type;
	new_image_origin:xy_point_type;
	score:real;
	cp:ij_point_type;

begin
	if not valid_image_ptr(ip) then exit;
	if not valid_analysis_bounds(ip) then begin
		report_error('Found not valid_analysis_bounds(ip) in '
			+CurrentRoutineName+'.');
		exit;
	end;
	if pp=nil then exit;
	if not pp^.valid then exit;

	max_num:=pp^.extent div 2;
	min_num:=-max_num;
	score:=0;
	for x_num:=min_num to max_num do begin
		for y_num:=min_num to max_num do begin 
			p.x:=(x_num+square_center_offset);
			p.y:=(y_num+square_center_offset);
			cp:=c_from_i(i_from_p(p,pp));
			if valid_image_analysis_point(cp,ip) then begin
				if odd(x_num+y_num) then 
					score:=score-ip^.intensity[cp.j,cp.i]
				else 
					score:=score+ip^.intensity[cp.j,cp.i]
			end;
		end;
	end;
	if score<0 then begin
		with pp^ do begin
			new_pattern_origin.x:=1;
			new_pattern_origin.y:=0;
			new_image_origin:=i_from_p(new_pattern_origin,pp);
			origin.x:=new_image_origin.x;
			origin.y:=new_image_origin.y;
		end;
	end;
end;

{
	rasnik_identify_pattern_squares fills the elements of the squares array in a 
	valid rasnik_pattern_type. Squares in pattern coordinates that exist on the
	screen we mark as valid, while those that are outside we mark as invalid.
	We record the square center intensity in the squares array as well. What
	remains to be done for each square is determine whether or not it is a code
	square, or a pivot square, or neither. For now, we mark each square as being
	neither. See the comments at the top of rasnik_adjust_pattern_parity for
	an explanation of why we calculate the square intensities again in this
	routine.
}
procedure rasnik_identify_pattern_squares(ip:image_ptr_type;pp:rasnik_pattern_ptr_type);

var
	x_num,y_num,i_extent,j_extent:integer;
	cp,tp:ij_point_type;
	valid_square_bounds:ij_rectangle_type;
	sum,count:integer;
	
begin
	if not valid_image_ptr(ip) then exit;
	if pp=nil then exit;
	if not pp^.valid then exit;
	
	pp^.squares:=new_rasnik_square_array(pp^.extent);
	if pp^.squares=nil then exit;

	i_extent:=round(pp^.image_x_width*square_center_fraction);
	j_extent:=round(pp^.image_y_width*square_center_fraction);
	if i_extent>max_square_center_extent then i_extent:=max_square_center_extent;
	if j_extent>max_square_center_extent then j_extent:=max_square_center_extent;
	if i_extent<min_square_center_extent then i_extent:=min_square_center_extent;
	if j_extent<min_square_center_extent then j_extent:=min_square_center_extent;

	valid_square_bounds:=ip^.analysis_bounds;
	with valid_square_bounds,pp^ do begin
		left:=left+i_extent;
		right:=right-i_extent;
		top:=top+j_extent;
		bottom:=bottom-j_extent;
	end;
	
	for x_num:=-pp^.extent to pp^.extent do begin
		for y_num:=-pp^.extent to pp^.extent do begin
			with pp^,pp^.squares^[x_num,y_num] do begin
				center_pp.x:=(x_num+square_center_offset);
				center_pp.y:=(y_num+square_center_offset);

				with display_outline,pp^ do begin
					cp:=c_from_i(i_from_p(center_pp,pp));
					left:=cp.i-i_extent;
					right:=cp.i+i_extent;
					top:=cp.j-j_extent;
					bottom:=cp.j+j_extent;
				end;

				is_a_valid_square:=
					ij_in_rectangle(
						c_from_i(i_from_p(center_pp,pp)),
						valid_square_bounds);

				if is_a_valid_square then begin
					count:=0;
					sum:=0;
					for tp.i:=cp.i-i_extent to cp.i+i_extent do begin
						for tp.j:=cp.j-j_extent to cp.j+j_extent do begin
							if valid_image_analysis_point(tp,ip) then begin
								sum:=sum+ip^.intensity[tp.j,tp.i];
								inc(count);
							end;
						end;
					end;
					center_intensity:=sum/count;
				end else 
					center_intensity:=-1;
			end;
		end;
	end;
end;

{
	square_whiteness returns a real number indicating the confidence with which 
	we can assert that a square is white. A value of +1 means we are certain it
	is white. A value of -1 means we are certain it is black. A value of 0 means
	we are not sure either way. We obtain this estimate by finding the maximum
	and minimum intensity of neighboring square centers and comparing these with
	the intensity of the candidate square.
}
function square_whiteness(pp:rasnik_pattern_ptr_type;x_num,y_num,extent:integer):real;

const
	n=1; {neighborhood extent}
	
var
	max,min,candidate,whiteness:real;
	x,y:integer;
	
begin
	if pp=nil then exit;
	if not pp^.valid then exit;
	if not pp^.squares^[x_num,y_num].is_a_valid_square then begin
		square_whiteness:=0;
		exit;
	end;
	
	candidate:=pp^.squares^[x_num,y_num].center_intensity;
	max:=min_intensity;
	min:=max_intensity;
	for x:=-n to +n do begin
		for y:=-n to +n do begin
			if ((y_num+y)<=extent) and ((y_num+y)>=-extent) 
				and ((x_num+x)<=extent) and ((x_num+x)>=-extent) then begin
				with pp^.squares^[x+x_num,y+y_num] do begin
					if is_a_valid_square then begin
						if center_intensity>max then max:=center_intensity;
						if center_intensity<min then min:=center_intensity;
					end;
				end;
			end;
		end;
	end;
	
	if (max-min<=0) then whiteness:=0
	else whiteness:=(2*candidate-max-min)/(max-min);
	square_whiteness:=whiteness;
end;

{
	rasnik_identify_code_squares goes through a rasnik_pattern_type
	squares array and determines which squares are out-of parity, and
	marks these as code squares. The routine identifies potential pivot 
	squares and eliminates those that do not agree with the majority.
}
procedure rasnik_identify_code_squares(ip:image_ptr_type;pp:rasnik_pattern_ptr_type);

var
	x_num,y_num,x_code,y_code,x_check,y_check,square_num:integer;
	max_correlation:integer;
	disqualified_by_edge:boolean;
	
	function can_use_square(x,y:integer):boolean;
	var c:boolean;
	begin
		c:=true;
		if (x<-pp^.extent) or (x>pp^.extent) 
			or (y<-pp^.extent) or (y>pp^.extent) then
				c:=false;
		if c then c:=pp^.squares^[x,y].is_a_valid_square;
		can_use_square:=c;
	end;

begin
	if not valid_image_ptr(ip) then exit;
	if pp=nil then exit;
	if not pp^.valid then exit;
	if not valid_analysis_bounds(ip) then exit;
{
	Find the code squares, which are those of opposite polarity to the 
	majority of the chessboard mask.
}
	for x_num:=-pp^.extent to pp^.extent do begin
		for y_num:=-pp^.extent to pp^.extent do begin
			with pp^.squares^[x_num,y_num] do begin
				if is_a_valid_square then begin
					center_whiteness:=square_whiteness(pp,x_num,y_num,pp^.extent);
					is_a_code_square:=
						(odd(x_num+y_num) and (center_whiteness>min_whiteness))
												or	
						(not odd(x_num+y_num) and (center_whiteness<-min_whiteness));
				end 
				else begin
					is_a_code_square:=false;
					center_whiteness:=0;
				end;
			end;
		end;
	end;
{
	Find potential pivot squares, which are code squares that lie at the end of a 
	column number and a row number in the mask.
}
	for x_num:=-pp^.extent to pp^.extent do begin
		for y_num:=-pp^.extent to pp^.extent do begin
			with pp^.squares^[x_num,y_num] do begin
				if is_a_code_square then begin
					disqualified_by_edge:=false;

					x_code:=0;
					for square_num:=1 to rasnik_code_pitch-1 do begin
						x_check:=x_num;
						y_check:=y_num+square_num;
						if not can_use_square(x_check,y_check) then 
							y_check:=y_check-rasnik_code_pitch;
						if not can_use_square(x_check,y_check) then 
							disqualified_by_edge:=true
						else 
							if pp^.squares^[x_check,y_check].is_a_code_square then
								x_code:=x_code+1;
					end;

					y_code:=0;
					for square_num:=1 to rasnik_code_pitch-1 do begin
						x_check:=x_num+square_num;
						y_check:=y_num;
						if not can_use_square(x_check,y_check) then 
							x_check:=x_check-rasnik_code_pitch;
						if not can_use_square(x_check,y_check) then 
							disqualified_by_edge:=true
						else 
							if pp^.squares^[x_check,y_check].is_a_code_square then 
								y_code:=y_code+1;
					end;

					is_a_pivot_square:=
						(y_code>0) and (x_code>0) and not disqualified_by_edge;
					pivot_correlation:=0;
				end;
			end;
		end;
	end;
end;

{
	set_code_directions determines the image x and y directions of
	the mask x and y coordinates in the image. The routine allows for
	us to change the orientation of the pattern coordinates with respect
	to the image coordinages, even though we have no plans to do so.
}
procedure set_code_directions(pp:rasnik_pattern_ptr_type);

var
	pp_a,pp_b:xy_point_type;
	cp_a,cp_b:ij_point_type;
	mask_x_rightwards,mask_y_upwards:integer;
	pattern_x_rightwards,pattern_y_upwards:integer;	

begin
{
	Create a rasnik pattern type to simplify our calculations 
	and transformations. 
}
	with pp^ do begin
{
	Set mask_x_rightwards and mask_y_upwards to match mask_orientation.
}
		case mask_orientation of
			rasnik_mask_orientation_nominal:begin
				mask_x_rightwards:=+1;
				mask_y_upwards:=+1;
			end;
			rasnik_mask_orientation_rotated_y:begin
				mask_x_rightwards:=-1;
				mask_y_upwards:=+1;
			end;
			rasnik_mask_orientation_rotated_x:begin
				mask_x_rightwards:=+1;
				mask_y_upwards:=-1;
			end;
			rasnik_mask_orientation_rotated_z:begin
				mask_x_rightwards:=-1;
				mask_y_upwards:=-1;
			end;			  
			otherwise begin
				report_error('Invalid mask orientation in '+CurrentRoutineName+'.');
				exit;
			end;
		end;
{
	Determine whether the pattern x-axis is left to right in the image.
}
		pp_a.x:=0;pp_a.y:=0; cp_a:=c_from_i(i_from_p(pp_a,pp));
		pp_b.x:=1;pp_b.y:=0; cp_b:=c_from_i(i_from_p(pp_b,pp));
		if (cp_b.i>cp_a.i) then pattern_x_rightwards:=+1
		else pattern_x_rightwards:=-1;
{
	Determine whether the pattern y-axis is bottom to top in the image.
}
		pp_a.x:=0;pp_a.y:=0; cp_a:=c_from_i(i_from_p(pp_a,pp));
		pp_b.x:=0;pp_b.y:=1; cp_b:=c_from_i(i_from_p(pp_b,pp));
		if (cp_b.j<cp_a.j) then pattern_y_upwards:=+1
		else pattern_y_upwards:=-1;
{
	Determine the pattern-coordinate x- and y- directions in which the
	first (and most significant) bit of a mask code is to be found with 
	respect to a pivot sqaure.
}
		x_code_direction:=mask_x_rightwards*pattern_x_rightwards;
		y_code_direction:=mask_y_upwards*pattern_y_upwards;
	end;
end;

{
	analyze_orientation does the bulk of the work for the subsequent
	rasnik_analyze_code routine. It identifies pivot squares, and 
	interprets the pattern codes assuming a certain orientation of
	the mask pattern in the image.
}
procedure analyze_orientation(pp:rasnik_pattern_ptr_type;
	code:integer; var score:integer);

const
	base=2;
	max_pivot_count=100;
	max_lone_pivots=7;
	min_score_fraction=0.2;

var 
	pp_a,pp_b:xy_point_type;
	cp_a,cp_b:ij_point_type;
	mask_x_rightwards,mask_y_upwards:integer;
	pattern_x_rightwards,pattern_y_upwards:integer;	
	x_num,y_num,square_num,x_check,y_check:integer;	
	code_weight,max_code_weight:integer;
	num_scoring_pivots:integer;
	main_pivot_count,check_pivot_count:integer;

	function can_use_square(x,y:integer):boolean;
	var c:boolean;
	begin
		c:=true;
		if (x<-pp^.extent) or (x>pp^.extent) 
			or (y<-pp^.extent) or (y>pp^.extent) then
				c:=false;
		if c then c:=pp^.squares^[x,y].is_a_valid_square;
		can_use_square:=c;
	end;

begin
	if pp=nil then exit;
	if not pp^.valid then exit;
	
	with pp^ do begin
{
	Set the code directions for the specified orientation number.
}
		mask_orientation:=code;
		set_code_directions(pp);
{
	Determine the weight of the most significant code bit.
}
		max_code_weight:=round(exp((rasnik_code_pitch-1-1)*ln(base)));
{
	Determine the pivot square x and y code for this orientation. We
	also take the precation of setting all the pivot correlations to zero.
}
		for x_num:=-extent to extent do begin
			for y_num:=-extent to extent do begin
				with squares^[x_num,y_num] do begin
					if is_a_pivot_square then begin
						pivot_correlation:=0;
						x_code:=0;
						code_weight:=max_code_weight;
						for square_num:=1 to rasnik_code_pitch-1 do begin
							x_check:=x_num;
							y_check:=y_num+square_num*y_code_direction;
							if not can_use_square(x_check,y_check) then 
								y_check:=y_check-rasnik_code_pitch*y_code_direction;
							if squares^[x_check,y_check].is_a_code_square then
								x_code:=x_code+code_weight;
							code_weight:=code_weight div base;
						end;
						y_code:=0;
						code_weight:=max_code_weight;
						for square_num:=1 to rasnik_code_pitch-1 do begin
							x_check:=x_num+square_num*x_code_direction;
							y_check:=y_num;
							if not can_use_square(x_check,y_check) then 
								x_check:=x_check-rasnik_code_pitch*x_code_direction;
							if squares^[x_check,y_check].is_a_code_square then 
								y_code:=y_code+code_weight;
							code_weight:=code_weight div base;
						end;
					end;
				end;
			end;
		end;
{
	Here we assign a pivot_correlation to each pivot square. The correlation is
	the number of pivot squares in the image that are consistent with the
	current pivot square, including itself. Two pivot squares are consistent if
	their code values differ correctly for their separation, and if their
	separation is an integer multiple of the code line spacing. If one pivot
	square has a corrupted code next to it, and we have five or six pivot
	squares in the image, we can eliminate pivot point with a corrupted code by
	noting that its pivot correlation is lower than that of other pivot point in
	the image. In the embedded loops, we check that the number of main pivots
	and check pivots we have tested remains within a limit max pivot count. If
	we don't do this, then certain noise images, or images with very small
	squares, can cause the loops to search and compare thousands of pivots with
	thousands of pivots, which takes thousands of times longer than necessary to
	determine that the image is no good.
}
		score:=0;
		main_pivot_count:=0;
		x_num:=-extent;
		while (x_num<=extent) and (main_pivot_count<max_pivot_count) do begin
			y_num:=-extent;
			while (y_num<=extent) and (main_pivot_count<max_pivot_count) do begin
				if squares^[x_num,y_num].is_a_pivot_square then begin
					squares^[x_num,y_num].pivot_correlation:=0;
					check_pivot_count:=0;
					x_check:=-extent;
					while (x_check<=extent) and (check_pivot_count<max_pivot_count) do begin
						y_check:=-extent;
						while (y_check<=extent) and (check_pivot_count<max_pivot_count) do begin
							if squares^[x_check,y_check].is_a_pivot_square then begin
								if ((squares^[x_check,y_check].x_code 
									- squares^[x_num,y_num].x_code)
									= ((x_check-x_num) 
										/ rasnik_code_pitch) 
										* x_code_direction)
									and 
								((squares^[x_check,y_check].y_code 
									- squares^[x_num,y_num].y_code)
									= ((y_check-y_num) 
										/ rasnik_code_pitch) 
										* y_code_direction)
									and
								(abs(x_check-x_num) mod rasnik_code_pitch = 0)
									and
								(abs(y_check-y_num) mod rasnik_code_pitch = 0)									
									then begin
									inc(squares^[x_num,y_num].pivot_correlation);
								end;
								if (squares^[x_num,y_num].pivot_correlation>score) then
									score:=squares^[x_num,y_num].pivot_correlation;
								inc(check_pivot_count);
							end;
							inc(y_check);
						end;
						inc(x_check);
					end;
					inc(main_pivot_count);
				end;
				inc(y_num);
			end;
			inc(x_num);
		end;
{
	We count the number of pivot squares that have correlation equal to
	the score. Because we set all the correlations to zero at the start
	of this routine, we know that if our score is one or creater, only 
	the pivots we have treated since then will be counted.
}
		num_scoring_pivots:=0;
		for x_num:=-extent to extent do
			for y_num:=-extent to extent do
				with squares^[x_num,y_num] do
					if is_a_pivot_square and (pivot_correlation=score) then
						inc(num_scoring_pivots);
{
	If the score is greater than one, we have at least two or more pivot points
	that agree with one another. In almost all cases, there is only one set of
	pivot points that agree with one another. In rare cases, there are two sets
	of differing size, so that the larger wins out. In some cases, there are two
	sets of the same size. We cannot decide between them so we set the score to
	zero.
}
		if (score>1) and (score<>num_scoring_pivots) then score:=0;
{
	If the score is one, we put a limit on the number of pivots.
}
		if (score=1) and (num_scoring_pivots>max_lone_pivots) then score:=0;
{
	If the score is greater than one, we insist that the number of scoring
	pivots must be greater than a certain fraction of the number of pivots
	we considered.
}
		if (score>1) and (num_scoring_pivots<
			main_pivot_count*min_score_fraction) then score:=0;
{
	If the score is one, we may have several candidate pivot points, all of
	which disagree with one another. So now we try to pick the best of these.
	First we go through and re-calculate the correlations, this time using the
	correlation variable to count the number of supporting evidence for this
	pivot point's validity. Then we find the most supported pivot, set its
	correlation to one, and set that of all the others to zero. If, by the end
	of these tests, we still can't pick a best pivot point, we give up and set
	the score to zero.
}
		if score=1 then begin
			score:=0;
			main_pivot_count:=0;
			x_num:=-extent;
			while (x_num<=extent) and (main_pivot_count<max_pivot_count) do begin
				y_num:=-extent;
				while (y_num<=extent) and (main_pivot_count<max_pivot_count) do begin
					with squares^[x_num,y_num] do begin
						if is_a_pivot_square then begin
							pivot_correlation:=0;
							if can_use_square(x_num+rasnik_code_pitch,y_num) then
								if squares^[x_num+rasnik_code_pitch,y_num].is_a_code_square then
									inc(pivot_correlation) else dec(pivot_correlation);			
							if can_use_square(x_num-rasnik_code_pitch,y_num) then
								if squares^[x_num-rasnik_code_pitch,y_num].is_a_code_square then
									inc(pivot_correlation) else dec(pivot_correlation);
							if can_use_square(x_num,y_num+rasnik_code_pitch) then
								if squares^[x_num,y_num+rasnik_code_pitch].is_a_code_square then
									inc(pivot_correlation) else dec(pivot_correlation);
							if can_use_square(x_num,y_num-rasnik_code_pitch) then
								if squares^[x_num,y_num-rasnik_code_pitch].is_a_code_square then
									inc(pivot_correlation) else dec(pivot_correlation);
							if score<pivot_correlation then score:=pivot_correlation;
							inc(main_pivot_count);
						end;
					end;
					inc(y_num);
				end;
				inc(x_num);
			end;
			main_pivot_count:=0;
			check_pivot_count:=0;
			x_num:=-extent;
			while (x_num<=extent) and (main_pivot_count<max_pivot_count) do begin
				y_num:=-extent;
				while (y_num<=extent) and (main_pivot_count<max_pivot_count) do begin
					with squares^[x_num,y_num] do begin
						if is_a_pivot_square then begin
							if pivot_correlation=score then begin
								pivot_correlation:=1;
								inc(check_pivot_count);
							end else pivot_correlation:=0;
							inc(main_pivot_count);
						end;
					end;
					inc(y_num);
				end;
				inc(x_num);
			end;
			if check_pivot_count>1 then score:=0 else score:=1;
		end;
	end;
end;

{
	rasnik_analyze_code calls analyze_orientation for a particular orientation,
	if orientation_code is non-zero, or for all orientations if orientation_code
	is zero. The routine tries to decide which of the orientations is correct.
}
procedure rasnik_analyze_code(pp:rasnik_pattern_ptr_type;orientation_code:integer);

const
	num_orientations=4;
	score_threshold=1;

var 
	score,orientation_num,max_score:integer;
	x_num,y_num,x,y:integer;

begin
	if pp=nil then exit;
	if not pp^.valid then exit;	
{
	If instructed to do so, try all orientations and pick the one with the 
	highest orientation score.
}
	if orientation_code=rasnik_try_all_orientations then begin
		max_score:=0;
		orientation_code:=1;
		for orientation_num:=1 to num_orientations do begin
			analyze_orientation(pp,orientation_num,score);
			if score>max_score then begin
				max_score:=score;
				orientation_code:=orientation_num;
			end;
		end;
	end;
{
	Analyze the selected orientation. If its score is less than the threshold
	for acceptance, report an error and mark the pattern as invalid.
}
	analyze_orientation(pp,orientation_code,score);
	if score<score_threshold then begin
		report_error('No valid pivot squares in '+CurrentRoutineName+'.');
		pp^.valid:=false;
	end;
{
	Remove any pivot squares with scores lower than that of the orientation
	score, and remove all pivot squares if the score is zero.
}
	with pp^ do
		for x_num:=-extent to extent do
			for y_num:=-extent to extent do
				with squares^[x_num,y_num] do
					if is_a_pivot_square then
						if (pivot_correlation<score) or (score=0) then
							is_a_pivot_square:=false;
end;

{
	rasnik_mask_position takes a point in image coordinates, and a completed
	rasnik_pattern_type (square array fully analyzed by above routines), and
	returns the position in the mask that has been projected onto the image point.
	To make this calculation, the routine needs to know also the width of the
	squares on the mask.
}
function rasnik_mask_position(pp:rasnik_pattern_ptr_type;
	reference_point:xy_point_type;
	square_size_um,pixel_size_um:real):xy_point_type;

const
	max_num_pivots=10;
	small_um=0.01;

type
	pivot_type=record
		mp:xy_point_type;
		score:integer;
	end;
	
var
	x_num,y_num,pivot_num,num_pivots,best_pivot_num,pivot_index:integer;
	pivot_square:rasnik_square_type;
	reference_pp,reference_ip:xy_point_type;
	cp:ij_point_type;
	pivots:array [1..max_num_pivots] of pivot_type;
	
begin
	if pp=nil then exit;
	if not pp^.valid then exit;

	num_pivots:=0;
	with pp^ do begin
		for x_num:=-pp^.extent to pp^.extent do begin
			for y_num:=-pp^.extent to pp^.extent do begin
				if squares^[x_num,y_num].is_a_pivot_square and 
						(num_pivots<max_num_pivots) then begin
					inc(num_pivots);
					pivot_square:=squares^[x_num,y_num];
{
	Calculate the position of the reference point, expressed in pattern 
	coordinates (in units of pixels).
}
					reference_ip:=xy_scale(reference_point,1/pixel_size_um);
					reference_pp:=p_from_i(reference_ip,pp);
{
	Calculate the vector from the mask origin to the point in the 
	mask that is projected onto the image coordinate origin, 
	expressed in mask coordinates (in units of micrometers).
}
					pivots[num_pivots].mp.x:=
						(reference_pp.x-pivot_square.center_pp.x)
							*x_code_direction
							*square_size_um
						+integer(pivot_square.x_code-mask_origin_x_code)
							*rasnik_code_pitch
							*square_size_um
						+mask_origin_offset
							*square_size_um;
							
					pivots[num_pivots].mp.y:=(reference_pp.y-pivot_square.center_pp.y)
							*y_code_direction
							*square_size_um
						+integer(pivot_square.y_code-mask_origin_y_code)
							*rasnik_code_pitch
							*square_size_um
						+mask_origin_offset
							*square_size_um;
				end;
			end;
		end;
	end;
	
	if num_pivots=0 then begin
		report_error('No pivot squares in '+CurrentRoutineName+'.');
		exit;
	end;
	
	for pivot_num:=1 to num_pivots do begin
		pivots[pivot_num].score:=0;
		for pivot_index:=1 to num_pivots do begin
			if (abs(pivots[pivot_num].mp.x-pivots[pivot_index].mp.x)<small_um)
					and (abs(pivots[pivot_num].mp.y-pivots[pivot_index].mp.y)<small_um) then begin
				inc(pivots[pivot_num].score);
			end;
		end;
	end;

	best_pivot_num:=1;
	for pivot_num:=1+1 to num_pivots do begin
		if pivots[pivot_num].score>pivots[best_pivot_num].score then begin
			best_pivot_num:=pivot_num;
		end;
	end;
	
	rasnik_mask_position:=pivots[best_pivot_num].mp;
end;

{
	rasnik_reference_point takes a reference code and calculates the 
	corresponding point in image coordinates specified by the reference code.
	We pass a the original ip to the routine. The reference codes
	are defined at the top of this unit. 
}
function rasnik_reference_point(ip:image_ptr_type;reference_code:integer;
	reference_x,reference_y:real;pixel_size_um:real):xy_point_type;
	
var
	image_rectangle:xy_rectangle_type;
	ccd_rectangle:ij_rectangle_type;
	ref:xy_point_type;
	
begin
	rasnik_reference_point:=xy_origin;
	if not valid_image_ptr(ip) then exit;
	
	case reference_code of
		rasnik_reference_top_left_corner:begin
			ref.x:=0;
			ref.y:=0;
		end;
		rasnik_reference_center_analysis_bounds:begin
			image_rectangle:=i_from_c_rectangle(ip^.analysis_bounds);
			with image_rectangle do begin
				ref.x:=(left+right)*one_half*pixel_size_um;
				ref.y:=(top+bottom)*one_half*pixel_size_um;
			end;
		end;
		rasnik_reference_center_ccd:begin
			with ccd_rectangle do begin
				left:=0;
				right:=ip^.i_size-1;
				top:=0;
				bottom:=ip^.j_size-1;
			end;
			image_rectangle:=i_from_c_rectangle(ccd_rectangle);
			with image_rectangle do begin
				ref.x:=(left+right)*one_half*pixel_size_um;
				ref.y:=(top+bottom)*one_half*pixel_size_um;
			end;
		end;
		rasnik_reference_image_point:begin
			ref.x:=reference_x;
			ref.y:=reference_y;
		end;
	end;
	rasnik_reference_point:=ref;
end;

{
	rasnik_from_pattern calculates the position in a rasnik mask that
	has been projected onto a reference point in an image of a rasnik
	mas. We do not pass the image to rasnik_from_pattern, only a
	fully-completed pattern record. The orientation code tells the
	routine the orientation of the mask as it appears in the image.
	The orientation codes are defined at the top of this unit. The
	reference_code and reference_point must both be valid.
}
function rasnik_from_pattern(ip:image_ptr_type;
	pp:rasnik_pattern_ptr_type;
	reference_code:integer;
	reference_x,reference_y:real;
	square_size_um,pixel_size_um:real):rasnik_ptr_type;

var	
	rp:rasnik_ptr_type;
	mask_point,reference_ip:xy_point_type;
	rotation_error:real;

begin
{
	Create a new rasnik_type.
}
	rp:=new_rasnik;
	rp^.valid:=false;
	rasnik_from_pattern:=rp;
{
	Check the pattern.
}
	if pp=nil then exit;
	if not pp^.valid then exit;
{
	Fill the rasnik record with all information necessary to calculate the
	rasnik results.
}
	rp^.mask_orientation:=pp^.mask_orientation;
	rp^.pixel_size_um:=pixel_size_um;
	rp^.reference_point:=
		rasnik_reference_point(ip,reference_code,
			reference_x,reference_y,pixel_size_um);
	rp^.square_size_um:=square_size_um;

	with rp^ do begin
{
	Calculate the position of the point in the mask that is projected
	onto the reference point in the image.
}
		mask_point:=rasnik_mask_position(pp,reference_point,square_size_um,pixel_size_um);
{
	Calculate the magnification, rotation, and fitting error.
}
		magnification_x:=pixel_size_um*pp^.pattern_x_width/square_size_um;
		magnification_y:=pixel_size_um*pp^.pattern_y_width/square_size_um;
		rotation:=arctan(sin(pp^.rotation)/cos(pp^.rotation));
		error:=sqrt(sqr(pixel_size_um*pp^.error/magnification_x)
			+sqr(pixel_size_um
				*xy_separation(
					xy_scale(reference_point,1/pixel_size_um),
					i_from_c(pp^.analysis_center_cp))
				*(pp^.error/pp^.analysis_width)
				/magnification_x));
		valid:=pp^.valid;
	end;
{
	Fill in other fields of the rasnik record.
}
	rp^.reference_code:=reference_code;
end;

{
	rasnik_display_reference_point marks the reference point on the rasnik
	image.
}
procedure rasnik_display_reference_point(ip:image_ptr_type;
	reference_code:integer;reference_x,reference_y:real;
	pixel_size_um:real);
	
const
	ref_rect_size=10;
	
var
	cp:ij_point_type;
	entire_image,saved_bounds,ref_rect:ij_rectangle_type;
	reference_point:xy_point_type;
	
begin
	if not valid_image_ptr(ip) then exit;
	
	with reference_point do begin
		x:=reference_x;
		y:=reference_y;
	end;
	cp:=c_from_i(xy_scale(reference_point,1/pixel_size_um));
	with entire_image do begin
		left:=0;
		right:=ip^.i_size-1;
		top:=0;
		bottom:=ip^.j_size-1;
	end;
	with ref_rect do begin
		left:=cp.i-ref_rect_size;
		right:=cp.i+ref_rect_size;
		top:=cp.j-ref_rect_size;
		bottom:=cp.j+ref_rect_size;
	end;
	saved_bounds:=ip^.analysis_bounds;
	
	case reference_code of
		rasnik_reference_top_left_corner,rasnik_reference_image_point:begin
			ip^.analysis_bounds:=entire_image;
			display_ccd_rectangle_cross(ip,ref_rect,orange_color);
			display_ccd_rectangle(ip,ref_rect,orange_color);
		end;
		rasnik_reference_center_analysis_bounds:begin
			display_ccd_cross(ip,cp,blue_color);
		end;
		rasnik_reference_center_ccd:begin
			ip^.analysis_bounds:=entire_image;
			display_ccd_cross(ip,cp,blue_color);
		end;
	end;

	ip^.analysis_bounds:=saved_bounds;
end;

{
	rasnik_shift_reference_point takes in a rasnik_type and re-calculates the
	rasnik measurements based upon a new reference point.
}
function rasnik_shift_reference_point(rasnik:rasnik_type;
	new_reference_point:xy_point_type):rasnik_type;
	
var
	new_rasnik:rasnik_type;
	pattern_vector,mask_vector:xy_point_type;
	pp:rasnik_pattern_ptr_type;
	
begin
	new_rasnik:=rasnik;
	new_rasnik.valid:=false;
	rasnik_shift_reference_point:=new_rasnik;
	if not rasnik.valid then exit;
{
	create a new pattern pointer for our calculateions, and fill in the
	necessary elements.
}
	pp:=new_rasnik_pattern;
	with pp^ do begin
		rotation:=rasnik.rotation;
		mask_orientation:=rasnik.mask_orientation;
		pattern_x_width:=rasnik.square_size_um*rasnik.magnification_x/rasnik.pixel_size_um;
		pattern_y_width:=rasnik.square_size_um*rasnik.magnification_y/rasnik.pixel_size_um;
	end;
	set_code_directions(pp);
{
	Calculate the vector in pattern coordinates (units are pixels) from the old 
	reference point to the new reference point.
}
	pattern_vector:=xy_scale(
		xy_difference(
			p_from_i(new_reference_point,pp),
			p_from_i(rasnik.reference_point,pp)),
		1/rasnik.pixel_size_um);
{
	Translate this change vector into a vector in mask coordinates (in micrometers).
}
	mask_vector.x:=pattern_vector.x*pp^.x_code_direction
		*rasnik.square_size_um;
	mask_vector.y:=pattern_vector.y*pp^.y_code_direction
		*rasnik.square_size_um;
{
	Dispose of our pattern pointer. 
}
	dispose_rasnik_pattern(pp);
{
	Add the mask vector to the old mask position to get the new rasnik measurement.
}
	new_rasnik.mask_point:=xy_sum(rasnik.mask_point,mask_vector);
	new_rasnik.reference_point:=new_reference_point;
	new_rasnik.valid:=true;
	rasnik_shift_reference_point:=new_rasnik;
end;

{
	rasnik_analyze_image returns a rasnik_ptr_type to the results of
	rasnik analysis applied to the specified image_type. It performs
	no drawing in the image overlay.
}
function rasnik_analyze_image(ip:image_ptr_type;
	orientation_code,reference_code:integer;
	reference_x,reference_y,square_size_um,pixel_size_um:real):rasnik_ptr_type;

var
	iip,jip:image_ptr_type;
	pp:rasnik_pattern_ptr_type;
	ref:xy_point_type;
	rp:rasnik_ptr_type;
	s:rasnik_square_type;
	
begin
	if not valid_image_ptr(ip) then begin
		report_error('Invalid image pointer in '+CurrentRoutineName+'.');
		exit;
	end;
	
	iip:=image_grad_i(ip);
	jip:=image_grad_j(ip);
	pp:=rasnik_find_pattern(iip,jip,false);
	rasnik_refine_pattern(pp,iip,jip,false);
	rasnik_adjust_pattern_parity(ip,pp);
	rasnik_identify_pattern_squares(ip,pp);
	rasnik_identify_code_squares(ip,pp);
	rasnik_analyze_code(pp,orientation_code);
	rp:=rasnik_from_pattern(ip,pp,reference_code,reference_x,reference_y,
		square_size_um,pixel_size_um);
	dispose_rasnik_pattern(pp);
	dispose_image(iip);
	dispose_image(jip);
	rasnik_analyze_image:=rp;
end;

{
	rasnik_analyze_file takes a file name as a CString, reads the file
	from disk, applies rasnik analysis with the specified parameters,
	and returns a pointer to a rasnik_type.
}
function rasnik_analyze_file(file_name:CString;
	orientation_code,reference_code:integer;
	reference_x,reference_y,square_size_um,pixel_size_um:real):rasnik_ptr_type;

var
	ip:image_ptr_type;

begin
	ip:=read_daq_file(short_string_from_c_string(file_name));
	rasnik_analyze_file:=rasnik_analyze_image(ip,
		orientation_code,reference_code,
		reference_x,reference_y,
		square_size_um,pixel_size_um);
	dispose_image(ip);
end;

{
	rasnik_simulated_image draws a rasnik pattern in an image. We specify the
	offset, square size, and rotation of the pattern with a rasnik_pattern_type.
	The origin sets the offset, rotation sets the rotation, and the
	pattern_x_width and pattern_y_width set the square size in the two pattern
	directions in units of pixels. We ignore all other fields. The rasnik image
	contains no code squares. It's just a plain chessboard. We use the
	chessboard to check rasnik_find_pattern and rasnik_refine_pattern. A final
	number in the command string can specify the amount of white noise to
	add to the image. When 1.0, we add a random number 0 to 1 to the intensity.
}
procedure rasnik_simulated_image(ip:image_ptr_type;command:short_string);

var 
	i,j:integer;
	c:ij_point_type;
	p:xy_point_type;
	v:real;
	pp:rasnik_pattern_ptr_type;
	sharpness:real;
	noise:real;
	
begin
	if not valid_image_ptr(ip) then begin
		report_error('Invalid image pointer in '+CurrentRoutineName+'.');
		exit;
	end;
	
	pp:=new_rasnik_pattern;
	pp^.origin.x:=read_real(command);
	pp^.origin.y:=read_real(command);
	pp^.pattern_x_width:=read_real(command);
	pp^.pattern_y_width:=read_real(command);
	pp^.rotation:=read_real(command)/mrad_per_rad;
	sharpness:=read_real(command);
	noise:=read_real(command);
	for j:=1 to ip^.j_size-1 do begin
		for i:=0 to ip^.i_size-1 do begin
			c.i:=i;
			c.j:=j;
			p:=p_from_i(i_from_c(c),pp);
			v:=mid_intensity*(1+sharpness*sin(pi*p.x)*sin(pi*p.y))
				+ random_0_to_1*noise;
			if v>max_intensity then v:=max_intensity;
			if v<min_intensity then v:=min_intensity;
			ip^.intensity[j,i]:=round(v);
		end;
	end;

	dispose_rasnik_pattern(pp);	
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