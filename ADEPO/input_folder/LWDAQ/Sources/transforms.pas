{
Routines for Transforming Between Coordinate Systems
Copyright (C) 2004, 2007 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University

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

unit transforms;
{
	This unit contains routines to transform points, line, and
	rectangles between the three coordinate systems we use in image
	analysis. It also contains routines to transform display commands
	in these coordinate systems into drawing commands in an image
	overlay.

	CCD coordinates specify a pixel in an image. They are named after
	the type of image sensor we used for most of our cameras. The
	letters CCD stand for Charge-Coupled Device. Our CCD images are
	rectangular with square pixels. The pixels are arranged in rows
	and columns. We specify a pixel in the image with its column and
	row number. A ccd point has the form (i,j) where i is the column
	number and j is the row number. Pixel (0,0) is the top-left pixel.
	Column number increases from left to right and row number
	increases from top to bottom. CCD Coordinates are therefore
	left-handed. We use ij_point_type for points in CCD Coordinates.
	You will find ij_point_type defined in our utils unit.

	Image coordinates specify a point in an image. An image point has
	the form (x,y), where x and y are real numbers, x is horizontal
	distance from left to right and y is vertical distance from top to
	bottom. The units of both x and y are pixels. Image point (0,0) is
	at the top-left corner of the top-left pixel. Point (1,1) is the
	bottom-right corner of the top-left pixel, and also the top-left
	corner of the second pixel in the second row.

	We have constants ccd_origin_x and ccd_origin_y that define the
	location of the ccd coordinate origin in image coordinates. The
	center values declared below for these two constants place the ccd
	origin at image point (0.5,0.5).

	Pattern coordinates specify a point in a pattern superimposed on
	an image. Pattern points are of the form (x,y), where x and y are
	the real. We assume the pattern is periodic in two orthogonal
	directions. A chessboard rasnik mask is such a pattern, and so is
	a sequence of encoder stripes. The chessboard has a finite period
	in two directions, while the encoder stripes have a finite period
	in one direction and a large period in the other direction. The
	x-axis is parallel to one direction in the orthogonal pattern, and
	the y-axis is parallel to the other direction. Pattern coordinates
	are left-handed for better cooperation with ccd and image
	coordinates, both of which are left-handed.

	We define a pattern coordinate system with five numbers. These
	numbers represent a translation, rotation, and scaling in two
	directions between image coordinates and pattern coordinates. In
	pattern_type, the origin field gives the image coordinates of the 
	pattern coordinate origin. The pattern coordinate origin will have
	some significance in the pattern. It might represent the top-left
	corner of a chessboard square, or the center of a wire shadow. The
	rotation parameter gives the rotation of the pattern coordinates
	anticlockwise with respect to image coordinates. The
	pattern_x_width parameter gives the length of one period of the
	pattern along the pattern x-axis, as measured in image
	coordinates. Imagine the pattern x-axis inclined at a slight angle
	with respect to the image rows, and therefore to the image x-axis.
	A square in the pattern has one edge parallel to the pattern
	x-axis. The length of this edge, as measured in the image
	coordinates, is pattern_x_width. We have pattern_y_width as well,
	because a pattern can, in general, be rectangular in its geometry.

	If the point (0,0) in pattern coordinates marks the top-left
	corner of a square in a chessboard pattern, then point (1,0) marks
	the top-right corner of the same square, and the top-left corner
	of the square to its right. Here were defining right and left as
	+ve and -ve in the x-direction, and top and bottom as +ve and -ve
	in the y direction. Point (0,1) is the bottom-left corner of the
	same square, and the top-left corner of the square immediately
	below. Moving around through a chessboard pattern is easy in
	pattern coordinates, because we simply add one to our x-coordinate
	to move to the square on the right, and add one to our
	y-coordinate to move to the square below.

	The pattern_type is the basis of any record used with the pattern
	coordinate tranform routines defined in this unit. But the
	pattern_type is not public. All transform routines refer to
	patterns through generic pointers. When another unit declares its
	own pattern record for use with the routines declared in this
	unit, the new record must begin with the same fields as
	pattern_type, so these fields may be referred to through a pointer
	as if the new record were a genuine pattern_type. See
	rasnik_pattern_type in rasnik.pas for an example of such a pattern
	type.
}

interface

uses 
	utils,images;{by KSH}

const {for ccd coordinates}	
	ccd_origin_x=0.5;{pixels}
	ccd_origin_y=0.5;{pixels}

{geometry transformations}
function i_from_c(point:ij_point_type):xy_point_type;
function c_from_i(point:xy_point_type):ij_point_type;
function p_from_i(point:xy_point_type;pattern_ptr:pointer):xy_point_type;
function i_from_p(point:xy_point_type;pattern_ptr:pointer):xy_point_type;
function c_from_i_line(line:xy_line_type):ij_line_type;
function i_from_p_line(line:xy_line_type;pattern_ptr:pointer):xy_line_type;
function i_from_c_line(line:ij_line_type):xy_line_type;
function p_from_i_line(line:xy_line_type;pattern_ptr:pointer):xy_line_type;
function i_from_c_rectangle(rect:ij_rectangle_type):xy_rectangle_type;
function c_from_i_rectangle(rect:xy_rectangle_type):ij_rectangle_type;
function i_from_c_ellipse(ellipse:ij_ellipse_type):xy_ellipse_type;
function c_from_i_ellipse(ellipse:xy_ellipse_type):ij_ellipse_type;

{display transformations}
procedure display_ccd_cross(ip:image_ptr_type;
	cross_point:ij_point_type;color:overlay_pixel_type);
procedure display_ccd_line(ip:image_ptr_type;line:ij_line_type;color:integer);
procedure display_ccd_pixel(ip:image_ptr_type;pixel:ij_point_type;color:integer);
procedure display_ccd_rectangle(ip:image_ptr_type;rect:ij_rectangle_type;color:integer);
procedure display_ccd_rectangle_cross(ip:image_ptr_type;
	rect:ij_rectangle_type;color:integer);
procedure display_ccd_rectangle_ellipse(ip:image_ptr_type;
	rect:ij_rectangle_type;color:integer);
procedure display_ccd_ellipse(ip:image_ptr_type;
	ellipse:ij_ellipse_type;color:integer);
procedure display_profile_row(ip:image_ptr_type;profile_ptr:x_graph_ptr_type;color:integer);
procedure display_profile_column(ip:image_ptr_type;profile_ptr:x_graph_ptr_type;
	color:integer);
procedure display_real_graph(ip:image_ptr_type;graph_ptr:xy_graph_ptr_type;
	color:integer;x_min,x_max,y_min,y_max,x_div,y_div:real);

implementation
 
type {for pattern coordinates}
	pattern_type=record
		valid:boolean;{valid pattern}
		padding:array [1..7] of byte; {force origin field to eight-byte boundary}
		origin:xy_point_type; {pattern coordinate origin in image coordinates}
		rotation:real; {radians}
		pattern_x_width:real; {scaling factor going from pattern x to image}
		pattern_y_width:real; {scaling factor going from pattern y to image}
	end;
	pattern_ptr_type=^pattern_type;

{
	i_from_c converts ccd coordinates to image coordinates.
}
function i_from_c(point:ij_point_type):xy_point_type;
var p:xy_point_type;
begin
	with point,p do begin
		x:=i+ccd_origin_x;
		y:=j+ccd_origin_y;
	end;
	i_from_c:=p;
end;

{
	c_from_i converts image coordinates to ccd coordinates.
}
function c_from_i(point:xy_point_type):ij_point_type;
const max=30000; min=-30000;
var q:real;p:ij_point_type;
begin 
	q:=point.x-ccd_origin_x;
	if q>max then q:=max;
	if q<min then q:=min;
	p.i:=round(q);

	q:=point.y-ccd_origin_y;
	if q>max then q:=max;
	if q<min then q:=min;
	p.j:=round(q);
	
	c_from_i:=p;
end;

{
	p_from_i converts image coordinates to pattern coordinates.
}
function p_from_i(point:xy_point_type;pattern_ptr:pointer):xy_point_type;
var p:pattern_ptr_type;q:xy_point_type;c,s:real;
begin
	p:=pattern_ptr_type(pattern_ptr);
	with p^ do begin
		c:=cos(rotation);
		s:=sin(rotation);
		q.x:=(point.x-origin.x)*c - (point.y-origin.y)*s;
		q.y:=(point.x-origin.x)*s + (point.y-origin.y)*c;
		q.x:=q.x/pattern_x_width;
		q.y:=q.y/pattern_y_width;
	end;
	p_from_i:=q;
end;

{
	i_from_p converts pattern coordinates to image coordinates.
}
function i_from_p(point:xy_point_type;pattern_ptr:pointer):xy_point_type;
var p:pattern_ptr_type;q:xy_point_type;c,s:real;
begin
	p:=pattern_ptr_type(pattern_ptr);
	with p^ do begin
		c:=cos(rotation);
		s:=sin(rotation);
		point.x:=point.x*pattern_x_width;
		point.y:=point.y*pattern_y_width;
		q.x:=  point.x*c + point.y*s + origin.x;
		q.y:= -point.x*s + point.y*c + origin.y;
	end;
	i_from_p:=q;
end;

{
	c_from_i_line converts a line in image coordinates into a line in 
	ccd coordinates.
}
function c_from_i_line(line:xy_line_type):ij_line_type;
var new_line:ij_line_type;
begin
	new_line.a:=c_from_i(line.a);
	new_line.b:=c_from_i(line.b);
	c_from_i_line:=new_line;
end;

{
	i_from_p_line converts a line in pattern coordinates into a line in
	image coordinates.
}
function i_from_p_line(line:xy_line_type;pattern_ptr:pointer):xy_line_type;
var new_line:xy_line_type;
begin
	new_line.a:=i_from_p(line.a,pattern_ptr);
	new_line.b:=i_from_p(line.b,pattern_ptr);
	i_from_p_line:=new_line;
end;

{
	i_from_c_line convertes a line in ccd coordinats into a line in
	image coordinates.
}
function i_from_c_line(line:ij_line_type):xy_line_type;
var new_line:xy_line_type;
begin
	new_line.a:=i_from_c(line.a);
	new_line.b:=i_from_c(line.b);
	i_from_c_line:=new_line;
end;

{
	p_from_i_line converts a line in image coordinates into a line in
	pattern coordinates.
}
function p_from_i_line(line:xy_line_type;pattern_ptr:pointer):xy_line_type;
var new_line:xy_line_type;
begin
	new_line.a:=p_from_i(line.a,pattern_ptr);
	new_line.b:=p_from_i(line.b,pattern_ptr);
	p_from_i_line:=new_line;
end;

{
	i_from_c_rectangle transforms a ccd coordinate rectangle
	into an image coordinate rectangle. 
}
function i_from_c_rectangle(rect:ij_rectangle_type):xy_rectangle_type;
var
	new_tl,new_br:xy_point_type;
	old_tl,old_br:ij_point_type;
	new_rect:xy_rectangle_type;	
begin 
	with rect do begin
		old_tl.i:=left;old_tl.j:=top;
		new_tl:=i_from_c(old_tl);
		old_br.i:=right;old_br.j:=bottom;
		new_br:=i_from_c(old_br);
	end;
	with new_rect do begin
		if new_tl.x<new_br.x then begin
			left:=new_tl.x;right:=new_br.x;
		end else begin
			left:=new_br.x;right:=new_tl.x;
		end;
		if new_tl.y<new_br.y then begin 
			top:=new_tl.y;bottom:=new_br.y;
		end else begin 
			top:=new_br.y;bottom:=new_tl.y; 
		end;
	end;
	i_from_c_rectangle:=new_rect;
end; 

{
	c_from_i_rectangle transforms an image coordinate rectangle
	into a ccd_rectangle.
}
function c_from_i_rectangle(rect:xy_rectangle_type):ij_rectangle_type;
var
	new_tl,new_br:ij_point_type;
	old_tl,old_br:xy_point_type;
	new_rect:ij_rectangle_type;
begin 
	with rect do begin
		old_tl.x:=left;old_tl.y:=top;
		new_tl:=c_from_i(old_tl);
		old_br.x:=right;old_br.y:=bottom;
		new_br:=c_from_i(old_br);
	end;
	with new_rect do begin
		if new_tl.i<new_br.i then begin
			left:=new_tl.i;right:=new_br.i;
		end else begin
			right:=new_tl.i;left:=new_br.i;
		end;
		if new_tl.j<new_br.j then begin
			top:=new_tl.j;bottom:=new_br.j;
		end else begin
			bottom:=new_tl.j;top:=new_br.j;
		end;
	end;
	c_from_i_rectangle:=new_rect;
end; 

{
	i_from_c_ellipse transforms a ccd coordinate ellipse into an image
	coordinate ellipse.
}
function i_from_c_ellipse(ellipse:ij_ellipse_type):xy_ellipse_type;
var
	e:xy_ellipse_type;
begin
	e.a:=i_from_c(ellipse.a);
	e.b:=i_from_c(ellipse.b);
	e.axis_length:=ellipse.axis_length;
	i_from_c_ellipse:=e;
end;

{
	c_from_i_ellipse transforms an image coordinate ellipse into a
	ccd coordinate ellipse. This transformation loses information:
	we round real values to integer values.
}
function c_from_i_ellipse(ellipse:xy_ellipse_type):ij_ellipse_type;
var
	e:ij_ellipse_type;
begin
	e.a:=c_from_i(ellipse.a);
	e.b:=c_from_i(ellipse.b);
	e.axis_length:=ellipse.axis_length;
	c_from_i_ellipse:=e;
end;

{
}
procedure display_ccd_pixel(ip:image_ptr_type;pixel:ij_point_type;color:integer);
begin
	draw_overlay_pixel(ip,pixel,overlay_pixel_type(color));
end;

{
}
procedure display_ccd_line(ip:image_ptr_type;line:ij_line_type;color:integer);
begin
	draw_overlay_line(ip,line,overlay_pixel_type(color));
end;

{
}
procedure display_ccd_rectangle(ip:image_ptr_type;rect:ij_rectangle_type;color:integer);
begin
	draw_overlay_rectangle(ip,rect,overlay_pixel_type(color));
end;

{
	display_ccd_rectangle_ellipse draws an ellips in a rectangulare bondary, bringing the 
	ellipse up to the top, bottom, left, and right edges. The ellipse axes are vertical
	and horizontal.
}
procedure display_ccd_rectangle_ellipse(ip:image_ptr_type;
	rect:ij_rectangle_type;color:integer);
begin
	draw_overlay_rectangle_ellipse(ip,rect,overlay_pixel_type(color));
end;

{
}
procedure display_ccd_ellipse(ip:image_ptr_type;
	ellipse:ij_ellipse_type;color:integer);
begin
	draw_overlay_ellipse(ip,ellipse,overlay_pixel_type(color));
end;

{
	display_ccd_rectangle_cross draws a cross centered on the specified rectangle and
	clipped to the rectangle. It does not display the rectangle itself. If you want 
	the rectangle as well, call display_ccd_rectangle.
}
procedure display_ccd_rectangle_cross(ip:image_ptr_type;
	rect:ij_rectangle_type;color:integer);

var 
	vertical_line,horizontal_line:ij_line_type;

begin
	if not valid_image_ptr(ip) then exit;
	with vertical_line,rect do begin
		a.i:=round((right+left)*one_half);
		a.j:=top;
		b.i:=a.i;
		b.j:=bottom;
	end;
	with horizontal_line,rect do begin
		a.i:=left;
		a.j:=round((top+bottom)*one_half);
		b.i:=right;
		b.j:=a.j;
	end;
	display_ccd_line(ip,vertical_line,color);
	display_ccd_line(ip,horizontal_line,color);
end;

{
	display_ccd_rectangle_cross draws a cross centered on the specified
	ccd point. The lines of the cross extend to the borders of the 
	image anslysis bounds.
}
procedure display_ccd_cross(ip:image_ptr_type;
	cross_point:ij_point_type;color:overlay_pixel_type);
	
var 
	vertical_line,horizontal_line:ij_line_type;
	
begin
	if not valid_image_ptr(ip) then exit;
	with vertical_line,ip^.analysis_bounds do begin
		a.i:=cross_point.i;
		a.j:=top;
		b.i:=a.i;
		b.j:=bottom;
	end;
	with horizontal_line,ip^.analysis_bounds do begin
		a.i:=left;
		a.j:=cross_point.j;
		b.i:=right;
		b.j:=a.j;
	end;
	display_ccd_line(ip,vertical_line,color);
	display_ccd_line(ip,horizontal_line,color);
end;

{
	display_real_graph uses the image anslysis boudaries as the space in which to plot a
	graph of xy_point_type data. You specify the range of the plot with x_min, x_max, y_min,
	and y_max. If you specify 0 for both x_min and x_max, display_real_graph will use
	the minimum and maximum valies of x in the xy_graph_type. It does the same in in the
	y-direction with y_min and y_max. Postive y in the graph will appear as upwards
	in the image, and positive x will be rightwards.
}
procedure display_real_graph(ip:image_ptr_type;graph_ptr:xy_graph_ptr_type;
	color:integer;x_min,x_max,y_min,y_max,x_div,y_div:real);

const
	min_divs=2;
	div_color=light_gray_color;
	
var
	index:integer;
	line:ij_line_type;
	x,y,xx,yy:real;

begin
	if not valid_image_ptr(ip) then exit;
	if graph_ptr=nil then exit;
	
	if (x_min=0) and (x_max=0) then begin
		with graph_ptr^[0] do begin
			x_min:=x;
			x_max:=x;
		end;		
		for index:=1 to graph_ptr^.num_points-1 do begin
			with graph_ptr^[index] do begin
				if x_max<x then x_max:=x;
				if x_min>x then x_min:=x;
			end;
		end;
	end;
	
	if x_min>=x_max then begin
		report_error('x_min>=x_max in '+CurrentRoutineName+'.');
		exit;
	end;
	
	if (y_min=0) and (y_max=0) then begin
		with graph_ptr^[0] do begin
			y_min:=y;
			y_max:=y;
		end;		
		for index:=1 to graph_ptr^.num_points-1 do begin
			with graph_ptr^[index] do begin
				if y_max<y then y_max:=y;
				if y_min>y then y_min:=y;
			end;
		end;
	end;
	
	if y_min>=y_max then begin
		report_error('y_min>=y_max in '+CurrentRoutineName+'.');
		exit;
	end;
	
	with ip^.analysis_bounds,line do begin
		if (x_div>0) then begin
			if ((x_max-x_min)/x_div > min_divs) then begin
				x:=x_min;
				a.j:=top; 
				b.j:=bottom;
				while (x<x_max) do begin
					a.i:=left+round((x-x_min)*(right-left)/(x_max-x_min));
					b.i:=a.i;
					display_ccd_line(ip,line,div_color);
					x:=x+x_div;
				end;
			end;
		end;
		if (y_div>0) then begin
			if ((y_max-y_min)/y_div > min_divs) then begin
				y:=y_min;
				a.i:=left; 
				b.i:=right;
				while (y<y_max) do begin
					a.j:=bottom-round((y-y_min)*(bottom-top)/(y_max-y_min));
					b.j:=a.j;
					display_ccd_line(ip,line,div_color);
					y:=y+y_div;
				end;
			end;
		end;
	end;
	
	for index:=0 to graph_ptr^.num_points-1 do begin
		with ip^.analysis_bounds,line,graph_ptr^[index] do begin
			xx:=left+(x-x_min)*(right-left)/(x_max-x_min);
			yy:=bottom-(y-y_min)*(bottom-top)/(y_max-y_min);
			if (abs(xx)<max_integer) and (abs(yy)<max_integer) then begin
				b.i:=round(xx);
				b.j:=round(yy);
			end else begin
				if xx>max_integer then b.i:=max_integer
				else if xx<-max_integer then b.i:=-max_integer
				else b.i:=round(xx);
				if yy>max_integer then b.j:=max_integer
				else if yy<-max_integer then b.j:=-max_integer
				else b.j:=round(yy);
			end;
			if index=0 then a:=b;
			display_ccd_line(ip,line,color);
			a:=b;
		end;
	end;
end;

{
	display_profile_row takes an instensity-profile and plots it in the overlay. The
	intensity-profile must be presented as a sequence of real values in an x_graph_type.
	The size of the x_graph_type must be exactly equal to the number of columns from 
	left to right in the image's analysis bounds. If the x_graph_type represents some
	property of the image as we move from left to right, its values will be displayed
	so that they coincide with the image features that gave rise to them. The simplest
	row profile is the sum of the intensities of each column in the analysis bounds.
	Larger row-values are higher up in the image. Look from the bottom of the image for
	a standard x-y graph.
}
procedure display_profile_row(ip:image_ptr_type;profile_ptr:x_graph_ptr_type;color:integer);

var
	graph_ptr:xy_graph_ptr_type;
	index:integer;
	r:real;
	
begin
	if not valid_image_ptr(ip) then exit;
	if profile_ptr=nil then exit;
	with profile_ptr^,ip^.analysis_bounds do begin
		if num_points<>(right-left+1) then begin
			report_error('Found num_points<>(right-left+1) in '+CurrentRoutineName+'.');
			exit;
		end;
	end;

	graph_ptr:=new_xy_graph(profile_ptr^.num_points);

	for index:=0 to graph_ptr^.num_points-1 do begin
		with graph_ptr^[index] do begin
			x:=index;
			y:=profile_ptr^[index];
		end;
	end;

	display_real_graph(ip,graph_ptr,color,0,0,0,0,0,0);
	
	dispose_xy_graph(graph_ptr);
end;

{
	display_profile_column is like display_profile_row, but in the vertical direction.
	Larger column values are farther to the left in the image. Look from the right
	side of the image for a standard x-y graph.
}
procedure display_profile_column(ip:image_ptr_type;profile_ptr:x_graph_ptr_type;
	color:integer);

var
	graph_ptr:xy_graph_ptr_type;
	index:integer;
	
begin
	if not valid_image_ptr(ip) then exit;
	if profile_ptr=nil then exit;
	with profile_ptr^,ip^.analysis_bounds do begin
		if num_points<>(bottom-top+1) then begin
			report_error('Found num_points<>(bottom-top+1) in '+CurrentRoutineName+'.');
			exit;
		end;
	end;
	
	
	graph_ptr:=new_xy_graph(profile_ptr^.num_points);
	
	for index:=0 to graph_ptr^.num_points-1 do begin
		with graph_ptr^[index] do begin
			y:=ip^.analysis_bounds.bottom-index;
			x:=-profile_ptr^[index];
		end;
	end;
	
	display_real_graph(ip,graph_ptr,color,0,0,0,0,0,0);
	
	dispose_xy_graph(graph_ptr);
end;

end.