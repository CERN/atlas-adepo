{<pre>}
program p;

{
	Wire Position Sensor Calibration Fitting Program
	Copyright (C) 2009 Kevan Hashemi, Open Source Instruments Inc.
	
	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the Free
	Software Foundation; either version 2 of the License, or (at your option)
	any later version.

	This program is distributed in the hope that it will be useful, but WITHOUT
	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
	FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
	more details.

	You should have received a copy of the GNU General Public License along with
	this program; if not, write to the Free Software Foundation, Inc., 59 Temple
	Place - Suite 330, Boston, MA  02111-1307, USA. calib_calc_4.pas calls
	routines in our wps.pas library to calculate the error in WPS measurement.
	It takes a set of WPS measurements and compares them to CMM measurements. It
	adjusts camera calibration constants until the root mean square camera error
	is close to a minimum. The program prints the CMM wire positions and the WPS
	three-dimensional error vector at the start of the fitting procedure. It
	prints the camera calibration constants and the rms error during the
	fitting. It prints the error vectors a second time at the end, and last of
	all calculates the ccd-pivot distance using the final parameters.

	At the end of the code are parameters we obtained with various sub-sets of
	the data, and by fitting various sub-sets of the parameters.

	Compile Instructions: Re-name this program p.pas and compile with "make p"
	in LWDAQ/Build. Adjust global constants and re-compile. Input data is
	embedded in the code. Output is to the terminal.

	VERSION NOTES: We add automatic reading of data from files, and automatic
	composure of the device name.
}

uses
	utils,bcam,wps;
	
const
	edge_direction=0;
	random_scale=1;
	num_parameters=9;
	max_num_shrinks=5;
	y_ref=1.220;{mm}
	max_num_points=100;
	
var
	num_points:integer;
	edge_str,wire_str,coord_str:long_string;
	wires:array [1..max_num_points] of wps_wire_type;
	edges:array [1..max_num_points] of wps_edge_type;

{
	Create a random disturbance scaled by random_scale.
}
function disturb:real;
begin
	disturb:=random_scale*(random_0_to_1-0.5);
end;

{
	We obtain the calibration error by comparing each wire position to the line
	implied by each image. We use the camera calibration constants to generate
	the lines from the images. We involve the rotation of the wire images in the
	error calculation by generating two lines for each wire image: one from a
	point in the image towards the top of the CCD and another from a point
	towards the bottom of the CCD. The y_shift parameter tells us how much to
	move up and down the image to choose the two points.
}
function error(v:simplex_vertex_type):real;
const
	y_shift=0.500;{mm}
var
	i:integer;
	sum:real;
	p:xy_point_type;
	c:wps_camera_type;
begin
	c.pivot.x:=v[1];
	c.pivot.y:=v[2];
	c.pivot.z:=v[3];
	c.sensor.x:=v[4];
	c.sensor.y:=v[5];
	c.sensor.z:=v[6];
	c.rot.x:=v[7];
	c.rot.y:=v[8];
	c.rot.z:=v[9];
	sum:=0;
	for i:=1 to num_points do begin
		p:=edges[i].position;
		p.y:=p.y-y_shift;
		p.x:=p.x-sin(edges[i].rotation)*y_shift/cos(edges[i].rotation);
		sum:=sum+sqr(xyz_length(wps_ray_error(p,edge_direction,wires[i],c)));
		p:=edges[i].position;
		p.y:=p.y+y_shift;
		p.x:=p.x+sin(edges[i].rotation)*y_shift/cos(edges[i].rotation);
		sum:=sum+sqr(xyz_length(wps_ray_error(p,edge_direction,wires[i],c)));
	end;
	error:=sqrt(sum/num_points/2);
end;

var 
	mount:kinematic_mount_type;
	i,j,camera_num:integer;
	s:short_string;
	simplex:simplex_type(num_parameters);
	camera:wps_camera_type;
	done:boolean;
	file_name,line,device_name:short_string;
	f:text;
	
begin
	fsd:=3;
	fsr:=6;

	write('Device Name? ');
	readln(device_name);
	write('Camera Number? ');
	readln(camera_num);
	file_name:='../../../Archive/WPS/'+device_name+'/Data_'+device_name+'.txt';
	reset(f,file_name);
	readln(f);
	readln(f,num_points);
	readln(f);
	readln(f);
	edge_str:='';
	for i:=1 to num_points do begin
		readln(f,line);
		edge_str:=edge_str+line+crlf;
	end;
	readln(f);
	readln(f);
	wire_str:='';
	for i:=1 to num_points do begin
		readln(f,line);
		wire_str:=wire_str+line+crlf;
	end;
	readln(f);
	readln(f);
	coord_str:='';
	for i:=1 to 3 do begin
		readln(f,line);
		coord_str:=coord_str+line+crlf;
	end;

{
	Read the mount coordinates from coord_str. We use the mount to convert
	between global and wps coordinates.
}
	mount:=read_kinematic_mount(coord_str);
{
	Read all the wire positions, edge positions, and image rotations out of the
	wire and edge strings. If we're going to use only the left or right edges,
	we read only those. If we are going to use the centers, we obtain the image
	centers by taking the average of the left and right edges.
}
	for i:=1 to num_points do begin
		with wires[i] do begin
			radius:=1/16*25.4/2; {one sixteenth inch steel pin}
			position:=wps_from_global_point(read_xyz(wire_str),mount);
			direction:=wps_from_global_vector(read_xyz(wire_str),mount);
		end;
		
		with edges[i] do begin
			position.y:=y_ref;
			if camera_num=2 then begin
				s:=read_word(edge_str);s:=read_word(edge_str);
				s:=read_word(edge_str);s:=read_word(edge_str);
			end;
			side:=edge_direction;
			case side of
				+1:begin
					s:=read_word(edge_str);
					position.x:=read_real(edge_str)/1000;
					rotation:=read_real(edge_str)/1000;
				end;
				0:begin
					s:=read_word(edge_str);
					position.x:=read_real(edge_str)/1000;
					rotation:=read_real(edge_str)/1000;
					position.x:=(position.x+read_real(edge_str)/1000)/2;
					rotation:=(rotation+read_real(edge_str)/1000)/2;
				end;
				-1:begin
					s:=read_word(edge_str);
					s:=read_word(edge_str);
					s:=read_word(edge_str);
					position.x:=read_real(edge_str)/1000;
					rotation:=read_real(edge_str)/1000;
				end;
			end;
		end;
		
		delete(edge_str,1,pos(chr(10),edge_str));
	end;
{
	Start with a nominal set of calibration constants, disturbed by a random
	amount in all parameters.
}
	camera:=nominal_wps_camera(camera_num);
	writeln('nominal:   ',string_from_wps_camera(camera));
	with camera do begin
		id:=device_name+'_'+string_from_integer(camera_num,1);
		case edge_direction of
			+1:id:=id+'_L';
			-1:id:=id+'_R';
		end;
		with pivot do begin
			x:=x+disturb;
			y:=y+disturb;
			z:=z+disturb;
		end;
		with sensor do begin
			x:=x+disturb;
			y:=y+disturb;
			z:=z+disturb;
		end;
		with rot do begin
			x:=x+disturb/10;
			y:=y+disturb/10;
			z:=z+disturb/10;
		end;
	end;
	writeln('disturbed: ',string_from_wps_camera(camera));
{
	Calculate and display the error corresponding to each image edge and its
	cmm-measured wire position. Here we use the point on each edge at y=y_ref.
}	
	for i:=1 to num_points do begin
		write(string_from_xyz(wires[i].position),' ',string_from_xyz(wires[i].direction));
		write(' ',string_from_xyz(wps_ray_error(edges[i].position,edge_direction,wires[i],camera)));
		writeln;
	end;
{
	Construct the fitting simplex, using our starting calibration as the first
	vertex.
}
	with simplex,camera do begin
		vertices[1,1]:=pivot.x;
		vertices[1,2]:=pivot.y;
		vertices[1,3]:=pivot.z;
		vertices[1,4]:=sensor.x;
		vertices[1,5]:=sensor.y;
		vertices[1,6]:=sensor.z;
		vertices[1,7]:=rot.x;
		vertices[1,8]:=rot.y;
		vertices[1,9]:=rot.z;
		construct_size:=random_scale/10;
		done_counter:=0;
		max_done_counter:=10;
	end;
	simplex_construct(simplex,error);	
{
	Run the simplex fit until we reach convergance, as determined by the
	simplex_step routine itself.
}
	done:=false;
	i:=0;
	while not done do begin
		simplex_step(simplex,error);
		done:=(simplex.done_counter>=simplex.max_done_counter);
		inc(i);
		if (i mod 100 = 0) or done then begin
			with simplex,camera do begin
				pivot.x:=vertices[1,1];
				pivot.y:=vertices[1,2];
				pivot.z:=vertices[1,3];
				sensor.x:=vertices[1,4];
				sensor.y:=vertices[1,5];
				sensor.z:=vertices[1,6];
				rot.x:=vertices[1,7];
				rot.y:=vertices[1,8];
				rot.z:=vertices[1,9];		
			end;
			writeln(i:5,' ',
				string_from_wps_camera(camera),' ',
				xyz_separation(camera.sensor,camera.pivot):fsr:fsd,' ',
				error(simplex.vertices[1])*1000:4:1);
		end;
	end;
{
	Calculate and display the errors again.
}	
	for i:=1 to num_points do begin
		write(string_from_xyz(wires[i].position),' ',string_from_xyz(wires[i].direction));
		write(' ',string_from_xyz(wps_ray_error(edges[i].position,edge_direction,wires[i],camera)));
		writeln;
	end;
end.

{
The numbers are: pivot.x, y, z (mm), sensor.x, y, z (mm), rot.x, y, z (rad), pivot-ccd (mm), error (mm).

We observe convergance after roughly 5000 iterations.
P0195_A_1 -4.3892 88.4846 -4.4033 -13.7607 93.7637 -4.3873 -1577.741 -0.008 -493.211 10.756  0.001
P0195_A_1 -4.3892 88.4846 -4.4033 -13.7607 93.7637 -4.3873 -1577.741 -0.008 -493.211 10.756  0.001
P0195_A_1 -4.3892 88.4846 -4.4033 -13.7607 93.7637 -4.3873 -1577.741 -0.008 -493.211 10.756  0.001
P0195_A_1 -4.3892 88.4846 -4.4033 -13.7607 93.7637 -4.3873 -1577.741 -0.008 -493.211 10.756  0.001
P0195_A_2 -3.8191 39.3077 -4.6536 -12.7098 33.5709 -4.7217 1562.642 -1.805 573.494 10.581  0.001
P0195_A_2 -3.8191 39.3077 -4.6536 -12.7098 33.5709 -4.7217 1562.642 -1.805 573.494 10.581  0.001
P0195_A_2 -3.8191 39.3077 -4.6536 -12.7098 33.5709 -4.7217 1562.642 -1.805 573.494 10.581  0.001
P0195_A_2_R -3.8946 39.2691 -4.6543 -12.7987 33.5273 -4.7227 1562.478 -1.475 574.337 10.595  0.001
P0195_A_2_R -3.8946 39.2691 -4.6543 -12.7987 33.5273 -4.7227 1562.478 -1.475 574.337 10.595  0.001
P0195_A_2_L -3.7944 39.3162 -4.6558 -12.6775 33.5812 -4.7238 1562.817 -2.127 572.635 10.574  0.001
P0195_A_2_L -3.7944 39.3162 -4.6558 -12.6775 33.5812 -4.7238 1562.817 -2.127 572.635 10.574  0.001
P0195_A_1_L -4.4128 88.4975 -4.3324 -13.7863 93.7793 -4.3018 -1577.741 0.529 -489.213 10.759  0.002
P0195_A_1_L -4.4128 88.4975 -4.3324 -13.7863 93.7793 -4.3018 -1577.741 0.529 -489.213 10.759  0.002
P0195_A_1_L -4.4128 88.4975 -4.3324 -13.7863 93.7793 -4.3018 -1577.741 0.529 -489.213 10.759  0.002
P0195_A_1_R -4.4230 88.5022 -4.4704 -13.7975 93.7812 -4.4684 -1577.715 -0.594 -497.244 10.759  0.001
P0195_A_1_R -4.4230 88.5022 -4.4704 -13.7975 93.7812 -4.4684 -1577.715 -0.594 -497.244 10.759  0.001
P0195_A_1 -4.3892 88.4846 -4.4033 -13.7607 93.7637 -4.3873 -1577.741 -0.008 -493.211 10.756  0.001
P0195_B_1 -4.3073 88.4222 -4.1131 -13.6644 93.6896 -4.0386 -1577.685 0.436 -495.197 10.738  0.001
P0195_A_2 -3.8191 39.3077 -4.6536 -12.7098 33.5709 -4.7217  1562.642 -1.805 573.494 10.581  0.001
P0195_B_2 -3.8608 39.3033 -4.3716 -12.7653 33.5628 -4.3823  1562.571 -2.101 573.215 10.594  0.001

Now we have the number of iterations to completion first.
 3925 P0200_A_1 -3.7766 89.3969 -4.2359 -12.5124 94.9219 -4.2645 -1567.300 10.051 -556.381 10.336  0.002
 6333 P0200_A_1 -3.7885 89.4043 -4.2376 -12.5270 94.9308 -4.2667 -1567.298 10.040 -556.169 10.339  0.002
 6756 P0200_A_1 -3.7885 89.4043 -4.2376 -12.5270 94.9308 -4.2667 -1567.298 10.040 -556.169 10.339  0.002
 7001 P0200_A_1 -3.7885 89.4043 -4.2376 -12.5270 94.9308 -4.2667 -1567.298 10.040 -556.169 10.339  0.002
 5123 P0200_A_2 -4.2149 38.6111 -4.5357 -13.2753 33.1152 -4.5946 1572.835 8.406 525.873 10.597  0.002
 4088 P0200_A_2 -4.2149 38.6111 -4.5357 -13.2753 33.1152 -4.5946 1572.835 8.406 525.873 10.597  0.002
 4675 P0197_A_1 -3.7906 89.4672 -3.8999 -12.5781 94.6556 -3.8052 -1575.547 14.727 -537.395 10.205  0.001
 5188 P0197_A_1 -3.7906 89.4672 -3.8999 -12.5781 94.6556 -3.8052 -1575.547 14.727 -537.395 10.205  0.001
 5969 P0197_A_2 -3.3961 38.2920 -4.5059 -12.2748 32.8203 -4.5708 1574.446 7.187 546.390 10.430  0.002
 6263 P0197_A_2 -3.3961 38.2920 -4.5059 -12.2748 32.8203 -4.5708 1574.446 7.187 546.390 10.430  0.002

We switch to reporting the error in um.
 7114 P0201_A_1 -3.7992 89.0629 -4.0823 -12.6996 94.3538 -4.1472 -1569.350 11.913 -532.884 10.354  1.5
 5550 P0201_A_1 -3.7992 89.0629 -4.0823 -12.6996 94.3538 -4.1472 -1569.350 11.913 -532.884 10.354  1.5
 5201 P0201_A_2 -4.1684 38.7802 -4.1355 -13.1010 33.2285 -4.2102 1560.343 15.907 547.316 10.518  1.3
 5209 P0201_A_2 -4.1684 38.7802 -4.1355 -13.1010 33.2285 -4.2102 1560.343 15.907 547.316 10.518  1.3
 4954 P0203_A_1 -3.1318 88.7801 -3.9966 -11.9431 94.2143 -3.9305 -1573.359 6.314 -539.410 10.353  1.3
 5472 P0203_A_1 -3.1318 88.7801 -3.9966 -11.9431 94.2143 -3.9305 -1573.359 6.314 -539.410 10.353  1.3

Here we see failure of the fit convergeance criteria:
 1735 P0203_A_2 -4.9933 40.3333 -5.3482 -13.9693 34.8070 -5.6867 1573.123 -7.387 529.836 10.546  2.5
 1677 P0203_A_2 -5.5491 40.0640 -6.4503 -14.6505 34.4762 -7.0214 1573.211 -7.124 519.995 10.695  5.1
 1929 P0203_A_2 -7.9753 38.6603 -4.2451 -17.6159 32.7615 -4.3478 1573.471 -6.121 480.605 11.303  8.3
 
We must increase the max_done_counter to 20 to get the following:
 9860 P0203_A_2 -4.7610 40.4305 -4.4217 -13.6844 34.9267 -4.5646 1573.078 -7.620 533.945 10.485  1.2
10000 P0203_A_2 -4.7610 40.4305 -4.4217 -13.6844 34.9267 -4.5646 1573.078 -7.620 533.945 10.485  1.2

Reduce max_done_counter to 10 again.
 6500 Q0132_A_1 -4.4475 87.6752 -4.0442 -14.6304 93.6529 -3.9048 -1574.944 1.036 -638.629 11.809  3.1
 6712 Q0132_A_1 -4.4475 87.6752 -4.0442 -14.6304 93.6529 -3.9048 -1574.944 1.036 -638.629 11.809  3.1
 5525 Q0132_A_2 -4.1223 37.6675 -4.9617 -14.3354 31.3532 -4.6422 1578.667 -23.815 537.598 12.012  3.5
 6391 Q0132_A_2 -4.1223 37.6675 -4.9617 -14.3354 31.3532 -4.6422 1578.667 -23.815 537.598 12.012  3.5
 3880 P0202_A_1 -3.9688 89.2693 -4.3937 -12.8662 94.7569 -4.2628 -1568.482 14.449 -540.951 10.454  1.5
 5447 P0202_A_1 -3.9688 89.2693 -4.3937 -12.8662 94.7569 -4.2628 -1568.482 14.449 -540.951 10.454  1.5
 6734 P0202_A_2 -4.4135 39.0829 -4.2892 -13.4683 33.8120 -4.3727 1573.235 2.048 514.979 10.477  1.5
 4190 P0202_A_2 -4.4135 39.0829 -4.2892 -13.4683 33.8120 -4.3727 1573.235 2.048 514.979 10.477  1.5
 
Re-calibrate P0198 and P0203. Had to increase max_done_counter to 100 for P0198_B_1
 6954 P0198_A_1 -3.1966 87.9025 -4.0920 -12.1305 93.3639 -4.2248 -1575.427 -5.739 -532.465 10.472  0.9
 6713 P0198_A_2 -3.8165 38.9616 -4.4038 -12.7999 33.3935 -4.4135 1567.585 -1.627 546.802 10.569  1.0
 7812 P0198_B_1 -3.0843 90.1940 -4.2425 -11.9576 95.7197 -4.3450 -1575.744 0.437 -541.792 10.454  1.2
33124 P0198_B_2 -3.7644 38.9943 -4.6077 -12.7347 33.4335 -4.6656 1567.472 -2.328 551.404 10.554  1.3
 6259 P0198_B_2 -3.7644 38.9943 -4.6077 -12.7347 33.4335 -4.6656 1567.472 -2.328 551.404 10.554  1.3
 7063 P0203_B_1 -3.0524 89.2967 -4.3284 -11.8453 94.7261 -4.3051 -1573.151 7.914 -543.224 10.334  1.9
 5519 P0203_B_2 -3.4665 38.0783 -4.1433 -12.3490 32.5047 -4.2011 1573.072 -6.642 538.407 10.486  1.6
 
WPS1-B Calibrations.
 4846 P0222_A_1 -3.8979 87.9984 -4.4237 -13.0247 93.3574 -4.4730 -1570.209 -7.919 -513.986 10.584  1.0
 6623 P0222_A_2 -4.5453 39.3411 -4.3267 -13.8010 34.0234 -4.4078 1580.291 12.109 508.396 10.675  1.7
 7198 P0223_A_1 -3.8841 87.8976 -4.2084 -12.9706 93.3465 -4.1088 -1571.456 15.510 -556.602 10.596  1.2
 6571 P0223_A_2 -4.5310 40.0608 -4.3034 -13.7758 34.5910 -4.5274 1574.408 -1.478 520.011 10.744  1.5
 6696 P0224_A_1 -3.3551 88.5050 -4.1745 -12.6030 93.9608 -4.2031 -1568.213 -8.750 -551.288 10.737  1.0
 7252 P0224_A_2 -5.4091 40.4620 -4.1222 -14.2126 35.4105 -3.9837 1571.051 20.308 503.579 10.151  1.0

CERN Returns P0195 saying it's calibration has changed. We re-calibrate with P0195_C, which is no good
then D, which is okay but we see that the top camera has been moved since calibration B and is not well-
centered on the field of view. We break off and reposition and end with E.
 4832 P0195_A_1 -4.3892 88.4846 -4.4033 -13.7607 93.7637 -4.3873 -1577.741 -0.008 -493.211 10.756  1.3
 6846 P0195_B_1 -4.3073 88.4222 -4.1131 -13.6644 93.6896 -4.0386 -1577.685 0.436 -495.197 10.738  1.3
 7745 P0195_D_1 -2.9251 89.8197 -3.9357 -12.1236 95.2510 -3.8333 -1577.452 -2.442 -523.617 10.683  2.0
 4505 P0195_A_2 -3.8191 39.3077 -4.6536 -12.7098 33.5709 -4.7217 1562.642 -1.805 573.494 10.581  1.2
 6748 P0195_B_2 -3.8608 39.3033 -4.3716 -12.7653 33.5628 -4.3823 1562.571 -2.101 573.215 10.594  0.8
 4007 P0195_D_2 -3.7660 39.3379 -4.6693 -12.6470 33.6073 -4.7388 1562.630 -2.330 574.561 10.570  1.4
 7460 P0195_E_1 -8.0503 91.8587 -4.2477 -17.2217 97.4737 -4.2104 -1577.398 -0.325 -533.494 10.754  1.6
 6498 P0195_E_2 -3.8649 39.2839 -4.3795 -12.7663 33.5418 -4.3931 1562.686 -1.550 572.270 10.593  1.6

CERN Returns P0199 with broken-off camera 1. Repair and re-calibrate.
 4620 P0199_A_1 -3.0807 90.0282 -4.1893 -11.7775 95.4612 -4.1093 -1573.379 12.464 -554.912 10.255  1.0
 3839 P0199_A_2 -4.2113 39.6984 -4.1309 -13.1938 34.3032 -4.0849 1571.324 -0.426 519.343 10.478  0.7
 5048 P0199_B_1 -3.3354 89.1019 -4.1875 -12.0084 94.5839 -4.1194 -1573.383 11.792 -561.162 10.261  0.9
 4322 P0199_B_2 -4.2923 39.6474 -4.3700 -13.2957 34.2403 -4.3719 1570.804 -1.029 520.598 10.502  1.1
 4926 P0199_C_1 -4.0176 88.0416 -4.4290 -12.7107 93.3821 -4.0536 -1573.817 38.910 -547.634 10.209  1.2
 6297 P0199_C_2 -4.4658 39.4894 -4.4051 -13.4677 34.0853 -4.1260 1571.587 20.234 519.217 10.503  1.9

Three WPS1s with broken-off cameras, re-glue and re-calibrate.
 6747 P0222_C_1 -3.2506 88.2492 -4.5628 -12.3277 93.8891 -4.4901 -1568.477 4.154 -581.213 10.687  2.1
 3848 P0222_C_2 -4.7831 38.5881 -4.5009 -13.5001 33.2596 -4.3538 1570.995 28.621 528.012 10.218  1.4
 5813 P0224_B_1 -3.8725 87.5525 -4.4068 -12.8327 93.1411 -4.1598 -1569.452 14.372 -540.840 10.563  2.9
 7682 P0224_B_2 -4.6969 39.6116 -4.3316 -14.0941 34.0965 -4.4956 1579.939 -1.910 511.416 10.897  1.6
 6468 P0224_C_1 -4.2213 87.7491 -4.6937 -13.2627 93.3834 -4.5124 -1569.469 14.796 -536.644 10.655  1.6
 8808 P0224_C_2 -4.5677 39.6968 -4.6057 -13.9320 34.2023 -4.8243 1579.873 -0.778 517.847 10.860  2.0
 6319 P0225_B_1 -3.1255 88.0477 -4.5187 -12.1260 93.5160 -4.6606 -1581.139 -2.690 -555.326 10.532  1.3
 4180 P0225_B_2 -4.1338 38.9178 -4.4174 -13.2475 33.4272 -4.2957 1582.116 23.001 530.661 10.641  1.1

This is our first WPS1-D, with a 0.5-mm aperture.
 4171 Q0129_D_1 -5.1326 89.5092 -4.7955 -14.2253 94.9853 -4.6239 -1573.462 19.096 -553.251 10.616  1.8
 5233 Q0129_D_2 -5.0402 38.8200 -4.2803 -14.0014 33.1804 -4.0978 1567.728 19.874 564.146 10.590  1.2

Our first WPS2. Four of the points were poorly-measured by the CMM and corrupt the fit. Second run better.
 4379 C0562_A_1 -3.7831 88.9236 -4.9657 -12.8952 94.4919 -4.9624 -1558.632 -0.607 -564.880 10.679  2.7
 6162 C0562_A_2 -3.0497 39.2291 -4.9371 -12.0902 33.7763 -5.0363 1582.796 -2.165 534.735 10.558  3.1
 6280 C0562_B_1 -3.2160 88.6035 -5.0909 -12.1945 94.0955 -5.0991 -1558.847 0.627 -578.869 10.525  1.5
 5214 C0562_B_2 -3.4260 39.0062 -5.0429 -12.5479 33.5050 -5.1555 1582.540 -2.492 529.965 10.653  1.5

More calibrations that are not great because of a problem with the stage slipping.
 6639 C0563_A_1 -3.3226 88.7738 -5.2346 -12.4954 94.4223 -5.2229 -1575.946 4.559 -548.303 10.772  1.6
 5910 C0563_A_2 -3.2378 39.3436 -4.9936 -12.3699 33.8665 -4.9786 1551.703 26.153 542.676 10.649  2.1
 4703 C0563_A_2 -3.2378 39.3436 -4.9936 -12.3699 33.8665 -4.9786 1551.703 26.153 542.676 10.649  2.1
 
Now we have fixed the stage and things are going better.
 5660 C0564_A_1 -3.9747 88.5415 -4.7928 -13.1483 94.0905 -4.6594 -1569.021 -8.746 -512.315 10.722  1.4
 5802 C0564_A_2 -3.9695 39.3654 -4.7458 -13.1743 34.0412 -4.7220 1593.724 4.024 520.136 10.634  0.9
 6925 C0565_A_1 -3.4187 88.5351 -5.1988 -12.4293 94.1686 -5.1354 -1567.718 10.503 -553.459 10.627  0.9
 6743 C0565_A_2 -3.9021 39.5280 -5.1123 -13.1077 34.1876 -5.2621 1564.862 -3.686 504.859 10.644  0.8
 5992 C0566_A_1 -3.8859 88.6454 -5.2273 -12.9857 94.2809 -5.1865 -1582.320 -20.841 -534.469 10.704  1.1
 7259 C0566_A_2 -3.7466 39.2677 -5.0547 -12.9736 33.8539 -5.0552 1563.256 -13.310 543.711 10.698  0.7
 6764 C0567_A_1 -3.5694 88.6711 -5.0861 -12.6712 94.3061 -5.0781 -1580.440 -5.260 -537.937 10.705  1.0
 5468 C0567_A_2 -3.7736 39.4031 -4.8684 -12.9777 33.9881 -4.9191 1572.537 0.816 536.695 10.679  0.9
 6939 C0568_A_1 -3.3651 88.4135 -4.9575 -12.6336 93.9676 -5.0198 -1569.200 17.249 -515.389 10.805  0.9
 5786 C0568_A_2 -3.3329 39.7802 -5.3015 -12.5409 34.4001 -5.4180 1573.311 -24.839 525.488 10.665  1.0
 6537 C0569_A_1 -3.7589 88.3002 -5.1047 -12.8801 93.9368 -4.9732 -1572.172 0.810 -521.804 10.723  1.1
 5855 C0569_A_2 -3.3012 39.2002 -5.0119 -12.4385 33.8331 -5.0350 1567.840 9.412 527.534 10.597  0.8
 6981 C0570_A_1 -3.2442 88.4068 -4.9615 -12.2915 94.0330 -4.7980 -1567.418 13.082 -564.814 10.655  0.8
 6705 C0570_A_2 -3.6587 39.5604 -4.7582 -12.8826 34.2429 -4.8317 1571.667 8.676 507.737 10.647  1.0
 6074 C0571_A_1 -3.4310 88.3453 -4.9420 -12.4542 94.0619 -4.8731 -1574.059 11.026 -545.430 10.682  0.7
 6392 C0571_A_2 -2.9100 39.2205 -4.8333 -12.0803 33.9034 -4.8948 1586.120 -3.044 523.163 10.601  1.9
 7124 C0572_A_1 -3.3310 88.4273 -5.0365 -12.3326 94.0394 -5.0141 -1572.532 -3.147 -584.894 10.608  1.1
 5530 C0572_A_2 -3.3205 39.1416 -4.6273 -12.5399 33.8051 -4.6120 1585.005 35.942 502.761 10.653  1.6
 6717 C0573_A_2 -3.1108 39.4726 -5.1132 -12.4342 34.2241 -5.4606 1583.793 -19.189 474.527 10.705  1.7
 6717 C0573_A_2 -3.1108 39.4726 -5.1132 -12.4342 34.2241 -5.4606 1583.793 -19.189 474.527 10.705  1.7
 6416 C0574_A_1 -3.7672 88.0655 -5.1314 -12.9420 93.6321 -5.1718 -1563.151 -11.060 -502.908 10.732  1.0
 4312 C0574_A_2 -3.4638 39.1504 -4.9903 -12.7721 33.8712 -4.9789 1582.060 9.463 476.708 10.701  1.0
 3860 C0575_A_1 -3.5899 88.2808 -4.8065 -12.7710 93.7388 -4.5779 -1555.422 0.226 -533.660 10.683  0.9
 5621 C0575_A_2 -3.4780 39.4648 -5.2590 -12.6939 34.0032 -5.3275 1574.193 -9.697 540.351 10.713  1.1
 4087 C0576_A_1 -3.6122 88.3072 -5.2199 -12.6852 93.9971 -5.2623 -1559.916 -9.041 -552.198 10.710  1.7
 7225 C0576_A_2 -3.5002 38.8492 -5.1328 -12.8716 33.4424 -5.3060 1579.434 -1.799 505.294 10.821  1.6
 7138 C0577_A_1 -3.0532 88.1737 -4.6874 -12.1139 93.7990 -4.6121 -1575.027 11.455 -531.172 10.665  1.0
 6542 C0577_A_2 -3.1468 39.4506 -4.9204 -12.5241 34.1552 -4.9024 1574.531 -12.994 499.106 10.769  1.0
 5531 C0578_A_1 -3.6175 88.0932 -5.0633 -12.7138 93.6782 -4.9648 -1572.136 12.085 -541.722 10.674  0.7
 6705 C0578_A_2 -3.3534 39.2265 -4.9850 -12.5076 33.7612 -4.9016 1565.918 11.386 492.205 10.662  0.9
 6548 C0579_A_1 -3.3659 88.2530 -5.1653 -12.4633 93.8897 -5.1154 -1564.642 8.264 -536.941 10.702  1.8
 5555 C0579_A_2 -3.7198 38.9574 -4.9004 -13.0884 33.5283 -4.9737 1571.121 -15.314 507.540 10.828  1.1
 4328 C0580_A_1 -3.4580 88.3465 -4.9325 -12.6421 94.0081 -4.8300 -1575.557 9.820 -548.068 10.789  1.7
 6703 C0580_A_2 -2.8809 39.4290 -5.0137 -12.1095 33.9672 -5.1403 1567.693 -6.918 543.600 10.724  1.6
 6384 C0581_A_1 -3.6676 88.2095 -5.3032 -12.9480 93.6797 -5.2093 -1570.081 12.812 -494.762 10.773  0.8
 6189 C0581_A_2 -3.3130 39.2144 -5.5655 -12.5075 33.7681 -5.7888 1571.064 2.444 529.898 10.689  1.6
 6916 C0582_A_1 -3.2097 88.1029 -4.8020 -12.2649 93.7537 -4.6914 -1568.776 5.256 -547.926 10.674  0.9
 6101 C0582_A_2 -3.4677 39.2683 -4.5794 -12.7149 33.8733 -4.7029 1567.015 3.807 535.636 10.707  1.1
 4671 C0583_A_1 -2.9301 88.2465 -5.0233 -12.0009 93.7958 -5.0725 -1575.312 -8.390 -546.042 10.634  1.3
 5338 C0583_A_2 -3.2566 39.5093 -5.0483 -12.6026 34.1069 -5.1614 1571.859 -26.316 537.762 10.796  1.7
 4523 C0584_A_1 -2.6671 88.1845 -5.3647 -11.8561 93.6596 -5.4282 -1564.383 -4.015 -507.552 10.697  0.8
 6633 C0584_A_2 -3.3693 39.0436 -4.5476 -12.7588 33.7395 -4.6014 1569.947 -5.566 501.326 10.784  2.0
 5165 C0585_A_1 -3.2273 88.1285 -5.1464 -12.3034 93.8127 -5.0275 -1576.955 15.395 -566.329 10.710  1.6
 5827 C0585_A_2 -3.7851 39.0673 -4.8461 -13.0856 33.5745 -4.8614 1568.647 -18.698 531.014 10.801  1.9
 
Recalibrations.
 7920 C0563_B_1 -3.5214 88.9127 -5.1230 -12.7312 94.5887 -5.0763 -1575.969 5.514 -542.610 10.819  1.5
 6530 C0563_B_2 -3.3509 39.2680 -4.9734 -12.5065 33.7752 -4.9481 1551.272 19.575 539.416 10.677  1.1
 7502 C0562_C_1 -3.5814 88.8400 -4.9796 -12.6389 94.3849 -4.9598 -1558.772 -0.344 -566.827 10.620  1.6
 4893 C0562_C_2 -3.2934 39.0816 -4.9960 -12.3827 33.6002 -5.1009 1582.496 -3.005 536.976 10.615  1.0
 6950 C0565_B_1 -3.5672 88.6207 -5.0629 -12.6076 94.2726 -4.9598 -1567.705 10.392 -546.849 10.662  1.0
 6473 C0565_B_2 -3.4484 39.8043 -5.2642 -12.5624 34.5183 -5.4396 1565.119 -3.078 508.839 10.537  1.3
 7019 C0568_B_1 -3.3093 88.3844 -5.1412 -12.5615 93.9346 -5.1872 -1570.244 16.832 -516.928 10.789  1.5
 6008 C0568_B_2 -3.3202 39.7891 -5.0332 -12.5296 34.4080 -5.0489 1574.662 -22.893 523.054 10.666  1.4
 }
