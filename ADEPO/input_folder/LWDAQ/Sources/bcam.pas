{
Utilities for BCAM Device Calibration and Measurement Transformation
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

unit bcam;
{
	bcam contains routines that transform between BCAM coordintes, global
	coordinates, and image coordinates. There are routines that analyze
	calibration measurements and calculate the bcam calibration constants. The
	BCAM measurements themselves we obtain separately using spot.pas. This unit
	uses only the utils unit. It does not deal with images or displays at all.

	bcam also contains routines that handle bcam calibration data, apparatus
	measurements, and paramter calculations. We designed these for use with
	BCAMs, but there is no reason why they cannot be used with other devices 
	calibrated in a similar way.
	
	Calibration measurements, such as the device measurements recorded during
	the calibration procedure, and the apparatus measurements made when the
	calibration apparatus itself is measured, can be stored in text files, and
	passed to and from the routines of the calibration unit as strings. We
	distinguish between two types of database entry in such files: apparatus
	measurements and device calibrations. An entry of each type begins with a
	title consisting of the entry type followed by a colon. After the title,
	separated by spaces or newlines or tabs are the contents of the entry, into
	which you can embed comments in curly brackets. The fields of the entry must
	appear in the string of text file in the same order as they appear in the
	record declarations below. Each field name is followed immediately by a
	colon, and then one or more separator characters, and perhaps a comment in
	curly brackets, followed by the value of the field, which must be a single
	word. After the fields, the data section of the entry begins with "data:"
	followed by numbers. The data section ends with "end. A database entry in a
	string need have no newline characters. But when a database entry is stored
	in a text file, the terminating "end." word must be on a separate line with
	no comments. Furthermore, no comment can contain a line with only the word
	"end." in it. These restrictions make it easier for a scripting language
	like TCL/TK to read whole entries from a file before they start taking
	notice of comments and field values, which speeds up and simpliefies the
	database routines.
	
	This program recognises the following bcam types, which we identify in calibration
	measurements and in the program below using the strings given on the left.
	
	black_polar_fc		black polar bcam front camera calibration
	black_polar_rc		black polar bcam rear camera calibration
	blue_polar_fc		blue polar bcam front camera calibration
	blue_polar_rc		blue polar bcam rear camera calibration
	black_h_fc			black h bcam front camera calibration
	black_h_rc			black h bcam rear camera calibration
	blue_h_fc			blue h bcam front camera calibration
	blue_h_rc			blue h bcam rear camera calibration
	black_azimuthal_c	black azimuthal bcam camera calibration
	blue_azimuthal_c	blue azimuthal bcam camera calibration
	black_polar_fs		black polar bcam front sources calibration
	black_polar_rs		black polar bcam rear sources calibration
	blue_polar_fs		blue polar bcam front sources calibration
	blue_polar_rs		blue polar bcam rear sources calibration
	black_h_fs			black h bcam front sources calibration
	black_h_rs			black h bcam rear sources calibration
	blue_h_fs			blue h bcam front sources calibration
	blue_h_rs			blue h bcam rear sources calibration
	black_azimuthal_s	black azimuthal sources calibration
	blue_azimuthal_s	blue azimuthal sources calibration
	j_plate				j plate source calibration
	k_plate				k plate source calibration
	black_fiber_rs		black fiber rear source calibration
	blue_fiber_rs		blue fiber rear source calibration
	
	To express our empirically-derived limits to calibration constant ranges for
	various devices, we have strings like bcam_camera_limit and
	bcam_black_azi_c_nominal. We handle these strings inside our code with the
	help of string readers. The strings are declared as global, so any other
	unit can refer to them.
}
interface

uses
	utils;
	
const {database keywords}
	device_calibration_begin='device_calibration:';
	device_calibration_end='end.';
	apparatus_measurement_begin='apparatus_measurement:';
	apparatus_measurement_end='end.';
	
const {array sizes}
	max_num_calibration_reals=100;
	max_num_apparatus_reals=100;
	max_num_parameter_reals=100;
	
type {database records}
	device_calibration_type=record 
		device_id:short_string;
		calibration_type:short_string;
		apparatus_version:short_string;
		calibration_time:short_string;
		operator_name:short_string;
		num_reals_used:integer;
		data:array[1..max_num_calibration_reals] of real;
	end;
	apparatus_measurement_type=record
		calibration_type:short_string;
		apparatus_version:short_string;
		measurement_time:short_string;
		operator_name:short_string;
		num_reals_used:integer;
		data:array[1..max_num_apparatus_reals] of real;
	end;
	
const
	num_roll_cage_pairs=3*2*1; {number of combinations of two from a set of four}
	bcam_z_angle=0.5596/2;{z-axis to slot-cone line in radians}
	bcam_mid_z=-40;{mm approx for discrimination}
	bcam_tc255_center_x=1.720;{along image coordinate x-axis (mm)}
	bcam_tc255_center_y=1.220;{along image coordinate y-axis (mm)}
	bcam_tc255_code=1;{in axis code specifies tc255}
	bcam_icx424_center_x=2.590;{along image coordinate x-axis (mm)}
	bcam_icx424_center_y=1.924;{along image coordinate y-axis (mm)}
	bcam_icx424_code=2;{in axis code specifies icx424}
	bcam_front_source_z=0.36;{front laser facet bcam-coord z-position (mm)}
	bcam_rear_source_z=-82.85;{rear laser facet bcam-coord z-position (mm)}
	num_mounts_per_pair=2;
	num_mounts_per_quad=4;
	num_sources_per_range=4;
	num_sources_per_pair=2;
	num_ranges_per_mount=2;

type
{
	bcam_camera_type gives the pivot, ccd_to_pivot distance, axis, and
	ccd_rotation of the camera in 'bcam coordinates'. The bcam
	coordinate z-axis runs along the nominal optical axis of the
	camera. It points in the direction of the arrow made by the
	mounting balls. The x-axis is in the plane of the mounting balls.
	It points to the left when you are looking in the z-direction with
	the balls below. The y-axis completes a right-handed system.
}
	bcam_camera_type=record
		pivot:xyz_point_type;{bcam coordinates of pivot point (mm)}
		axis:xyz_point_type;{cosine vectors of camera axis}
		code:real;{camera version code, gives sensor type}
		ccd_to_pivot:real;{from ccd to pivot along camera axis (mm)}
		ccd_rotation:real;{rotation of ccd about camera axis (rad)}
		id:short_string;{identifier}
	end;
{
	bcam_sources_type gives the centers of two light sources in bcam coordinates.
}
	bcam_sources_type=record
		sources:array [1..num_sources_per_pair] 
			of xyz_point_type;{bcam coordinates of source (mm)}
		id:short_string;{identifier}
	end;
{
	bcam_jk_type is the same as bcam_sources_type.
}
	bcam_jk_type=bcam_sources_type;

{geometry}
function bcam_coordinates_from_mount(mount:kinematic_mount_type):coordinates_type;
function bcam_from_image_point(p:xy_point_type;camera:bcam_camera_type):xyz_point_type;
function bcam_from_global_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function bcam_from_global_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function bcam_from_global_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;
function bcam_from_global_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;
function image_from_bcam_point(p:xyz_point_type;camera:bcam_camera_type):xy_point_type;
function global_from_bcam_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function global_from_bcam_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
function global_from_bcam_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;
function global_from_bcam_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;
function bcam_image_position(source_position:xyz_point_type;
	camera:bcam_camera_type):xy_point_type;
function bcam_source_bearing(spot_center:xy_point_type;
	camera:bcam_camera_type):xyz_line_type;
function bcam_source_position(spot_center:xy_point_type;range:real;
	camera:bcam_camera_type):xyz_point_type;

{strings}
function bcam_sources_from_string(s:short_string):bcam_sources_type;
function bcam_jk_from_string(s:short_string):bcam_jk_type;
function bcam_camera_from_string(s:short_string):bcam_camera_type;
function string_from_bcam_sources(sources:bcam_sources_type):short_string;
function string_from_bcam_jk(sources:bcam_jk_type):short_string;
function string_from_bcam_camera(camera:bcam_camera_type):short_string;
function device_calibration_from_string(s:short_string):device_calibration_type;
function apparatus_measurement_from_string(s:short_string):apparatus_measurement_type;
procedure write_apparatus_measurement(var f:string;app:apparatus_measurement_type);
procedure write_device_calibration(var f:string;calib:device_calibration_type);

{calculating calibration constants}
function nominal_bcam_camera(device_type:short_string):bcam_camera_type;
function bcam_camera_calib(calib:device_calibration_type;
	app:apparatus_measurement_type;
	verbose,check:boolean):short_string;
function bcam_sources_calib(calib:device_calibration_type;
	app:apparatus_measurement_type;
	verbose,check:boolean):short_string;
function bcam_jk_calib(calib:device_calibration_type;
	app:apparatus_measurement_type;
	verbose,check:boolean):short_string;

	
const
	bcam_camera_limit='limit 0.08 0.08 4 0.1 0.1 0 0.3 1';
	bcam_sources_limit='limit 0.08 0.08 0.08 0.08 0.1';
	bcam_jk_limit='limit 0.1 0.04 0.04 0.1 0.04 0.04';

	bcam_camera_range='range 1 1 10 10 10 0.1 2 100';
	bcam_sources_range='range 1 1 1 1 0.1';
	bcam_jk_range='range 0.1 0.5 0.5 0.1 0.5 0.5';

	bcam_black_azimuthal_c_nominal='nominal -12.675 13.137 2 0 0 1 75 3141.6';
	bcam_blue_azimuthal_c_nominal='nominal -12.675 -13.137 2 0 0 1 75 0.0';
	bcam_black_polar_fc_nominal='nominal 12.751 35.311 2 0 0 1 75 0.0';
	bcam_black_polar_rc_nominal='nominal -12.751 35.311 -81.900 0 0 -1 75 0.0';
	bcam_blue_polar_fc_nominal='nominal 12.751 -35.311 2 0 0 1 75 3141.6';
	bcam_blue_polar_rc_nominal='nominal -12.751 -35.311 -81.900 0 0 -1 75 3141.6';
	bcam_black_h_fc_nominal='nominal 12.751 35.311 2 0 0 2 50 0.0';
	bcam_black_h_rc_nominal='nominal -12.751 35.311 -81.900 0 0 -2 50 0.0';
	bcam_blue_h_fc_nominal='nominal 12.751 -35.311 2 0 0 2 50 3141.6';
	bcam_blue_h_rc_nominal='nominal -12.751 -35.311 -81.900 0 0 -2 50 3141.6';

	bcam_black_azimuthal_s_nominal='nominal -20.676 13.137 -4.764 13.137 0.360';
	bcam_blue_azimuthal_s_nominal='nominal -20.676 -13.137 -4.764 -13.137 0.360';
	bcam_black_polar_fs_nominal='nominal 4.674 36.812 20.670 36.812 0.360';
	bcam_black_polar_rs_nominal='nominal -4.674 36.812 -20.670 36.812 -82.850';
	bcam_blue_polar_fs_nominal='nominal 4.674 -36.812 20.670 -36.812 0.360';
	bcam_blue_polar_rs_nominal='nominal -4.674 -36.812 -20.670 -36.812 -82.850';
	bcam_black_h_fs_nominal='nominal 4.674 35.311 20.670 35.311 0.360';
	bcam_black_h_rs_nominal='nominal -4.674 35.311 -20.670 35.311 -82.850';
	bcam_blue_h_fs_nominal='nominal 4.674 -35.311 20.670 -35.311 0.360';
	bcam_blue_h_rs_nominal='nominal -4.674 -35.311 -20.670 -35.311 -82.850';

	bcam_j_plate_nominal='nominal -3.730 4.670 5.710 -3.730 20.670 5.710';
	bcam_k_plate_nominal='nominal -3.730 20.670 -5.710 -3.730 4.670 -5.710';
	
	bcam_black_fiber_rs_nominal='nominal -5.029 21.820 -21.029 21.820 -71.211';	
	bcam_blue_fiber_rs_nominal='nominal -5.029 -21.820 -21.029 -21.820 -71.211';
	
implementation

type
{
	calib_datum_type gives the position of a light spot on the camera ccd in ccd 
	coordinates, and the z-coordinate of the light source in global coordinates. The routine
	is for calibration stands in which the global z-coordinate is parallel to the bcam
	z-coordinate.
}
	calib_datum_type=record
		spot_center:xy_point_type;{light spot center image coordinates (um)}
		source_range:real;{z-coordinate of source in global coordinates (mm)}
	end;
{
	bcam_camera_calib_type contains the six bcam_camera_type records produced
	by the six pairs of orientations available from a roll-cage calibration.
}
	bcam_camera_calib_type=record
		pairs:array [1..num_roll_cage_pairs] of bcam_camera_type;
		average:bcam_camera_type;
		spread:bcam_camera_type;
		id,time,device_type:short_string;
	end;
{
	bcam_sources_calib_type contains the six bcam_source_pair_type records
	produced by the six pairs of orientations available from a roll-cage
	calibration.
}
	bcam_sources_calib_type=record
		pairs:array [1..num_roll_cage_pairs] of bcam_sources_type;
		average:bcam_sources_type;
		spread:bcam_sources_type;
		id,time,device_type:short_string;
	end;
{
	bcam_jk_calib_type is identical to bcam_sources_calib_type.
}
	bcam_jk_calib_type=bcam_sources_calib_type;
{
	bcam_jk_mount_type contains the three pin centers, the diameter of
	the pin and the type of plate.
}
	bcam_jk_mount_type=record
		pin1,pin2,pin3:xyz_point_type;
		diameter:real;
		plate_type:short_string;
	end;

{
	bcam_sources_from_string converts a string in the established "sources"
	format, which gives the x and y of the two sources followed by the shared z
	coordinate, into a bcam_sources_type. The sources are listed in order "1 2"
	with respect to the LWDAQ device element numbers that select the lasers, or
	"3 4". The "3 4" applies to all front-side bcam sources, the "1 2" to the
	rear-side sources.
}
function bcam_sources_from_string(s:short_string):bcam_sources_type;
var
	sources:bcam_sources_type;
begin
	with sources do begin
		id:=read_word(s);
		sources[1].x:=read_real(s);
		sources[1].y:=read_real(s);
		sources[2].x:=read_real(s);
		sources[2].y:=read_real(s);
		sources[1].z:=read_real(s);
		sources[2].z:=sources[1].z;
	end;
	bcam_sources_from_string:=sources;
end;

{
	bcam_jk_from_string converts a string in the established "jk" format, which
	gives the x, y, and z of the two sources with the left one first, into a
	bcam_sources_type.
}
function bcam_jk_from_string(s:short_string):bcam_jk_type;
var
	sources:bcam_sources_type;
begin
	with sources do begin
		id:=read_word(s);
		sources[1].x:=read_real(s);
		sources[1].y:=read_real(s);
		sources[1].z:=read_real(s);
		sources[2].x:=read_real(s);
		sources[2].y:=read_real(s);
		sources[2].z:=read_real(s);
	end;
	bcam_jk_from_string:=sources;
end;

{
	bcam_camera_from_string converts a string into a bcam_camera_type;
}
function bcam_camera_from_string(s:short_string):bcam_camera_type;
var 
	camera:bcam_camera_type;
begin
	with camera do begin
		id:=read_word(s);
		pivot:=read_xyz(s);
		axis:=read_xyz(s);
		with axis do begin
			x:=x/mrad_per_rad;
			y:=y/mrad_per_rad;
			code:=abs(z);
			if z>0 then z:=1 else z:=-1;
		end;
		ccd_to_pivot:=read_real(s);
		ccd_rotation:=read_real(s);
		ccd_rotation:=ccd_rotation/mrad_per_rad;
	end;
	bcam_camera_from_string:=camera;
end;

{
	string_from_bcam_sources writes bcam source positions to a string. This 
	routine writes the x and y coordinates of the sources, then the shared
	z coordinate.
}
function string_from_bcam_sources(sources:bcam_sources_type):short_string;
const 
	fsr=8;fsd=3;fsdr=3;fsid=10;fss=4;
var 
	source_num:integer;
	f:short_string='';
begin
	with sources do begin
		writestr(f,f,id:fsid);
		for source_num:=1 to num_sources_per_pair do
			with sources[source_num] do
				writestr(f,f,x:fsr:fsd,y:fsr:fsd);
		writestr(f,f,sources[1].z:fsr:fsd);
	end;
	string_from_bcam_sources:=f;
end;

{
	string_from_bcam_jk writes jk source positions to a string. This routine
	writes the x, y, z coordinates of each source.
}
function string_from_bcam_jk(sources:bcam_jk_type):short_string;
const 
	fsr=8;fsd=3;fsdr=3;fsid=10;fss=4;
var 
	source_num:integer;
	f:short_string='';
begin
	with sources do begin
		writestr(f,id:fsid);
		for source_num:=1 to num_sources_per_pair do
			with sources[source_num] do
				writestr(f,f,x:fsr:fsd,y:fsr:fsd,z:fsr:fsd);
	end;
	string_from_bcam_jk:=f;
end;

{
	string_from_bcam_camera appends a camera type to a string, using only one line.
}
function string_from_bcam_camera(camera:bcam_camera_type):short_string;	
const 
	fsr=8;fsd=3;fsdr=3;fsid=10;fss=4;
var 
	f:short_string='';
begin
	with camera do begin
		writestr(f,f,id:fsid);
		with pivot do 
			writestr(f,f,x:fsr:fsd,y:fsr:fsd,z:fsr:fsd);
		with axis do 
			writestr(f,f,x*mrad_per_rad:fsr:fsdr,y*mrad_per_rad:fsr:fsdr);
		writestr(f,f,axis.z*code:fss:0);
		writestr(f,f,ccd_to_pivot:fsr:fsd);
		writestr(f,f,' ',ccd_rotation*mrad_per_rad:fsr:fsdr);
	end;
	string_from_bcam_camera:=f;
end;

{
	check_bcam_sources_calib examines the fields of a source pair calibration to
	see if the values match the device type and whether the spread of values
	within the calibration lies within the limits defined by constant strings
	above. The routine returns a string describing all the errors it finds.
}
function check_bcam_sources_calib(calib:bcam_sources_calib_type):short_string;

const
	fsr=6;
	fsd=3;
	fsi=1;

var
	source_num:integer;
	limit,range,nominal:bcam_sources_type;
	f,s:short_string;
	
begin
	f:='';
	
	range:=bcam_sources_from_string(bcam_sources_range);
	if calib.device_type='black_polar_fs' then 
		nominal:=bcam_sources_from_string(bcam_black_polar_fs_nominal)
	else if calib.device_type='black_polar_rs' then 
		nominal:=bcam_sources_from_string(bcam_black_polar_rs_nominal) 
	else if calib.device_type='blue_polar_fs' then 
		nominal:=bcam_sources_from_string(bcam_blue_polar_fs_nominal)
	else if calib.device_type='blue_polar_rs' then 
		nominal:=bcam_sources_from_string(bcam_blue_polar_rs_nominal) 
	else if calib.device_type='black_h_fs' then 
		nominal:=bcam_sources_from_string(bcam_black_h_fs_nominal)
	else if calib.device_type='black_h_rs' then 
		nominal:=bcam_sources_from_string(bcam_black_h_rs_nominal) 
	else if calib.device_type='blue_h_fs' then 
		nominal:=bcam_sources_from_string(bcam_blue_h_fs_nominal)
	else if calib.device_type='blue_h_rs' then 
		nominal:=bcam_sources_from_string(bcam_blue_h_rs_nominal) 
	else if calib.device_type='black_azimuthal_s' then 
		nominal:=bcam_sources_from_string(bcam_black_azimuthal_s_nominal) 
	else if calib.device_type='blue_azimuthal_s' then 
		nominal:=bcam_sources_from_string(bcam_blue_azimuthal_s_nominal) 
	else if calib.device_type='black_fiber_rs' then 
		nominal:=bcam_sources_from_string(bcam_black_fiber_rs_nominal) 
	else if calib.device_type='blue_fiber_rs' then 
		nominal:=bcam_sources_from_string(bcam_blue_fiber_rs_nominal) 
	else begin
		writestr(f,f,eol,'WARNING: Unrecognised device type "',calib.device_type,'".');
		check_bcam_sources_calib:=f;
		exit;
	end;
	
	s:=' ';
	for source_num:=1 to num_sources_per_pair do begin
		with calib.average.sources[source_num] do begin
			if (x>nominal.sources[source_num].x+range.sources[source_num].x)
				or (x<nominal.sources[source_num].x-range.sources[source_num].x) then
					s:=s+'x_'+string_from_integer(source_num,1)+' ';
			if (y>nominal.sources[source_num].y+range.sources[source_num].y)
				or (y<nominal.sources[source_num].y-range.sources[source_num].y) then
					s:=s+'y_'+string_from_integer(source_num,1)+' ';
		end;
	end;
	if length(s)>1 then
		writestr(f,f,eol,'WARNING:',s,'wrong for ',calib.device_type,'.');
	
	limit:=bcam_sources_from_string(bcam_sources_limit);
	for source_num:=1 to num_sources_per_pair do begin
		with calib.spread.sources[source_num] do begin
			if x>limit.sources[source_num].x then 
				writestr(f,f,eol,'WARNING: source ',source_num:fsi,' x spread exceeds ',
					limit.sources[source_num].x:fsr:fsd,' mm');
			if y>limit.sources[source_num].y then 
				writestr(f,f,eol,'WARNING: source ',source_num:fsi,' y spread exceeds ',
					limit.sources[source_num].y:fsr:fsd,' mm');
			if z>limit.sources[source_num].z then 
				writestr(f,f,eol,'WARNING: source ',source_num:fsi,' z spread exceeds ',
					limit.sources[source_num].z:fsr:fsd,' mm');
		end;
	end;
	
	check_bcam_sources_calib:=f;
end;

{
	check_bcam_jk_calib is similar to check_bcam_sources_calib, but for jk-plate calibration
	constants.
}
function check_bcam_jk_calib(calib:bcam_jk_calib_type):short_string;

const
	fsr=6;
	fsd=3;
	fsi=1;

var
	source_num:integer;
	limit,range,nominal:bcam_sources_type;
	f,s:short_string;
	
begin
	f:='';
	
	range:=bcam_jk_from_string(bcam_jk_range);
	if calib.device_type='j_plate' then 
		nominal:=bcam_jk_from_string(bcam_j_plate_nominal)
	else if calib.device_type='k_plate' then 
		nominal:=bcam_jk_from_string(bcam_k_plate_nominal) 
	else begin
		writestr(f,f,eol,'WARNING: Unrecognised device type "',calib.device_type,'".');
		check_bcam_jk_calib:=f;
		exit;
	end;
	
	s:=' ';
	for source_num:=1 to num_sources_per_pair do begin
		with calib.average.sources[source_num] do begin
			if (x>nominal.sources[source_num].x+range.sources[source_num].x)
				or (x<nominal.sources[source_num].x-range.sources[source_num].x) then
					s:=s+'x_'+string_from_integer(source_num,1)+' ';
			if (y>nominal.sources[source_num].y+range.sources[source_num].y)
				or (y<nominal.sources[source_num].y-range.sources[source_num].y) then
					s:=s+'y_'+string_from_integer(source_num,1)+' ';
		end;
	end;
	if length(s)>1 then
		writestr(f,f,eol,'WARNING:',s,'wrong for ',calib.device_type,'.');
	
	limit:=bcam_jk_from_string(bcam_jk_limit);
	for source_num:=1 to num_sources_per_pair do begin
		with calib.spread.sources[source_num] do begin
			if x>limit.sources[source_num].x then 
				writestr(f,f,eol,'WARNING: source ',source_num:fsi,' x spread exceeds ',
					limit.sources[source_num].x:fsr:fsd,' mm');
			if y>limit.sources[source_num].y then 
				writestr(f,f,eol,'WARNING: source ',source_num:fsi,' y spread exceeds ',
					limit.sources[source_num].y:fsr:fsd,' mm');
			if z>limit.sources[source_num].z then 
				writestr(f,f,eol,'WARNING: source ',source_num:fsi,' z spread exceeds ',
					limit.sources[source_num].z:fsr:fsd,' mm');
		end;
	end;
	
	check_bcam_jk_calib:=f;
end;

{
	check_bcam_camera_calib is like check_bcam_sources_calib, but for camera calibration
	constants.
}
function check_bcam_camera_calib(calib:bcam_camera_calib_type):short_string;

const
	fsr=6;
	fsd=3;
	
var
	limit,range,nominal:bcam_camera_type;
	f,s:short_string;

begin
	f:='';
	
	range:=bcam_camera_from_string(bcam_camera_range);
	if calib.device_type='black_polar_fc' then 
		nominal:=bcam_camera_from_string(bcam_black_polar_fc_nominal)
	else if calib.device_type='black_polar_rc' then 
		nominal:=bcam_camera_from_string(bcam_black_polar_rc_nominal) 
	else if calib.device_type='blue_polar_fc' then 
		nominal:=bcam_camera_from_string(bcam_blue_polar_fc_nominal)
	else if calib.device_type='blue_polar_rc' then 
		nominal:=bcam_camera_from_string(bcam_blue_polar_rc_nominal) 
	else if calib.device_type='black_h_fc' then 
		nominal:=bcam_camera_from_string(bcam_black_h_fc_nominal)
	else if calib.device_type='black_h_rc' then 
		nominal:=bcam_camera_from_string(bcam_black_h_rc_nominal) 
	else if calib.device_type='blue_h_fc' then 
		nominal:=bcam_camera_from_string(bcam_blue_h_fc_nominal)
	else if calib.device_type='blue_h_rc' then 
		nominal:=bcam_camera_from_string(bcam_blue_h_rc_nominal) 
	else if calib.device_type='black_azimuthal_c' then 
		nominal:=bcam_camera_from_string(bcam_black_azimuthal_c_nominal) 
	else if calib.device_type='blue_azimuthal_c' then 
		nominal:=bcam_camera_from_string(bcam_blue_azimuthal_c_nominal) 
	else begin
		writestr(f,f,eol,'WARNING: Unrecognised device type "',calib.device_type,'".');
		check_bcam_camera_calib:=f;
		exit;
	end;
	
	s:=' ';
	with calib.average do begin
		if (pivot.x>nominal.pivot.x+range.pivot.x) 
			or (pivot.x<nominal.pivot.x-range.pivot.x) then
				s:=s+'pivot.x ';
		if (pivot.y>nominal.pivot.y+range.pivot.y)
			or (pivot.y<nominal.pivot.y-range.pivot.y) then
				s:=s+'pivot.y ';
		if (pivot.z>nominal.pivot.z+range.pivot.z)
			or (pivot.z<nominal.pivot.z-range.pivot.z) then 
				s:=s+'pivot.z ';
		if (axis.x>nominal.axis.x+range.axis.x)
			or (axis.x<nominal.axis.x-range.axis.x) then
				s:=s+'axis.y ';
		if (axis.y>nominal.axis.y+range.axis.y)
			or (axis.y<nominal.axis.y-range.axis.y) then
				s:=s+'axis.y ';
		if (ccd_to_pivot>nominal.ccd_to_pivot+range.ccd_to_pivot)
			or (ccd_to_pivot<nominal.ccd_to_pivot-range.ccd_to_pivot) then
				s:=s+'ccd_to_pivot ';
		if (ccd_rotation>nominal.ccd_rotation+range.ccd_rotation)
			or (ccd_rotation<nominal.ccd_rotation-range.ccd_rotation) then
				s:=s+'ccd_rotation ';
		if length(s)>1 then
			writestr(f,f,eol,
				'WARNING:',s,'wrong for ',calib.device_type,'.');
	end;

	limit:=bcam_camera_from_string(bcam_camera_limit);
	with calib.spread do begin
		if pivot.x>limit.pivot.x then 
			writestr(f,f,eol,'WARNING: pivot.x spread exceeds ',
				limit.pivot.x:fsr:fsd,' mm.');
		if pivot.y>limit.pivot.y then 
			writestr(f,f,eol,'WARNING: pivot.y spread exceeds ',
				limit.pivot.y:fsr:fsd,' mm.');
		if pivot.z>limit.pivot.z then 
			writestr(f,f,eol,'WARNING: pivot.z spread exceeds ',
				limit.pivot.z:fsr:fsd,' mm.');
		if axis.x>limit.axis.x then 
			writestr(f,f,eol,'WARNING: axis.x spread exceeds ',
				mrad_per_rad*limit.axis.x:fsr:fsd,' mrad.');
		if axis.y>limit.axis.y then 
			writestr(f,f,eol,'WARNING: axis.y spread exceeds ',
				mrad_per_rad*limit.axis.y:fsr:fsd,' mrad.');
		if ccd_to_pivot>limit.ccd_to_pivot then 
			writestr(f,f,eol,'WARNING: ccd_to_pivot spread exceeds ',
				limit.ccd_to_pivot,' mm.');
		if ccd_rotation>limit.ccd_rotation then 
			writestr(f,f,eol,'WARNING: ccd_rotation spread exceeds ',
				mrad_per_rad*limit.ccd_rotation:fsr:fsd,' mrad.');
	end;
	
	check_bcam_camera_calib:=f;
end;

{
	string_from_sources_calib prints the results of a bcam sources calibration
	to a string. If verbose, the printout will include tabulation and all six
	pair calibrations from the roll-cage calibration process. Otherwise, the
	printout will be a single line giving the source x and y positions followed
	by the shared z coordinate. If check is set, the routine calls
	check_bcam_sources_calib, and so adds warnings to the printout. These
	warnings will each be on a separate line beginning "WARNING:".
}
function string_from_sources_calib(calib_output:bcam_sources_calib_type;
	verbose,check:boolean):short_string;

var 
	pair_num:integer;
	s,w:short_string='';
	
begin
	if verbose then with calib_output do begin
		if average.sources[1].z>bcam_mid_z then 
			writestr(s,'Calibration Constants for Front Sources on Device ',id,':',eol)
		else
			writestr(s,'Calibration Constants for Rear Sources on Device ',id,':',eol);
		writestr(s,s,' -------------------------------------------------',eol);
		writestr(s,s,'          | First Source  | Second Source |         ',eol);
		writestr(s,s,'          |-----------------------|-------|         ',eol);
		writestr(s,s,'          |   x   |   y   |   x   |   y   |   z     ',eol);
		writestr(s,s,'    Pair  |  (mm) |  (mm) |  (mm) |  (mm) |  (mm)   ',eol);
		writestr(s,s,' -------------------------------------------------',eol);
		for pair_num:=1 to num_roll_cage_pairs do
			s:=s+string_from_bcam_sources(pairs[pair_num])+eol;
		writestr(s,s,' -------------------------------------------------',eol);
		s:=s+string_from_bcam_sources(average)+eol;
		s:=s+string_from_bcam_sources(spread)+eol;
		s:=s+string_from_bcam_sources(bcam_sources_from_string(bcam_sources_limit))+eol;
		writestr(s,s,' -------------------------------------------------',eol);
		writestr(s,s,'Calibration performed at time ',time);
	end else begin
		s:=string_from_bcam_sources(calib_output.average);
		w:=read_word(s);
	end;
	
	if check then s:=s+check_bcam_sources_calib(calib_output);
	string_from_sources_calib:=s;
end;

{
	string_from_jk_calib is similar to string_from_sources_calib, but for the
	roll-cage jk-plate calibration results.
}
function string_from_jk_calib(calib_output:bcam_jk_calib_type;
	verbose,check:boolean):short_string;

var 
	pair_num:integer;
	s,w:short_string='';

begin
	if verbose then with calib_output do begin
		writestr(s,'Calibration Constants for Sources on Device ',id,':',eol);
		writestr(s,s,' ---------------------------------------------------------',eol);
		writestr(s,s,'          |     Left  Source      |     Right Source   ',eol);
		writestr(s,s,'          |-----------------------|-----------------------',eol);
		writestr(s,s,'          |   x   |   y   |   z   |   x   |   y   |   z   ',eol);
		writestr(s,s,'    Pair  |  (mm) |  (mm) |  (mm) |  (mm) |  (mm) |  (mm) ',eol);
		writestr(s,s,' ---------------------------------------------------------',eol);
		for pair_num:=1 to num_roll_cage_pairs do
			s:=s+string_from_bcam_jk(pairs[pair_num])+eol;
		writestr(s,s,' ---------------------------------------------------------',eol);
		s:=s+string_from_bcam_jk(average)+eol;
		s:=s+string_from_bcam_jk(spread)+eol;
		s:=s+string_from_bcam_jk(bcam_jk_from_string(bcam_jk_limit))+eol;
		writestr(s,s,' ---------------------------------------------------------',eol);
		writestr(s,s,'Calibration performed at time ',time);
	end else begin
		s:=string_from_bcam_jk(calib_output.average);
		w:=read_word(s);
	end;

	if check then s:=s+check_bcam_jk_calib(calib_output);
	string_from_jk_calib:=s;
end;

{
	string_from_camera_calib is similar to string_from_sources_calib, but for the
	roll-cage camera calibration results.
}
function string_from_camera_calib(calib_output:bcam_camera_calib_type;
	verbose,check:boolean):short_string;
	
var 
	pair_num:integer;
	s,w:short_string='';
	
begin
	if verbose then with calib_output do begin
		s:=eol;
		if (average.axis.z>0) then 
			writestr(s,s,'Calibration Constants for Front-Facing Camera on Device ',id,':',eol)
		else
			writestr(s,s,'Calibration Constants for Rear-Facing Camera on Device ',id,':',eol);
		writestr(s,s,' -----------------------------------------------------------------------',eol);
		writestr(s,s,'          |      Pivot Position   |   Axis Direction  |  CCD  |  CCD    ',eol);
		writestr(s,s,'          |-----------------------|-------------------| -to-  |  Rot-   ',eol);
		writestr(s,s,'          |    x  |   y   |   z   |    x  |    y  |   | Pivot |  ation  ',eol);
		writestr(s,s,'    Pair  |  (mm) |  (mm) |  (mm) | (mrad)| (mrad)| z |  (mm) |  (mrad) ',eol);
		writestr(s,s,' -----------------------------------------------------------------------',eol);
		for pair_num:=1 to num_roll_cage_pairs do
			s:=s+string_from_bcam_camera(pairs[pair_num])+eol;
		writestr(s,s,' -----------------------------------------------------------------------',eol);
		s:=s+string_from_bcam_camera(average)+eol;
		s:=s+string_from_bcam_camera(spread)+eol;
		s:=s+string_from_bcam_camera(
			bcam_camera_from_string(bcam_camera_limit))+eol;
		writestr(s,s,' -----------------------------------------------------------------------',eol);
		writestr(s,s,'Calibration performed at time ',time);
	end else begin
		s:=string_from_bcam_camera(calib_output.average);
		w:=read_word(s);
	end;
	
	if check then s:=s+check_bcam_camera_calib(calib_output);
	string_from_camera_calib:=s;
end;

{
	Converte a string into a device calibration.
}
function device_calibration_from_string(s:short_string):device_calibration_type;

var
	data_num:integer;
	word,id:short_string;
	dc:device_calibration_type;
	okay:boolean;
	
begin
	with dc do begin
		device_id:='';
		calibration_type:='';
		apparatus_version:='';
		calibration_time:='';
	end;
	device_calibration_from_string:=dc;
	
	repeat 
		if length(s)=0 then begin
			report_error('Calibration does not contain "'
				+device_calibration_begin
				+'" in '+CurrentRoutineName+'.');
			exit;
		end;
		word:=read_word(s);
	until (word=device_calibration_begin);

	with dc do begin
		word:=read_word(s);device_id:=read_word(s);
		word:=read_word(s);calibration_type:=read_word(s);
		word:=read_word(s);apparatus_version:=read_word(s);
		word:=read_word(s);calibration_time:=read_word(s);
		word:=read_word(s);operator_name:=read_word(s);
		writestr(id,device_id,'-',calibration_type,'-',calibration_time);

		word:=read_word(s); {this gets the data: title}
		word:=read_word(s); {this gets the first datum}
		num_reals_used:=1;
		while (word<>device_calibration_end) do begin
			if num_reals_used=max_num_calibration_reals then begin
				report_error('Calibration "'+id+'" has too many values in '
					+CurrentRoutineName+'.');
				exit;
			end;
			data[num_reals_used]:=real_from_string(word,okay);
			if not okay then begin
				report_error('Calibration "'+id+'" terminated incorrectly in '
					+CurrentRoutineName+'.');
				exit;
			end;
			inc(num_reals_used);
			word:=read_word(s);
		end;
	end;
	device_calibration_from_string:=dc;
end;

{
	Convert a string into an apparatus measurement record.
}
function apparatus_measurement_from_string(s:short_string):apparatus_measurement_type;

var
	data_num:integer;
	word,id:short_string;
	am:apparatus_measurement_type;
	okay:boolean;
	
begin
	with am do begin
		calibration_type:='';
		apparatus_version:='';
		measurement_time:='';
	end;
	apparatus_measurement_from_string:=am;
	
	repeat 
		if length(s)=0 then begin
			report_error('Measurement does not contain "'
					+apparatus_measurement_begin+'" in '
					+CurrentRoutineName+'.');
			exit;
		end;
		word:=read_word(s);
	until (word=apparatus_measurement_begin);

	with am do begin
		word:=read_word(s);calibration_type:=read_word(s);
		word:=read_word(s);apparatus_version:=read_word(s);
		word:=read_word(s);measurement_time:=read_word(s);
		word:=read_word(s);operator_name:=read_word(s);
		writestr(id,apparatus_version,'-',calibration_type,'-',measurement_time);

		word:=read_word(s); {this gets data: title}
		word:=read_word(s); {this gest first datum}
		num_reals_used:=1;
		while (word<>apparatus_measurement_end) do begin
			if (num_reals_used=max_num_apparatus_reals) then begin
				report_error('Measurement "'+id+'" has too many data values in '
					+CurrentRoutineName+'.');
				exit;
			end;
			data[num_reals_used]:=real_from_string(word,okay);
			if not okay then begin
				report_error('Measurement "'+id+'" terminated incorrectly in'
					+CurrentRoutineName+'.');
				exit;
			end;
			inc(num_reals_used);
			word:=read_word(s);
		end;
	end;
	apparatus_measurement_from_string:=am;
end;

{
	Write a device calibration to a string. We append the calibration to the end
	of the existing string.
}
procedure write_device_calibration(var f:string;calib:device_calibration_type);

const
	data_per_line=8;
	fsr=1;
	fsd=2;
	
var
	data_num:integer;
	
begin
	writestr(f,f,eol);
	with calib do begin
		writestr(f,f,device_calibration_begin,eol);
		writestr(f,f,'device_id: ',device_id,eol);
		writestr(f,f,'calibration_type: ',calibration_type,eol);
		writestr(f,f,'apparatus_version: ',apparatus_version,eol);
		writestr(f,f,'calibration_time: ',calibration_time,eol);
		writestr(f,f,'operator_name: ',operator_name,eol);
		writestr(f,f,'data: ',eol);
		if (num_reals_used<1) or (num_reals_used>max_num_calibration_reals) then 
			num_reals_used:=max_num_calibration_reals;
		for data_num:=1 to num_reals_used do begin
			writestr(f,f,data[data_num]:fsr:fsd,' ');
			if (data_num=num_reals_used) or (data_num mod data_per_line=0) then 
				writestr(f,f,eol);
		end;
		writestr(f,f,device_calibration_end,eol);
	end;
end;

{
	Write an apparatus measurement to a string. We append the new characters to the
	existing string.
}
procedure write_apparatus_measurement(var f:string;app:apparatus_measurement_type);

const
	data_per_line=9;
	fsr=1;
	fsd=3;
	
var
	data_num:integer;
	
begin
	if app.apparatus_version='' then exit;
	writestr(f,f,eol);
	with app do begin
		writestr(f,f,apparatus_measurement_begin,eol);
		writestr(f,f,'calibration_type: ',calibration_type,eol);
		writestr(f,f,'apparatus_version: ',apparatus_version,eol);
		writestr(f,f,'measurement_time: ',measurement_time,eol);
		writestr(f,f,'operator_name: ',operator_name,eol);
		writestr(f,f,'data: ',eol);
		if (num_reals_used<1) or (num_reals_used>max_num_apparatus_reals) then 
			num_reals_used:=max_num_apparatus_reals;
		for data_num:=1 to num_reals_used do begin
			writestr(f,f,data[data_num]:fsr:fsd,' ');
			if (data_num=num_reals_used) or (data_num mod data_per_line=0) then 
				writestr(f,f,eol);
		end;
		writestr(f,f,apparatus_measurement_end);
	end;
end;

{
	bcam_camera_average calculates the average calibration constants from a sequence
	of bcam_camera_type records.
}
function bcam_camera_average(cp:pointer;num_calibs:integer):bcam_camera_type;

var
	calib_num:integer;
	calib_ptr:^bcam_camera_type;
	sum_calib:bcam_camera_type;
	
begin
	with sum_calib do begin
		pivot:=xyz_origin;
		axis:=xyz_origin;
		code:=0;
		ccd_to_pivot:=0;
		ccd_rotation:=0;
	end;
	for calib_num:=1 to num_calibs do begin
		calib_ptr:=pointer(integer(cp)+(calib_num-1)*sizeof(bcam_camera_type));
		with sum_calib do begin
			pivot.x:=pivot.x+calib_ptr^.pivot.x/num_calibs;
			pivot.y:=pivot.y+calib_ptr^.pivot.y/num_calibs;
			pivot.z:=pivot.z+calib_ptr^.pivot.z/num_calibs;
			axis.x:=axis.x+calib_ptr^.axis.x/num_calibs;
			axis.y:=axis.y+calib_ptr^.axis.y/num_calibs;
			axis.z:=axis.z+calib_ptr^.axis.z/num_calibs;
			code:=code+calib_ptr^.code/num_calibs;
			ccd_to_pivot:=ccd_to_pivot+calib_ptr^.ccd_to_pivot/num_calibs;
			ccd_rotation:=ccd_rotation+calib_ptr^.ccd_rotation/num_calibs;
		end;
	end;
	sum_calib.id:='average';
	bcam_camera_average:=sum_calib;
end;

{
	bcam_camera_spread calculates the spread of each calibration constant from a sequence
	of bcam_camera_type records.
}
function bcam_camera_spread(cp:pointer;num_calibs:integer):bcam_camera_type;

var
	calib_num:integer;
	calib_ptr:^bcam_camera_type;
	max,min,spread:bcam_camera_type;
	
begin
	for calib_num:=1 to num_calibs do begin
		calib_ptr:=pointer(integer(cp)+(calib_num-1)*sizeof(bcam_camera_type));
		if calib_num=1 then begin
			max:=calib_ptr^;
			min:=calib_ptr^;
		end
		else begin
			with calib_ptr^ do begin
				if max.pivot.x<pivot.x then max.pivot.x:=pivot.x;
				if max.pivot.y<pivot.y then max.pivot.y:=pivot.y;
				if max.pivot.z<pivot.z then max.pivot.z:=pivot.z;
				if max.axis.x<axis.x then max.axis.x:=axis.x;
				if max.axis.y<axis.y then max.axis.y:=axis.y;
				if max.axis.z<axis.z then max.axis.z:=axis.z;
				if max.code<code then max.code:=code;
				if max.ccd_to_pivot<ccd_to_pivot then max.ccd_to_pivot:=ccd_to_pivot;
				if max.ccd_rotation<ccd_rotation then max.ccd_rotation:=ccd_rotation;
				if min.pivot.x>pivot.x then min.pivot.x:=pivot.x;
				if min.pivot.y>pivot.y then min.pivot.y:=pivot.y;
				if min.pivot.z>pivot.z then min.pivot.z:=pivot.z;
				if min.axis.x>axis.x then min.axis.x:=axis.x;
				if min.axis.y>axis.y then min.axis.y:=axis.y;
				if min.axis.z>axis.z then min.axis.z:=axis.z;
				if min.code>code then min.code:=code;
				if min.ccd_to_pivot>ccd_to_pivot then min.ccd_to_pivot:=ccd_to_pivot;
				if min.ccd_rotation>ccd_rotation then min.ccd_rotation:=ccd_rotation;
			end;
		end;
	end;
	with spread do begin
		pivot:=xyz_difference(max.pivot,min.pivot);
		axis:=xyz_difference(max.axis,min.axis);
		ccd_to_pivot:=max.ccd_to_pivot-min.ccd_to_pivot;
		ccd_rotation:=max.ccd_rotation-min.ccd_rotation;
	end;
	spread.id:='spread';
	bcam_camera_spread:=spread;
end;

{
	bcam_sources_average calculates the average calibration constants from a sequence
	of bcam_sources_type records.
}
function bcam_sources_average(cp:pointer;num_calibs:integer):bcam_sources_type;

var
	calib_num,source_num:integer;
	calib_ptr:^bcam_sources_type;
	sum_calib:bcam_sources_type;
	
begin
	for source_num:=1 to num_sources_per_pair do begin
		sum_calib.sources[source_num]:=xyz_origin;
	end;
	for calib_num:=1 to num_calibs do begin
		calib_ptr:=pointer(integer(cp)+(calib_num-1)*sizeof(bcam_sources_type));
		for source_num:=1 to num_sources_per_pair do begin
			sum_calib.sources[source_num]:=
				xyz_sum(sum_calib.sources[source_num],
					xyz_scale(calib_ptr^.sources[source_num],1/num_calibs));
		end;
	end;
	sum_calib.id:='average';
	bcam_sources_average:=sum_calib;
end;

{
	bcam_sources_spread calculates the spread of each calibration constant from a sequence
	of bcam_sources_type records.
}
function bcam_sources_spread(cp:pointer;num_calibs:integer):bcam_sources_type;

var
	calib_num,source_num:integer;
	calib_ptr:^bcam_sources_type;
	max,min,spread:bcam_sources_type;
	
begin
	for calib_num:=1 to num_calibs do begin
		calib_ptr:=pointer(integer(cp)+(calib_num-1)*sizeof(bcam_sources_type));
		if calib_num=1 then begin
			max:=calib_ptr^;
			min:=calib_ptr^;
		end
		else begin
			for source_num:=1 to num_sources_per_pair do begin
				with calib_ptr^ .sources[source_num] do begin
					if max.sources[source_num].x<x then max.sources[source_num].x:=x;
					if max.sources[source_num].y<y then max.sources[source_num].y:=y;
					if max.sources[source_num].z<z then max.sources[source_num].z:=z;
					if min.sources[source_num].x>x then min.sources[source_num].x:=x;
					if min.sources[source_num].y>y then min.sources[source_num].y:=y;
					if min.sources[source_num].z>z then min.sources[source_num].z:=z;
				end;
			end;
		end;
	end;
	with spread do begin
		for source_num:=1 to num_sources_per_pair do begin
			spread.sources[source_num]:=
				xyz_difference(max.sources[source_num],min.sources[source_num]);
		end;
	end;
	spread.id:='spread';
	bcam_sources_spread:=spread;
end;

{
	bcam_origin returns the origin of the bcam coordinates for the specified mounting balls.
}
function bcam_origin(mount:kinematic_mount_type):xyz_point_type;

begin
	bcam_origin:=mount.cone;
end;

{
	bcam_coordinates_from_mount takes the global coordintes of the camera mounting balls 
	and calculates the origin and axis unit vectors of the bcam coordinate system expressed in global 
	coordinates.
}
function bcam_coordinates_from_mount(mount:kinematic_mount_type):coordinates_type;
	
var
	bcam:coordinates_type;
	cs,cp,cs_normal:xyz_point_type;
	
begin
	with bcam,mount do begin
{
	The unit vectors cs and cp define a plane. The normal to this plane
	is the y-axis of the bcam coordinate system, as defined by the cross
	product of cp with cs.
}
		cs:=xyz_unit_vector(xyz_difference(slot,cone));
		cp:=xyz_unit_vector(xyz_difference(plane,cone));
		y_axis:=xyz_unit_vector(xyz_cross_product(cp,cs));
{
	The orientation of the bcam camera around its y-axis is set by the slot 
	and cone. We create the z-axis of the bcam system by rotating sc
	by z_angle about the y-axis. The resulting z-axis lies parallel to the 
	nominal optical axis of the camera. To perform the rotation, we define 
	cs_normal using cs and y_axis.
}
		cs_normal:=xyz_unit_vector(xyz_cross_product(cs,y_axis));
		z_axis:=
			xyz_unit_vector(
				xyz_sum(
					xyz_scale(cs,-cos(bcam_z_angle)),
					xyz_scale(cs_normal,-sin(bcam_z_angle))));
{
	The x-axis is the cross product of the y and z axes respectively.
}
		x_axis:=xyz_unit_vector(xyz_cross_product(y_axis,z_axis));
{
	We place the origin with the bcam_origin routine.
}
		origin:=bcam_origin(mount);
	end;
	bcam_coordinates_from_mount:=bcam;
end;

{
	bcam_jk_coordinates_from_mount takes the global coordintes of three pins and
	returns the mount coordinates for a j_plate or k_plate, which are based upon
	the top front corner of the plate that is nearest the sources. The y-axis
	goes across the top-front edge of the plate. The x-axis goes forwards. In
	the j_plate the z-axis is down. In the k_plate the z-axis is up. To form the
	coordinate system, we take three pin centers and their diameters and
	calculate the location of the front corner of the jk plate, and unit vectors
	for its local coordinate axes. We take account of the type of plate to
	establish the directions of the coordinates. The J plate z-axis is
	downwards, while the K plate's is upwards.
}
function bcam_jk_coordinates_from_mount(mount:bcam_jk_mount_type):coordinates_type;

var	
	top:xyz_line_type;
	side:xyz_point_type;
	c:coordinates_type;
	
begin
	with mount do begin
		top.point:=pin1;
		top.direction:=xyz_difference(pin1,pin2);
		side:=xyz_point_line_vector(pin3,top);
		c.origin:=xyz_sum(pin3,side);
		c.origin:=xyz_sum(c.origin,xyz_scale(xyz_unit_vector(top.direction),diameter/2));
		c.origin:=xyz_sum(c.origin,xyz_scale(xyz_unit_vector(side),-diameter/2));
		c.y_axis:=xyz_unit_vector(top.direction);
		c.z_axis:=xyz_unit_vector(side);
		if plate_type='j_plate' then c.z_axis:=xyz_scale(c.z_axis,-1);
		c.x_axis:=xyz_cross_product(c.y_axis,c.z_axis);
	end;
	bcam_jk_coordinates_from_mount:=c;
end;

{
	bcam_from_global_vector converts a direction in global coordinates into a 
	direction in bcam coordinates.
}
function bcam_from_global_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;

var
	M:xyz_matrix_type;
	bcam:coordinates_type;
	
begin
	bcam:=bcam_coordinates_from_mount(mount);
	M:=xyz_matrix_from_points(bcam.x_axis,bcam.y_axis,bcam.z_axis);
	bcam_from_global_vector:=xyz_transform(M,p);
end;

{
	bcam_from_global_point converts a point in global coordinates into a point
	in bcam coordinates.
}
function bcam_from_global_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;

begin
	bcam_from_global_point:=bcam_from_global_vector(xyz_difference(p,bcam_origin(mount)),mount);
end;

{
	bcam_from_global_z calculates the z-position of a source in bcam coordinates 
	given its z-position in global coordinates. The routine assumes that the source is on 
	the global z-axis. 
}
function bcam_from_global_z(z:real;mount:kinematic_mount_type):real;

var
	p,q:xyz_point_type;
	
begin
	p.x:=0;
	p.y:=0;
	p.z:=z;
	q:=bcam_from_global_point(p,mount);
	bcam_from_global_z:=q.z;
end;

{
	global_from_bcam_vector converts a direction in bcam coordinates into a 
	direction in global coordinates.
}
function global_from_bcam_vector(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;
var bc:coordinates_type;	
begin
	bc:=bcam_coordinates_from_mount(mount);
	global_from_bcam_vector:=
<<<<<<< HEAD
		xyz_transform(xyz_matrix_inverse(xyz_matrix_from_points(bc.x_axis,bc.y_axis,bc.z_axis)),p);
=======
		xyz_transform(
			xyz_matrix_inverse(
				xyz_matrix_from_points(bc.x_axis,bc.y_axis,bc.z_axis)),
			p);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
end;

{
	global_from_bcam_point converts a point in bcam coordinates into a point
	in global coordinates.
}
function global_from_bcam_point(p:xyz_point_type;mount:kinematic_mount_type):xyz_point_type;

begin
	global_from_bcam_point:=xyz_sum(bcam_origin(mount),global_from_bcam_vector(p,mount));
end;

{
	global_from_bcam_line converts a bearing (point and direction) in bcam coordinates into
	a bearing in global coordinates.
}
function global_from_bcam_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;

var
	gb:xyz_line_type;
	
begin
	gb.point:=global_from_bcam_point(b.point,mount);
	gb.direction:=global_from_bcam_vector(b.direction,mount);
	global_from_bcam_line:=gb;
end;

{
	bcam_from_global_line does the opposite of global_from_bcam_line
}
function bcam_from_global_line(b:xyz_line_type;mount:kinematic_mount_type):xyz_line_type;

var
	bb:xyz_line_type;
	
begin
	bb.point:=bcam_from_global_point(b.point,mount);
	bb.direction:=bcam_from_global_vector(b.direction,mount);
	bcam_from_global_line:=bb;
end;

{
	global_from_bcam_plane converts a bearing (point and direction) in bcam coordinates into
	a bearing in global coordinates.
}
function global_from_bcam_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;

var
	gp:xyz_plane_type;
	
begin
	gp.point:=global_from_bcam_point(p.point,mount);
	gp.normal:=global_from_bcam_vector(p.normal,mount);
	global_from_bcam_plane:=gp;
end;

{
	bcam_from_global_plane does the opposite of global_from_bcam_plane
}
function bcam_from_global_plane(p:xyz_plane_type;mount:kinematic_mount_type):xyz_plane_type;

var
	bp:xyz_plane_type;
	
begin
	bp.point:=bcam_from_global_point(p.point,mount);
	bp.normal:=bcam_from_global_vector(p.normal,mount);
	bcam_from_global_plane:=bp;
end;

{
	bcam_ccd_center calculates the bcam coordinates of the ccd center.
}
function bcam_ccd_center(camera:bcam_camera_type):xyz_point_type;
begin
	with camera do 
		bcam_ccd_center:=xyz_sum(pivot,xyz_scale(axis,-ccd_to_pivot));
end;

{
	bcam_from_image_point converts a point on the ccd into a point in bcam coordinates. 
	The calculation takes account of the orientation of the ccd in the camera.
}
function bcam_from_image_point(p:xy_point_type;camera:bcam_camera_type):xyz_point_type;

var
	q:xy_point_type;
	r:xyz_point_type;
	cc:xyz_point_type;
	
begin
	cc:=bcam_ccd_center(camera);
	with camera do begin
		if code=bcam_icx424_code then begin
			q.x:=p.x-bcam_icx424_center_x;
			q.y:=p.y-bcam_icx424_center_y;
		end else begin
			q.x:=p.x-bcam_tc255_center_x;
			q.y:=p.y-bcam_tc255_center_y;
		end;
		if axis.z>0 then begin
			r.x:=cc.x+q.x*cos(ccd_rotation)-q.y*sin(ccd_rotation);
			r.y:=cc.y+q.y*cos(ccd_rotation)+q.x*sin(ccd_rotation);
		end else begin
			r.x:=cc.x-q.x*cos(ccd_rotation)+q.y*sin(ccd_rotation);
			r.y:=cc.y+q.y*cos(ccd_rotation)+q.x*sin(ccd_rotation);
		end;
		r.z:=cc.z;
	end;
	bcam_from_image_point:=r;
end;

{
	image_from_bcam_point does the opposite of bcam_from_image_point. It assumes that 
	the z-coordinate of the bcam point is in the ccd.
}
function image_from_bcam_point(p:xyz_point_type;camera:bcam_camera_type):xy_point_type;

var
	q,r,ic:xy_point_type;
	cc:xyz_point_type;
	
begin
	cc:=bcam_ccd_center(camera);
	with camera do begin
		r.x:=p.x-cc.x;
		r.y:=p.y-cc.y;
		if code=bcam_icx424_code then begin
			ic.x:=bcam_icx424_center_x;
			ic.y:=bcam_icx424_center_y;
		end else begin
			ic.x:=bcam_tc255_center_x;
			ic.y:=bcam_tc255_center_y;
		end;
		if axis.z>0 then begin
			q.x:=ic.x+r.x*cos(ccd_rotation)+r.y*sin(ccd_rotation);
			q.y:=ic.y+r.y*cos(ccd_rotation)-r.x*sin(ccd_rotation);
		end else begin
			q.x:=ic.x-r.x*cos(ccd_rotation)+r.y*sin(ccd_rotation);
			q.y:=ic.y+r.y*cos(ccd_rotation)+r.x*sin(ccd_rotation);
		end;
	end;
	image_from_bcam_point:=q;
end;

{
	bcam_source_bearing takes the position of a light spot on the ccd, and returns the pivot point
	and the direction of the source from the pivot point in bcam coordinates.
}
function bcam_source_bearing
	(spot_center:xy_point_type;camera:bcam_camera_type):xyz_line_type;

var
	bearing:xyz_line_type;
	image:xyz_point_type;
	
begin
	image:=bcam_from_image_point(spot_center,camera);
	bearing.point:=camera.pivot;
	bearing.direction:=xyz_unit_vector(xyz_difference(camera.pivot,image));
	bcam_source_bearing:=bearing;
end;

{
	bcam_source_position returns the bcam coordinates of a source, 
	given its bcam z-coordinate, its image center, and the camera
	calibration constants.
}
function bcam_source_position(spot_center:xy_point_type;
	range:real;camera:bcam_camera_type):xyz_point_type;

begin
	bcam_source_position:=
		xyz_line_plane_intersection(
			bcam_source_bearing(spot_center,camera),
			xyz_z_plane(range));
end;

{
	bcam_image_position takes the position of a source in bcam coordiates and returns the 
	position of the center of its image (the spot) on the ccd.
}
function bcam_image_position(source_position:xyz_point_type;
	camera:bcam_camera_type):xy_point_type;

var
	bearing:xyz_line_type;
	cc:xyz_point_type;
	
begin
	cc:=bcam_ccd_center(camera);
	bearing.point:=camera.pivot;
	bearing.direction:=
		xyz_unit_vector(
			xyz_difference(camera.pivot,source_position));
	bcam_image_position:=
		image_from_bcam_point(
			xyz_line_plane_intersection(
				bearing,
				xyz_z_plane(cc.z)),
			camera);
end;

{
	global_from_calib_datum takes a calib_datum_type and calculates the position of
	the source in global coordinates.
}
function global_from_calib_datum(p:calib_datum_type;
	camera:bcam_camera_type;
	mount:kinematic_mount_type):xyz_point_type;

begin
	global_from_calib_datum:=
		xyz_line_plane_intersection(
			global_from_bcam_line(bcam_source_bearing(p.spot_center,camera),mount),
			xyz_z_plane(p.source_range));
end;

{
	ccd_image_of_bcam_source takes a point in bcam coordinates and calculates 
	the theoretical position of its image on the ccd in image coordinates.
}
function ccd_image_of_bcam_source(p:xyz_point_type;
	camera:bcam_camera_type):xy_point_type;

var
	line:xyz_line_type;
	plane:xyz_plane_type;
	cc:xyz_point_type;

begin
	line.point:=camera.pivot;
	line.direction:=xyz_difference(p,line.point);
	cc:=bcam_ccd_center(camera);
	plane:=xyz_z_plane(cc.z);
	ccd_image_of_bcam_source:=
		image_from_bcam_point(
			xyz_line_plane_intersection(line,plane),
			camera);
end;

{
	global_offset_vector returns the vector in global coordinates that 
	joins the bcam axis to the source specified by the calib_datum_type.  
}
function global_offset_vector(p:calib_datum_type;
	camera:bcam_camera_type;
	mount:kinematic_mount_type):xyz_point_type;

var
	source_point,axis_point:xyz_point_type;
	axis_data_point:calib_datum_type;

begin
	source_point:=global_from_calib_datum(p,camera,mount);
	with axis_data_point do begin
		if camera.code=bcam_icx424_code then begin
			spot_center.x:=bcam_icx424_center_x;
			spot_center.y:=bcam_icx424_center_y;
		end else begin
			spot_center.x:=bcam_tc255_center_x;
			spot_center.y:=bcam_tc255_center_y;
		end;
		source_range:=p.source_range;
	end;
	axis_point:=global_from_calib_datum(axis_data_point,camera,mount);
	global_offset_vector:=xyz_difference(source_point,axis_point);
end;

{
	nominal_bcam_camera returns a nominal bcam of the specified type.
}
function nominal_bcam_camera(device_type:short_string):bcam_camera_type;
var camera:bcam_camera_type;
begin
	camera:=bcam_camera_from_string('0 0 0 0 0 1 1 0');
	if (device_type = 'black_azimuthal_c') then 
		camera:=bcam_camera_from_string(bcam_black_azimuthal_c_nominal);
	if (device_type = 'blue_azimuthal_c') then 
		camera:=bcam_camera_from_string(bcam_blue_azimuthal_c_nominal);
	if (device_type = 'black_polar_fc') then 
		camera:=bcam_camera_from_string(bcam_black_polar_fc_nominal);
	if (device_type = 'black_polar_rc') then 
		camera:=bcam_camera_from_string(bcam_black_polar_rc_nominal);
	if (device_type = 'blue_polar_fc') then 
		camera:=bcam_camera_from_string(bcam_blue_polar_fc_nominal);
	if (device_type = 'blue_polar_rc') then 
		camera:=bcam_camera_from_string(bcam_blue_polar_rc_nominal);
	if (device_type = 'black_h_fc') then 
		camera:=bcam_camera_from_string(bcam_black_h_fc_nominal);
	if (device_type = 'black_h_rc') then 
		camera:=bcam_camera_from_string(bcam_black_h_rc_nominal);
	if (device_type = 'blue_h_fc') then 
		camera:=bcam_camera_from_string(bcam_blue_h_fc_nominal);
	if (device_type = 'blue_h_rc') then 
		camera:=bcam_camera_from_string(bcam_blue_h_rc_nominal);
	nominal_bcam_camera:=camera;
end;

{
	bcam_camera_pair_calib_input_type is a special data structure for use with
	bcam_pair_calib.
}
type
	source_locations_type=array [1..num_sources_per_range] of xy_point_type;
	bcam_camera_pair_calib_input_type=record
		mounts:array [1..num_mounts_per_pair] of kinematic_mount_type;
		measurements:
			array [1..num_mounts_per_pair,1..num_ranges_per_mount,1..num_sources_per_range] 
			of calib_datum_type;
		source_locations:source_locations_type;
		id,device_type:short_string;{identifier}
		axis_direction:real;
	end;

{
	bcam_pair_calib takes the measurements made in two positions of a calibration
	roll cage, which consist of the locations of the images of the four sources on
	the source block at two ranges for each of the two roll cage positions, and 
	calculates from these the bcam calibration constants. The input data are complex
	enough that we create a special data structure for the calculation, which we
	define above.
}
function bcam_pair_calib(calib_data:bcam_camera_pair_calib_input_type):bcam_camera_type;

const
	close_range_num=1;
	far_range_num=2;
	first_mount_num=1;
	second_mount_num=2;
	show_details=false;
	fsn=20;
	fsd=6;
	
var
	offsets:array [1..num_mounts_per_pair,1..num_ranges_per_mount,1..num_sources_per_range] 
		of xyz_point_type;
	mount_num,source_num,second_source_num,range_num,count:integer;
	calibration:bcam_camera_type;
	divergance_global,camera_axis,zero_pivot:xyz_point_type;
	r,s:xy_point_type;
	p,q,pivot_sum,axis_sum,xyz_datum:xyz_point_type;
	line:xyz_line_type;
	plane:xyz_plane_type;
	far_range,close_range,sum,datum,cos_sum,sin_sum,ns,fs:real;
	M_1,M_2,M,N:xyz_matrix_type;
	bc_1,bc_2:coordinates_type;
	
begin
	with calib_data do begin
{
	Set the bcam calibration to some initial values.
}
		calibration:=nominal_bcam_camera(device_type);
		calibration.id:=calib_data.id;
{
	Calculate the z-position of the pivot point.
}
		with calibration do begin
			if show_details then gui_writeln('pivot.z');
			sum:=0;
			count:=0;
			for mount_num:=1 to num_mounts_per_pair do begin
				for source_num:=1 to num_sources_per_range-1 do begin
					for second_source_num:=source_num+1 to num_sources_per_range do begin
						ns:=xy_separation(
							measurements[mount_num,close_range_num,source_num].spot_center,
							measurements[mount_num,close_range_num,second_source_num].spot_center);
						fs:=xy_separation(
							measurements[mount_num,far_range_num,source_num].spot_center,
							measurements[mount_num,far_range_num,second_source_num].spot_center);
						datum:=
							bcam_from_global_z(
								measurements[mount_num,close_range_num,source_num].source_range-
									(measurements[mount_num,far_range_num,source_num].source_range
									-measurements[mount_num,close_range_num,source_num].source_range)
										/(ns/fs-1),
								mounts[mount_num]);
						sum:=sum+datum;
						inc(count);
						if show_details then begin 
							writestr(debug_string,id,mount_num:fsd,source_num:fsd,
								second_source_num:fsd,
								ns:fsn:fsd,
								fs:fsn:fsd,
								datum:fsn:fsd);
							gui_writeln(debug_string);
						end;
					end;
				end;
			end;
			pivot.z:=sum/count;
			if show_details then begin
				writestr(debug_string,sum/count:fsn:fsd);
				gui_writeln(debug_string);
			end;
		end;
{
	Calculate ccd to pivot distance. We use the value of pivot.z we
	obtained in the previous stage, even though the value we obtained is
	less accurate than the value we obtain from our drawings. The reason
	we use the calculated pivot.z is because it appears to express the
	errors in the calibration images. Our calibration of the ccd-pivot
	distance will be accurate despite these errors so long as we use our
	calculated pivot.z. We found this out by measuring the ccd-pivot and
	pivot.z directly on a 2-m granite beam with a ruler and a pair of
	sources. The pivot.z calculated in the previous stage was incorrect by
	2 mm, but if we used the correct value when calculating ccd-pivot, we
	obtained the wrong value for ccd-pivot. When we used our calculated
	pivot.z, however, we obtained a ccd-pivot distance accurate to better
	than 0.1%.
}
		with calibration do begin
			if show_details then gui_writeln('ccd_to_pivot');
			sum:=0;
			count:=0;
			for mount_num:=1 to num_mounts_per_pair do begin
				for range_num:=1 to 1 {num_ranges_per_mount} do begin
					for source_num:=1 to num_sources_per_range-1 do begin
						for second_source_num:=source_num+1 to num_sources_per_range do begin
							datum:=axis.z*
								(bcam_from_global_z(
									measurements[mount_num,range_num,source_num].source_range,
									mounts[mount_num])
								-pivot.z)
								*xy_separation(measurements[mount_num,range_num,source_num].spot_center,
									measurements[mount_num,range_num,second_source_num].spot_center)
								/xy_separation(source_locations[source_num],
									source_locations[second_source_num]);
							sum:=sum+datum;
							inc(count);
							if show_details then begin
								writestr(debug_string,id,mount_num:fsd,range_num:fsd,
									source_num:fsd,second_source_num:fsd,datum:fsn:fsd);
								gui_writeln(debug_string);
							end;
						end;
					end;
				end;
			end;
			ccd_to_pivot:=sum/count;
			if show_details then begin
				writestr(debug_string,sum/count:fsn:fsd);
				gui_writeln(debug_string);
			end;
		end;
{
	Calculate rotation of CCD
}
		with calibration do begin
			if show_details then gui_writeln('ccd_rotation');
			sin_sum:=0;
			cos_sum:=0;
			count:=0;
			for mount_num:=1 to num_mounts_per_pair do begin
				for range_num:=1 to num_ranges_per_mount do begin
					for source_num:=1 to num_sources_per_range-1 do begin
						for second_source_num:=source_num+1 to num_sources_per_range do begin
							p:=xyz_unit_vector(
									xyz_difference(
										global_from_calib_datum(
											measurements[mount_num,range_num,second_source_num],
											calibration,mounts[mount_num]),
										global_from_calib_datum(
											measurements[mount_num,range_num,source_num],
											calibration,mounts[mount_num])));
							r:=xy_unit_vector(
									xy_difference(
										source_locations[second_source_num],
										source_locations[source_num]));
							datum:=calibration.ccd_rotation
								-full_arctan(p.y,p.x)+full_arctan(r.y,r.x);
							cos_sum:=cos_sum+cos(datum);
							sin_sum:=sin_sum+sin(datum);
							inc(count);
							if show_details then begin
								writestr(debug_string,id,mount_num:fsd,range_num:fsd,
									source_num:fsd,second_source_num:fsd,datum:fsn:fsd);
								gui_writeln(debug_string);
							end;
						end;
					end;
				end;
			end;
			ccd_rotation:=full_arctan(sin_sum/count,cos_sum/count);
			if (ccd_rotation < -pi/2) then ccd_rotation:=ccd_rotation+2*pi;
			if show_details then begin
				writestr(debug_string,ccd_rotation:fsn:fsd);
				gui_writeln(debug_string);
			end;
		end;
{
	Calculate the offset vectors in global coordinates that join the bcam axis to
	each source at each range in each mount. When we calculate these offsets, we use
	the nominal values of the pivot point position and the axis bearing. We use then
	use these offsets to calculate the actual pivot and axis.
}
		for mount_num:=1 to num_mounts_per_pair do begin
			for range_num:=1 to num_ranges_per_mount do begin
				for source_num:=1 to num_sources_per_range do begin
					offsets[mount_num,range_num,source_num]:=
						global_offset_vector(
							measurements[mount_num,range_num,source_num],
							calibration,
							mounts[mount_num]);
				end;
			end;
		end;
{
	Calculate the pivot x and y coordinates, and the axis x and y components. We will use
	the offsets extensively in this calculation.
}
		count:=0;
		axis_sum:=xyz_origin;
		pivot_sum:=xyz_origin;
		if show_details then gui_writeln('axis and pivot');
		for source_num:=1 to num_sources_per_range do begin
{
	We need to know how far the source is from the pivot point. We assume that
	the range of the source is the same for both mounts, which is to say we
	assume that the two camera mounts have their origins in the same z-plane.
}
			close_range:=
				bcam_from_global_z(
					measurements[first_mount_num,close_range_num,source_num].source_range,
					mounts[first_mount_num])
				-calibration.pivot.z;
			far_range:=
				bcam_from_global_z(
					measurements[first_mount_num,far_range_num,source_num].source_range,
					mounts[first_mount_num])
				-calibration.pivot.z;
{
	With the camera on two different mounts, the lens center is in two
	positions, and the axis is in two orientations. We calculate the divergance
	of the second orientation with respect to the first orientation in global coordinates by examining the offsets we
	calculated above. We express the divergence as a vector whose z-component is
	1, so that the result is a unit vector in the direction of the divergance.
	This divergance is opposite to the divergance of the camera axes, so to obtain the 
	divergance of the axis in mount_1 from the axis in
	mount_2, we must multiply by -1, which we do at the same time we divide by
	the difference between the far and close ranges to obtain the divergance per
	unit length.
}
			divergance_global:=
				xyz_scale(
					xyz_difference(
						xyz_difference(
							offsets[second_mount_num,far_range_num,source_num],
							offsets[first_mount_num,far_range_num,source_num]),
						xyz_difference(
							offsets[second_mount_num,close_range_num,source_num],
							offsets[first_mount_num,close_range_num,source_num])),
					-1/(far_range-close_range));
			divergance_global.z:=1; 
{
	Now we transform this divergance vector into bcam coordinates. We start by
	constructing the rotation matrices that transform from global to local
	coordinates. These matrices are the unit vectors of the local coordinate
	axes. We call them M_1 and M_2. A point vector v in global coordinates
	appears as M_1.v in the coordinates of the first mount, and M_2.v in the
	coordinates of the second mount.
}
			bc_1:=bcam_coordinates_from_mount(mounts[first_mount_num]);
			bc_2:=bcam_coordinates_from_mount(mounts[second_mount_num]);
			with bc_1 do M_1:=xyz_matrix_from_points(x_axis,y_axis,z_axis);
			with bc_2 do M_2:=xyz_matrix_from_points(x_axis,y_axis,z_axis);
{
	The axis bearing, v, is the same in both mount coordinates. If we denote its
	appearance in global coordinates as v_1 when in the first mount and v_2 when
	in the second mount, then we see that v_1 = inverse(M_1).v and v_2 =
	inverse(M_2).v. Thus the difference divergance of v_2 with respect to
	v_1 is = v_2 - v_1 = (inverse(M_2) - inverse(M_1)).v = M.v.
}
			M:=xyz_matrix_difference(xyz_matrix_inverse(M_2),xyz_matrix_inverse(M_1));
{
	The matrix M is not invertible, although a two-dimensional subset of M is
	invertible. In two dimensions, each vector undergoes a unique change during
	rotation. But in three dimensions, all vectors with the same components
	perpendicular to the axis of rotation will change by the same amount. Only
	if we fix the component of a vector in the direction of rotation. The rows
	of M are the difference between the bcam-coordinate versions of the global
	axes. Because the z-axis of both bcam coordinates is almost exactly parallel
	to the global z-axis, the difference between the global z-axis as seen by
	both bcam coordinates is close to zero. In order for M to be invertible, we
	must set M[3,3] to 1. The elements M[3,1] and M[3,2] tell us how the z-axis
	of the second mount diverges from the z-axis of the first mount, so these
	are important.
}
			M[3,3]:=1;
{
	We invert M to obtain the "coupling matrix", N, and we transform our global
	divergance vector with the coupling matrix to produce a vector in bcam
	coordinates that represents the divergance of the camera axis from the bcam
	z-axis. The first two columns of the coupling matrix operate upon the small
	x and y components of our global divergance, so as to produce the x and y
	components that our camera axis would have to have if our two bcam
	coordinate z axese were exactly parallel. The third column of the coupling
	matrix, meanwhile, interacts with the unit length of our global divergance
	so as to subtract an offset from the camera axis we obtain from only the
	first two columns. This offset is x and y components of the camera axis that
	we would obtain if we had a camera axis exactly parallel to the bcam z-axis,
	but ignored the difference between the global direction of the second
	mount's z-axis compared to the first mounts. The result is a vector in bcam
	coordinates that is parallel to the camera axis.
}
			N:=xyz_matrix_inverse(M);
			xyz_datum:=xyz_transform(N,divergance_global);
{
	Some cameras have axes that are opposite to the bcam z-axis, and we must account
	for these by looking at the sign of the z-axis. Also, we are going to ignore the
	z-component of our axis vector, so we set it to zero now.
}
			if calibration.axis.z<0 then xyz_datum:=xyz_scale(xyz_datum,-1);
			xyz_datum.z:=0;
{
	We add our axis divergance to a sum.
}
			axis_sum:=xyz_sum(axis_sum,xyz_datum);
			if show_details then begin
				writestr(debug_string,id,source_num:fsd,xyz_datum.x:fsn:fsd,xyz_datum.y:fsn:fsd);
				gui_writeln(debug_string);
			end;
{
	We now determine the vector between the first and second pivot positions. We
	start by subtracting the offset of the source in the second mount from the
	offset of the source in the first mount, which gives us the offset of the 
	second axis from the first axis in global coordinates at the close_range.
}
			xyz_datum:=xyz_difference(
				offsets[first_mount_num,close_range_num,source_num],
				offsets[second_mount_num,close_range_num,source_num]);

{
	We determine the offset at range zero by subtracting divergance of the two
	axes along the length close_range. We set the z-component of
	divergance_global to zero so as to isolate the x and y components for
	scaling. 
}
			divergance_global.z:=0;
			xyz_datum:=xyz_difference(
				xyz_datum,
				xyz_scale(divergance_global,close_range));
{	
	We now have a vector in global coordinates from the first pivot position to
	the second. We assume that both pivot positions are in the same global
	z-plane. Some of this vector is due to the movement of the bcam z-axis
	between mount positions. We know the local z-coordinate of the pivot point,
	so we can determine the movement of the pivot point that is due only to the
	movement of the mount, subtract this from the movement we observe, and so
	obtain the movement that is due to the pivot point being off the z-axis.
}
			with zero_pivot do begin x:=0; y:=0; z:=calibration.pivot.z; end;
			xyz_datum:=xyz_difference(xyz_datum,
				xyz_difference(
					global_from_bcam_point(zero_pivot,mounts[second_mount_num]),
					global_from_bcam_point(zero_pivot,mounts[first_mount_num])));
{
	We now have the change in pivot position that would occur due to rotation
	only from the first mount to the second. The z-component of this change
	should be zero. We set it to zero just to be sure. We apply the coupling
	matrix to obtain the location of the pivot point. Because the z component of
	the change is zero, we will be sure not to involve the change in the
	orientation of the bcam z-axis in our calculation of the pivot location.
}
			xyz_datum.z:=0;
			xyz_datum:=xyz_transform(N,xyz_datum);
{
	We add our new estimate of pivot position to our sum.
}
			pivot_sum:=xyz_sum(pivot_sum,xyz_datum);
			if show_details then begin
				writestr(debug_string,xyz_datum.x:fsn:fsd,xyz_datum.y:fsn:fsd);
				gui_writeln(debug_string);
			end;
{
	Done with this run through the loop so increment the data counter.
}
			inc(count);
		end;
		with calibration do begin
			pivot.x:=pivot_sum.x/count;
			pivot.y:=pivot_sum.y/count;
			axis.x:=axis_sum.x/count;
			axis.y:=axis_sum.y/count;
			if show_details then begin
				debug_string:=string_from_xyz(pivot);gui_writeln(debug_string);
				debug_string:=string_from_xyz(axis);gui_writeln(debug_string);
			end;
		end;
	end;
{
	Done.
}
	bcam_pair_calib:=calibration;
end;

{
	bcam_camera_calib takes all the image positions recorded during a four-position
	roll-cage calibration of a bcam camera, combined with the global ball positions
	of the camera mount, and range and rotation measurements for the roll cage base 
	with respect to the source block, and the locations of the sources within the source
	block, and calculates six sets of calibration constants for the camera, as well as
	the average values of these constants.
}
function bcam_camera_calib(calib:device_calibration_type;
	app:apparatus_measurement_type;
	verbose,check:boolean):short_string;

type
	input_type=record
		mounts:array [1..num_mounts_per_quad] of kinematic_mount_type;
		measurements:array [1..num_mounts_per_quad,1..num_ranges_per_mount,1..num_sources_per_range] 
			of calib_datum_type;
		source_locations:source_locations_type;
		id,time,device_type:short_string;
		axis_direction:real;
	end;

var
	calib_input:input_type;
	calib_output:bcam_camera_calib_type;
	pair_data:bcam_camera_pair_calib_input_type;
	mount_num,second_mount_num,source_num,range_num:integer;
	pair_num,app_data_num,calib_data_num:integer;
	r:real;
	result:short_string='';
	p:xyz_point_type;
	
	function next_calib_real:real;
	begin 
		inc(calib_data_num);
		if calib_data_num>calib.num_reals_used then next_calib_real:=0
		else next_calib_real:=calib.data[calib_data_num];
	end;

	function next_app_real:real;
	begin 
		inc(app_data_num);
		if app_data_num>app.num_reals_used then next_app_real:=0
		else next_app_real:=app.data[app_data_num];
	end;
	
begin
{
	Compose the data structure required by our calculation.
}
	app_data_num:=0;
	calib_data_num:=0;
	with calib_input do begin
		id:=calib.device_id;
		time:=calib.calibration_time;
		device_type:=calib.calibration_type;
		for mount_num:=1 to num_mounts_per_quad do begin
			with mounts[mount_num] do begin
				with cone do begin
					x:=next_app_real;y:=next_app_real;z:=next_app_real;
				end;
				with slot do begin
					x:=next_app_real;y:=next_app_real;z:=next_app_real;
				end;
				with plane do begin
					x:=next_app_real;y:=next_app_real;z:=next_app_real;
				end;
			end;
		end;
		for range_num:=1 to num_ranges_per_mount do begin
			r:=next_app_real;
			for mount_num:=1 to num_mounts_per_quad do begin
				for source_num:=1 to num_sources_per_range do begin
					measurements[mount_num,range_num,source_num].source_range:=r;
				end;
			end;
		end;
		for source_num:=1 to num_sources_per_range do begin
			with source_locations[source_num] do begin
				x:=next_app_real;y:=next_app_real;
			end;
		end;
		axis_direction:=next_app_real;
		for range_num:=1 to num_ranges_per_mount do begin
			for mount_num:=1 to num_mounts_per_quad do begin
				for source_num:=1 to num_sources_per_range do begin
					with measurements[mount_num,range_num,source_num].spot_center do begin
						x:=next_calib_real/um_per_mm;
						y:=next_calib_real/um_per_mm;
					end;
				end;
			end;
		end;
	end;
{
	Apply apparatus description and camera name to pair data.
}
	pair_data.source_locations:=calib_input.source_locations;
	pair_data.axis_direction:=calib_input.axis_direction;
	pair_data.device_type:=calib_input.device_type;
{
	Construct all possible bcam_camera_pair_calib_input_types for bcam_pair_calib and
	calculate calibration. 
}
	pair_num:=1;
	for mount_num:=1 to num_mounts_per_quad-1 do begin
		for second_mount_num:=mount_num+1 to num_mounts_per_quad do begin
			writestr(pair_data.id,mount_num:1,'_',second_mount_num:1);
			pair_data.mounts[1]:=calib_input.mounts[mount_num];
			pair_data.mounts[2]:=calib_input.mounts[second_mount_num];
			for range_num:=1 to num_ranges_per_mount do begin
				for source_num:=1 to num_sources_per_range do begin
					pair_data.measurements[1,range_num,source_num]:=
						calib_input.measurements[mount_num,range_num,source_num];
				end;
			end;
			for range_num:=1 to num_ranges_per_mount do begin
				for source_num:=1 to num_sources_per_range do begin
					pair_data.measurements[2,range_num,source_num]:=
						calib_input.measurements[second_mount_num,range_num,source_num];
				end;
			end;
			calib_output.pairs[pair_num]:=bcam_pair_calib(pair_data);
			inc(pair_num);
		end;
	end;
{
	Calculate spread and average parameters.
}
	with calib_output do begin
		average:=bcam_camera_average(@calib_output.pairs,num_roll_cage_pairs);
		spread:=bcam_camera_spread(@calib_output.pairs,num_roll_cage_pairs);
		id:=calib_input.id;
		time:=calib_input.time;
		device_type:=calib_input.device_type;
	end;
{
	Compose the result string.
}
	bcam_camera_calib:=string_from_camera_calib(calib_output,verbose,check);
end;

{
	bcam_sources_calib takes a roll-cage device calibration and apparatus
	measurement and calculates the locations of the bcam sources in bcam
	coordinates. It returns a string giving the source calibration constants.
	With verbose, the string is long and contains the result from all six pairs
	of roll cage orientations. With check, the string contains warnings if the
	source locations are inconsistent or out of range.
}
function bcam_sources_calib(calib:device_calibration_type;
	app:apparatus_measurement_type;
	verbose,check:boolean):short_string;

type
	input_type=record
		mounts:array [1..num_mounts_per_quad] of kinematic_mount_type;
		viewing_x_direction:real;
		viewing_scale:real;
		measurements:array [1..num_mounts_per_quad,1..num_sources_per_pair] 
			of calib_datum_type;
		id,time,device_type:short_string;
	end;

var
	result:short_string='';
	calib_input:input_type;
	calib_output:bcam_sources_calib_type;
	first_mount_num,second_mount_num,source_num,pair_num:integer;
	p,s,global_link:xyz_point_type;
	viewing_link,v:xy_point_type;
	mount_num,app_data_num,calib_data_num:integer;
	source_z:real;
	null_source:xyz_point_type;
	M_1,M_2,M,N:xyz_matrix_type;
	bc_1,bc_2:coordinates_type;
	
	function next_calib_real:real;
	begin 
		inc(calib_data_num);
		if calib_data_num>calib.num_reals_used then next_calib_real:=0
		else next_calib_real:=calib.data[calib_data_num];
	end;

	function next_app_real:real;
	begin 
		inc(app_data_num);
		if app_data_num>app.num_reals_used then next_app_real:=0
		else next_app_real:=app.data[app_data_num];
	end;

begin
{
	Compose a data structure form the input strings.
}
	app_data_num:=0;
	calib_data_num:=0;
	with calib_input do begin
		id:=calib.device_id;
		time:=calib.calibration_time;
		device_type:=calib.calibration_type;
		for mount_num:=1 to num_mounts_per_quad do begin
			with mounts[mount_num] do begin
				with cone do begin
					x:=next_app_real;y:=next_app_real;z:=next_app_real;
				end;
				with slot do begin
					x:=next_app_real;y:=next_app_real;z:=next_app_real;
				end;
				with plane do begin
					x:=next_app_real;y:=next_app_real;z:=next_app_real;
				end;
			end;
		end;
		viewing_x_direction:=next_app_real;
		viewing_scale:=next_app_real;
		source_z:=next_app_real;
		for mount_num:=1 to num_mounts_per_quad do begin
			for source_num:=1 to num_sources_per_pair do begin
				measurements[mount_num,source_num].source_range:=source_z;
			end;
		end;
		for mount_num:=1 to num_mounts_per_quad do begin
			for source_num:=1 to num_sources_per_pair do begin
				with measurements[mount_num,source_num].spot_center do begin
					x:=next_calib_real/um_per_mm;
					y:=next_calib_real/um_per_mm;
				end;
			end;
		end;
	end;
{
	Calculate source positions.
}
	with calib_input do begin
		pair_num:=1;
		calib_output.id:=id;
		for first_mount_num:=1 to num_mounts_per_quad-1 do begin
			for second_mount_num:=first_mount_num+1 to num_mounts_per_quad do begin
				for source_num:=1 to num_sources_per_pair do begin
					viewing_link:=xy_difference(
						measurements[second_mount_num,source_num].spot_center,
						measurements[first_mount_num,source_num].spot_center);
{
	Rotate viwing link to account for orientation of viewing camera wrt global x.
}
					v:=xy_rotate(viewing_link,-viewing_x_direction/mrad_per_rad);
{
	Negate y-component because positive y in image is negative y in global coords.
}
					v.y:=-v.y;
{
	Get actual translation from ccd translation.
}
					v:=xy_scale(v,viewing_scale);
{
	We now have the movement in global coordinates of the source on its way from the first
	mount to the second mount.
}
					with global_link do begin x:=v.x;y:=v.y;z:=0; end;
{
	If the source lay upon the z-axis of its own bcam mount, it would still move. We can calculate
	this movement and subtract it from our global_link to leave us with a global movement that is
	due only to the fact that the source does not lie upon the z-axis of its own bcam mount.
}
					with null_source do begin 
						x:=0; 
						y:=0; 
						z:=source_z; 
					end;
					global_link:=xyz_difference(
						global_link,
						xyz_difference(
							global_from_bcam_point(null_source,mounts[second_mount_num]),
							global_from_bcam_point(null_source,mounts[first_mount_num])));
{
	Now we convert the global link into the bcam coords of source position with the help of 
	the coupling matrix for the two mount positions. Look at the comments in
	bcam_pair_calib for a detailed explanation of the following manipulation.
}
					bc_1:=bcam_coordinates_from_mount(mounts[first_mount_num]);
					bc_2:=bcam_coordinates_from_mount(mounts[second_mount_num]);
					with bc_1 do M_1:=xyz_matrix_from_points(x_axis,y_axis,z_axis);
					with bc_2 do M_2:=xyz_matrix_from_points(x_axis,y_axis,z_axis);
					M:=xyz_matrix_difference(xyz_matrix_inverse(M_2),xyz_matrix_inverse(M_1));
					M[3,3]:=1;
					N:=xyz_matrix_inverse(M);
					p:=xyz_transform(N,global_link);
{
	We know the z-position of the source, so we specify it now.
}
					p.z:=source_z;
					calib_output.pairs[pair_num].sources[source_num]:=p;
				end;
				writestr(calib_output.pairs[pair_num].id,
					first_mount_num:1,'_',second_mount_num:1);
				inc(pair_num);
			end;
		end;
	end;
{
	Calculate spread and average parameters.
}
	with calib_output do begin
		average:=bcam_sources_average(@calib_output.pairs,num_roll_cage_pairs);
		spread:=bcam_sources_spread(@calib_output.pairs,num_roll_cage_pairs);
		id:=calib_input.id;
		time:=calib_input.time;
		device_type:=calib_input.device_type;
	end;
{
	Create the result string.
}
	bcam_sources_calib:=string_from_sources_calib(calib_output,verbose,check);
end;


{
	bcam_jk_calib take a j_plate or k_plate device calibration and its
	corresponding apparatus measurement and calculates the location of the left
	and right sources in the j_plate or k_plate coordiantes.
}
function bcam_jk_calib(calib:device_calibration_type;
	app:apparatus_measurement_type;
	verbose,check:boolean):short_string;

var
	calib_output:bcam_jk_calib_type;
	mounts:array [1..num_mounts_per_quad] of bcam_jk_mount_type;
	measurements:array [1..num_mounts_per_quad,1..num_sources_per_pair] of xy_point_type;
	scale,diameter,rotation,source_z:real;
	f,w:short_string='';
	first_mount_num,second_mount_num,source_num,pair_num:integer;
	app_data_num,calib_data_num:integer;
	r:real;
	global_link,p:xyz_point_type;
	v:xy_point_type;
	M_1,M_2,M,N:xyz_matrix_type;
	pc_1,pc_2:coordinates_type;
	i,j:integer;
	
	function next_calib_real:real;
	begin 
		inc(calib_data_num);
		if calib_data_num>calib.num_reals_used then next_calib_real:=0
		else next_calib_real:=calib.data[calib_data_num];
	end;

	function next_app_real:real;
	begin 
		inc(app_data_num);
		if app_data_num>app.num_reals_used then next_app_real:=0
		else next_app_real:=app.data[app_data_num];
	end;
	
begin
{
	Interpret apparatus measurement.
}
	app_data_num:=0;
	calib_data_num:=0;
	for first_mount_num:=1 to num_mounts_per_quad do begin
		with mounts[first_mount_num] do begin
			with pin1 do begin
				x:=next_app_real;y:=next_app_real;z:=0;
			end;
			with pin2 do begin
				x:=next_app_real;y:=next_app_real;z:=0;
			end;
			with pin3 do begin
				x:=next_app_real;y:=next_app_real;z:=0;
			end;
		end;
	end;
	scale:=next_app_real;
	rotation:=next_app_real/mrad_per_rad;
	diameter:=next_app_real;
	source_z:=next_app_real;
	for first_mount_num:=1 to num_mounts_per_quad do begin
		mounts[first_mount_num].diameter:=diameter;
		mounts[first_mount_num].plate_type:=calib.calibration_type;
	end;
{
	Interpret the device calibration.
}
	for first_mount_num:=1 to num_mounts_per_quad do begin
		for source_num:=1 to num_sources_per_pair do begin
			with measurements[first_mount_num,source_num] do begin
				x:=next_calib_real/um_per_mm;
				y:=next_calib_real/um_per_mm;
			end;
		end;
	end;
{
	Calculate source positions.
}
	pair_num:=1;
	for first_mount_num:=1 to num_mounts_per_quad-1 do begin
		for second_mount_num:=first_mount_num+1 to num_mounts_per_quad do begin
			for source_num:=1 to num_sources_per_pair do begin
{
	Calculate the movement of the image on the CCD, going from the first mount
	position to the second. Rotate this vector so as to account for the rotation
	of the CCD with respect to the roll cage. NOTE: WE HAVE NOT TESTED THE SIGN
	OF THE ROTATION IN THE CODE. After that we scale the rotated vector to get
	the movement of the source in global coordinates.
}
				v:=xy_difference(
					measurements[second_mount_num,source_num],
					measurements[first_mount_num,source_num]);
				v:=xy_rotate(v,-rotation);
				with global_link do begin
					x:=v.x*scale;
					y:=-v.y*scale;
					z:=0;
				end;
{
	We transform this global link into jk plate coordinates using a coupling matrix.
	See bcam_pair_calib for a detailed description of the coupling matrix calculation.
	One difference here is that the degenerate element in the matrix is M[3,1] because
	the jk_plate x-axis is parallel with the global z-axis.
}
				pc_1:=bcam_jk_coordinates_from_mount(mounts[first_mount_num]);
				pc_2:=bcam_jk_coordinates_from_mount(mounts[second_mount_num]);
				with pc_1 do M_1:=xyz_matrix_from_points(x_axis,y_axis,z_axis);
				with pc_2 do M_2:=xyz_matrix_from_points(x_axis,y_axis,z_axis);
				M:=xyz_matrix_difference(
					xyz_matrix_inverse(M_2),
					xyz_matrix_inverse(M_1));
				M[3,1]:=1;
				N:=xyz_matrix_inverse(M);
				p:=xyz_transform(N,
					xyz_difference(global_link,
						xyz_difference(pc_2.origin,pc_1.origin)));
{
	The point p is in plate coordinates, so it is our estimate of the source calibration.
}
				with calib_output.pairs[pair_num].sources[source_num] do begin
					x:=source_z;
					y:=p.y;
					z:=p.z;
				end;
			end;
			writestr(calib_output.pairs[pair_num].id,first_mount_num:1,'_',second_mount_num:1);
			inc(pair_num);
		end;
	end;
{
	Calculate spread and average parameters.
}
	with calib_output do begin
		average:=bcam_sources_average(@calib_output.pairs,num_roll_cage_pairs);
		spread:=bcam_sources_spread(@calib_output.pairs,num_roll_cage_pairs);
		id:=calib.device_id;
		time:=calib.calibration_time;
		device_type:=calib.calibration_type;
	end;
{
	Create the result string.
}
	bcam_jk_calib:=string_from_jk_calib(calib_output,verbose,check);
end;

end.

