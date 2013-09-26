{
Utilities for WPS Device Calibration and Measurement Transformation
Copyright (C) 2008-2009 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University

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

unit wps;
{
}
interface

uses
	utils,bcam;
	
const
	wps_sensor_x=bcam_tc255_center_x;
	wps_sensor_y=bcam_tc255_center_y;
	
type
{
	wps_camera_type gives the pivot point coordinates, the coordinates of the
	center of the ccd, and the rotation about x, y, and z of the ccd. All
	coordinates are in wps coordinates, which are defined with respect to the
	wps mounting balls in the same way we define bcam coordinates with respect
	to bcam mounting balls. Rotation (0, 0, 0) is when the ccd is in a z-y wps
	plane, with the image sensor x-axis parallel to the wps y-axis and the image
	sensor y-axis is parallel and opposite to the wps z-axis.
}
	wps_camera_type=record
		pivot:xyz_point_type;{wps coordinates of pivot point (mm)}
		sensor:xyz_point_type;{wps coordinates of ccd center}
		rot:xyz_point_type;{rotation of ccd about x, y, z in rad}
		id:short_string;{identifier}
	end;
{
	wps_wire_type describes a wire in space.
}
	wps_wire_type=record
		position:xyz_point_type;{where the center-line crosses the measurement plane}
		direction:xyz_point_type;{direction cosines of center-line direction}
		radius:real;{radius of wire}
	end;
{
	wps_edge_type describes an edge line on the ccd;
}
	wps_edge_type=record
		position:xy_point_type;{of a point in the edge line, in image coordinates, mm}
		rotation:real;{of the edge line, anticlockwise positive in image, radians}
		side:integer;{0 for wire center, +1 for left edges, -1 for right edges, as seen in image}
	end;
	
function wps_ray(p:xy_point_type;camera:wps_camera_type):xyz_line_type;
function wps_wire_plane(p:xy_point_type;r:real;camera:wps_camera_type):xyz_plane_type;
function wps_wire(p_1,p_2:xy_point_type;r_1,r_2:real;c_1,c_2:wps_camera_type):xyz_line_type;
function wps_coordinates_from_mount(mount:kinematic_mount_type):coordinates_type;
function wps_from_image_point(p:xy_point_type;camera:wps_camera_type):xyz_point_type;
function image_from_wps_point(p:xyz_point_type;camera:wps_camera_type):xy_point_type;
function wps_from_global_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function wps_from_global_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function wps_from_global_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;
function wps_from_global_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;
function global_from_wps_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function global_from_wps_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function global_from_wps_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;
function global_from_wps_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;
function nominal_wps_camera(code:integer):wps_camera_type;
function read_wps_camera(var f:string):wps_camera_type;
function wps_camera_from_string(s:short_string):wps_camera_type;
function string_from_wps_camera(camera:wps_camera_type):short_string;
function wps_ray_error(image:xy_point_type;edge_direction:integer;
	wire:wps_wire_type;camera:wps_camera_type):xyz_point_type;
function wps_error(p_1,p_2:xy_point_type;r_1,r_2:real;c_1,c_2:wps_camera_type;
	wire:xyz_line_type;
	z_ref:real):xyz_point_type;


implementation

const
	n=3;{three-dimensional space}

{
	read_wps_camera reads a camera type from a string.
}
function read_wps_camera(var f:string):wps_camera_type;

var 
	i:integer;
	camera:wps_camera_type;

begin
	with camera do begin
		id:=read_word(f);
		pivot:=read_xyz(f);
		sensor:=read_xyz(f);
		rot:=read_xyz(f);
		with rot do begin
			x:=x/mrad_per_rad;
			y:=y/mrad_per_rad;
			z:=z/mrad_per_rad;
		end;
	end;
	read_wps_camera:=camera;
end;

{
	wps_camera_from_string converts a string into a wps_camera_type;
}
function wps_camera_from_string(s:short_string):wps_camera_type;
begin
	wps_camera_from_string:=read_wps_camera(s);
end;

{
	string_from_wps_camera appends a camera type to a string, using only one line.
}
function string_from_wps_camera(camera:wps_camera_type):short_string;
	
const 
	fsr=1;fsd=4;fsdr=3;fss=4;

var 
	f:short_string='';

begin
	with camera do begin
		writestr(f,f,id,' ');
		with pivot do 
			writestr(f,f,x:fsr:fsd,' ',y:fsr:fsd,' ',z:fsr:fsd,' ');
		with sensor do 
			writestr(f,f,x:fsr:fsd,' ',y:fsr:fsd,' ',z:fsr:fsd,' ');
		with rot do 
			writestr(f,f,x*mrad_per_rad:fsr:fsdr,' ',
				y*mrad_per_rad:fsr:fsdr,' ',
				z*mrad_per_rad:fsr:fsdr);
	end;
	string_from_wps_camera:=f;
end;


{
	wps_origin returns the origin of the wps coordinates for the specified mounting balls.
}
function wps_origin(mount:kinematic_mount_type):xyz_point_type;

begin
	wps_origin:=mount.cone;
end;

{
	wps_coordinates_from_mount takes the global coordinates of the wps
	mounting balls and calculates the origin and axis unit vectors of the wps
	coordinate system expressed in global coordinates. We define wps coordinates
	in the same way as bcam coordinates, so we just call the bcam routine that
	generates these coordinates, and use its result.
}
function wps_coordinates_from_mount(mount:kinematic_mount_type):coordinates_type;
	
begin
	wps_coordinates_from_mount:=bcam_coordinates_from_mount(mount);
end;

{
	wps_from_global_vector converts a direction in global coordinates into a 
	direction in wps coordinates.
}
function wps_from_global_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;

var
	M:xyz_matrix_type;
	wps:coordinates_type;
	
begin
	wps:=wps_coordinates_from_mount(mount);
	M:=xyz_matrix_from_points(wps.x_axis,wps.y_axis,wps.z_axis);
	wps_from_global_vector:=xyz_transform(M,p);
end;


{
	wps_from_global_point converts a point in global coordinates into a point
	in wps coordinates.
}
function wps_from_global_point (p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;

begin
	wps_from_global_point:=wps_from_global_vector(xyz_difference(p,wps_origin(mount)),mount);
end;

{
	global_from_wps_vector converts a direction in wps coordinates into a 
	direction in global coordinates.
}
function global_from_wps_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
var bc:coordinates_type;	
begin
	bc:=wps_coordinates_from_mount(mount);
	global_from_wps_vector:=
		xyz_transform(
			xyz_matrix_inverse(
				xyz_matrix_from_points(bc.x_axis,bc.y_axis,bc.z_axis)),
			p);
end;

{
	global_from_wps_point converts a point in wps coordinates into a point
	in global coordinates.
}
function global_from_wps_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;

begin
	global_from_wps_point:=xyz_sum(wps_origin(mount),global_from_wps_vector(p,mount));
end;

{
	global_from_wps_line converts a bearing (point and direction) in wps coordinates into
	a bearing in global coordinates.
}
function global_from_wps_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;

var
	gb:xyz_line_type;
	
begin
	gb.point:=global_from_wps_point(b.point,mount);
	gb.direction:=global_from_wps_vector(b.direction,mount);
	global_from_wps_line:=gb;
end;

{
	wps_from_global_line does the opposite of global_from_wps_line
}
function wps_from_global_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;

var
	bb:xyz_line_type;
	
begin
	bb.point:=wps_from_global_point(b.point,mount);
	bb.direction:=wps_from_global_vector(b.direction,mount);
	wps_from_global_line:=bb;
end;

{
	global_from_wps_plane converts a bearing (point and direction) in wps coordinates into
	a bearing in global coordinates.
}
function global_from_wps_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;

var
	gp:xyz_plane_type;
	
begin
	gp.point:=global_from_wps_point(p.point,mount);
	gp.normal:=global_from_wps_vector(p.normal,mount);
	global_from_wps_plane:=gp;
end;

{
	wps_from_global_plane does the opposite of global_from_wps_plane
}
function wps_from_global_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;

var
	bp:xyz_plane_type;
	
begin
	bp.point:=wps_from_global_point(p.point,mount);
	bp.normal:=wps_from_global_vector(p.normal,mount);
	wps_from_global_plane:=bp;
end;

{
	wps_from_image_point converts a point on the ccd into a point in wps coordinates. 
	The calculation takes account of the orientation of the ccd in the camera.
}
function wps_from_image_point(p:xy_point_type;camera:wps_camera_type):xyz_point_type;

var
	q:xyz_point_type;
	
begin
	q.x:=0;
	q.y:=p.y-wps_sensor_y;
	q.z:=-(p.x-wps_sensor_x);
	q:=xyz_rotate(q,camera.rot);
	q:=xyz_sum(q,camera.sensor);
	wps_from_image_point:=q;
end;

{
	image_from_wps_point converts a point on in wps coordinates into a point in
	image coordinates. We make a line out of the point and the wps pivot, and 
	intersect this line with the image plane to obtain the point on the image
	plane that marks the image of the wps point.
}
function image_from_wps_point(p:xyz_point_type;camera:wps_camera_type):xy_point_type;

var
	plane:xyz_plane_type;
	ray:xyz_line_type;
	normal_point,q:xyz_point_type;
	r:xy_point_type;
	
begin
	r.x:=wps_sensor_x;
	r.y:=wps_sensor_y;
	plane.point:=wps_from_image_point(r,camera);
	with normal_point do begin x:=1; y:=0; z:=0; end;
	normal_point:=xyz_rotate(normal_point,camera.rot);
	normal_point:=xyz_sum(normal_point,camera.sensor);
	plane.normal:=xyz_difference(normal_point,plane.point);
	ray.point:=camera.pivot;
	ray.direction:=xyz_difference(p,camera.pivot);
	q:=xyz_line_plane_intersection(ray,plane);
	q:=xyz_difference(q,camera.sensor);
	q:=xyz_unrotate(q,camera.rot);
	r.x:=wps_sensor_x-q.z;
	r.y:=wps_sensor_y+q.y;
	image_from_wps_point:=r;
end;

{
	wps_ray returns the ray that passes through the camera pivot point
	and strikes the ccd at a point in the ccd. We specify a point in
	the ccd with parameter "p", which is given in image coordinates. 
	We specify the camera calibration constants with the "camera" parameter. 
	The routine gives the ray with the pivot point and a vector 
	parallel to the ray.
}
function wps_ray(p:xy_point_type;camera:wps_camera_type):xyz_line_type;

var
	ray:xyz_line_type;
	image:xyz_point_type;
	
begin
	image:=wps_from_image_point(p,camera);
	ray.point:=camera.pivot;
	ray.direction:=xyz_difference(camera.pivot,image);
	wps_ray:=ray;
end;

{
	wps_wire_plane returns the plane that contains the wire image and
	the camera pivot point. We assume that the wire itself must lie in
	this same plane. We specify a point in the ccd that lies upon the
	wire center with parameter "p", which is given in image coordinates.
	The rotation of the image, counter-clockwise on the sensor, is "r"
	in radians. We specify the camera calibration constants with the
	"camera" parameter. The routine specifies the plane with the pivot
	point and a normal vector it obtains by taking the cross product
	of the ray through "p" and another virtual point in the wire
	image. We perform the cross product so as to produce a normal vector
	that is in the positive z-direction for most wps applications.
}
function wps_wire_plane(p:xy_point_type;r:real;camera:wps_camera_type):xyz_plane_type;

var
	plane:xyz_plane_type;
	ray_1,ray_2:xyz_line_type;
	
begin
	ray_1:=wps_ray(p,camera);
	p.y:=p.y+1;
	p.x:=p.x+1*sin(r);
	ray_2:=wps_ray(p,camera);
	
	plane.point:=camera.pivot;
	plane.normal:=
		xyz_unit_vector(
			xyz_cross_product(
				ray_2.direction,ray_1.direction));
	wps_wire_plane:=plane;
end;

{
	wps_wire returns the wps measurement of a wire's center-line position in wps
	coordinates, given a point on the center-line of the image in both cameras,
	the rotation of the center line in both cameras, and the calibration
	constants of both cameras. The measurement is a line in wps coordinates,
	with a position and a direction. We obtain this line by intersecting the two
	planes defined by each image projected through its camera pivot point.
}
function wps_wire(p_1,p_2:xy_point_type;r_1,r_2:real;c_1,c_2:wps_camera_type):xyz_line_type;

var
	plane_1,plane_2:xyz_plane_type;
	
begin
	wps_wire:=xyz_plane_plane_intersection(
		wps_wire_plane(p_1,r_1,c_1),wps_wire_plane(p_2,r_2,c_2));
end;

{
	nominal_wps_camera returns the nominal wps_camera_type.
}
function nominal_wps_camera(code:integer):wps_camera_type;

var
	camera:wps_camera_type;
	
begin
	with camera do begin
		case code of
			1:begin
				id:='WPS1_A_1';
				pivot.x:=-4.5;
				pivot.y:=87.4;
				pivot.z:=-5;
				rot.x:=-pi/2;
				rot.y:=0;
				rot.z:=-0.541;
				sensor.x:=pivot.x-11.4*cos(rot.z);
				sensor.y:=pivot.y-11.4*sin(rot.z);
				sensor.z:=pivot.z;
			end;
			2:begin
				id:='WPS1_A_2';
				pivot.x:=-4.5;
				pivot.y:=37.4;
				pivot.z:=-5;
				rot.x:=+pi/2;
				rot.y:=0;
				rot.z:=+0.541;
				sensor.x:=pivot.x-11.4*cos(rot.z);
				sensor.y:=pivot.y-11.4*sin(rot.z);
				sensor.z:=pivot.z;
			end;
			otherwise begin
				id:='DEFAULT';
				pivot:=xyz_origin;
				sensor.x:=-1;
				sensor.y:=0;
				sensor.z:=0;
				rot:=xyz_origin;
			end;
		end;
	end;
	nominal_wps_camera:=camera;
end;


{
	wps_ray_error returns the distance between the ray defined by the position of an
	edge in an image to the actual position of the edge of the wire, or from the
	center of an image to the center of a wire. We specify left edges with
	edge_direction +1, right edges with -1, and wire centers with 0.
}
function wps_ray_error(image:xy_point_type;edge_direction:integer;
	wire:wps_wire_type;camera:wps_camera_type):xyz_point_type;

var
	ray,guide_ray,center_line,bridge:xyz_line_type;
	guide_vector:xyz_point_type;
	guide_point:xy_point_type;
	
begin
{
	Create a line along the center of the wire.
}
	center_line.point:=wire.position;
	center_line.direction:=wire.direction;
{	
	Create a line through the edge position and the pivot point.
}
	ray:=wps_ray(image,camera);
{
	Determine the shortest bridge between these two lines.
}
	bridge:=xyz_line_line_bridge(ray,center_line);
{
	If we are using the center of an image, we are done.
}
	if edge_direction=0 then begin
		wps_ray_error:=bridge.direction;
	end
{
	Displace the edge position in the direction of the center of the wire
	image and create a new ray that should be on the same side of the first
	ray as the wire center.
}
	else begin
		guide_point.x:=image.x+edge_direction;
		guide_point.y:=image.y;
		guide_ray:=wps_ray(guide_point,camera);
{
	Find the vector from the bridge point on the edge ray to the guide ray.
}
		guide_vector:=xyz_point_line_vector(bridge.point,guide_ray);
{
	If the guide_vector is in roughly the same direction as the bridge, we
	reduce the length of the bridge by one radius of the wire. Otherwise we
	extend the length of the bridge by one wire radius.
}
		if (xyz_dot_product(bridge.direction,guide_vector)>0) then 
			wps_ray_error:=
				xyz_scale(
					xyz_unit_vector(bridge.direction),
					xyz_length(bridge.direction)-wire.radius)
		else 
			wps_ray_error:=
				xyz_scale(
					xyz_unit_vector(bridge.direction),
					xyz_length(bridge.direction)+wire.radius);
	end;
end;

{
	wps_error returns the error in wps measurement at a specified z-plane. We
	provide the routine with image points in both cameras, the rotation of the
	image in both cameras, the camera calibration constants, the actual wire
	position and a reference z-coordinate. We take the wps wire line and the
	actual wire line and intersect them with the z-plane. We return the vector
	in wps coordinates from the actual to the wps wire position.
	
}
function wps_error(p_1,p_2:xy_point_type;r_1,r_2:real;c_1,c_2:wps_camera_type;
	wire:xyz_line_type;
	z_ref:real):xyz_point_type;

var
	w_1,w_2:xyz_point_type;
	z_plane:xyz_plane_type;
	
begin
	with z_plane.point do begin x:=0;y:=0;z:=z_ref; end;
	with z_plane.normal do begin x:=0;y:=0;z:=1; end;
	w_1:=xyz_line_plane_intersection(wps_wire(p_1,p_2,r_1,r_2,c_1,c_2),z_plane);
	w_2:=xyz_line_plane_intersection(wire,z_plane);
	wps_error:=xyz_difference(w_1,w_2);
end;

end.

