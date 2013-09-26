{
Routines for Image Handling
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
unit images;

interface

uses
	utils;
	
const {for names}
	default_image_name='lwdaq_image_';
	scratch_image_name='lwdaq_scratch';

const {for eight-bit intensity values}
	max_intensity=255;
	min_intensity=0;
	mid_intensity=128;
	low_intensity=5;
	black_intensity=min_intensity;
	white_intensity=max_intensity;

const {overlay colors}
	red_mask=$E0;
	green_mask=$1C;
	blue_mask=$03;
	
	black_color=0; {black}
	clear_color=254; {transparent, so you see black-and-white image beneath}
	white_color=255; {white}

	dark_brown_color=96;
	dark_red_color=160;
	red_color=224;
	vdark_green_color=8;
	dark_green_color=20;
	green_color=28;
	vdark_blue_color=1;
	dark_blue_color=2;
	blue_color=3;
	sky_blue_color=147;
	orange_color=236;
	yellow_color=216;
	salmon_color=242;
	magenta_color=227;
	brown_color=140;
	dark_gray_color=73;
	gray_color=146;
	light_gray_color=182;

const {for four-byte screen pixels}
	opaque_alpha=max_byte;

const {for field sizes}
	max_num_image_pixels=10000000;

const {for intensification}
	no_intensify=0;
	mild_intensify=1;
	strong_intensify=2;
	exact_intensify=3;

type {for image storage}
	overlay_pixel_type=byte;
	intensity_pixel_type=byte;
	image_type(j_size,i_size:integer)=record
		intensity:array [0..j_size-1,0..i_size-1] of intensity_pixel_type;
		overlay:array [0..j_size-1,0..i_size-1] of overlay_pixel_type;
		analysis_bounds:ij_rectangle_type;
		average,amplitude,maximum,minimum:real;
		name:short_string;
		intensification:integer;
		results:short_string;
	end;
	image_ptr_type=^image_type;
	
type {for drawing space}
	drawing_space_pixel_type=packed record
		red,green,blue,alpha:byte;
	end;
	drawing_space_type(size:integer)=
		array [0..size-1] of drawing_space_pixel_type;
	drawing_space_ptr_type=^drawing_space_type;
	color_table_type(size:integer)=
		array [0..size-1] of drawing_space_pixel_type;
	color_table_ptr_type=^color_table_type;

type {for image headers}
	image_header_type=record
		j_max,i_max,top,left,bottom,right:shortint;
		results:array[0..short_string_length] of char;
	end;
	image_header_ptr_type=^image_header_type;

const {for master image list}
	master_image_list_size=100;
	
var {for global use}
	master_image_list:array [0..master_image_list_size-1] of image_ptr_type;
	drawing_space_ptr:drawing_space_ptr_type=nil;
	image_counter:cardinal=0;
	gamma_correction:real=1;
	rggb_red_scale:real=1;
	rggb_blue_scale:real=1;

{
	Image creation, drawing, and simple examination.
}
procedure clear_overlay(ip:image_ptr_type);
procedure dispose_image(ip:image_ptr_type);
	attribute (name='Dispose_Image');
procedure dispose_named_images(key:short_string);
procedure draw_image(ip:image_ptr_type);
procedure draw_rggb_image(ip:image_ptr_type);
procedure draw_overlay_line(ip:image_ptr_type;line:ij_line_type;
	color:overlay_pixel_type);
procedure draw_overlay_pixel(ip:image_ptr_type;pixel:ij_point_type;
	color:overlay_pixel_type);
procedure draw_overlay_rectangle(ip:image_ptr_type;rect:ij_rectangle_type;
	color:overlay_pixel_type);
procedure draw_overlay_rectangle_ellipse(ip:image_ptr_type;rect:ij_rectangle_type;
	color:overlay_pixel_type);
procedure draw_overlay_ellipse(ip:image_ptr_type;
	ellipse:ij_ellipse_type;color:overlay_pixel_type);
procedure embed_image_header(ip:image_ptr_type);
procedure fill_overlay(ip:image_ptr_type);
function image_ptr_from_name(name:short_string):image_ptr_type;
function image_amplitude(ip:image_ptr_type):real;
function image_average(ip:image_ptr_type):real;
function image_maximum(ip:image_ptr_type):real;
function image_minimum(ip:image_ptr_type):real;
function image_sum(ip:image_ptr_type; threshold:integer):integer;
function overlay_color_from_integer(i:integer):overlay_pixel_type;
procedure paint_overlay(ip:image_ptr_type;color:overlay_pixel_type);
procedure paint_overlay_bounds(ip:image_ptr_type;color:overlay_pixel_type);
function new_image(j_size,i_size:integer):image_ptr_type;
	attribute (name='New_Image');
function valid_analysis_bounds(ip:image_ptr_type):boolean;
function valid_image_analysis_point(point:ij_point_type;ip:image_ptr_type):boolean;	
function valid_image_name(s:short_string):boolean;
function valid_image_point(ip:image_ptr_type;p:ij_point_type):boolean;
function valid_image_ptr(ip:image_ptr_type):boolean;
procedure write_image_list(var f:string;key:short_string;verbose:boolean);

{
	Interface for C programs. The routines declared with the "attribute" key word
	above are also for use with C programs.
}
function image_from_daq(data_ptr:pointer;data_size:integer;
	var width,height,left,top,right,bottom,try_header:integer;
	var results,name:CString):image_ptr_type;
	attribute (name='Image_From_Daq');
procedure daq_from_image(ip:image_ptr_type;data_ptr:pointer);
	attribute (name='Daq_From_Image');
function read_daq_file(name:CString):image_ptr_type;
	attribute (name='Read_Daq_File');
procedure write_daq_file(name:CString;ip:image_ptr_type);
	attribute (name='Write_Daq_File');
function image_from_contents(intensity_ptr:pointer;
	width,height,left,top,right,bottom:integer;
	results,name:CString):image_ptr_type;
	attribute (name='Image_From_Contents');
procedure contents_from_image(ip:image_ptr_type;intensity_ptr:pointer;
	var width,height,left,top,right,bottom:integer;var results,name:CString);
	attribute (name='Contents_From_Image');

implementation
	
var
	image_color_table_ptr:color_table_ptr_type;
	overlay_color_table_ptr:color_table_ptr_type;

{
	paint_overlay fills an image's overlay with the specified color.
}
procedure paint_overlay(ip:image_ptr_type;color:overlay_pixel_type);
begin
	with ip^ do block_set(@overlay,j_size*i_size,color);
end;

{
	clear_overlay clears an image's overlay, making it transparant.
}
procedure clear_overlay(ip:image_ptr_type);
begin
	paint_overlay(ip,clear_color);
end;

{
	fill_overlay fills an image's overlay with opaque white.
}
procedure fill_overlay(ip:image_ptr_type);
begin
	paint_overlay(ip,white_color);
end;

{
	paint_overlay_bounds fills an image's overlay with the specified color
	within its analysis bounds.
}
procedure paint_overlay_bounds(ip:image_ptr_type;color:overlay_pixel_type);
var i,j:integer;
begin
	with ip^ do
		with analysis_bounds do
			for j:=top to bottom do
				for i:=left to right do
					overlay[j,i]:=color;
end;

{
	new_image allocates space for a new image_type with the specified
	j_size and i_size. It adds this image to the master image list. The 
	analysis boundaries are left = 0, top = 1, right = i_size-1, and 
	bottom = j_size-1. We let top=1 because routines like embed_image_header
	use the first row for information about the image, such as the dimensions
	and analysis bounds.
}
function new_image(j_size,i_size:integer):image_ptr_type;
 
var
	ip:image_ptr_type;
	image_num:integer;
	
begin
	new_image:=nil;
	
	image_num:=0;
	while (image_num<master_image_list_size) and (master_image_list[image_num]<>nil) do
		inc(image_num);
	if (image_num>=master_image_list_size) then begin
		report_error('Master image list is full in '+CurrentRoutineName+'.');
		exit;
	end;

	if (j_size<=0) or (i_size<=0) then begin
		report_error('Found (j_size<=0) or (i_size<=0) in '+CurrentRoutineName+'.');
		exit;
	end;
	if (j_size*i_size)>max_num_image_pixels then begin
		report_error('Found (j_size*i_size)>max_num_image_pixels in '+CurrentRoutineName+'.');
		exit;
	end;
	
	ip:=new(image_ptr_type,j_size,i_size);
	if ip=nil then begin
		report_error('Failed to allocate for ip in '+CurrentRoutineName+'.');
		exit;
	end;
	inc_num_outstanding_ptrs(sizeof(ip^),CurrentRoutineName);
	
	master_image_list[image_num]:=ip;
	inc(image_counter);
	
	with ip^ do begin	
		with analysis_bounds do begin
			left:=0;
			right:=i_size-1;
			top:=1;
			bottom:=j_size-1;
		end;
		writestr(name,default_image_name,image_counter:1);
		average:=not_valid_code;
		amplitude:=not_valid_code;
		maximum:=not_valid_code;
		minimum:=not_valid_code;
		block_clear(@intensity,j_size*i_size);
		results:='';
	end;
	clear_overlay(ip);
	
	new_image:=ip;
end;

{
	overlay_color_from_integer returns a unique color depending
	upon the integer input. We can use it to provide colors for
	indexed arrays of lines, graphs, or shapes on a white background.
}
function overlay_color_from_integer(i:integer):overlay_pixel_type;

const
	num_predefined_colors=18;
	colors: array [0..num_predefined_colors-1] of overlay_pixel_type =
		(red_color,green_color,blue_color,
		orange_color,yellow_color,magenta_color,
		brown_color,salmon_color,sky_blue_color,
		black_color,gray_color,light_gray_color,
		dark_red_color,dark_green_color,dark_blue_color,
		dark_brown_color,vdark_green_color,vdark_blue_color);
	k=67;

var
	c:overlay_pixel_type;
	
begin
	if (i>=0) and (i<num_predefined_colors) then c:=colors[i]
	else c:= (i*k) mod white_color;
	overlay_color_from_integer:=c;
end;

{
	valid_image_ptr returns true iff ip^ is in the master image list.
}
function valid_image_ptr(ip:image_ptr_type):boolean;

var
	image_num:integer;
	valid:boolean;

begin
	valid:=false;
	if ip=nil then 
		valid:=false
	else begin
		for image_num:=0 to master_image_list_size-1 do
			if master_image_list[image_num]=ip then
				valid:=true;
	end;
	valid_image_ptr:=valid;
end;

{
	image_from_daq takes a block of data in the DAQ file format and
	creates a new image by reading the width, height and analysis bounds
	from the beginning of the file block. The image size, bounds, and name
	parameters return either as they were passed, if their values were
	uses, or changes to the values that image_from_daq decided upon. You
	must pass the size of the data block to image_from_daq so that, in
	case it deducesd large and invalid values for the image width and
	height, it constrains itself to copy only from the available image
	data.
}
function image_from_daq(data_ptr:pointer;data_size:integer;
	var width,height,left,top,right,bottom,try_header:integer;
	var results,name:CString):image_ptr_type;

var 
	ip:image_ptr_type=nil;
	ihp:image_header_ptr_type=nil;
	char_index,copy_size:integer;
	q:integer;
	s:short_string;

begin
	if data_ptr=nil then exit;
	if data_size<=0 then exit;
	
	ihp:=pointer(data_ptr);

	if (try_header<>0) then begin
		q:=local_from_big_endian_shortint(ihp^.j_max)+1;
		if (q>0) then height:=q;
		q:=local_from_big_endian_shortint(ihp^.i_max)+1;
		if (q>0) then width:=q;
	end;
	if (width<=0) or (height<=0) then begin
		width:=trunc(sqrt(data_size));
		if (sqr(width)<data_size) then width:=width+1;
		height:=width;
	end;

	if (width*height>data_size) then copy_size:=data_size
	else copy_size:=(width*height);

	ip:=new_image(height,width);
	if ip=nil then begin
		report_error('Failed to allocate memory for new image in '+CurrentRoutineName+'.');
		exit;
	end;

	block_move(data_ptr,@ip^.intensity,copy_size);

	if (try_header<>0) then begin
		q:=local_from_big_endian_shortint(ihp^.left);
		if (q>=0) then left:=q;
	end;
	if (left<0) or (left>=width) then left:=0;
	ip^.analysis_bounds.left:=left;
	
	if (try_header<>0) then begin
		q:=local_from_big_endian_shortint(ihp^.right);
		if (q>left) then right:=q;
	end;
	if (right<=left) or (right>=width) then right:=width-1;
	ip^.analysis_bounds.right:=right;

	if (try_header<>0) then begin
		q:=local_from_big_endian_shortint(ihp^.top);
		if (q>=0) then top:=q;
	end;
	if (top<1) or (top>=height) then top:=1;
	ip^.analysis_bounds.top:=top;
	
	if (try_header<>0) then begin
		q:=local_from_big_endian_shortint(ihp^.bottom);
		if (q>top) then bottom:=q;
	end;
	if (bottom<=top) or (bottom>=height) then bottom:=height-1;
	ip^.analysis_bounds.bottom:=bottom;
	
	if (try_header<>0) then begin
		ip^.results:='';
		char_index:=0;
		while (char_index<short_string_length) 
				and (ihp^.results[char_index]<>chr(0)) do begin
			ip^.results:=ip^.results+ihp^.results[char_index];
			inc(char_index);
		end;
		results:=ip^.results;
	end 
	else ip^.results:=short_string_from_c_string(results);
	
	s:=short_string_from_c_string(name);
	if s<>'' then begin
		if valid_image_name(s) then
			dispose_image(image_ptr_from_name(s));
		ip^.name:=s;
	end;

	image_from_daq:=ip;
end;

{
	daq_from_image does the opposite of image_from_daq. You must pass
	daq_from_image a pointer to a block of memory that is at least
	as large as ip^.width*ip^.height.
}
procedure daq_from_image(ip:image_ptr_type;data_ptr:pointer);

var
	ihp:image_header_ptr_type;
	char_index:integer;
	
begin
	if data_ptr=nil then exit;
	with ip^ do begin
		ihp:=pointer(@intensity);
		ihp^.i_max:=big_endian_from_local_shortint(i_size-1);
		ihp^.j_max:=big_endian_from_local_shortint(j_size-1);
		ihp^.left:=big_endian_from_local_shortint(analysis_bounds.left);
		ihp^.right:=big_endian_from_local_shortint(analysis_bounds.right);
		ihp^.top:=big_endian_from_local_shortint(analysis_bounds.top);
		ihp^.bottom:=big_endian_from_local_shortint(analysis_bounds.bottom);
		for char_index:=1 to length(results) do 
			ihp^.results[char_index-1]:=results[char_index];
		ihp^.results[length(results)]:=chr(0);
	end;
	block_move(data_ptr,@ip^.intensity,ip^.j_size*ip^.i_size);
end;

{
	read_daq_file reads an image in daq format out of a file and 
	returns a pointer to the image in memory. It calls image_from_daq to 
	convert the file contents into an image.
}
function read_daq_file(name:CString):image_ptr_type;

var
	b:byte_array_ptr;
	width,height,left,top,right,bottom:integer=0;
	try_header:integer=1;
	image_results,image_name:CString='';
	
begin
	b:=read_file(short_string_from_c_string(name));
	if b=nil then exit;
	read_daq_file:=image_from_daq(@b^[0],b^.size,
		width,height,left,top,right,bottom,
		try_header,
		image_results,image_name);
	dispose_byte_array(b);
end;

{
	write_daq_file writes an image to disk in daq format. It 
	calls daq_from_image to create the daq data block.
}
procedure write_daq_file(name:CString;ip:image_ptr_type);

var
	b:byte_array_ptr;
	
begin
	b:=new_byte_array(sizeof(ip^.intensity));
	if b=nil then begin
		report_error('Error allocating for byte array in '+CurrentRoutineName+'.');
		exit;
	end;
	daq_from_image(ip,@b^[0]);
	write_file(short_string_from_c_string(name),b);
	dispose_byte_array(b);
end;

{
	image_from_contents creates a new image with dimensions width 
	and height, fills the intensity array with the block of data
	pointed to by intensity_ptr, and fills the analysis bounds with
	left, top, right, and bottom. The routine returns an image pointer.
}
function image_from_contents(intensity_ptr:pointer;
	width,height,left,top,right,bottom:integer;
	results,name:CString):image_ptr_type;

var 
	i,j:integer;
	ip:image_ptr_type;

begin
	ip:=new_image(height,width);
	block_move(intensity_ptr,@ip^.intensity,ip^.j_size*ip^.i_size);
	ip^.analysis_bounds.left:=left;
	ip^.analysis_bounds.top:=top;
	ip^.analysis_bounds.right:=right;
	ip^.analysis_bounds.bottom:=bottom;
	ip^.results:=short_string_from_c_string(results);
	ip^.name:=short_string_from_c_string(name);
	image_from_contents:=ip;
end;

{
	contents_from_image does the opposite of image_from_contents.
	If you pass a nil pointer in intensity_prt, the routine will 
	not copy the image contents, but simply return the remaining 
	parameters.
}
procedure contents_from_image(ip:image_ptr_type;intensity_ptr:pointer;
	var width,height,left,top,right,bottom:integer;var results,name:CString);

var 
	i,j:integer;

begin
	if intensity_ptr<>nil then
		block_move(@ip^.intensity,intensity_ptr,ip^.j_size*ip^.i_size);
	left:=ip^.analysis_bounds.left;
	top:=ip^.analysis_bounds.top;
	right:=ip^.analysis_bounds.right;
	bottom:=ip^.analysis_bounds.bottom;
	results:=ip^.results;
	name:=ip^.name;
end;

{
	valid_image_name returns true iff an image with name s is in
	the image list.
}
function valid_image_name(s:short_string):boolean;

begin
	valid_image_name:=valid_image_ptr(image_ptr_from_name(s));
end;

{
	dispose_image disposes of an image and removes it from the master 
	image list.
}
procedure dispose_image(ip:image_ptr_type);

var
	image_num:integer;
	
begin
	if not valid_image_ptr(ip) then exit;
	image_num:=0;
	while (master_image_list[image_num]<>ip) do inc(image_num);
	master_image_list[image_num]:=nil;
	dec_num_outstanding_ptrs(sizeof(ip^),CurrentRoutineName);
	dispose(ip);
end;

{
	dispose_named_images disposes of any images in the image list
	whose name matches the key string. The key string can contain
	"*" for the string wild card, and "?" for the character wild
	card.
}
procedure dispose_named_images(key:short_string);
var image_num:integer;
begin
	for image_num:=0 to master_image_list_size-1 do
		if master_image_list[image_num]<>nil then
			if string_match(key,master_image_list[image_num]^.name) then
				dispose_image(master_image_list[image_num]);
end;

{
	image_ptr_from_name returns the last image with the specified name in the
	master image list.
}
function image_ptr_from_name(name:short_string):image_ptr_type;

var
	image_num:integer;
	ip:image_ptr_type;

begin
	ip:=nil;
	
	for image_num:=0 to master_image_list_size-1 do 
		if master_image_list[image_num]<>nil then
			if master_image_list[image_num]^.name=name then
				ip:=master_image_list[image_num];
	image_ptr_from_name:=ip;
end;

{
	valid_image_point returns true iff point p lies within the bounds of the
	intensity and overlay areas.
}
function valid_image_point(ip:image_ptr_type;p:ij_point_type):boolean;

begin
	valid_image_point:=
		(p.i>=0) and (p.i<ip^.i_size)
		and (p.j>=0) and (p.j<ip^.j_size);
end;

{
	valid_analysis_bounds checks for self-consistency within an image's 
	analysis bounds, and also checks that the analysis bounds are 
	contained entirely within the image.
}
function valid_analysis_bounds(ip:image_ptr_type):boolean;
begin
	with ip^.analysis_bounds,ip^ do begin
		if (left<0) or (left>i_size-1)
		or (right<0) or (right>i_size-1) 
		or (top<0) or (top>j_size-1)
		or (bottom<0) or (bottom>j_size-1)
		or (left>right) or (top>bottom) then 
			valid_analysis_bounds:=false
		else
			valid_analysis_bounds:=true;
	end;
end;

{
	valid_image_analysis_point returns true iff the point is in the analysis bounds.
}
function valid_image_analysis_point(point:ij_point_type;ip:image_ptr_type):boolean;	
begin 
	with point,ip^.analysis_bounds do
		valid_image_analysis_point:=
			(i>=left) and (i<=right) and (j>=top) and (j<=bottom);
end;

{
	image_maximum returns the maximum image intensity within the image analysis
	bounds.
}
function image_maximum(ip:image_ptr_type):real;
	
var
	i,j,maximum:integer;
	
begin 
	if not valid_image_ptr(ip) then begin
		image_maximum:=min_intensity;
		exit;
	end;

	maximum:=min_intensity;
	with ip^.analysis_bounds do
		for i:=left to right do
			for j:=top to bottom do 
				if ip^.intensity[j,i]>maximum then
					maximum:=ip^.intensity[j,i];
	image_maximum:=maximum;
end;

{
	image_minimum returns the minimum image intensity within the image analysis 
	bounds.
}
function image_minimum(ip:image_ptr_type):real;

var
	i,j,minimum:integer;
	
begin 
	if not valid_image_ptr(ip) then begin
		image_minimum:=max_intensity;
		exit;
	end;

	minimum:=max_intensity;
	with ip^.analysis_bounds do
		for i:=left to right do
			for j:=top to bottom do 
				if ip^.intensity[j,i]<minimum then
					minimum:=ip^.intensity[j,i];
	image_minimum:=minimum;
end;

{
	image_average samples num_points in the image and calculates the average
	image intensity from these points.
}
function image_average(ip:image_ptr_type):real;

const 
	num_points=10000;

var 
	counter,sum:integer;
	point:ij_point_type;

begin
	if not valid_image_ptr(ip) then begin
		image_average:=min_intensity;
		exit;
	end;

	sum:=0;
	for counter:=1 to num_points do begin
		point:=ij_random_point(ip^.analysis_bounds);
		sum:=sum+ip^.intensity[point.j,point.i];
	end;
	image_average:=sum/num_points;
end;

{
	image_amplitude samples num_points in the image and calculates the standard
	deviation of the intensity from these points.
}
function image_amplitude(ip:image_ptr_type):real;

const 
	num_points=10000;

var 
	counter:integer;
	mean,sum:real;
	point:ij_point_type;

begin
	if not valid_image_ptr(ip) then begin
		image_amplitude:=0;
		exit;
	end;

	mean:=image_average(ip);
	sum:=0;
	for counter:=1 to num_points do begin
		point:=ij_random_point(ip^.analysis_bounds);
		sum:=sum+sqr(ip^.intensity[point.j,point.i]-mean);
	end;
	image_amplitude:=sqrt(sum/num_points);
end;

{
	image_sum returns the total intensity of an image after subtracting 
	a threshold intensity.
}
function image_sum(ip:image_ptr_type; threshold:integer):integer;

var 
	i,j,sum,p:integer;
	
begin
	if not valid_image_ptr(ip) then begin
		image_sum:=0;
		exit;
	end;

	sum:=0;
	for j:=ip^.analysis_bounds.top to ip^.analysis_bounds.bottom do begin
		for i:=ip^.analysis_bounds.left to ip^.analysis_bounds.right do begin
			p:=ip^.intensity[j,i]-threshold;
			if p>0 then sum:=sum+p;
		end;
	end;
	image_sum:=sum;
end;

{
	draw_overlay_pixel colors a pixel from ij space into the image overlay,
	provided the pixel lies between the image analysis boundries in ij
	space.
}
procedure draw_overlay_pixel(ip:image_ptr_type;pixel:ij_point_type;
	color:overlay_pixel_type);
	
begin
	if not valid_image_ptr(ip) then exit;
	if not valid_analysis_bounds(ip) then exit;
	if not ij_in_rectangle(pixel,ip^.analysis_bounds) then exit;
	ip^.overlay[pixel.j,pixel.i]:=color;
end;

{
	draw_overlay_line draws a line in two-dimensional integer space onto the overlay
	of the specified image. The routine draws the line in the specified color, and
	clips it to the image analysis bounds.
}
procedure draw_overlay_line(ip:image_ptr_type;line:ij_line_type;
	color:overlay_pixel_type);
	
const
	rough_step_size=0.8;{pixels}
	
var
	num_steps,step_num:integer;
	p,q,step:xy_point_type;
	s:ij_point_type;
	outside:boolean;

begin
	if not valid_image_ptr(ip) then exit;
	if not valid_analysis_bounds(ip) then exit;
	ij_clip_line(line,outside,ip^.analysis_bounds);
	if outside then exit;
	if not ij_in_rectangle(line.a,ip^.analysis_bounds) then exit;
	if not ij_in_rectangle(line.b,ip^.analysis_bounds) then exit;
	
	with line,ip^ do begin
		overlay[a.j,a.i]:=color;
		overlay[b.j,b.i]:=color;
		p.x:=a.i;
		p.y:=a.j;
		q.x:=b.i;
		q.y:=b.j;
		s:=a;
	end;
	
	if xy_separation(p,q)<rough_step_size then num_steps:=0
	else num_steps:=round(xy_separation(p,q)/rough_step_size);
	step:=xy_scale(xy_difference(q,p),1/(num_steps+1));

	for step_num:=1 to num_steps do begin
		p:=xy_sum(p,step);
		if p.x-s.i>0.5 then inc(s.i)
		else if p.x-s.i<-0.5 then dec(s.i);
		if p.y-s.j>0.5 then inc(s.j)
		else if p.y-s.j<-0.5 then dec(s.j);
		ip^.overlay[s.j,s.i]:=color;
	end;
end;

{
	draw_overlay_rectangle draws a rectangle in two-dimensional integer space 
	onto the overlay of the specified image. The routine draws the rectangle in 
	the specified color, and clips it to the overlay boundries.
}
procedure draw_overlay_rectangle(ip:image_ptr_type;rect:ij_rectangle_type;
	color:overlay_pixel_type);
	
var
	line:ij_line_type;
	
begin
	if not valid_image_ptr(ip) then exit;
	with line,rect do begin
		a.i:=left;a.j:=top;b.i:=left;b.j:=bottom;
		draw_overlay_line(ip,line,color);
		a.i:=left;a.j:=bottom;b.i:=right;b.j:=bottom;
		draw_overlay_line(ip,line,color);
		a.i:=right;a.j:=bottom;b.i:=right;b.j:=top;
		draw_overlay_line(ip,line,color);
		a.i:=right;a.j:=top;b.i:=left;b.j:=top;
		draw_overlay_line(ip,line,color);
	end;
end;

{	
	draw_overlay_rectangle_ellipse draws an ellipse in the boundaries of a
	rectangle. This routine uses code we from Gerd Platl at the following web
	address:

	http://www.bsdg.org/SWAG/GRAPHICS/0276.PAS.html

	We provide our own PutPixel so we don't have to modify his code at all. This
	routine is efficient at drawing circles, which you obtain by passing a
	square as the boundary, with the center of the square at the center of the
	circle, and the width of the square equal to the diameter of the circle. For
	general-purpose ellipse drawing see draw_overlay_ellipse.
}
procedure draw_overlay_rectangle_ellipse(ip:image_ptr_type;rect:ij_rectangle_type;
	color:overlay_pixel_type);

	procedure PutPixel(x,y:integer;c:overlay_pixel_type);
	var
		p:ij_point_type;
	begin
		p.i:=x;
		p.j:=y;
		draw_overlay_pixel(ip,p,c);
	end;
	
{
	Variables used by Gerd's code.
}
var
	x,mx1,mx2,my1,my2:integer;
	aq,bq,dx,dy,r,rx,ry,mx,my,a,b:integer;
	c:integer;

begin
{
	Set up variables used by Gerd's code.
}
	with rect do begin
		mx:=round((right+left)/2);
		my:=round((top+bottom)/2);
		a:=round((right-left)/2);
		b:=round((bottom-top)/2);
	end;
{
	Start of Gerd's code.
}
  PutPixel (mx + a, my, color);
  PutPixel (mx - a, my, color);

  mx1 := mx - a;   my1 := my;
  mx2 := mx + a;   my2 := my;

  aq := longint (a) * a;        {calc sqr}
  bq := longint (b) * b;
  dx := aq shl 1;               {dx := 2 * a * a}
  dy := bq shl 1;               {dy := 2 * b * b}
  r  := a * bq;                 {r  := a * b * b}
  rx := r shl 1;                {rx := 2 * a * b * b}
  ry := 0;                      {because y = 0}
  x := a;

  while x > 0
  do begin
    if r > 0
    then begin                  { y + 1 }
      inc (my1);   dec (my2);
      inc (ry, dx);             {ry = dx * y}
      dec (r, ry);              {r = r - dx + y}
    end;
    if r <= 0
    then begin                  { x - 1 }
      dec (x);
      inc (mx1);   dec (mx2);
      dec (rx, dy);             {rx = dy * x}
      inc (r, rx);              {r = r + dy * x}
    end;
    PutPixel (mx1, my1, color);
    PutPixel (mx1, my2, color);
    PutPixel (mx2, my1, color);
    PutPixel (mx2, my2, color);
  end;
{
	End of Gerd's code.
}
end;

{
	draw_overlay_ellipse draws the border of an ij_ellipse_type on the screen. It 
	works by going through all the pixels in the analysis bounds of the image and
	finding those that are close to the edge of the ellipse. Of these, it marks 
	the points that are inside the ellipse, but which border on at least one pixel
	that is outside the ellipse. To get the routine to run faster, consider limiting
	the image analysis bounds to a rectangle that encloses the ellipse. On our 1.3 GHz
	G4 iBook, the routine took 16 ms to draw an ellipse that filled a rectangle 240
	pixels high and 100 pixels wide. We used the same rectangle as the boundary. 
	Compare that to 400 us for the same ellipse drawn to the borders of the rectangle
	by draw_overlay_rectangle_ellipse.
}
procedure draw_overlay_ellipse(ip:image_ptr_type;
	ellipse:ij_ellipse_type;color:overlay_pixel_type);

var
	separation,range:real;
	i,j:integer;
	p:ij_point_type;
	
	function on_border(p:ij_point_type):boolean;
	const
		border=2;
	var 
		i_min,i_max,j_min,j_max,i,j:integer;
		s:real;
		q:ij_point_type;
		on:boolean;
	begin
		on:=false;
		s:=ij_separation(p,ellipse.a)+ij_separation(p,ellipse.b);
		if (s<=ellipse.axis_length) and (s>=ellipse.axis_length-border) then begin
			with ip^.analysis_bounds do begin
				if p.i>left then i_min:=p.i-1 else on:=true;
				if p.i<right then i_max:=p.i+1 else on:=true;
				if p.j>top then j_min:=p.j-1 else on:=true;
				if p.j<bottom then j_max:=p.j+1 else on:=true;
			end;
			if not on then
				for q.i:=i_min to i_max do
					for q.j:=j_min to j_max do 
						with ellipse do 
							if ij_separation(q,a)+ij_separation(q,b)>axis_length then
								on:=true;
		end;
		on_border:=on;
	end;
	
begin
{
	Determine some properties of the ellipse.
}
	separation:=ij_separation(ellipse.a,ellipse.b);
{
	Check the eccentricity of the ellipse. The length of the major axis must be
	greater than or equal to the separation of the focal points.
}
	if (separation>ellipse.axis_length) then exit;
{
	Mark the pixels on the border.
}
	with ip^.analysis_bounds do
		for p.i:=left to right do
			for p.j:=top to bottom do
				if on_border(p) then 
					draw_overlay_pixel(ip,p,color);
end;

{
	embed_image_header encodes as much of the image header as possible in the
	first line of image pixels. It records j_size-1, i_size-1, top, left,
	bottom, and right as short integers with big-endian byte ordering. These six
	numbers take up twelve pixels. The remaining pixels of the first line are
	available for the null-terminated results string. If the results string is
	too long to fit in the first row, embed_image_header cuts it short with a
	null character.
}
procedure embed_image_header(ip:image_ptr_type);

const
	number_space=12;
	
var
	ihp:image_header_ptr_type;
	end_index,char_index:integer;
	
begin
	with ip^ do begin
		ihp:=pointer(@intensity);
		ihp^.i_max:=big_endian_from_local_shortint(i_size-1);
		ihp^.j_max:=big_endian_from_local_shortint(j_size-1);
		ihp^.left:=big_endian_from_local_shortint(analysis_bounds.left);
		ihp^.right:=big_endian_from_local_shortint(analysis_bounds.right);
		ihp^.top:=big_endian_from_local_shortint(analysis_bounds.top);
		ihp^.bottom:=big_endian_from_local_shortint(analysis_bounds.bottom);
		if j_size-number_space-1 > length(results) then
			end_index:=length(results)
		else
			end_index:=j_size-number_space-1;
		for char_index:=1 to end_index do 
			ihp^.results[char_index-1]:=results[char_index];
		ihp^.results[end_index]:=chr(0);
	end;
end;

{
	draw_image draws the specified image in the drawing space. If there
	is not enough room in the drawing space, draw_image allocates more
	space. To determine the colors in the drawing space from the colors in
	the image pixels, draw_image composes a color look-up table. To determine
	overlay colors from the colors in the image overlayk, draw_image composes
	another look-up table.
}
procedure draw_image(ip:image_ptr_type);

const
	mild_range=10;
	strong_range=4;

var
	l:ij_line_type;
	c_index,i,j,shade,gamma_corrected_shade:integer;
	allocate_drawing_space:boolean;
	image_offset,shade_offset,shade_scale,im:real;
	required_drawing_space:integer;
	d_ptr:^drawing_space_pixel_type;
	i_ptr:^intensity_pixel_type;
	o_ptr:^overlay_pixel_type;
	
begin
	if not valid_image_ptr(ip) then begin
		report_error('Found not valid_image_ptr(ip) in '+CurrentRoutineName+'.');
		exit;
	end;
	
	required_drawing_space:=
		ip^.i_size*ip^.j_size
		*sizeof(drawing_space_pixel_type)
		div sizeof(intensity_pixel_type);
	allocate_drawing_space:=false;
	if drawing_space_ptr=nil then allocate_drawing_space:=true
	else begin
		if drawing_space_ptr^.size<required_drawing_space then begin
			dec_num_outstanding_ptrs(sizeof(drawing_space_ptr^),CurrentRoutineName);
			dispose(drawing_space_ptr);
			allocate_drawing_space:=true;
		end;
	end;
	if allocate_drawing_space then begin
		new(drawing_space_ptr,required_drawing_space);
		inc_num_outstanding_ptrs(sizeof(drawing_space_ptr^),CurrentRoutineName);
	end;

	with ip^ do begin
		shade_scale:=1;
		shade_offset:=0;
		image_offset:=0;
		
		case intensification of
			mild_intensify:begin
				average:=image_average(ip);
				amplitude:=image_amplitude(ip);
				image_offset:=average;
				shade_offset:=mid_intensity;
				if (amplitude<>0) then 
					shade_scale:=(max_intensity/mild_range)/amplitude
				else shade_scale:=1;
			end;
			strong_intensify:begin
				average:=image_average(ip);
				amplitude:=image_amplitude(ip);
				image_offset:=average;
				shade_offset:=mid_intensity;
				if (amplitude<>0) then 
					shade_scale:=(max_intensity/strong_range)/amplitude
				else shade_scale:=1;
			end;
			exact_intensify:begin
				average:=image_average(ip);
				amplitude:=image_amplitude(ip);
				image_offset:=image_minimum(ip);
				shade_offset:=min_intensity;
				im:=image_maximum(ip);
				if (im-image_offset)<>0 then
					shade_scale:=(white_intensity-black_intensity)/
						(image_maximum(ip)-image_offset)
				else shade_scale:=1;
			end;
		end;
	end;

	for c_index:=min_intensity to max_intensity do begin
		with image_color_table_ptr^[c_index] do begin
			shade:=round(shade_scale*(c_index-image_offset)+shade_offset);
			if shade>white_intensity then shade:=white_intensity;
			if shade<black_intensity then shade:=black_intensity;
			
			gamma_corrected_shade:=round(
				xpy((shade-black_intensity)/(white_intensity-black_intensity),
					1/gamma_correction)
				* (white_intensity-black_intensity));

			red:=gamma_corrected_shade;
			green:=gamma_corrected_shade;
			blue:=gamma_corrected_shade;
			alpha:=opaque_alpha;
		end;
	end;
		
{$X+}
	d_ptr:=@drawing_space_ptr^[0];
	i_ptr:=@ip^.intensity[0,0];
	o_ptr:=@ip^.overlay[0,0];
	for j:=0 to ip^.j_size-1 do begin
		for i:=0 to ip^.i_size-1 do begin
			if o_ptr^=clear_color then d_ptr^:=image_color_table_ptr^[i_ptr^]
			else d_ptr^:=overlay_color_table_ptr^[o_ptr^];
			inc(d_ptr);
			inc(i_ptr);
			inc(o_ptr);
		end;
	end;
{$X-}

end;

{
	draw_rggb_image draws the specified image in the drawing space, assuming
	that its pixels are arranged as sets of four in a block with color filters
	over them like this:
	
	RG
	GB
	
	The routine performs intensification of color, and scales the red and blue
	with respect to the green using the global variables rggb_blue_scale
	and rggb_red_scale.
}
procedure draw_rggb_image(ip:image_ptr_type);

const
	mild_range=10;
	strong_range=4;
	num_rgb=3;

var
	l:ij_line_type;
	c_index,i,j,shade,gamma_corrected_shade:integer;
	allocate_drawing_space:boolean;
	image_offset,shade_offset,shade_scale,im:real;
	required_drawing_space:integer;
	d_ptr:^drawing_space_pixel_type;
	
begin
	if not valid_image_ptr(ip) then begin
		report_error('Found not valid_image_ptr(ip) in '+CurrentRoutineName+'.');
		exit;
	end;
	
	required_drawing_space:=
		ip^.i_size*ip^.j_size
		*sizeof(drawing_space_pixel_type)
		div sizeof(intensity_pixel_type);
	allocate_drawing_space:=false;
	if drawing_space_ptr=nil then allocate_drawing_space:=true
	else begin
		if drawing_space_ptr^.size<required_drawing_space then begin
			dec_num_outstanding_ptrs(sizeof(drawing_space_ptr^),CurrentRoutineName);
			dispose(drawing_space_ptr);
			allocate_drawing_space:=true;
		end;
	end;
	if allocate_drawing_space then begin
		new(drawing_space_ptr,required_drawing_space);
		inc_num_outstanding_ptrs(sizeof(drawing_space_ptr^),CurrentRoutineName);
	end;

	with ip^ do begin
		shade_scale:=1;
		shade_offset:=0;
		image_offset:=0;
		
		case intensification of
			mild_intensify:begin
				average:=image_average(ip);
				amplitude:=image_amplitude(ip);
				image_offset:=average;
				shade_offset:=mid_intensity;
				if (amplitude<>0) then 
					shade_scale:=(max_intensity/mild_range)/amplitude
				else shade_scale:=1;
			end;
			strong_intensify:begin
				average:=image_average(ip);
				amplitude:=image_amplitude(ip);
				image_offset:=average;
				shade_offset:=mid_intensity;
				if (amplitude<>0) then 
					shade_scale:=(max_intensity/strong_range)/amplitude
				else shade_scale:=1;
			end;
			exact_intensify:begin
				average:=image_average(ip);
				amplitude:=image_amplitude(ip);
				shade_offset:=min_intensity;
				image_offset:=image_minimum(ip);
				im:=image_maximum(ip);
				if (im-image_offset)>0 then
					shade_scale:=(white_intensity-black_intensity)/(im-image_offset)
				else shade_scale:=1;
			end;
		end;
	end;

	for c_index:=min_intensity to max_intensity do begin
		with image_color_table_ptr^[c_index] do begin
			shade:=round(shade_scale*(c_index-image_offset)+shade_offset);			
			if shade>white_intensity then shade:=white_intensity;
			if shade<black_intensity then shade:=black_intensity;
			gamma_corrected_shade:=round(
				xpy((shade-black_intensity)/(white_intensity-black_intensity),
					1/gamma_correction)
				* (white_intensity-black_intensity));

			shade:=round(gamma_corrected_shade*rggb_red_scale);
			if shade>white_intensity then shade:=white_intensity;
			if shade<black_intensity then shade:=black_intensity;
			red:=shade;

			green:=gamma_corrected_shade;

			shade:=round(gamma_corrected_shade*rggb_blue_scale);
			if shade>white_intensity then shade:=white_intensity;
			if shade<black_intensity then shade:=black_intensity;
			blue:=shade;

			alpha:=opaque_alpha;
		end;
	end;
		
{$X+}
{
	Here we calculate the color of each pixel using the red, blue, and green
	color intensities available in its own sensor pixel and the eight pixels
	around it. The sensor has its pixels with color filters arranged like this:
	
	column number      0 1 2 3 4 5 6 7...
	even-numbered row  R G R G R G R G...
	odd-numbered row   G B G B G B R G...
	even-numbered row  R G R G R G R G...
	odd-numbered row   G B G B G B R G...
	even-numbered row  R G R G R G R G...
	odd-numbered row   G B G B G B R G...
	
	For example, at a green pixel in an even-numbered row, we use the blue above
	and below to determine the blue intensity, and the red left and right for
	the red intensity.
}
	d_ptr:=@drawing_space_ptr^[0];
	for j:=1 to ip^.j_size-2 do begin
		inc(d_ptr);
		for i:=1 to ip^.i_size-2 do begin
			if ip^.overlay[j,i]=clear_color then begin
				if not odd(j) then begin
					if not odd(i) then begin
						{Red Pixels}
						d_ptr^.red:=image_color_table_ptr^[ip^.intensity[j,i]].red;
						d_ptr^.green:=image_color_table_ptr^[round(one_quarter*
							(ip^.intensity[j,i+1]
							+ip^.intensity[j,i-1]
							+ip^.intensity[j+1,i]
							+ip^.intensity[j-1,i]))].green;
						d_ptr^.blue:=image_color_table_ptr^[round(one_quarter*
							(ip^.intensity[j+1,i+1]
							+ip^.intensity[j+1,i-1]
							+ip^.intensity[j-1,i+1]
							+ip^.intensity[j-1,i-1]))].blue;
						d_ptr^.alpha:=opaque_alpha;
					end else begin
						{Green Pixels On Even-Numbered Rows}
						d_ptr^.red:=image_color_table_ptr^[round(one_half*
							(ip^.intensity[j,i+1]
							+ip^.intensity[j,i-1]))].red;
						d_ptr^.green:=image_color_table_ptr^[ip^.intensity[j,i]].green;
						d_ptr^.blue:=image_color_table_ptr^[round(one_half*
							(ip^.intensity[j+1,i]
							+ip^.intensity[j-1,i]))].blue;
						d_ptr^.alpha:=opaque_alpha;
					end;
				end else begin
					if not odd(i) then begin
						{Green Pixels On Odd-Numbered Rows}
						d_ptr^.red:=image_color_table_ptr^[round(one_half*
							(ip^.intensity[j+1,i]
							+ip^.intensity[j-1,i]))].red;
						d_ptr^.green:=image_color_table_ptr^[ip^.intensity[j,i]].green;
						d_ptr^.blue:=image_color_table_ptr^[round(one_half*
							(ip^.intensity[j,i+1]
							+ip^.intensity[j,i-1]))].blue;
						d_ptr^.alpha:=opaque_alpha;
					end else begin
						{Blue Pixels}
						d_ptr^.red:=image_color_table_ptr^[round(one_quarter*
							(ip^.intensity[j+1,i+1]
							+ip^.intensity[j+1,i-1]
							+ip^.intensity[j-1,i+1]
							+ip^.intensity[j-1,i-1]))].red;
						d_ptr^.green:=image_color_table_ptr^[round(one_quarter*
							(ip^.intensity[j,i+1]
							+ip^.intensity[j,i-1]
							+ip^.intensity[j+1,i]
							+ip^.intensity[j-1,i]))].green;
						d_ptr^.blue:=image_color_table_ptr^[ip^.intensity[j,i]].blue;
						d_ptr^.alpha:=opaque_alpha;
					end;
				end;
			end else d_ptr^:=overlay_color_table_ptr^[ip^.overlay[j,i]];
			inc(d_ptr);
		end;
		inc(d_ptr);
	end;
{$X-}
end;

{
	write_image_list appends a list of images with names matching the 
	key string to a string.
}
procedure write_image_list(var f:string;key:short_string;verbose:boolean);

const
	fsc=12;
	
var
	image_num,num_entries,list_size:cardinal;
	
begin
	image_num:=0;
	num_entries:=0;
	list_size:=0;
	if verbose then begin
		writestr(f,f,eol);
		writestr(f,f,'Master Image List (Sizes in Bytes)',eol);
		writestr(f,f,'	   Index	   Image	   Entry  Name',eol);
		for image_num:=0 to master_image_list_size-1 do begin
			if master_image_list[image_num]<>nil then begin
				if string_match(key,master_image_list[image_num]^.name) then begin
					inc(num_entries);
					writestr(f,f,
						image_num:fsc,
						sizeof(master_image_list[image_num]^.intensity):fsc,
						sizeof(master_image_list[image_num]^):fsc,'  ',
						master_image_list[image_num]^.name,eol);
					list_size:=list_size+sizeof(master_image_list[image_num]^);
				end;
			end;
		end;
		if num_entries=0 then writestr(f,f,'no image list entries match "',key,'".',eol);
		writestr(f,f,'Total size of listed images is ',list_size:1,' bytes.',eol);
		if drawing_space_ptr=nil then writestr(f,f,'No drawing space assigned.',eol)
		else writestr(f,f,'Drawing space is ',sizeof(drawing_space_ptr^),eol);
	end else begin
		for image_num:=0 to master_image_list_size-1 do begin
			if master_image_list[image_num]<>nil then begin
				if string_match(key,master_image_list[image_num]^.name) then begin
					writestr(f,f,master_image_list[image_num]^.name,' ');
				end;
			end;
		end;
	end;
end;

{
	initialization allocates space for drawing color tables, and fills the 
	overlay color table.
}
initialization 

var index:cardinal;

new(image_color_table_ptr,max_byte+1);
inc_num_outstanding_ptrs(sizeof(image_color_table_ptr^),CurrentRoutineName);

new(overlay_color_table_ptr,max_byte+1);
inc_num_outstanding_ptrs(sizeof(overlay_color_table_ptr^),CurrentRoutineName);

for index:=0 to max_byte-1 do begin
	with overlay_color_table_ptr^[index] do begin
		red:=round(max_byte * (index and red_mask) / red_mask);
		green:=round(max_byte * (index and green_mask) / green_mask);
		blue:=round(max_byte * (index and blue_mask) / blue_mask);
		alpha:=opaque_alpha;
	end;
end;
with overlay_color_table_ptr^[max_byte] do begin
	red:=max_byte;
	green:=max_byte;
	blue:=max_byte;
	alpha:=opaque_alpha;
end;

for index:=0 to master_image_list_size-1 do 
	master_image_list[index]:=nil;

{
	finalization disposes of global dynamic arrays.
}
finalization 

dec_num_outstanding_ptrs(sizeof(image_color_table_ptr^),CurrentRoutineName);
dispose(image_color_table_ptr);
dec_num_outstanding_ptrs(sizeof(overlay_color_table_ptr^),CurrentRoutineName);
dispose(overlay_color_table_ptr);
if drawing_space_ptr<>nil then begin
	dec_num_outstanding_ptrs(sizeof(drawing_space_ptr^),CurrentRoutineName);
	dispose(drawing_space_ptr);
end;

end.