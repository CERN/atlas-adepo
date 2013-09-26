{
Utilities for Mathematical Analysis
Copyright (C) 2004-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA	02111-1307, USA.
}

unit utils;
{
	utils contains general-purpose, platform-independent constants, types, and
	routines for use in our analysis library. All names in utils.pas must use
	full words separated by underscore characters, unless the a word has an
	abbreviation given in the list below, in which case the abbreviation must be
	used.

	Word			Abbreviation
	----------------------------
	address			addr
	number			num
	pointer			ptr
	handle			hdl
	increment		inc
	decrement		dec
		
	Routines that transform parameters from one form to another, or from one
	space to another use the name convention second_from_first(). We prefer this
	convention to the first_to_second convention because it makes assignment
	statements clearer. Consider i:=integer_from_real() as compared to
	i:=real_to_integer(). In the first case, reading left to right, we see that
	i will be assigned and integer value, and this value will be derived from a
	real number. In the second case we have to go back and forth across the name
	to make the same determination.
	
	Routines in our analysis library use the global error_string variable to
	record error messages using the report_error procedure. Only a main program
	body or a function declared in the main program may reset the error_string
	to the empty string. No routine outside the main program may make its
	execution conditional upon the state of the error_string. The main program
	might be something like our p.pas, which compiles to a stand-alone
	console-executable program, or lwdaq.pas, which compiles to a shared
	library. The report_error routine will append error messages to the global
	error string when the global flag append_errors is true, otherwise it will
	over-write existing errors.
	
	The utils 'uses' clause must remain empty both in the interface and
	implementation sections. The compiled utils.pas object is always the first
	object in the link order of any dynamic library or executable. Furthermore,
	we should be able to compile a dynamic link library out of utils.pas with
	the help of only the Gnu Pascal Compiler (GPC) run-time library (libgpc.a),
	and we must be able to do so on any platform.

	The utils initialization routine is at the end of the implementation
	section. It initializes the random number generator and the gui (graphical
	user interface) procedure variables.

	In Pascal, the standard input and output channels are called "input" and
	"output". In C they are called "stdin" and "stdout". The readln routine can
	crash a program if the standard input channel is not available. If the
	standard output channel is not available, then writeln output will be lost.
	Utils provides two global variables, stdout_available and stdin_available to
	indicate whether these channels are available or not. Utils routines will
	not attempt to use a channel if its global availability variable is false.

	Utils provides a set global procedure variables: gui_draw, gui_support,
	gui_wait, gui_writeln, and gui_readln. Utils initializes these four
	procedural variables to default_gui_draw, etc. The graphical user interface
	assigns working procedures to the variables. After that, analysis code can
	interact with the graphical user interface using these procedure variables.

	Utils makes free use of GNU Pascal extensions, such as the routine
	CurrentRoutineName. These extensions stand out in the code because they use
	capital letters instead of underscores to delimit phrases within their
	names.

	There are many Utils routines that use strings for input and output. These
	routines deletes characters they passes over, just as if they were reading
	from a file, with the string acting as the file. As a routine writes, it
	appends to the end of the string. When Utils routines read from a string,
	they ignore characters within curly brackets. With curly brackets, you can
	embed comments in the strings read from and written to by utils routines.

	Utils provides a selection of routines that convert between strings and
	numbers, and visa versa. The procedures beginning with "write_" convert
	mathematical objects into strings and append them to a file string.
	Functions beginning with "read_" read a numberical object from the beginning
	of a file string and delete it from the file string. Functions beginning
	with "string_from_" take a mathematical parameter and return a short_string.
	Functions ending with "from_string" convert a short_string into a
	mathematical object.

	For measuring execution time, Utils provides the start_time, mark_time, and
	report_time_marks routines. When you call start_time, you set a global
	timestamp. Subsequently, mark_time records elapsed time by subtracting the
	start_time from the current time. The routines create a list of elapsed time
	strings which you display later with report_time_marks. By this means, you
	do not slow down your execution with text display. The mark_time routine
	takes roughly 100 us to executte on a 1.3 GHz G4 iBook, so you can use it to
	measure execution times of 1 ms with good precision. That's not to say that
	the elapsed time measured by mark_time corresponds exactly to the time used
	by your process. We observe frequent jumps of tens of milliseconds. We
	believe these jumps are caused by the microprocessor switching to another
	task and then back again.
}

interface

{
	Routines we import from the Pascal run-time library that are
	not imported by default.
}
function GetMicroSecondTime:longint;
  external name '_p_GetMicroSecondTime';
procedure UnixTimeToTimeStamp(ut:longint; var ts:TimeStamp); 
  external name '_p_UnixTimeToTimeStamp';

var {for debugging}
	stdout_available:boolean=true;
	stdin_available:boolean=true;
	num_outstanding_ptrs:cardinal=0;
	track_ptrs:boolean=false;
	append_errors:boolean=false;
	debug_counter:integer=0;
	debug_string:string[254]='';
	
var {for multi-platform support}
	big_endian:boolean;

const {for benchmarks}
	max_num_time_marks=100;

const {system}
	not_valid_code=-1;{must be negative}
	ignore_remaining_data=-1;{must be negative}

const {mathematical}
	pi=3.1415926536;
	max_integer=$7FFFFFFF;
	max_shortint=$7FFF;
	max_shortcard=65535;
	max_byte=$FF;
	one_half=0.5;
	one_quarter=0.25;
	integer_mask=$FFFFFFFF;
	shortint_mask=$0000FFFF;
	byte_mask=$000000FF;
	nibble_mask=$0000000F;
	small_real=1e-20;
	large_real=1e40;

const {physical units}
	us_per_s=1000000;
	s_per_min=60;
	min_per_hr=60;
	hr_per_day=24;
	day_per_mo=30.44;
	mo_per_yr=12;
	rad_per_deg=pi/180;
	mrad_per_rad=1000;	
	um_per_mm=1000;
	um_per_cm=10000;
	mm_per_cm=10;
	um_per_m=1000000;
	decades_per_ln=0.4342944;
	mA_per_A=1000;
	one_percent=0.01;
	
type {for type-casting pointers}
	shortint_ptr=^shortint;
	integer_ptr=^integer;
	cardinal_ptr=^cardinal;
	byte_ptr=^byte;
	byte_hdl=^byte_ptr;

type {for 1-D geometry}
	x_graph_type(num_points:integer)=array [0..num_points-1] of real;
	x_graph_ptr_type=^x_graph_type;

const {for geometry}
	num_xy_dimensions=2;
	num_xyz_dimensions=3;

type {for 2-D integer geometry}
	ij_point_type=record i,j:integer; end;
	ij_point_ptr_type=^ij_point_type;
	ij_line_type=record a,b:ij_point_type; end;
	ij_line_ptr_type=^ij_line_type;
	ij_rectangle_type=record top,left,bottom,right:integer; end;
	ij_rectangle_ptr_type=^ij_rectangle_type;
	ij_ellipse_type=record a,b:ij_point_type; axis_length:real; end;
	ij_ellipse_ptr_type=^ij_ellipse_type;
	ij_graph_type(num_points:integer)=array [0..num_points-1] of ij_point_type;
	ij_graph_ptr_type=^ij_graph_type;

type {for 2-D real geometry}
	xy_point_type=record x,y:real; end;
	xy_point_ptr_type=^xy_point_type;
	xy_line_type=record a,b:xy_point_type;end;
	xy_line_ptr_type=^xy_line_type;
	xy_rectangle_type=record top,left,bottom,right:real; end;
	xy_rectangle_ptr_type=^xy_rectangle_type;
	xy_ellipse_type=record a,b:xy_point_type; axis_length:real; end;
	xy_ellipse_ptr_type=^xy_ellipse_type;
	xy_graph_type(num_points:integer)=array [0..num_points-1] of xy_point_type;
	xy_graph_ptr_type=^xy_graph_type;
	
type {for 3-D real geometry}
	xyz_point_type=record x,y,z:real; end;
	xyz_point_ptr_type=^xyz_point_type;
	xyz_line_type=record point,direction:xyz_point_type; end;
	xyz_line_ptr_type=^xyz_line_type;
	xyz_plane_type=record point,normal:xyz_point_type; end;
	xyz_plane_ptr_type=^xyz_plane_type;
	xyz_graph_type(num_points:integer)=array [0..num_points-1] of xyz_point_type;
	xyz_graph_ptr_type=^xyz_graph_type;
	coordinates_type=record
		origin,x_axis,y_axis,z_axis:xyz_point_type;{a point and three unit vectors}
	end;
	kinematic_mount_type=record 
		cone,slot,plane:xyz_point_type;{ball centers}
	end;

type {for math}
	real_ptr_type=^real;
	sinusoid_type=record
		amplitude,phase:real;
	end;

type {for simplex fitting}
	simplex_vertex_type (n:integer) = array [1..n] of real;
	simplex_ptr=^simplex_type;
	simplex_type (n:integer) = record
		vertices:array [1..n+1] of simplex_vertex_type(n);
		altitudes:array [1..n+1] of real;
		construct_size:real; {length of sides for simplex construction}
		done_counter:integer; {counter used to detect convergance}
		max_done_counter:integer; {counter value at convergance, try 10}
	end;
	simplex_altitude_function_type = function(vertex:simplex_vertex_type):real;
	
type {for matrices}
	matrix_ptr=^matrix_type;
	matrix_type(num_rows,num_columns:integer)=
		array [1..num_rows,1..num_columns] of real;
	xyz_matrix_type=
		array [1..num_xyz_dimensions,1..num_xyz_dimensions] of real;

var {for matrices}
	matrix_determinant_saved:real=0;
	matrix_rank_saved:integer=0;

const {for strings}
	wild_char='?';
	wild_string='*';
	true_chars:set of char = ['y','Y','t','T','1'];
	false_chars:set of char = ['n','N','f','F','0'];
	file_name_separators:set of char = [':','/','\'];
	separator_chars:set of char = ['{','}',' ',',',chr(13),chr(10),chr(9)];
	start_comment_chars:set of char = ['{'];
	end_comment_chars:set of char = ['}'];
	true_string='1';
	false_string='0';
	null_code='_null_code_';
	error_prefix='ERROR: ';
	null_char=chr(0);
	crlf=chr(13)+chr(10);
	tab=chr(9);
	hex_digits_per_byte=2;
	short_string_length=2000;
	long_string_length=200000;

type {strings}
	short_string = string(short_string_length);
	short_string_ptr = ^short_string;
	long_string = string(long_string_length);
	long_string_ptr = ^long_string;
	byte_array(size:integer) = array [0..size-1] of byte;
	byte_array_ptr = ^byte_array;

var {strings}
	eol:string[10]=chr(10);{can be set dynamically to suit platform}
	error_string:short_string='';
	
type {for gui procedures}
	gui_procedure_type=procedure(s:short_string);
	gui_function_type=function(s:short_string):short_string;
	
var {for gui}
	gui_draw:gui_procedure_type;
	gui_support:gui_procedure_type;
	gui_wait:gui_procedure_type;
	gui_writeln:gui_procedure_type;
	gui_readln:gui_function_type;

var {for string formatting}
	fsr:integer=8;
	fsd:integer=6;
	
type {for sort routines}
	sort_swap_procedure_type=procedure(a,b:integer);
	sort_compare_function_type=function(a,b:integer):boolean;

{for gui}
procedure default_gui_draw(s:short_string); 
procedure default_gui_wait(s:short_string); 
procedure default_gui_writeln(s:short_string); 
function default_gui_readln(s:short_string):short_string;

{string testing}
function alphabet_char(c:char):boolean;
function alphanumeric_char(c:char):boolean;
function strings_in_order(a,b:short_string):boolean;
function string_match(key,subject:short_string):boolean;
function string_checksum(s:short_string):integer;

{file string handling}
function new_long_string:long_string_ptr;
procedure dispose_long_string(lsp:long_string_ptr);

{string converters}
function short_string_from_c_string(c_string:CString):short_string;
function c_string_from_short_string(pascal_string:short_string):CString;
function long_string_from_c_string(c_string:CString):long_string_ptr;
function digit_from_char(c:char):integer;
function char_from_digit(digit:integer):char;
function boolean_from_string(s:short_string):boolean;
function cardinal_from_hex_string(s:short_string):cardinal;
function integer_from_string(s:short_string;var okay:boolean):integer;
function decimal_from_string(s:short_string;base:integer):integer;
function real_from_string(s:short_string;var okay:boolean):real;
function xy_from_string(s:short_string):xy_point_type;
function xyz_from_string(s:short_string):xyz_point_type;
function xyz_line_from_string(s:short_string):xyz_line_type;
function xyz_plane_from_string(s:short_string):xyz_plane_type;
function kinematic_mount_from_string(s:short_string):kinematic_mount_type;
function string_from_boolean(value:boolean):short_string;
function string_from_integer(value,fsi:integer):short_string;
function string_from_real(value:real;field_width,decimal_places:integer):short_string;
function string_from_decimal(decimal_number:integer;base,num_digits:integer):short_string;
function hex_string_from_cardinal(number:cardinal):short_string;
function hex_string_from_byte(number:byte):short_string;
function string_from_ij(p:ij_point_type):short_string;
function string_from_xy(p:xy_point_type):short_string;
function string_from_xyz(p:xyz_point_type):short_string;
function string_from_xyz_line(l:xyz_line_type):short_string;
function string_from_xyz_plane(p:xyz_plane_type):short_string;

{short string manipulation}
function upper_case(s:short_string):short_string;
function lower_case(s:short_string):short_string;
function strip_folder_name(s:short_string):short_string;
function strip_spaces(s:short_string):short_string;
function strip_separators(s:short_string):short_string;
function delete_substring(s:short_string;index,count:integer):short_string;
function delete_to_mark(s:short_string;mark:char):short_string;
function no_marks_left(s:short_string; mark:char):boolean;

{generic string manipulation}
function word_count(var s:string):integer;
function read_word(var s:string):short_string;
function read_boolean(var s:string):boolean;
function read_real(var s:string):real;
function read_integer(var s:string):integer;
function read_xy(var s:string):xy_point_type;
function read_xyz(var s:string):xyz_point_type;
function read_x_graph(var s:string):x_graph_ptr_type;
function read_xy_graph(var s:string):xy_graph_ptr_type;
procedure read_matrix(var s:string;var M:matrix_type);
function read_kinematic_mount(var s:string):kinematic_mount_type;
procedure write_ij(var s:string;p:ij_point_type);
procedure write_xy(var s:string;p:xy_point_type);
procedure write_xyz(var s:string;p:xyz_point_type);
procedure write_xyz_line(var s:string;l:xyz_line_type);
procedure write_xyz_plane(var s:string;p:xyz_plane_type);
procedure write_xyz_matrix(var s:string;M:xyz_matrix_type);
procedure write_memory_map(var s:string;base:cardinal;size:integer);
procedure write_matrix(var s:string;var M:matrix_type);
procedure write_kinematic_mount(var s:string;mount:kinematic_mount_type);

{memory}
function big_endian_from_local_shortint(i:shortint):shortint;
procedure block_clear(a:pointer;length:integer);
procedure block_fill(a:pointer;length:integer);
procedure block_set(a:pointer;length:integer;value:byte);
procedure block_move(a,b:pointer;length:integer);
function local_from_little_endian_shortint(i:shortint):shortint;
function local_from_big_endian_shortint(i:shortint):shortint;
function memory_byte(address:cardinal):byte;
function memory_shortint(address:cardinal):shortint;
function memory_integer(address:cardinal):integer;
procedure read_memory_byte(address:cardinal;var value:byte);
procedure read_memory_shortint(address:cardinal;var value:shortint);
procedure read_memory_integer(address:cardinal;var value:integer);
function real_from_integer(i:integer):real;
function reverse_shortint_bytes(i:shortint):shortint;
procedure write_memory_byte(address:cardinal;value:byte);
procedure write_memory_shortint(address:cardinal;value:shortint);
procedure write_memory_integer(address:cardinal;value:integer);

{debugging}
procedure inc_num_outstanding_ptrs(size:integer;caller:short_string);
procedure dec_num_outstanding_ptrs(size:integer;caller:short_string);
procedure start_timer(id,caller:short_string);
procedure mark_time(id,caller:short_string);
procedure report_time_marks;
procedure report_error(s:short_string);

{math}
procedure check_for_math_error(x:real);
function math_error(x:real):boolean;
function math_overflow(x:real):boolean;
function error_function(x:real):real;
function complimentary_error_function(x:real):real;
function gamma_function(z:real):real;
function chi_squares_distribution(sum_chi_squares:real;num_parameters:integer):real;
function chi_squares_probability(sum_chi_squares:real;num_parameters:integer):real;
function factorial(n:integer):real;
function full_arctan(a,b:real):real;
function sum_sinusoids(a,b:sinusoid_type):sinusoid_type;
function xpy(x,y:real):real;
function xpyi(x:real;y:integer):real;
function random_0_to_1:real;

{one-dimensional data}
function new_x_graph(num_points:integer):x_graph_ptr_type;
procedure dispose_x_graph(gp:x_graph_ptr_type);
function average_x_graph(gp:x_graph_ptr_type):real;
function max_x_graph(gp:x_graph_ptr_type):real;
function min_x_graph(gp:x_graph_ptr_type):real;
function stdev_x_graph(gp:x_graph_ptr_type):real;

{two-dimensional data}
function new_xy_graph(num_points:integer):xy_graph_ptr_type;
procedure dispose_xy_graph(gp:xy_graph_ptr_type);
function average_xy_graph(gp:xy_graph_ptr_type):real;
function max_xy_graph(gp:xy_graph_ptr_type):real;
function min_xy_graph(gp:xy_graph_ptr_type):real;
function stdev_xy_graph(gp:xy_graph_ptr_type):real;

{three-dimensional data}
function new_xyz_graph(num_points:integer):xyz_graph_ptr_type;
procedure dispose_xyz_graph(gp:xyz_graph_ptr_type);

{signal processing}
function recursive_filter(x:x_graph_ptr_type;a_list,b_list:short_string):x_graph_ptr_type;
procedure glitch_filter(dp:x_graph_ptr_type;threshold:real);
procedure window_function(dp:x_graph_ptr_type;extent:integer);
procedure calculate_ft_term(period:real;dp:x_graph_ptr_type;var amplitude,offset:real);
procedure frequency_component(frequency:real;dp:x_graph_ptr_type;var amplitude,offset:real);
function fft(dp:xy_graph_ptr_type):xy_graph_ptr_type;
function fft_inverse(ft:xy_graph_ptr_type):xy_graph_ptr_type;
function fft_real(dp:x_graph_ptr_type):xy_graph_ptr_type;
function fft_real_inverse(ft:xy_graph_ptr_type):x_graph_ptr_type;
procedure straight_line_fit(dp:xy_graph_ptr_type;
	var slope,intercept,rms_residual:real);
procedure weighted_straight_line_fit (dp:xyz_graph_ptr_type;
	var slope,intercept,rms_residual:real);
procedure linear_interpolate(dp:xy_graph_ptr_type;position:real;
	var result:real);
function nearest_neighbor(var point,library:matrix_type):integer;

{simplex fitting}
procedure simplex_step(var simplex:simplex_type;
	altitude:simplex_altitude_function_type);
function simplex_volume(var simplex:simplex_type):real;
function simplex_size(var simplex:simplex_type):real;
procedure simplex_sort(var simplex:simplex_type);
procedure simplex_construct(var simplex:simplex_type;
	altitude:simplex_altitude_function_type);
	
{sorting}
procedure bubble_sort(a,b:integer;
	swap:sort_swap_procedure_type;
	greater:sort_compare_function_type);
procedure quick_sort(a,b:integer;
	swap:sort_swap_procedure_type;
	greater:sort_compare_function_type);

{matrices}
procedure unit_matrix(var M:matrix_type);
procedure matrix_product(var A,B,M:matrix_type);
function matrix_determinant(var M:matrix_type):real;
procedure matrix_difference(var A,B,M:matrix_type);
procedure matrix_inverse(var A,M:matrix_type);
procedure swap_matrix_rows(var M:matrix_type;row_1,row_2:integer);

{geometry}
function ij_origin:ij_point_type;
function ij_separation(a,b:ij_point_type):real;
function ij_difference(a,b:ij_point_type):ij_point_type;
function ij_dot_product(a,b:ij_point_type):real;
procedure ij_clip_line(var line:ij_line_type;var outside:boolean;clip:ij_rectangle_type);
procedure ij_clip_rectangle(var rect:ij_rectangle_type;clip:ij_rectangle_type);
function ij_combine_rectangles(a,b:ij_rectangle_type):ij_rectangle_type;
function ij_line_crosses_rectangle(line:ij_line_type;rect:ij_rectangle_type):boolean;
function ij_line_line_intersection(l1,l2:ij_line_type):ij_point_type;
function ij_in_rectangle(point:ij_point_type;rect:ij_rectangle_type): boolean;	
function ij_random_point(rect:ij_rectangle_type):ij_point_type;
function xy_difference(p,q:xy_point_type):xy_point_type;
function xy_dot_product(p,q:xy_point_type):real;
function xy_random:xy_point_type;
function xy_length(p:xy_point_type):real;
function xy_bearing(p:xy_point_type):real;
function xy_line_line_intersection(l1,l2:xy_line_type):xy_point_type;
function xy_origin:xy_point_type;
function xy_rotate(p:xy_point_type;r:real):xy_point_type;
function xy_scale(p:xy_point_type;scale:real):xy_point_type;
function xy_separation(p,q:xy_point_type):real;
function xy_sum(p,q:xy_point_type):xy_point_type;
function xy_unit_vector(p:xy_point_type):xy_point_type;
function xy_rectangle_ellipse(rect:xy_rectangle_type):xy_ellipse_type;
function xyz_random:xyz_point_type;
function xyz_length(p:xyz_point_type):real;
function xyz_dot_product(p,q:xyz_point_type):real;
function xyz_cross_product(p,q:xyz_point_type):xyz_point_type;
function xyz_angle(p,q:xyz_point_type):real;
function xyz_unit_vector(p:xyz_point_type):xyz_point_type;
function xyz_scale(p:xyz_point_type;scale:real):xyz_point_type;
function xyz_sum(p,q:xyz_point_type):xyz_point_type;
function xyz_origin:xyz_point_type;
function xyz_difference(p,q:xyz_point_type):xyz_point_type;
function xyz_separation(p,q:xyz_point_type):real;
function xyz_z_plane(z:real):xyz_plane_type;
function xyz_transform(M:xyz_matrix_type;p:xyz_point_type):xyz_point_type;
function xyz_matrix_from_points(p,q,r:xyz_point_type):xyz_matrix_type;
function xyz_plane_plane_plane_intersection(p,q,r:xyz_plane_type):xyz_point_type;
function xyz_line_plane_intersection(line:xyz_line_type;plane:xyz_plane_type):xyz_point_type;
function xyz_plane_plane_intersection(p,q:xyz_plane_type):xyz_line_type;
function xyz_line_reflect(line:xyz_line_type;plane:xyz_plane_type):xyz_line_type;
function xyz_point_line_vector(point:xyz_point_type;line:xyz_line_type):xyz_point_type;
function xyz_line_line_bridge(p,q:xyz_line_type):xyz_line_type;
function xyz_point_plane_vector(point:xyz_point_type;plane:xyz_plane_type):xyz_point_type;
function xyz_matrix_determinant(A:xyz_matrix_type):real;
function xyz_matrix_inverse(A:xyz_matrix_type):xyz_matrix_type;
function xyz_matrix_difference(A,B:xyz_matrix_type):xyz_matrix_type;
function xyz_rotate(point,rotation:xyz_point_type):xyz_point_type;
function xyz_unrotate(point,rotation:xyz_point_type):xyz_point_type;

{file}
function new_byte_array(size:integer):byte_array_ptr;
procedure dispose_byte_array(b:byte_array_ptr);
function read_file(name:short_string):byte_array_ptr;
procedure write_file(name:short_string;b:byte_array_ptr);

implementation

var
	start_time:longint; {start time in microseconds}
	mark_time_list:array [0..max_num_time_marks] of short_string;
	mark_time_index:integer=0;

{
	full_arctan calculates the arctangent of a/b, giving an answer between-pi and 
	pi radians.
}
function full_arctan(a,b:real):real;
var
	phase: real;
begin
	if (b=0) and (a=0) then phase:=0;
	if (b=0) and (a>0) then phase:=pi/2;
	if (b=0) and (a<0) then phase:=3*pi/2;
	if (b>0) and (a>=0) then phase:=arctan(a/b);
	if (b<0) and (a>=0) then phase:=pi-arctan(-a/b);
	if (b<0) and (a<0) then phase:=pi+arctan(a / b);
	if (b>0) and (a<0) then phase:=2*pi-arctan(-a/b);
	if phase>pi then phase:=-(2*pi-phase);
	full_arctan := phase;
end;

{
	sum_sinusoids adds two sinusoids of the same frequency but differing phase and
	amplitude.
}
function sum_sinusoids(a,b:sinusoid_type):sinusoid_type;
var
	p,q:real;
	sum:sinusoid_type;
begin
	p:=a.amplitude + b.amplitude*cos(b.phase-a.phase);
	q:=b.amplitude*sin(b.phase-a.phase);
	sum.amplitude:=sqrt(p*p+q*q);
	sum.phase:=full_arctan(q,p);
	sum_sinusoids:=sum;
end;

{
	xpy returns x to the power y.
}
function xpy(x,y:real):real;

begin
	if (x<0) then begin
		report_error('x<0 in xpy in xpy.');
		xpy:=0;
	end;
	if (x=0) then begin
		xpy:=0;
	end;
	if (x>0) then begin
		if y<>0 then xpy:=exp(ln(x)*y)
		else xpy:=1;
	end;
end;

{
	xpy is the same as xpy, but y is an integer greater than or equal to zero.
}
function xpyi(x:real;y:integer):real;
var i:integer;z:real;
begin
	z:=1;
	for i:=1 to abs(y) do z:=z*x;
	if y<0 then xpyi:=1/z else xpyi:=z;
end;{function xpy}

{
	factor_16 returns 16 to the power x
}
function factor_16(x:integer):cardinal;

var
	i,y:cardinal;

begin
	y:=1;
	for i:=1 to x do y:=y*16;
	factor_16:=y;
end;{sub-function}

{
	factorial calculates n!.
}
function factorial(n:integer):real;

var
	i:integer;
	product:real;
	
begin
	product:=1;
	for i:=2 to n do product:=product*i;
	factorial:=product;
end;

{
	error_function calculates the error function, the integral from zero to u of
	2/sqrt(pi)*exp(-x*x) with respect to x, by using an approximate series
	expansion. We calculate the series expansion efficiently using the method
	described to us by Harley Flanders. The routine is accurate to ten decimal
	places for 0 < u < 4 and runs in 20 us on a 1-GHz iBook G4. 
	
	The series expansion is:
	
	erf(x) = 2/sqrt(pi) * sum(n=0 to max_n) of (-1)^n * x^(2n+1) / (2n+1)n! 
		= sum(n=0 to max_n) of T(n)
	
	Each term for n>=1 is related to the previous term by:
	
	T(n) = T(n-1) * -1 * x * x * (2n-1) / (2n+1)n
	
	We proceed from n=1 to max_n by adding the previous term multiplied by the above
	factor to our sum.
}
function error_function(x:real):real;

const
	max_n=100;
	
var
	n:integer;
	sum,term:real;
	
begin
	if (x<0) then begin
		error_function:=0;
		exit;
	end;
	
	term:=x;
	sum:=x;
	for n:=1 to max_n do begin
		term:=term*(-1.0)*x*x*(2*n-1.0)/(2.0*n+1)/n;
		sum:=sum+term;
	end;
	error_function:=sum*2/sqrt(pi);
end;

{
	complimentary_error_function calculates the complimentary error function, which is 1 - erf.
}
function complimentary_error_function(x:real):real;
begin complimentary_error_function:=1-error_function(x); end;

{
	gamma_function uses a version of the Lanczos Approximation we found here:
	
	http://www.rskey.org/gamma.htm
	
	The routine is accurate to six significant figures for z<10 and takes 10 us on
	a 1 GHz G4 laptop. Thanks to Harley Flanders for pointing out this routine to
	us. 
}
function  gamma_function(z:real):real;

const
	max_index=6;
	coefficients:array[0..max_index] of real =
		(75122.6331530,80916.6278952,36308.2951477,8687.24529705,
		1168.92649479,83.8676043424,2.50662827511);

var
	sum,product:real;
	n:integer;
	
begin
	if z>0 then begin
		sum:=0;
		for n:=0 to max_index do
			sum:=sum+coefficients[n]*xpy(z,n);
		product:=1;
		for n:=0 to max_index do 
			product:=product*(z+n);
		gamma_function:=sum/product*xpy(z+5.5,z+0.5)*exp(-z-5.5);
	end;
	if z<0 then begin
		gamma_function:=-pi/(-z*gamma_function(-z)*sin(-pi*z));
	end;
	if z=0 then begin
		gamma_function:=0;
	end;
end; 

{
	chi_squares_distribution gives the value of the sum of chi squares
	distribution for a fit with the specified number of parameters, at your 
	specified value of sum of chi squares. Because the function is a ratio
	of two terms that both become very large with large sum_chi_square and
	num_paramters, we calculate it in steps, so that we keep a running ratio
	that is manageable. A one-step calculation would look like this:

	chi_squares_distribution := 	
		xpy(sum_chi_squares,num_parameters/2 - 1)
			*exp(-sum_chi_squares/2)
			/xpy(2,num_parameters/2)
			/gamma_function(num_parameters/2);

	The exponents are all terms in half of the two parameters, so in our routine
	we work with half-values of the parameters, decrementing each by 1 until it
	drops below our threshold. After that, we implement the above formula on the
	remaining factors.
}
function chi_squares_distribution(sum_chi_squares:real;num_parameters:integer):real;

const
	np2_min=2;
	ncs2_min=2;
	max_d=100000000000;
	min_d=0.0000000001;
	
var
	d:real;
	ncs2,np2:real;
	e:real;
	counter,max_counter:integer;
	
begin
	if num_parameters<=0 then d:=0
	else if sum_chi_squares<0 then d:=1
	else begin
		max_counter:=num_parameters+round(sum_chi_squares);
		e:=exp(1);
		d:=1;
		ncs2:=sum_chi_squares/2;
		np2:=num_parameters/2;
		counter:=0;
		while (ncs2>ncs2_min) or (np2>np2_min) do begin
			if (np2>np2_min) and (d<max_d) then begin
				d:=d*sum_chi_squares/2/(np2-1);
				np2:=np2-1;
			end;
			if (ncs2>ncs2_min) and (d>min_d) then begin
				d:=d/e;
				ncs2:=ncs2-1;
			end;
			inc(counter);
			if counter>max_counter then break;
		end;
		if counter<max_counter then
			d:=d*xpy(sum_chi_squares,np2 - 1)
				*exp(-ncs2)
				/xpy(2,np2)
				/gamma_function(np2)
		else d:=0;
	end;
	
	check_for_math_error(d);
	chi_squares_distribution:=d;
end;

{
	chi_squares_probability returns the probability that the sum of chi squares
	from a fit with num_parameters parameters will exceed sum_chi_squares. We
	integrate the chi squares distribution to obtain our answer, which avoids
	using multiple-approximations. For num_parameters=1, the distribution tends
	to infinity as sum_chi_squares tends to zero. You could use the exact error
	function solution for num_parameters=1, like this:

	probability:=complimentary_error_function(sqrt(sum_chi_squares*one_half))

	We could include such an option in our routine, but we don't. Instead, we go
	through some effort to integrate the chi squares distribution in the
	neighborhood of zero, and so obtain an approximation of the complimentary
	error function that is accurate to better than 1% all the way down to
	sum_chi_squares=0. For num_parameters>1, the distribution is finite at zero,
	and for large num_parameters, its value at zero becomes insignificant
	compared to the peak of the distribution, which occurs somewhere in the
	neighborhood of sum_chi_squares = num_parameters. As num_parameters
	increases, this peak becomes narrower. Our numerical integration of the
	distribution tries to be efficient about its choice of step size and the
	interval of sum_chi_squares over which it operates. The distribution
	calculation time increases with num_parameters, while at the same time its
	peak becomes narrower in proportion to the value of its center
	sum_chi_squares. We reduce the integration time by paying particular
	attention to integrating throughout the peak, and not elsewhere. This we do
	by checking if sum_chi_squares is less than num_parameters. If it is, then
	we first integrate the distribution from sum_chi_squares = num_paramters
	until the incremental additions we are making to the integral with each step
	fall below stop_element. We go back and integrate downwards from
	num_parameters to sum_chi_squares. If the elements are smaller than
	stop_element, then we stop. In the case of num_parameters=1, and
	sum_chi_squares=0, we start reducing the step size by asymptotic_factor as
	we approach zero, and stop only when the incremental additions drop below
	stop_element. We are able to use sum_chi_squares = num_parameters as a
	starting point because we are certain that for all values of num_paramters,
	the value of the distribution returned by our distribution routine is
	greater than 10% of its peak value. We have tested this for values of
	num_parameters up to ten million. If sum_chi_squares is greater than
	num_parameters, all we do is integrate from sum_chi_squares up, until the
	elements are smaller than stop_element.

	We can test the performance of the integration for num_parameters=1 by
	comparing it to the complimentary error function. We can test it for
	num_parameters>1 by setting sum_chi_squares to zero. The intergral should
	come up with probability 1.000. For num_parameters ranging from one to one
	million, we find the integral is accurate to better than 1%.
	
	When num_paramters is one million and sum_chi_squares is zero, the integral
	execution time is roughly 600 ms on a 1-GHz G4, and it comes up with the
	answer 0.9996. For num_parameters one thousand, and sum_chi_squares zero,
	the execution time drops to 2.5 ms.
}
function chi_squares_probability(sum_chi_squares:real;num_parameters:integer):real;

const
	x_step_factor=0.1;
	stop_element=0.0001;
	asymptotic_fraction=0.5;
	show_progress=false;
	step_exponent=0.7;
	
var
	integral,significant_csd,x,x_step,csd,element:real;

	procedure show(s:short_string);
	begin
		if show_progress then
			writeln(x:1:3,' ',x_step:1:3,' ',csd:1:9,' ',
				element:1:9,' ',integral:1:9,' ',s);
	end;
	
begin
	integral:=0;
	if (num_parameters <= 0) or (sum_chi_squares < 0) then integral:=0
	else begin
		x_step:=xpy(num_parameters,step_exponent)*x_step_factor;
		if sum_chi_squares<num_parameters then begin
			x:=num_parameters;
			repeat
				csd:=chi_squares_distribution(x+x_step*one_half,num_parameters);
				element:=x_step*csd;
				integral:=integral+element;
				show('Up from center.');
				x:=x+x_step;
			until element<stop_element;	
			x:=num_parameters;
			repeat
				csd:=chi_squares_distribution(x-x_step*one_half,num_parameters);
				element:=x_step*csd;
				integral:=integral+element;
				show('Down from center.');
				x:=x-x_step;
			until (x-x_step<sum_chi_squares+x_step) or (element<stop_element);
			if (element>stop_element) then begin
				repeat
					x_step:=asymptotic_fraction*(x-sum_chi_squares);
					csd:=chi_squares_distribution(x-x_step*one_half,num_parameters);
					element:=csd*x_step;
					integral:=integral+element;
					show('Asymptotic to end.');
					x:=x-x_step;
				until element<stop_element;
			end;
		end else begin
			x:=sum_chi_squares;
			repeat
				csd:=chi_squares_distribution(x+x_step*one_half,num_parameters);
				element:=csd*x_step;
				integral:=integral+element;
				show('Up from sum_chi_squares.');
				x:=x+x_step;
			until element<stop_element;
		end;
	end;
		
	chi_squares_probability:=integral;
	check_for_math_error(integral);
 end;

{
	delete_substring creates a new string by deleting count characters
	from a string starting at character index.
}
function delete_substring(s:short_string;index,count:integer):short_string;
begin
	delete(s,index,count);
	delete_substring:=s;
end;

{
	char_from_digit converts a number into a character 0..9 or A..Z.
}
function char_from_digit(digit:integer):char;

const
	max_for_decimal_digit=9;
	max_digit=26+9;

begin
	if(digit>max_digit) or(digit<0) then digit:=0;
	if digit in [0..max_for_decimal_digit] then char_from_digit:=chr(ord('0')+digit)
	else char_from_digit:=chr(ord('A')+digit-max_for_decimal_digit-1);
end;

{
	digit_from_char converts a character into a number 0..35.
}
function digit_from_char(c: char): integer;

const
	invalid_digit=-1;

var
	x:integer;

begin
	x:=invalid_digit;
	if(ord(c)>=ord('0')) and(ord(c)<=ord('9')) then x:=ord(c)-ord('0');
	if(ord(c)>=ord('A')) and(ord(c)<=ord('F')) then x:=ord(c)-ord('A')+10;
	if(ord(c)>=ord('a')) and(ord(c)<=ord('f')) then x:=ord(c)-ord('a')+10;
	digit_from_char:= x;
end;{sub-function}

{
	hex_string_from_cardinal takes a 32-bit unsigned integer and converts it into 
	a hex string eight digits long.
}
function hex_string_from_cardinal(number:cardinal):short_string;

const
		size=hex_digits_per_byte*sizeof(cardinal);
		
var
	line:string[size];
	digit:integer;

begin 
	line:=char_from_digit(number div factor_16(size-1));
	for digit:=size-1 downto 1 do
		line:=line+char_from_digit((number mod factor_16(digit)) div factor_16(digit-1));
	hex_string_from_cardinal:= line;
end;

{
	cardinal_from_hex_string takes a hex string, which may or may not have a leading
	'$' character, and turns it into a integer. If any one of the characters, after the leading
	space and '$' character, is not a hex character, then we return zero.
}
function cardinal_from_hex_string(s:short_string):cardinal;

const
	max_size=8;

var
	index: integer;
	value: integer;
	valid: boolean;
	digit: integer;

begin 
	while(s[1]=' ') or(s[1]='$') do delete(s,1,1);
	value:=0;	
	valid:=true;
	if length(s)<=max_size then begin
		for index:=1 to length(s) do begin
			digit:=digit_from_char(s[index]);
			value:=value+digit*factor_16(length(s)-index);
			if digit<0 then valid:=false;
		end;
	end;
	if valid then cardinal_from_hex_string:=value
	else cardinal_from_hex_string:=0;
end;

{
	hex_string_from_byte converts a byte into a string of two hex(base-sixteen) characters.
}
function hex_string_from_byte(number:byte):short_string;

const
		size=hex_digits_per_byte*sizeof(byte);
		
var
	line:string[size];
	digit:integer;

begin 
		line:=char_from_digit(number div factor_16(size-1));
		for digit:=size-1 downto 1 do
			line:=line+char_from_digit((number mod factor_16(digit)) div factor_16(digit-1));
		hex_string_from_byte:=line;
end;

{
	string_from_decimal converts a positive decimal number to a string of num_digits 
	characters representing its value in base 'base'.
}
function string_from_decimal(decimal_number:integer;base,num_digits:integer):short_string;
	
const
	mask=$7FFFFFFF;
	max_num_digits=32;
	max_base=$7FFFFFFF;
	default_base=10;
	
var
	digit_string:string[max_num_digits];
	index:integer;
	
begin 
	decimal_number:=decimal_number and mask;
	
	if(num_digits>max_num_digits) or(num_digits<1) then 
		num_digits:=max_num_digits;
	
	if(base<0) or(base>max_base) then 
		base:=default_base;
	
	digit_string:='';	
	for index:=1 to num_digits do begin 
		digit_string:=
			char_from_digit(decimal_number mod base)
			+digit_string;
		decimal_number:=decimal_number div base;
	end;

	string_from_decimal:=digit_string;
end;

{
	decimal_from_string does the opposite of string_from_decimal: it converts a string 
	expressing a number in a specified base into a decimal integer.
}
function decimal_from_string(s:short_string;base:integer):integer;

var
	index: integer;
	x: integer;

	function factor(x: integer): integer;
	var
		i: integer;
		y: integer;
	begin
		y := 1;
		for i := 1 to x do y := y * base;
		factor := y;
	end;
	
begin 
	x := 0;
	for index := 1 to length(s) do
		x := x + digit_from_char(s[index])
					*factor(length(s) - index);
	decimal_from_string := x;
end;

{
	string_from_real takes a real number and turns it into an ascii string of length
	field_width and allowing decimal_places digits after the decimal point.
}
function string_from_real(value:real;field_width,decimal_places:integer):short_string;

const
	max_field_width=10;
	base=10;
	failure_string='NaN ';
	
var
	s:short_string;
	digit_num,top_digit_num,bottom_digit_num,digit:integer;
	leading_zeros,negative:boolean;
	test_increment:real;
	
begin
	s:='';

	top_digit_num:=max_field_width;
	
	negative:=(value<0);
	if negative then begin
		value:=-value;
		dec(top_digit_num)
	end;
	
	if (decimal_places>0) then top_digit_num:=top_digit_num-decimal_places;
	bottom_digit_num:=-decimal_places;

	if (top_digit_num<=bottom_digit_num) then begin
		string_from_real:=failure_string;
		report_error('Invalid field sizes in string_from_real.');
		exit;
	end;

	while (trunc(value/xpyi(base,top_digit_num))>=base) 
			and (top_digit_num<max_field_width) do
		inc(top_digit_num);
	
	leading_zeros:=true;
	value:=value+xpy(base,bottom_digit_num-1);
	for digit_num:=top_digit_num downto bottom_digit_num do begin
		if digit_num=-1 then s:=s+'.';
		digit:=trunc(value/xpy(base,digit_num));
		if (digit>0) or (digit_num<1) then leading_zeros:=false;
		if not leading_zeros then s:=s+char_from_digit(digit);
		value:=value-digit*xpyi(base,digit_num);
	end;
	
	if negative then s:='-'+s;
	while(length(s)<field_width) do s:=' '+s;
	string_from_real:=s;
end;

{
	string_from_integer takes an integer and turns it into an ascii string fsi characters long.
}
function string_from_integer(value,fsi:integer):short_string;

const
	max_fsi=20;
	
var
	s:short_string;
	fsr:integer;
	
begin
	if((fsi<=1) or(fsi>=max_fsi)) then fsr:=max_fsi
	else fsr:=fsi;
	s:=string_from_real(value,fsr,0);
	if(fsi<=1) then s:=strip_spaces(s);
	string_from_integer:=s;
end;

{
	real_from_string takes a string and interprets it as a real number. If it
	cannot make a real number out of the string, the routine returns zero and
	appends an error string to the global error_string. If you pass the routine
	an empty string, it returns the value zero but does not generate an error.
	Whenever it fails to read a real number, the routine returns okay set to
	false.
}
function real_from_string(s:short_string;var okay:boolean):real;

const
	max_exponent=99;

type
	states=(start,preamble,int,dec,separator,exponent,done,fail,quit);

var
	state:states;
	places,index:integer;
	sign: -1..1;
	power:integer;
	value:real;

begin
	okay:=true;
	state:=start;
	repeat
		case state of
			start:begin
				index:=1;value:=0;places:=0;sign:=+1;power:=0;
				if length(s)<>0 then state:=preamble
				else state:=fail;
			end;

			preamble:begin
				case s[index] of
					'0','1','2','3','4','5','6','7','8','9':state:=int;
					'-':begin index:=index+1;sign:=-1*sign;state:=preamble;end;
					'+',' ':begin index:=index+1;state:=preamble;end;
					'.':begin index:=index+1;state:=dec;end;
					else state:=fail;
				end;
			end;

			int:begin
				if index>length(s) then state:=done
				else case s[index] of
					'0','1','2','3','4','5','6','7','8','9':begin
						value:=value*10+sign*(ord(s[index])-ord('0'));
						index:=index+1;state:=int;
					end;
					'.':begin index:=index+1;state:=dec;end;
					'e','E':begin index:=index+1;state:=separator;sign:=+1;end;
					',',' ':state:=done
					else state:=fail;
				end;
			end;

			dec:begin
				if(index>length(s)) then state:=done
				else case s[index] of
					'0','1','2','3','4','5','6','7','8','9':begin
						places:=places+1;
						value:=value+
						sign*(ord(s[index])-ord('0'))/xpy(10,places);
						index:=index+1;state:=dec;
						end;
					'e','E':begin index:=index+1;state:=separator;sign:=+1;end;
					',',' ':state:=done
					else state:=fail;
				end;
			end;

			separator:begin
				case s[index] of
					'0','1','2','3','4','5','6','7','8','9':state:=exponent;
					'-':begin index:=index+1;sign:=-1*sign;state:=separator;end;
					'+':begin index:=index+1;state:=separator;end;
					' ':begin index:=index+1;state:=separator;end
					else state:=fail;
				end;
			end;

			exponent:begin
				if index>length(s) then state:=done
				else case s[index] of
					'0','1','2','3','4','5','6','7','8','9':begin
						power:=power*10+sign*(ord(s[index])-ord('0'));
						index:=index+1;state:=exponent;
					end;
					' ',',':state:=done
					else state:=fail;
				end;
			end;

			done:begin
				if abs(power)>=max_exponent then state:=fail
				else begin
					if power>0 then for places:=1 to power do value:=value*10;
					if power<0 then for places:=-1 downto power do value:=value/10;
					state:=quit;
				end;
			end;

			fail:begin 
				okay:=false;
				state:=quit;
				if s<>'' then
					report_error('Invalid string "'+s+'" in real_from_string.');
			end;
		end;{case state of}
	until state=quit;

	if okay then real_from_string:=value
	else real_from_string:=0;
end;

{
	integer_from_string takes a string and interprets it as an integer. If it cannot
	make an integer out of the string, the routine returns zero and sets the okay
	flag to false. Instead of objecting to a fractional real number, we simply round
	it off to the nearest integer and pass that number back.
}
function integer_from_string(s:short_string; var okay:boolean):integer;

begin
	integer_from_string:=round(real_from_string(s,okay));
end;

{
	boolean_from_string takes a string and determines if it indicates boolean
	true or boolean false. The default value is false, except in the case of
	passing an empty string to the routine, in which case boolean_from_string
	returns true. We return true for empty strings so that an empty value string
	associated with an option in a command line will return true, to set the
	boolean option instead of clear it. If the string is not a boolean string,
	we don't issue and error or set an error flag. We just set the result to
	false.
}
function boolean_from_string(s:short_string):boolean;

var 
	value,okay:boolean;
	i:integer;
	
begin
	value:=false;
	if s<>'' then begin
		if s[1] in true_chars then value:=true
		else begin
			i:=integer_from_string(s,okay);
			if okay then value:=(i<>0);
		end;
	end else value:=true;
	boolean_from_string:=value;
end; 

{
	string_from_boolean takes a boolean and returns a string naming its value.
}
function string_from_boolean(value:boolean):short_string;
begin
	if value then string_from_boolean:=true_string
	else string_from_boolean:=false_string;
end;

{
	read_word is the basis of all the utils file-like string read routines.
	It extracts the first word from s and returns it. At the same time,
	read_word deletes the word from s, as well as any charcters it has skipped
	over while extracting the word. Note that read_word returns a short_string_type,
	which can then be used by other routines like boolean_from_string.
}
function read_word(var s:string):short_string;

var
	word:short_string;
	index:integer;
	comment,go:boolean;
	
begin
	word:='';
	read_word:=word;
	if s='' then exit;
	
	index:=0;
	comment:=false;
	go:=true;
	while go do begin
		inc(index);
		if index>length(s) then break;
		if (s[index] in start_comment_chars) then comment:=true;
		if (s[index] in end_comment_chars) then comment:=false;
		if (not comment) and (not (s[index] in separator_chars)) then go:=false;
	end;
	while (index<=length(s)) and (not (s[index] in separator_chars)) do begin
		word:=word+s[index];
		inc(index);
	end;
	delete(s,1,index-1);
	read_word:=word;
end;

{
	word_count returns the number of words in a string.
}
function word_count(var s:string):integer;

var
	i,count:integer;
	in_word:boolean;
	
begin
	if length(s)=0 then begin
		word_count:=0;
		exit;
	end;
	
	in_word:= not (s[1] in separator_chars);
	if in_word then count:=1 else count:=0;

	for i:=2 to length(s) do begin
		if (s[i] in separator_chars) then begin
			in_word:=false;		
		end else begin
			if not in_word then begin
				in_word:=true;
				inc(count);
			end;
		end;
	end;
	word_count:=count;
end;

{
	The following read_* functions read things out of a file string and delete them 
	as they go. We don't report anything if we fail to read the correct variable 
	type, but the global error_message will be set to indicated such a failure.
}
function read_real(var s:string):real;
var okay:boolean;
begin
	read_real:=real_from_string(read_word(s),okay);
end;

function read_xy(var s:string):xy_point_type;
var p:xy_point_type;
begin
	with p do begin
		x:=read_real(s);
		y:=read_real(s);
	end;
	read_xy:=p;
end;

function read_xyz(var s:string):xyz_point_type;
var p:xyz_point_type;
begin
	with p do begin
		x:=read_real(s);
		y:=read_real(s);
		z:=read_real(s);
	end;
	read_xyz:=p;
end;

function read_integer(var s:string):integer;
var okay:boolean;
begin
	read_integer:=integer_from_string(read_word(s),okay);
end;

function read_boolean(var s:string):boolean;
begin
	read_boolean:=boolean_from_string(read_word(s));
end;

procedure read_matrix(var s:string;var M:matrix_type);
var i,j:integer;
begin
	for j:=1 to M.num_rows do
		for i:=1 to M.num_columns do
			M[j,i]:=read_real(s);
end;

function read_kinematic_mount(var s:string):kinematic_mount_type;
var mount:kinematic_mount_type;
begin
	with mount do begin
		cone:=read_xyz(s);
		slot:=read_xyz(s);
		plane:=read_xyz(s);
	end;
	read_kinematic_mount:=mount;
end;

{
	Reads a sequence of space-delimited numbers from a string into
	an x_graph_type and returns a pointer to this graph. Does not
	alter the original string.
}
function read_x_graph(var s:string):x_graph_ptr_type;

var 
	num_points,point_num,index:integer;
	gp1,gp2:x_graph_ptr_type;
	w:short_string;
	okay:boolean;

begin
{
	Create a new graph long enough to accommodate the largest 
	possible number of numerical entries in the string.
}
	gp1:=new_x_graph(length(s));
{
	Read all available numerical entries from the string and put
	them in the new graph. If we encounter a bad numerical entry,
	we stop.
}
	num_points:=0;
	okay:=true;
	index:=1;
	while (index<=length(s)) and okay do begin
		while (index<=length(s)) and (s[index] in separator_chars) do 
			inc(index);
		w:='';
		while (index<=length(s)) and (not (s[index] in separator_chars)) do begin
			w:=w+s[index];
			inc(index);
		end;
		if w<>'' then begin
			gp1^[num_points]:=real_from_string(w,okay);
			inc(num_points);
		end;
	end;
{
	Create a new graph just the right size for the available points
	and fill it.
}
	if num_points>0 then begin
		gp2:=new_x_graph(num_points);
		for point_num:=0 to num_points-1 do
			gp2^[point_num]:=gp1^[point_num];
	end else begin
		gp2:=new_x_graph(1);
		gp2^[0]:=0;
	end;
{
	Dispose of the initial graph and return the fully-populated graph.
}
	dispose_x_graph(gp1);
	read_x_graph:=gp2;
end;

{
	Reads a sequence of space-delimited numbers from a string into
	an xy_graph_type and returns a pointer to this graph. Does not
	alter the original string. Returns an error if there are an odd
	number of numbers in the string.
}
function read_xy_graph(var s:string):xy_graph_ptr_type;

var 
	num_points,value_num,point_num:integer;
	gp1:x_graph_ptr_type;
	gp2:xy_graph_ptr_type;

begin
{
	Read the numbers out of the string and into an x-graph.
}
	gp1:=read_x_graph(s);
{
	Create an xy graph of the correct size.
}
	if gp1^.num_points>1 then begin
		gp2:=new_xy_graph(gp1^.num_points div 2);
{
	Go through the x-graph, reading pairs of x and y into the xy-graph.
}
		point_num:=0;
		value_num:=0;
		while (value_num<=gp1^.num_points-1) do begin
			gp2^[point_num].x:=gp1^[value_num];
			gp2^[point_num].y:=gp1^[value_num+1];
			inc(point_num);
			inc(value_num);
			inc(value_num);
		end;
{
	If there's an extra number on the end, we issue an error.
}
		if value_num<gp1^.num_points-1 then
			report_error('Missing y-value for final point in read_xy_graph.');
	end else begin
		gp2:=new_xy_graph(1);
		gp2^[0].x:=0;
		gp2^[0].y:=0;
	end;
{
	Dispose of the x-graph and return the xy-graph.
}
	dispose_x_graph(gp1);
	read_xy_graph:=gp2;
end;

{
	The following *_from_string functions transform strings into mathematical
	and geometric objects by copying an input string and then calling one of
	the above read_* routines on the copy. The copy is only 255 characters long,
	so if the original string is longer, it will be curtailed.
}
function xy_from_string(s:short_string):xy_point_type;
begin xy_from_string:=read_xy(s);end;

function xyz_from_string(s:short_string):xyz_point_type;
begin xyz_from_string:=read_xyz(s);end;

function xyz_line_from_string(s:short_string):xyz_line_type;
var l:xyz_line_type;
begin 
	l.point:=read_xyz(s);
	l.direction:=read_xyz(s);
	xyz_line_from_string:=l;
end;

function xyz_plane_from_string(s:short_string):xyz_plane_type;
var p:xyz_plane_type;
begin 
	p.point:=read_xyz(s);
	p.normal:=read_xyz(s);
	xyz_plane_from_string:=p;
end;

function kinematic_mount_from_string(s:short_string):kinematic_mount_type;
begin kinematic_mount_from_string:=read_kinematic_mount(s); end;

{
	The following "write_*" functions append a string to the end
	of a file string.
}
procedure write_ij(var s:string;p:ij_point_type);
const fsi=1; var a:short_string;
begin
	writestr(a,p.i:fsi,' ',p.j:fsi);
	s:=s+a;
end;

procedure write_xy(var s:string;p:xy_point_type);
var a:short_string;
begin
	writestr(a,p.x:fsr:fsd,' ',p.y:fsr:fsd);
	s:=s+a;
end;

procedure write_xyz(var s:string;p:xyz_point_type);
var a:short_string;
begin 
	writestr(a,p.x:fsr:fsd,' ',p.y:fsr:fsd,' ',p.z:fsr:fsd);
	s:=s+a;
end;

procedure write_xyz_line(var s:string;l:xyz_line_type);
var a:short_string;
begin 
	with l.point do writestr(a,x:fsr:fsd,' ',y:fsr:fsd,' ',z:fsr:fsd);
	with l.direction do writestr(a,a,' ',x:fsr:fsd,' ',y:fsr:fsd,' ',z:fsr:fsd);
	s:=s+a;
end;

procedure write_xyz_plane(var s:string;p:xyz_plane_type);
var a:short_string;
begin 
	with p.point do writestr(a,x:fsr:fsd,' ',y:fsr:fsd,' ',z:fsr:fsd);
	with p.normal do writestr(a,a,' ',x:fsr:fsd,' ',y:fsr:fsd,' ',z:fsr:fsd);
	s:=s+a;
end;

procedure write_xyz_matrix(var s:string;M:xyz_matrix_type);
var column_num,row_num:integer;a:short_string;
begin
	a:='';
	for row_num:=1 to num_xyz_dimensions do begin
		for column_num:=1 to num_xyz_dimensions do begin
			writestr(a,a,M[row_num,column_num]:fsr:fsd,' ');
		end;
		a:=a+eol;
	end;
	s:=s+a;
end;

procedure write_matrix(var s:string;var M:matrix_type);
var i,j:integer;
begin
	for j:=1 to M.num_rows do begin
		for i:=1 to M.num_columns do begin
			writestr(s,s,M[j,i]:fsr:fsd,' ');
		end;
		s:=s+eol;
	end;
end;

procedure write_kinematic_mount(var s:string;mount:kinematic_mount_type);
begin
	with mount do begin
		write_xyz(s,cone);
		write_xyz(s,slot);
		write_xyz(s,plane);
	end;
end;

{
	The following string_from_* routines call the write_* routines to create
	and return string representations of mathematical and geometric objects.
}
function string_from_ij(p:ij_point_type):short_string;
var s:short_string='';
begin
	write_ij(s,p);
	string_from_ij:=s;
end;

function string_from_xy(p:xy_point_type):short_string;
var s:short_string='';
begin
	write_xy(s,p);
	string_from_xy:=s;
end;

function string_from_xyz(p:xyz_point_type):short_string;
var s:short_string='';
begin
	write_xyz(s,p);
	string_from_xyz:=s;
end;

function string_from_xyz_line(l:xyz_line_type):short_string;
var s:short_string='';
begin
	write_xyz_line(s,l);
	string_from_xyz_line:=s;
end;

function string_from_xyz_plane(p:xyz_plane_type):short_string;
var s:short_string='';
begin
	write_xyz_plane(s,p);
	string_from_xyz_plane:=s;
end;

{
	delete_to_mark creates a new string by deleting all characters in 
	a string before and including the mark character. If there is no mark
	character in the string, the entire string is deleted, and we return
	an empty string.
}
function delete_to_mark(s:short_string;mark:char):short_string;
var p:integer;
begin 
	p:=pos(mark,s);
	if p>0 then delete(s,1,pos(mark,s))
	else s:='';
	delete_to_mark:=s;
end; 

{
	no_marks_left returns true if the string contains no mark characters.
}
function no_marks_left(s:short_string;mark:char):boolean;
begin 
	no_marks_left:=(pos(mark,s)=0); 
end;

{
	strip_folder_name deletes all characters in a string(a file name)
	up to and including the last folder (directory) separator, and 
		returns the new string, which we assume is the name of the file
		within its home folder (directory). The routine is imperfect in
		that it strips DOS, UNIT, and MacOS folder separators. A UNIX file
		with a colon in its name will be stripped of the characters leading
		up to the colon.
}
function strip_folder_name(s:short_string):short_string;
var 
		separator:char;		
begin
		for separator in file_name_separators do
				repeat
						s:=delete_to_mark(s,separator);
				until no_marks_left(s,separator);
	strip_folder_name:=s;
end;

{
	strip_spaces deletes all leading spaces.
}
function strip_spaces(s:short_string):short_string;
begin
	while s[1]=' ' do delete(s,1,1);
	strip_spaces:=s;
end;

{
	strip_separators deletes all leading separators.
}
function strip_separators(s:short_string):short_string;
begin
	while s[1] in separator_chars do delete(s,1,1);
	strip_separators:=s;
end;

{
	alphabet_char returns true iff c is a letter.
}
function alphabet_char(c:char):boolean;

begin
	alphabet_char:=
		((ord('a')<=ord(c)) and(ord('z')>=ord(c)))
		or
		((ord('A')<=ord(c)) and(ord('Z')>=ord(c)));
end;

{
	alphanumeric_char returns true iff c is a letter or a number.
}
function alphanumeric_char(c:char):boolean;

begin
	alphanumeric_char:=
		((ord('0')<=ord(c)) and(ord('9')>=ord(c)))
		or
		alphabet_char(c);
end;

{
	upper_case returns the upper-case only version of s.
}
function upper_case(s:short_string):short_string;

var
	index:integer;

begin
	for index:=1 to length(s) do 
		if(ord(s[index])>=ord('a')) and(ord(s[index])<=ord('z')) then
			s[index]:=chr(ord(s[index])+ord('A')-ord('a'));
	upper_case:=s;
end;

{
	lower_case returns the lower-case only version of s.
}
function lower_case( s:short_string):short_string;

var
	index:integer;

begin
	for index:=1 to length(s) do 
		if(ord(s[index])>=ord('A')) and(ord(s[index])<=ord('Z')) then
			s[index]:=chr(ord(s[index])+ord('a')-ord('A'));
	lower_case:=s;
end;

{
	string_match returns true if the subject string matches the key string.
	The key string may contain the '*' string wild-card, or the '?'
	character wild-card, but the subject string may not contain either wild
	card. The routine converts both key and subject to upper-case before it
	begins its comparison of the two strings, so the match is case insensitive.
}
function string_match(key,subject:short_string):boolean;

var
	match,key_empty,subject_empty:boolean;
	key_i,subject_i:integer;
	saved_char:char;
	
begin
	key:=upper_case(key);
	subject:=upper_case(subject);
	
	key_empty:=(key='');
	subject_empty:=(subject='');
	
	if(key_empty) and (subject_empty) then begin
		match:=true;
	end;

	if(key_empty) and (not subject_empty) then begin
		match:=false;
	end;

	if(not key_empty) and (subject_empty) then begin
		if(key[1]<>wild_string) then begin
			match:=false
		end
		else begin
			delete(key,1,1);
			match:=string_match(key,subject);
		end;
	end;

	if(not key_empty) and (not subject_empty) then begin
		if key[1]=wild_string then begin
			while (key<>'') and (key[1]=wild_string) do delete(key,1,1);
			if(key='') then match:=true
			else begin
				if(key='?') or(key[1]=subject[1]) then begin
					delete(key,1,1);
					delete(subject,1,1);
					match:=string_match(key,subject);
				end
				else begin
					repeat
						repeat
							delete(subject,1,1);
						until (subject='') or (subject[1]=key[1]);
						if(subject='') then match:=false
						else begin
							saved_char:=key[1];
							delete(key,1,1);
							delete(subject,1,1);
							match:=string_match(key,subject);
							if not match then key:=saved_char+key;
						end;
					until match or(subject='')
				end;
			end;
		end
		else begin
			if(key[1]=wild_char) or(key[1]=subject[1]) then begin
				delete(key,1,1);
				delete(subject,1,1);
				match:=string_match(key,subject);
			end
			else begin
				match:=false;
			end;
		end;
	end;
	string_match:=match;
end;

{
	strings_in_order returns true if a is alphabetically before b. If either
	string has zero length, or contains characters that are not alpha-numeric,
	then strings_in_order returns false.
}
function strings_in_order(a,b:short_string):boolean;

var
	i:integer;
	order,done:boolean;
	
begin
	a:=upper_case(a);
	b:=upper_case(b);
	order:=false;
	done:=(a='') or(b='');
	i:=1;
	repeat
		if(i>length(a)) and(i>length(b)) then done:=true;
		if(i>length(a)) and(i<=length(b)) then begin
			done:=true;
			order:=true;
		end;
		if(i>length(b)) and(i<=length(a)) then done:=true;
		
		if(i<=length(a)) or(i<=length(b)) then begin
			if a[i]<>b[i] then begin
				done:=true;
				if	alphanumeric_char(a[i]) and	alphanumeric_char(b[i]) then
					order:=ord(a[i])<ord(b[i]);
			end;
			inc(i);
		end;
	until done;
	strings_in_order:=order;
end;

{
	string_checksum returns an integer equal to the sum of the ordinal
	values of all characters in a string.
}
function string_checksum(s:short_string):integer;

var
	i,sum:integer;

begin
	sum:=0;
	for i:=1 to length(s) do sum:=sum+ord(s[i]);
	string_checksum:=sum;
end;

{
	new_long_string creates a new file string in memory and returns a 
	pointer to the file string.
}
function new_long_string:long_string_ptr;
var lsp:long_string_ptr;
begin
	lsp:=new(long_string_ptr);
	if lsp=nil then begin
		report_error('Failed to allocate lsp in new_long_string.');
		exit;
	end;
	inc_num_outstanding_ptrs(sizeof(lsp^),CurrentRoutineName);
	lsp^:='';
	new_long_string:=lsp;
end;

{
	dispose_file string disposes of a file string.
}
procedure dispose_long_string(lsp:long_string_ptr);
begin
	dec_num_outstanding_ptrs(sizeof(lsp^),CurrentRoutineName);
	dispose(lsp);
end;

{
	short_string_from_c_string returns the pascal version of c_string.
}
function short_string_from_c_string(c_string:CString):short_string;

var
	char_num:integer;
	s:short_string;

begin 
{$X+}
	char_num:=0;
	s:='';
	while(char_num<short_string_length) and (c_string[char_num]<>null_char) do begin
		inc(char_num); 
		s:=s+c_string[char_num-1];
	end;
	short_string_from_c_string:=s;
{$X-}
end;

{
	long_string_from_c_string returns the pascal version of c_string. We turn on 
	the X compiler options to allow us to refer to a C string with an index.
}
function long_string_from_c_string(c_string:CString):long_string_ptr;

var
	char_num:integer;
	sp:long_string_ptr;

begin 
{$X+}
	sp:=new_long_string;
	char_num:=0;
	sp^:='';
	while(char_num<long_string_length) and (c_string[char_num]<>null_char) do begin
		inc(char_num); 
		insert(c_string[char_num-1],sp^,length(sp^)+1);
	end;
	long_string_from_c_string:=sp;
{$X-}
end;

{
	c_string_from_short_string returns the c version of a pascal string.
}
function c_string_from_short_string(pascal_string:short_string):CString;

const
	null_character=chr(0); 
	max_string_length=255;

var
	char_num:integer;
	s:short_string;

begin 
	for char_num:=0 to length(pascal_string)-1 do 
		s[char_num]:=pascal_string[char_num+1];
	s[length(pascal_string)]:=null_character;
	c_string_from_short_string:=s;
end;

{
	straight_line_fit calculates the slope and intercept(on the y-axix)
	of the straight line with minimum rms residuals upon the data
	set specified by dp. It also calculates the rms residuals. If 
	the slope or intercept are infinite, we set error_string to
	a non-empty string using check_for_math_error.
}
procedure straight_line_fit(dp:xy_graph_ptr_type;
	var slope,intercept,rms_residual:real);

const
	min_num_points=2;

var 
	index:integer;	
	k00,k10,k01,k11,k20:real;
	
begin 
	slope:=0;intercept:=0;rms_residual:=0;
	if dp^.num_points>=min_num_points then begin
		k00:=0;k10:=0;k01:=0;k11:=0;k20:=0;
		for index:=0 to dp^.num_points-1 do begin
			with dp^[index] do begin
				k00:=k00+1;
				k10:=k10+x;
				k01:=k01+y;
				k11:=k11+x*y;
				k20:=k20+x*x;
			end;
		end;	
		if (k20*k00-k10*k10 <> 0) then begin
			slope:=(k11*k00-k01*k10)/(k20*k00-k10*k10);
			intercept:=(k01*k20-k11*k10)/(k20*k00-k10*k10);
		end else begin
			slope:=0;
			intercept:=0;
		end;
		rms_residual:=0;
		for index:=0 to dp^.num_points-1 do begin
			with dp^[index] do begin
				rms_residual:=rms_residual+sqr(x*slope+intercept-y);
			end;
		end;
		if dp^.num_points<>0 then 
			rms_residual:=sqrt(rms_residual/dp^.num_points);
	end 
	else begin
		slope:=0;
		if dp^.num_points=1 then intercept:=dp^[0].y
		else intercept:=0;
		rms_residual:=0;
	end;
	check_for_math_error(slope);
	check_for_math_error(intercept);
end;

{
	weighted_straight_line_fit acts as straight_line_fit, but it takes in 
	three-dimensional data: x,y and z. The first two are the points in the 
	line, and the last, z, is the weighting factor the routine should apply 
	to the point in the fit. This weighting factor must be greater than or
	equal to zero. If it is equal to the ignore_remaining_data constant, which
	is negative, then weighted_straight_line fit ignores the rest of the
	data in the graph.
}
procedure weighted_straight_line_fit (dp:xyz_graph_ptr_type;
	var slope,intercept,rms_residual:real);

const
	min_num_points=2;

var 
	index,num_points_used:integer;	
	k00,k10,k01,k11,k20:real;
	
begin 
	slope:=0;intercept:=0;rms_residual:=0;
	if dp^.num_points>=min_num_points then begin
		k00:=0;k10:=0;k01:=0;k11:=0;k20:=0;
		for index:=0 to dp^.num_points-1 do begin
			with dp^[index] do begin
				if (z=ignore_remaining_data) then break;
				k00:=k00+z;
				k10:=k10+x*z;
				k01:=k01+y*z;
				k11:=k11+x*y*z;
				k20:=k20+x*x*z;
			end;
		end;	
		num_points_used:=index;
		if num_points_used>min_num_points then begin
			if (k20*k00-k10*k10 <> 0) then begin
				slope:=(k11*k00-k01*k10)/(k20*k00-k10*k10);
				intercept:=(k01*k20-k11*k10)/(k20*k00-k10*k10);
			end else begin
				slope:=0;
				intercept:=0;
			end;
			rms_residual:=0;
			for index:=0 to num_points_used-1 do 
				with dp^[index] do 
					rms_residual:=rms_residual+z*sqr(y-x*slope-intercept);
			if k00>0 then rms_residual:=sqrt(rms_residual/k00)
		end else 
			if num_points_used=1 then intercept:=dp^[0].y
	end 
	else begin
		slope:=0;
		if dp^.num_points=1 then intercept:=dp^[0].y
		else intercept:=0;
		rms_residual:=0;
	end;
	check_for_math_error(slope);
	check_for_math_error(intercept);
end;

{
	linear_interpolate returns the value obtained by interpolating between
	the two nearest data points in a graph pointed to by dp. The data points
	do not have to be in ascending order in the graph.
}
procedure linear_interpolate(dp:xy_graph_ptr_type;position:real; 
	var result:real);

const
	min_num_points=2;

var
	index,lower_index,upper_index:integer;
	s:short_string;
	
begin
	if dp^.num_points<min_num_points then begin
		if dp^.num_points>0 then result:=dp^[0].y
		else result:=0;
	end else begin
		lower_index:=0;
		upper_index:=0;
		for index:=1 to dp^.num_points-1 do begin
			if (dp^[lower_index].x<=dp^[index].x) 
					and (dp^[index].x<=position) then
				lower_index:=index
			else if (position<dp^[lower_index].x)
					and (dp^[index].x<dp^[lower_index].x) then
				lower_index:=index;
			if (dp^[upper_index].x>=dp^[index].x) 
					and (dp^[index].x>=position) then
				upper_index:=index
			else if (position>dp^[upper_index].x)
					and (dp^[index].x>dp^[upper_index].x) then
				upper_index:=index;
		end;
		if (dp^[upper_index].x<>dp^[lower_index].x) then
			result:=(position-dp^[lower_index].x)
					*(dp^[upper_index].y-dp^[lower_index].y)
					/(dp^[upper_index].x-dp^[lower_index].x)
					+dp^[lower_index].y
		else result:=dp^[lower_index].y;
	end;
end;

{
	nearest_neighbor takes an N-dimensional point, p, and
	finds the nearest point to it in a library of N-dimensional
	points. We use matrix structures to store the point and
	the list. The point is a matrix of one row and N columns.
	The list is a matrix with M rows and n columns, where M
	is the number of points in the list. 
}
function nearest_neighbor(var point,library:matrix_type):integer;

var 
	separation,min_separation:real;
	i,j,min_j:integer;
	
begin
	nearest_neighbor:=0;
	
	if point.num_rows<>1 then begin
		report_error('point.num_rows<>1 in nearest_neighbor');
		exit;
	end;
	if library.num_rows<1 then begin
		report_error('library.num_rows<1 in nearest_neighbor');
		exit;
	end;
	if point.num_columns<>library.num_columns then begin
		report_error('point.num_columns<>library.num_columns in nearest_neighbor');
		exit;
	end;
	
	min_separation:=-1;
	for j:=1 to library.num_rows do begin
		separation:=0;
		for i:=1 to point.num_columns do
			separation:=separation+sqr(point[1,i]-library[j,i]);
		if (separation<min_separation) or (min_separation<0) then begin
			min_separation:=separation;
			min_j:=j;
		end;
	end;
	
	nearest_neighbor:=min_j;
end;

{
	The following functions allocate and dispose of space for
	graphs.
}
function new_x_graph(num_points:integer):x_graph_ptr_type;
var gp:x_graph_ptr_type;
begin
	if num_points<=0 then num_points:=1;
	new(gp,num_points);
	inc_num_outstanding_ptrs(sizeof(gp^),CurrentRoutineName);
	new_x_graph:=gp;
end;

procedure check_for_math_error(x:real);
var s,w:short_string;
begin
	writestr(s,x);
	w:=read_word(s);
	if (w='Inf') or (w='-Inf') or (w='NaN') then 
		report_error('Real number with value "'+w+'".');
end;

function math_error(x:real):boolean;
var s,w:short_string;
begin
	writestr(s,x);
	w:=read_word(s);
	if (w='Inf') or (w='-Inf') or (w='NaN') then 
		math_error:=true
	else 
		math_error:=false;
end;

function math_overflow(x:real):boolean;
begin
	if math_error(x) then 
		math_overflow:=true
	else if (abs(x)>large_real) or (abs(x)<small_real) then
		math_overflow:=true
	else 
		math_overflow:=false;
end;

function average_x_graph(gp:x_graph_ptr_type):real;
var i:integer;sum:longreal;ave:real;
begin
	if gp^.num_points<1 then begin
		average_x_graph:=0;
		exit;
	end;
	sum:=0;
	for i:=0 to gp^.num_points-1 do sum:=sum+gp^[i];
	ave:=sum/gp^.num_points;
	average_x_graph:=ave;
	check_for_math_error(ave);
end;

function max_x_graph(gp:x_graph_ptr_type):real;
var i:integer;max:real;
begin
	if gp^.num_points<1 then begin
		max_x_graph:=0;
		exit;
	end;
	max:=gp^[0];
	for i:=1 to gp^.num_points-1 do 
		if gp^[i]>max then max:=gp^[i];
	max_x_graph:=max;
	check_for_math_error(max);
end;

function min_x_graph(gp:x_graph_ptr_type):real;
var i:integer;min:real;
begin
	if gp^.num_points<1 then begin
		min_x_graph:=0;
		exit;
	end;
	min:=gp^[0];
	for i:=1 to gp^.num_points-1 do 
		if gp^[i]<min then min:=gp^[i];
	min_x_graph:=min;
	check_for_math_error(min);
end;

function stdev_x_graph(gp:x_graph_ptr_type):real;
var i:integer;sum:longreal;stdev,ave:real;
begin
	if gp^.num_points<1 then begin
		stdev_x_graph:=0;
		exit;
	end;
	sum:=0;
	ave:=average_x_graph(gp);
	for i:=0 to gp^.num_points-1 do 
		sum:=sum+sqr(gp^[i]-ave);
	stdev:=sqrt(sum/gp^.num_points);
	stdev_x_graph:=stdev;
	check_for_math_error(stdev);
end;

function new_xy_graph(num_points:integer):xy_graph_ptr_type;
var gp:xy_graph_ptr_type;
begin
	if num_points<=0 then num_points:=1;
	new(gp,num_points);
	inc_num_outstanding_ptrs(sizeof(gp^),CurrentRoutineName);
	new_xy_graph:=gp;
end;

function average_xy_graph(gp:xy_graph_ptr_type):real;
var i:integer;sum:longreal;ave:real;
begin
	if gp^.num_points<1 then exit;
	sum:=0;
	for i:=0 to gp^.num_points-1 do 
		sum:=sum+gp^[i].y;
	ave:=sum/gp^.num_points;
	average_xy_graph:=ave;
	check_for_math_error(ave);
end;

function stdev_xy_graph(gp:xy_graph_ptr_type):real;
var i:integer;sum:longreal;stdev,ave:real;
begin
	if gp^.num_points<1 then exit;
	sum:=0;
	ave:=average_xy_graph(gp);
	for i:=0 to gp^.num_points-1 do 
		sum:=sum+sqr(gp^[i].y-ave);
	stdev:=sqrt(sum/gp^.num_points);
	stdev_xy_graph:=stdev;
	check_for_math_error(stdev);
end;

function max_xy_graph(gp:xy_graph_ptr_type):real;
var i:integer;max:longreal;
begin
	if gp^.num_points<1 then exit;
	max:=gp^[0].y;
	for i:=1 to gp^.num_points-1 do 
		if max<gp^[i].y then max:=gp^[i].y;
	max_xy_graph:=max;
end;

function min_xy_graph(gp:xy_graph_ptr_type):real;
var i:integer;min:longreal;
begin
	if gp^.num_points<1 then exit;
	min:=gp^[0].y;
	for i:=1 to gp^.num_points-1 do 
		if min>gp^[i].y then min:=gp^[i].y;
	min_xy_graph:=min;
end;

function new_xyz_graph(num_points:integer):xyz_graph_ptr_type;
var gp:xyz_graph_ptr_type;
begin
	if num_points<=0 then num_points:=1;
	new(gp,num_points);
	inc_num_outstanding_ptrs(sizeof(gp^),CurrentRoutineName);
	new_xyz_graph:=gp;
end;

procedure dispose_x_graph(gp:x_graph_ptr_type);
begin
	dec_num_outstanding_ptrs(sizeof(gp^),CurrentRoutineName);
	dispose(gp);
end;

procedure dispose_xy_graph(gp:xy_graph_ptr_type);
begin
	dec_num_outstanding_ptrs(sizeof(gp^),CurrentRoutineName);
	dispose(gp);
end;

procedure dispose_xyz_graph(gp:xyz_graph_ptr_type);
begin
	dec_num_outstanding_ptrs(sizeof(gp^),CurrentRoutineName);
	dispose(gp);
end;

{
	window_function smooths off the first and last few samples of an
	x_graph_type with a ramp function so that they converge upon the
	graph's average value. If we specify extent = 3 then the window
	function affects the first and last 3 samples in the graph.
}
procedure window_function(dp:x_graph_ptr_type;extent:integer);

const
	min_multiple=2.0;
	
var
	n,m:integer;
	a:real;
	
begin
	if (extent<1) then exit;
	if dp=nil then exit;
	
	m:=dp^.num_points;
	if (m<=1) then exit;
	
	a:=average_x_graph(dp);
	if (min_multiple*extent>m) then extent:=round(m/min_multiple);

	for n:=0 to extent-1 do begin
		dp^[n]:=a+(dp^[n]-a)*n/extent;
		dp^[m-n-1]:=a+(dp^[m-n-1]-a)*n/extent;
	end;
end;

{
	The recursive_filter function implements a recursive filter with
	coefficients listed in the a_list and b_list strings. The a_list contains
	the coefficients used to multiply the input values and the b_list contains
	the recursion coefficients used to multiply the output values. The lists can
	have length up to max_poles+1. The a_list must begin with a[0], followed by
	a[1], a[2], and so on, until the string ends, and values after that will be
	set to zero by default. The b_list must have the same format, except it
	begins with b[1], and has maximum length max_poles. We always assume b[0] =
	0. The routine receives its data via an x-graph and returns data as an
	x-graph. It reads instructions and parameters from a command string.
}
function recursive_filter(x:x_graph_ptr_type;a_list,b_list:short_string):x_graph_ptr_type;

const
	min_num_points=2;
	max_poles=20;
	small_value=0.001;
	
var 
	i,k,n,end_b,end_a:integer;
	a:array [0..max_poles] of real;
	b:array [1..max_poles] of real;
	y:x_graph_ptr_type;
	dc_gain,p,q:real;

begin
	recursive_filter:=nil;
	if (x=nil) then exit;
	if (x^.num_points<min_num_points) then begin
		report_error('gp^.num_points<min_num_points in dsp');
		exit;
	end;	
	n:=x^.num_points;
	y:=new_x_graph(n);
	
	for i:=0 to max_poles do a[i]:=0;
	end_a:=0;
	while (a_list<>'') and (end_a<=max_poles) do begin
		a[end_a]:=read_real(a_list);
		inc(end_a);
	end;
	for i:=1 to max_poles do b[i]:=0;
	end_b:=1;
	while (b_list<>'') and (end_b<=max_poles) do begin
		b[end_b]:=read_real(b_list);
		inc(end_b);
	end;
	
	p:=0;
	for i:=0 to end_a do p:=p+a[i];
	q:=1;
	for i:=1 to end_b do q:=q-b[i];
	if abs(q)>small_value then dc_gain:=p/q
	else dc_gain:=1;
	
	for k:=0 to n-1 do begin
		y^[k]:=0;
		for i:=0 to end_a do
			if (k-i)>=0 then y^[k]:=y^[k]+a[i]*x^[k-i]
			else y^[k]:=y^[k]+a[i]*x^[0];
		for i:=1 to end_b do
			if (k-i)>=0 then y^[k]:=y^[k]+b[i]*y^[k-i]
			else y^[k]:=y^[k]+b[i]*x^[0]*dc_gain;
	end;
	
	recursive_filter:=y;
end;

{
	glitch_filter attempts to remove glitches from unreliable data. Any
	jump of more than threshold from one sample to the next will be 
	removed from the data. Starting up the filter takes some care: we must
	find a "standing value" to which to compare the first sample, and so
	detect a glitch that occurs at the start of the signal.
}
procedure glitch_filter(dp:x_graph_ptr_type;threshold:real);

const
	sub_threshold_fraction=0.1;
	min_length=3;
	
var
	n:integer;
	standing_value,sub_threshold:real;
	
begin
	if (threshold<=0) then exit;
	if dp=nil then exit;
	if (dp^.num_points<=min_length) then exit;
	
	n:=1;
	standing_value:=dp^[0];
	sub_threshold:=sub_threshold_fraction*threshold;
	while (n<dp^.num_points-1) do begin				
		if (abs(dp^[n-1]-dp^[n])<sub_threshold) 
			and (abs(dp^[n-1]-dp^[n])>0.0) 
			and (abs(dp^[n+1]-dp^[n])<sub_threshold) 
			and (abs(dp^[n+1]-dp^[n])>0.0) then begin
			standing_value:=dp^[n];
			n:=dp^.num_points;
		end else inc(n);
	end;

	for n:=0 to dp^.num_points-1 do begin
		if abs(dp^[n]-standing_value)>threshold then
			dp^[n]:=standing_value
		else
			standing_value:=dp^[n];
	end;
end;

{
	calculate_ft_term calculates the amplitude and offset of the
	discrete fourier transform component with sinusoidal period
	"period". We express period as a real-valued multiple of the
	sample period, T. The special case of period=0 we use to determine
	the DC component of the waveform. We pass data to the routine in
	an array of real numbers, each of which represents a sample.

	If your waveform has a significant DC component, we recommend you
	subtract the DC component from its elements before you calculate
	other components, because the DC component has a second-order
	effect upon the phase of other components.

	This routine returns a single component as an amplitude and an
	offset. The offset is related to the phase by phase =
	-2*pi*offset/period. You obtain the sinusoidal component value at
	point x with amplitude*sin(2*pi*(x-offset)/period).
	
	If you want to calculate the entire discrete fourier transform,
	and you have data with N a power of 2, then you can try our fft
	routine, but note that it returns complex-valued terms, which you
	have to convert into amplitude and offset. This routine returns
	amplitude and offset if a format that is convenient for image
	analysis. 
}
procedure calculate_ft_term(period:real;
	dp:x_graph_ptr_type;
	var amplitude,offset:real);

const
	scaling_factor=2;

var
	n:integer;
	phase_step,phase,a,b:real;

begin
	if dp=nil then exit;
	if (dp^.num_points<1) or (period<0) then exit;
	if (period=0) then begin
		phase:=0;
		amplitude:=average_x_graph(dp);
	end else begin
		phase_step:=2*pi/period;
		phase:=0;
		a:=0;
		b:=0;
		for n:=0 to dp^.num_points-1 do begin
			a:=a+cos(phase)*dp^[n];
			b:=b+sin(phase)*dp^[n];
			phase:=phase+phase_step;
		end;
		offset:=-period*full_arctan(a,b)/(2*pi);
		amplitude:=sqrt(sqr(a)+sqr(b))*scaling_factor/dp^.num_points;
	end;
	check_for_math_error(offset);
	check_for_math_error(amplitude);
end;

{
	frequency_component is like calculate_ft_term, but accepts a
	frequency as a multiple of the fundamental signal frequency, or
	1/<i>NT</i>, where <i>T</i> is the sample period and <i>N</i> is
	the number of samples. It returns the amplitude and offset of 
	a sine wave amplitude*sin(2*pi*(x-offset)*f/N). If you want to
	obtain a true complex-valued discrete fourier transform, try 
	our fft routine.
}
procedure frequency_component(frequency:real;
	dp:x_graph_ptr_type;
	var amplitude,offset:real);

const
	scaling_factor=2;

var
	n:integer;
	phase_step,phase,a,b:real;

begin
	amplitude:=0;
	offset:=0;
	if dp=nil then exit;
	if (dp^.num_points<1) then exit;
	phase_step:=2*pi*frequency/dp^.num_points;
	phase:=0;
	a:=0;
	b:=0;
	for n:=0 to dp^.num_points-1 do begin
		a:=a+cos(phase)*dp^[n];
		b:=b+sin(phase)*dp^[n];
		phase:=phase+phase_step;
	end;
	amplitude:=sqrt(sqr(a)+sqr(b))*scaling_factor/dp^.num_points;
	if frequency<>0 then offset:=-dp^.num_points*full_arctan(a,b)/(2*pi*frequency);
	check_for_math_error(offset);
	check_for_math_error(amplitude);
end;

{
	fft is a Fast Fourier Transform routine for determining the 
	discrete fourier transform in Nlog(N) time by a divide-and-conquer
	algorithm due to Colley and Tokey. The routine operates in the 
	complex plane, taking complex input data and producting complex
	transform components.
	
	fft takes a complex-valued sequence of N data points and returns
	the N complex-valued components that make up its complete discrete
	fourier transform. The routine takes its data in an xy_graph and
	returns the transform in another xy_graph. The routine is
	reversible also: if you pass the transform back to fft, you will
	re-construct the original data. Each term dp^[k] in the data is a
	complex number. The k'th term represents the k'th sample, with the
	samples being numbered 0 to N-1. The real part of the term is
	dp^[k].x and the imaginary part is dp^[k].y. When the data is a
	real-valued sequence of samples, the imaginary components are all
	zero. Each term in the output is likewise a complex number. The
	k'th term represents a sinusoidal function with frequency k/NT.
	The magnitude of the complex number is the amplitude of the
	sinusoid. The phase is the argument. The sinusoidal amplitude is
	therefore a = sqrt(sqr(tp^[k].x)+sqr(tp^[k].y)) and the sinusoidal
	phase is p = full_arctan(tp^[k].y/tp^[k].x)). So the sinusoidal
	component is a*sin(2*pi*k/NT - p).

	The fft_step implements the Cooley-Tukey FFT algorithm. The fft
	routine calls fft_step, and fft_step calls itself recursively. The
	recursion does not involve the allocation of new arrays because
	they all share the same memory. The routine sets up a transform
	array and a scratch array, each of N complex elements. It
	stores the evolving transform in the transform array, but performs
	the merging of odd and even components in the scratch array.

	We applied fft to sets of real-valued samples and measured
	execution time on an iBook G4 1.33 GHz by calculating the fft a
	hundred times and dividing the total execution time by 100. We
	obtained the following results for ascending values of N.
	
	N		Time (ms)
	64		0.28
	128		1.2
	256		2.2
	512		3.7
	1024	8.1
	2048	15
	4096	33

	We can use the fft routine to perform an inverse-transform also.
	Take the discrete fourier transform the routine produces and
	reverse the order of its terms, so that X(k) -> X(N-k), but note
	that X(N) = X(0) so the first term remains in place.
}
function fft(dp:xy_graph_ptr_type):xy_graph_ptr_type;

var
	tp,sp:xy_graph_ptr_type;

{
	The fft_step routine is the heart of the fft procedure. It
	implements the Cooley-Tukey algorithm, calling itself recursively.
	In each call, fft_step divides the transform job into two parts,
	each of half the size, and therefore one quarter the execution
	time. The first half consists of the transform of the odd-numbered
	samples. The second half is the transform of the even-numbered
	samples. The routine is complicated by the shared use of an
	existing scratch and transform array, but this sharing is
	neccessary to avoid allocating new arrays on every recursive call.
	After determining the sub-transforms, fft_step merges them
	together. When fft_step is called on data of length 1, it returns
	as its answer the single data point. We say "returns", but what
	actuall happens is the data point is copied over into the
	transform array.
}
	procedure fft_step(step,start:integer);
	
	var
		k,i_new,i_odd,i_even,npd2,np:integer;
		phase,phase_step:real;
		sc:xy_point_type;
		
	begin
		np:=dp^.num_points div step;
		npd2:=np div 2;
		if np>1 then begin
			fft_step(step*2,start);
			fft_step(step*2,start+step);
			
			for k:=0 to npd2-1 do begin
				i_new:=start+k*step;
				sc.x:=cos(-2*pi*k/np);
				sc.y:=sin(-2*pi*k/np);
				i_even:=start+2*k*step;
				i_odd:=i_even+step;
				sp^[i_new].x:=
					tp^[i_even].x
					+sc.x*tp^[i_odd].x-sc.y*tp^[i_odd].y;
				sp^[i_new].y:=
					tp^[i_even].y
					+sc.x*tp^[i_odd].y+sc.y*tp^[i_odd].x;
				i_new:=i_new+npd2*step;
				sp^[i_new].x:=
					tp^[i_even].x
					-sc.x*tp^[i_odd].x+sc.y*tp^[i_odd].y;
				sp^[i_new].y:=
					tp^[i_even].y
					-sc.x*tp^[i_odd].y-sc.y*tp^[i_odd].x;				
			end;
			
			for k:=0 to np-1 do begin
				i_new:=start+k*step;
				tp^[i_new]:=sp^[i_new];
			end;
		end else begin
			tp^[start]:=dp^[start];
		end;
	end;

var
	i:integer;
	scale:real;

begin
{
	A nil pointer indicates a problem.
}
	fft:=nil;
	if dp=nil then exit;
{
	We insist upon at least one data point.
}
	if dp^.num_points<1 then begin
		report_error('dp^.num_points<1 in fft');
		exit;
	end;
{
	We insist upon a number of samples that is a perfect power of two.
}
	i:=dp^.num_points;
	while ((i mod 2) = 0) do i:=i div 2;
	if (i>1) then begin
		report_error('dp^.num_points is not a power of two in fft');
		exit;
	end;
{
	We allocate space for our transform and for a scratch area, in which
	we will assemble intermediate transform components.
}
	tp:=new_xy_graph(dp^.num_points);
	sp:=new_xy_graph(dp^.num_points);
{
	Apply our recursive fft_step routine to the data.
}
	fft_step(1,0);
{
	Scale all the components by 1/N.
}
	scale:=1/tp^.num_points;
	for i:=0 to tp^.num_points-1 do begin
		tp^[i]:=xy_scale(tp^[i],scale);
	end;
{
	Dispose of the scratch area and return the completed transform.
}
	dispose_xy_graph(sp);
	fft:=tp;
end;

{
	fft_inverse takes a complex-valued spectrum of the form generated by
	our fft routine (its components have been scaled by 1/N to give the 
	correct sinusoidal amplitudes) and calculates the complex-valued inverse
	transform. The routine accepts N components and produces N points, where
	N must be a power of two. The fft_inverse works by reversing the order
	of the N frequency components and feeding them into the fft routine. After
	that, we scale the resulting components by N so that they have the correct
	magnitude.
}
function fft_inverse(ft:xy_graph_ptr_type):xy_graph_ptr_type;

var
	ftr,dp:xy_graph_ptr_type;
	k,n:integer;
	
begin
{
	A nil pointer indicates a problem.
}
	fft_inverse:=nil;
	if ft=nil then exit;
{
	Create a reverse-order array.
}
	ftr:=new_xy_graph(ft^.num_points);
	for k:=0 to ft^.num_points-1 do
		ftr^[k]:=ft^[(ft^.num_points-k) mod ft^.num_points];
{
	Obtain the inverse-transform.
}
	dp:=fft(ftr);
	dispose_xy_graph(ftr);	
	if dp=nil then exit;
{
	Scale the points by N.
}
	for n:=0 to dp^.num_points-1 do 
		dp^[n]:=xy_scale(dp^[n],dp^.num_points);
{
	Return the complex-valued data points.
}
	fft_inverse:=dp;
end;

{
	The fft_real function takes N real-valued samples in an x-graph and returns
	N/2 frequency components in an xy-graph. The frequency components are
	expressed as magnitude and phase, with phase in radians. The full discrete
	fourier transform (DFT), as implemented by our fft routine, produces N
	complex-valued components from N coplex-valued data points. But when the
	data points are real-valued (their imaginary parts are all zero), we find
	that the k'th component is the complex conjugate of the (N-k)'th component.
	Meanwhile, the (N-k)'th component is equivalent to the -k'th component, and
	the -k'th component is the complex conjugate of the k'th component. So we
	find that, for real-valued inputs, the sum of the k'th and (N-k)'th
	components is twice the k'th component. Thus we don't bother returning the
	top N/2 components for real-valued inputs. We just return twice the first
	N/2 components. The 0'th component is an exception. In this case we return
	the magnitude of the 0'th component and the magnitude of the N/2'th
	component. The phase of these components is always 0 or pi, never anything
	in between, and we can represent phase 0 with a positive magnitude and phase
	pi with a negative.
}
function fft_real(dp:x_graph_ptr_type):xy_graph_ptr_type;

var 
	dpxy,ft:xy_graph_ptr_type;
	n,k:integer;
	
begin
{
	A nil pointer indicates a problem.
}
	fft_real:=nil;
	if dp=nil then exit;
	if dp^.num_points<=1 then exit;
{
	Copy our real data into a complex array.
}
	dpxy:=new_xy_graph(dp^.num_points);
	for n:=0 to dp^.num_points-1 do begin
		dpxy^[n].x:=dp^[n];
		dpxy^[n].y:=0;
	end;
{
	Obtain the complex-valued transform.
}
	ft:=fft(dpxy);
	dispose_xy_graph(dpxy);
	if ft=nil then exit;
{
	Convert complex transform to compact magnitude-phase transform.
}
	dpxy:=new_xy_graph(dp^.num_points div 2);
	dpxy^[0].x:=ft^[0].x;
	dpxy^[0].y:=ft^[dpxy^.num_points].x;
	for k:=1 to dpxy^.num_points-1 do begin
		dpxy^[k].x:=2*xy_length(ft^[k]);
		dpxy^[k].y:=xy_bearing(ft^[k]);
	end;
	dispose_xy_graph(ft);
{
	Return the compact transform.
}
	fft_real:=dpxy;
end;

{
	fft_real_inverse takes a compact transform of N/2 components in
	magnitude-phase format, as produced by fft_real, and applies the inverse
	fourier transform to the components to produce N real-valued data points.
	The one complication in our compact format is that we specify the 0 and N/2
	components in the first element of the transform. The x-component of the
	first element is the 0-frequency magnitude, and the y-component is the
	N/2-frequency magnitude.
}
function fft_real_inverse(ft:xy_graph_ptr_type):x_graph_ptr_type;

var
	ftxy,dpxy:xy_graph_ptr_type;
	dp:x_graph_ptr_type;
	k,n:integer;
	
begin
{
	A nil pointer indicates a problem.
}
	fft_real_inverse:=nil;
	if ft=nil then exit;
{
	Convert the N/2 magnitude-phase components of the compact transform
	into a complex-valued series of N components.
}
	ftxy:=new_xy_graph(2*ft^.num_points);
	ftxy^[0].x:=ft^[0].x;
	ftxy^[0].y:=0;
	for k:=1 to ft^.num_points-1 do begin
		ftxy^[k].x:=ft^[k].x/2*cos(ft^[k].y);
		ftxy^[k].y:=ft^[k].x/2*sin(ft^[k].y);
	end;
	ftxy^[ft^.num_points].x:=ft^[0].y;
	ftxy^[ft^.num_points].y:=0;
	for k:=(ft^.num_points+1) to (2*ft^.num_points-1) do begin
		ftxy^[k].x:=ftxy^[2*ft^.num_points-k].x;
		ftxy^[k].y:=-ftxy^[2*ft^.num_points-k].y;
	end;
{
	Obtain the inverse transform.
}
	dpxy:=fft_inverse(ftxy);
	dispose_xy_graph(ftxy);
{
	Extract real values.
}
	dp:=new_x_graph(dpxy^.num_points);
	for n:=0 to dpxy^.num_points-1 do
		dp^[n]:=dpxy^[n].x;
	dispose_xy_graph(dpxy);
{
	Return the result.
}
	fft_real_inverse:=dp;
end;

{	
	memory_byte	returns the value of the byte at the specified address.
}
function memory_byte(address:cardinal):byte;
begin 
	memory_byte:=byte_ptr(address)^;
end;

{	
	memory_shortint returns the value of the word at the specified address.
}
function memory_shortint(address:cardinal):shortint;
begin 
	memory_shortint:=shortint_ptr(address)^;
end;

{	
	memory_integer returns the value of the integer at the specified 
	address.
}
function memory_integer(address:cardinal):integer;
begin
	memory_integer:=integer_ptr(address)^;
end;

{
	read_memory_byte is a procedural form of memory_byte.
}
procedure read_memory_byte(address:cardinal; var value:byte);
begin
	value:=memory_byte(address);
end;

{
	read_memory_shortint is a procedural form of memory_integer.
}
procedure read_memory_shortint(address:cardinal;var value:shortint);
begin 
	value:=memory_shortint(address);
end;

{
	read_memory_integer is a procedural form of memory_integer.
}
procedure read_memory_integer(address:cardinal;var value:integer);
begin	
	value:=memory_integer(address);
end; 

{
	write_memory_byte sets the byte at address to value.
}
procedure write_memory_byte(address:cardinal;value:byte);
begin 
	byte_ptr(address)^:=value;
end; 

{
	write_memory_shortint sets the short integer at address to value.
}
procedure write_memory_shortint(address:cardinal;value:shortint);
begin
	shortint_ptr(address)^:=value;
end; 

{
	write_memory_integer sets the integer at address to value.
}
procedure write_memory_integer(address:cardinal;value:integer);
begin 
	integer_ptr(address)^:=value;
end; 

{
	write_memory_map writes memory contents to a string. It displays
	the values of size bytes starting with the byte at address base, 
	and expresses the values in hex.
}
procedure write_memory_map(var s:string;base:cardinal;size:integer);

const
	bytes_per_line=8;
	fs=3;

var
	address:cardinal;
	i,j:integer;
	a:short_string;

begin
	a:='';
	for address:=base to base+size-1 do begin
		if(address-base) mod bytes_per_line=0 then begin
			s:=s+a;
			a:=eol+'$'+hex_string_from_cardinal(address)+': ';
		end;
		a:=a+hex_string_from_byte(memory_byte(address));
	end;
end;

{
	block_move copies length bytes starting at a^ to the location
	starting at b^.
}
procedure block_move(a,b:pointer;length:integer);

begin
	while ((cardinal(a) mod sizeof(integer))<>0) 
			and (length>=sizeof(byte)) do begin
		byte_ptr(b)^:=byte_ptr(a)^;
		a:=pointer(integer(a)+sizeof(byte));
		b:=pointer(integer(b)+sizeof(byte));
		length:=length-sizeof(byte);
	end;
	while (length>=sizeof(integer)) do begin
		integer_ptr(b)^:=integer_ptr(a)^;
		a:=pointer(integer(a)+sizeof(integer));
		b:=pointer(integer(b)+sizeof(integer));
		length:=length-sizeof(integer);
	end;
	while (length>=sizeof(byte)) do begin
		byte_ptr(b)^:=byte_ptr(a)^;
		a:=pointer(integer(a)+sizeof(byte));
		b:=pointer(integer(b)+sizeof(byte));
		length:=length-sizeof(byte);
	end;
end;

{
	block_set writes the specified byte value to length bytes
	starting at a^.
}
procedure block_set(a:pointer;length:integer;value:byte);
var c:cardinal;
begin
	if length<=0 then exit;
	c:= value and $000000FF;
	c:= c or (c shl 8);
	c:= c or (c shl 16);
	while ((cardinal(a) mod sizeof(cardinal))<>0) 
			and (length>=sizeof(byte)) do begin
		byte_ptr(a)^:=value;
		a:=pointer(cardinal(a)+sizeof(byte));
		length:=length-sizeof(byte);
	end;
	while (length>=sizeof(cardinal)) do begin
		cardinal_ptr(a)^:=c;
		a:=pointer(cardinal(a)+sizeof(cardinal));
		length:=length-sizeof(cardinal);
	end;
	while (length>=sizeof(byte)) do begin
		byte_ptr(a)^:=value;
		a:=pointer(cardinal(a)+sizeof(byte));
		length:=length-sizeof(byte);
	end;
end;

{
	block_clear clears length bytes starting at a^ to zero.
}
procedure block_clear(a:pointer;length:integer);
begin
	block_set(a,length,$00);
end;

{
	block_fill fills length bytes starting at a^ with ones.
}
procedure block_fill(a:pointer;length:integer);
begin
	block_set(a,length,$FF);
end;

{
	real_from_integer converts a real number into a four-byte
	integer. GPC appears to have trouble doing this automatically.
}
function real_from_integer(i:integer):real;
begin real_from_integer:=1.0*i; end;

{
	reverse_shortint_bytes swaps the bytes of a short integer;
}
function reverse_shortint_bytes(i:shortint):shortint;

type
	two_bytes_type=packed record
		a,b:byte;
	end;

var
	new_i,old_i:two_bytes_type;	
	
begin
	old_i:=two_bytes_type(i);
	new_i.a:=old_i.b;
	new_i.b:=old_i.a;
	reverse_shortint_bytes:=shortint(new_i);
end;

{
	check_big_endian returns true if this processor stores the high byte 
	of a multi-byte integer in the low-address location. Otherwise it 
	returns false. We use check_big_endian to initialize the big_endian
	global variable.
}
function check_big_endian:boolean;

const
	high_byte_ones=$FF000000;

type
	four_byte_integer=packed record
		first_byte,second_byte,third_byte,fourth_byte:byte;
	end;
		
var
	i:cardinal attribute (Size = 32);
		
begin
	i:=high_byte_ones;
	check_big_endian:=(four_byte_integer(i).first_byte<>0);
end;

{
	big_endian_from_local_shortint takes a local shortint
	and returns a shortint with big-endian byte ordering,
	regardless of host platform..
}
function big_endian_from_local_shortint(i:shortint):shortint;
begin
	if big_endian then big_endian_from_local_shortint:=i
	else big_endian_from_local_shortint:=reverse_shortint_bytes(i);
end;

{
	local_from_big_endian_shortint takes a big-endian shortint
	and returns a shortint in the local byte ordering, regardless
	of host platform.
}
function local_from_big_endian_shortint(i:shortint):shortint;
begin
	if big_endian then local_from_big_endian_shortint:=i
	else local_from_big_endian_shortint:=reverse_shortint_bytes(i);
end;

{
	local_from_little_endian_shortint takes a little-endian shortint
	and returns a shortint in the local byte ordering, regardless
	of host platform.
}
function local_from_little_endian_shortint(i:shortint):shortint;
begin
	if (not big_endian) then local_from_little_endian_shortint:=i
	else local_from_little_endian_shortint:=reverse_shortint_bytes(i);
end;

{
	2-D real-valued geometry
}
function xy_difference(p,q:xy_point_type):xy_point_type;
var d:xy_point_type;
begin
	d.x:=p.x-q.x;
		d.y:=p.y-q.y;
		xy_difference:=d;
end;

function xy_dot_product(p,q:xy_point_type):real;
begin
	xy_dot_product:=p.x*q.x+p.y*q.y;
end;

function xy_random:xy_point_type;
var p:xy_point_type;
begin
	with p do begin
		x:=random_0_to_1; 
		y:=random_0_to_1; 
	end;
	xy_random:=p;
end;

function xy_length(p:xy_point_type):real;
var x:real;
begin
	x:=sqr(p.x)+sqr(p.y);
	if x>0 then xy_length:=sqrt(x)
	else xy_length:=0;
end;

function xy_bearing(p:xy_point_type):real;
var x:real;
begin
	x:=full_arctan(p.y,p.x);
	xy_bearing:=x;
end;

function xy_origin:xy_point_type;
var p:xy_point_type;
begin
	p.x:=0;p.y:=0;
	xy_origin:=p;
end;

function xy_scale(p:xy_point_type;scale:real):xy_point_type;
var s:xy_point_type;
begin
	s.x:=p.x*scale;
	s.y:=p.y*scale;
		xy_scale:=s;
end;

function xy_separation(p,q:xy_point_type):real;
var x:real;
begin
	x:=sqr(p.x-q.x)+sqr(p.y-q.y);
	if x>0 then xy_separation:=sqrt(x)
	else xy_separation:=0;
end;

function xy_sum(p,q:xy_point_type):xy_point_type;
var s:xy_point_type;
begin
	s.x:=p.x+q.x;
	s.y:=p.y+q.y;
		xy_sum:=s;
end;

function xy_unit_vector(p:xy_point_type):xy_point_type;
var v:xy_point_type;
begin
	if xy_length(p)<>0 then begin
		v.x:=p.x/xy_length(p);
		v.y:=p.y/xy_length(p);
	end else begin
				v.x:=1;v.y:=0;
		end;
		xy_unit_vector:=v;
end;

{
	xy_rectangle_ellipse calculates the focal points and major axis
	length of the ellipse that fits exactly into an xy_rectangle_type.
}
function xy_rectangle_ellipse(rect:xy_rectangle_type):xy_ellipse_type;
var
	minor_axis_length,focal_separation:real;
	ellipse:xy_ellipse_type;
begin
	with ellipse,rect do begin
		if (right-left)>(bottom-top) then begin
			axis_length:=right-left;
			minor_axis_length:=bottom-top;
			focal_separation:=sqrt(sqr(axis_length)-sqr(minor_axis_length));
			a.x:=(right+left)/2+focal_separation/2;
			a.y:=(bottom+top)/2;
			b.x:=(right+left)/2-focal_separation/2;
			b.y:=a.y;
		end;
		if (right-left)<(bottom-top) then begin
			axis_length:=bottom-top;
			minor_axis_length:=right-left;
			focal_separation:=sqrt(sqr(axis_length)-sqr(minor_axis_length));
			a.x:=(right+left)/2;
			a.y:=(bottom+top)/2-focal_separation/2;
			b.x:=a.x;
			b.y:=(bottom+top)/2+focal_separation/2;
		end;
		if (right-left)=(bottom-top) then begin
			axis_length:=bottom-top;
			a.x:=(right+left)/2;
			a.y:=(top+bottom)/2;
			b:=a;
		end;
	end;
	xy_rectangle_ellipse:=ellipse;
end;

{
	xy_rotate takes an xy point and rotates it about the origin
	by r radians in the anti-clockwise direction.
}
function xy_rotate(p:xy_point_type;r:real):xy_point_type;
var v:xy_point_type;
begin
	v.x:=p.x*cos(r)-p.y*sin(r);
	v.y:=p.x*sin(r)+p.y*cos(r);
	xy_rotate:=v;
end;

{
	xy_line_line_intersection calculates the intersection of two 
	lines in two-dimensional space. If there is no intersection,
	the routine returns a point with x and y set to large_real+1.
}
function xy_line_line_intersection(l1,l2:xy_line_type):xy_point_type;
var
	D,F:array [1..2,1..2] of real;
	E:array [1..2] of real;
	determinant:real;
	p:xy_point_type;
begin 
	D[1,1]:=l1.b.y-l1.a.y; D[1,2]:=-(l1.b.x-l1.a.x); E[1]:=l1.a.x*D[1,1]+l1.a.y*D[1,2];
	D[2,1]:=l2.b.y-l2.a.y; D[2,2]:=-(l2.b.x-l2.a.x); E[2]:=l2.a.x*D[2,1]+l2.a.y*D[2,2];
	determinant:=D[1,1]*D[2,2]-D[1,2]*D[2,1];
	if not math_overflow(determinant) then begin
		F[1,1]:=D[2,2]/determinant;
		F[1,2]:=-D[1,2]/determinant;
		F[2,1]:=-D[2,1]/determinant;
		F[2,2]:=D[1,1]/determinant;
		p.x:=F[1,1]*E[1]+F[1,2]*E[2];
		p.y:=F[2,1]*E[1]+F[2,2]*E[2];
	end else begin
		p.x:=large_real+1;
		p.y:=large_real+1;
	end;
	xy_line_line_intersection:=p;
end;

{
	2-D integer-valued geometry.
}
function ij_origin:ij_point_type;
var p:ij_point_type;
begin
	p.i:=0;
	p.j:=0;
	ij_origin:=p;
end;

function ij_separation(a,b:ij_point_type):real;
var x:real;
begin
	x:=sqr(a.i-b.i)+sqr(a.j-b.j);
	if x>0 then ij_separation:=sqrt(x)
	else ij_separation:=0;
end;

function ij_difference(a,b:ij_point_type):ij_point_type;
var d:ij_point_type;
begin
	d.i:=a.i-b.i;
		d.j:=a.j-b.j;
		ij_difference:=d;
end;

function ij_dot_product(a,b:ij_point_type):real;
begin
	ij_dot_product:=a.i*b.i+a.j*b.j;
end;

{
	ij_line_line_intersection determines the closest ij_point to 
	the intersection of two ij_lines. It calls the more general
	xy_line_line_intersection to obtain its result.
}
function ij_line_line_intersection(l1,l2:ij_line_type):ij_point_type;
var r1,r2:xy_line_type;p:xy_point_type;q:ij_point_type;
begin
	r1.a.x:=l1.a.i;r1.a.y:=l1.a.j;r1.b.x:=l1.b.i;r1.b.y:=l1.b.j;
	r2.a.x:=l2.a.i;r2.a.y:=l2.a.j;r2.b.x:=l2.b.i;r2.b.y:=l2.b.j;
	p:=xy_line_line_intersection(r1,r2);
	if (abs(p.x)<max_integer) and (abs(p.y)<max_integer) then begin
		q.i:=round(p.x);q.j:=round(p.y);
	end else begin
		if p.x>max_integer then q.i:=max_integer
		else if p.x<-max_integer then q.i:=-max_integer
		else q.i:=round(p.x);
		if p.y>max_integer then q.j:=max_integer
		else if p.y<-max_integer then q.j:=-max_integer
		else q.j:=round(p.y);
	end;
	ij_line_line_intersection:=q;
end;

{
	ij_in_rectangle returns true iff an ij point lies in or on the border of 
	an ij_rectangle.
}
function ij_in_rectangle(point:ij_point_type;rect:ij_rectangle_type):boolean;	
begin 
	with point,rect do
		ij_in_rectangle:=(i>=left) and (i<=right) and (j>=top) and (j<=bottom);
end;

{
	ij_clip_line clips a line defined by the two points of an ij_line_type to an 
	ij_rectangle_type. The routine returns outside true iff no portion of the line 
	lying between the two points lies in the specified ij_line_type cross the 
	rectangle. After ij_clip_line is done, the line contains two points both within
	the rectangle. If one end of the line passed to the routine was outside the
	rectangle, this end will be replaced by a point on the edge of the rectangle,
	where the line crossed the edge.
}
procedure ij_clip_line(var line:ij_line_type;var outside:boolean;clip:ij_rectangle_type);

const
	max_num_intersections=4;
	min_num_intersections=2;
	
var 
	num_intersections:integer;
	tl,tr,bl,br,k:ij_point_type;
	i:array [1..max_num_intersections] of ij_point_type;
	a_in,b_in:boolean;
	
	function intersection(a,b:ij_point_type):ij_point_type;
	var edge:ij_line_type;
	begin
		edge.a:=a;edge.b:=b;
		intersection:=ij_line_line_intersection(edge,line);
	end;

begin
	num_intersections:=0;
	tl.i:=clip.left;tl.j:=clip.top;
	tr.i:=clip.right;tr.j:=clip.top;
	bl.i:=clip.left;bl.j:=clip.bottom;
	br.i:=clip.right;br.j:=clip.bottom;
	i[1]:=ij_origin;
	i[2]:=ij_origin;
	a_in:=ij_in_rectangle(line.a,clip);
	b_in:=ij_in_rectangle(line.b,clip);
	if (line.a.i<>line.b.i) or (line.a.j<>line.b.j) then begin
		if a_in and b_in then begin
			outside:=false;
		end else begin
			if line.a.i=line.b.i then begin
				if (line.a.i>=clip.left) and (line.a.i<=clip.right) then begin
					inc(num_intersections);
					i[num_intersections]:=intersection(tl,tr);
					inc(num_intersections);
					i[num_intersections]:=intersection(bl,br);
				end;
			end;
			if line.a.j=line.b.j then begin
				if (line.a.j>=clip.top) and (line.a.j<=clip.bottom) then begin
					inc(num_intersections);
					i[num_intersections]:=intersection(tl,bl);
					inc(num_intersections);
					i[num_intersections]:=intersection(tr,br);
				end;
			end;
			if (line.a.i<>line.b.i) and (line.a.j<>line.b.j) then begin	
				k:=intersection(tl,tr);
				if ij_in_rectangle(k,clip) then begin
					inc(num_intersections);
					i[num_intersections]:=k;
				end;
				k:=intersection(tr,br);
				if ij_in_rectangle(k,clip) then begin
					inc(num_intersections);
					i[num_intersections]:=k;
				end;
				k:=intersection(br,bl);
				if ij_in_rectangle(k,clip) then begin
					inc(num_intersections);
					i[num_intersections]:=k;
				end;
				k:=intersection(bl,tl);
				if ij_in_rectangle(k,clip) then begin
					inc(num_intersections);
					i[num_intersections]:=k;
				end;
			end;
			if num_intersections>=min_num_intersections then begin
				if not a_in and not b_in then begin
					outside:=ij_dot_product(
						ij_difference(line.a,i[1]),
						ij_difference(line.b,i[1]))>=0;
					line.a:=i[1];
					line.b:=i[min_num_intersections];
				end;
				if a_in and not b_in then begin
					if (ij_separation(line.b,i[1])
							>ij_separation(line.b,i[min_num_intersections])) then 
								line.b:=i[min_num_intersections]
					else line.b:=i[1];
					outside:=false;
				end;
				if b_in and not a_in then begin
					if (ij_separation(line.a,i[1])
							>ij_separation(line.a,i[min_num_intersections])) then 
								line.a:=i[min_num_intersections]
					else line.a:=i[1];
					outside:=false;
				end;
			end else begin
				outside:=true;
			end;
		end;
	end else begin
		outside:=not ij_in_rectangle(line.a,clip);
	end;
end;

{
	ij_combine_rectangles combines two rectangles and returns a single rectangle that
	encloses both the originals.
}
function ij_combine_rectangles(a,b:ij_rectangle_type):ij_rectangle_type;

begin
	if b.left<a.left then a.left:=b.left;
	if b.right>a.right then a.right:=b.right;
	if b.top<a.top then a.top:=b.top;
	if b.bottom>a.bottom then a.bottom:=b.bottom;
	ij_combine_rectangles:=a;
end;

{
	ij_line_crosses_rectangle returns true iff line crosses rect at two
	distinct points. Much of this routine is similar to ij_clip_line, but
	ij_line_crosses_rectanlge detects a degenerate crossing at a corner,
	and allows a crossing along one edge of the rectangle. We could, of
	course, break out parts of ij_clip_line and use them again in this
	routine, but to do so would take us at least an hour or two of debugging
	afterwards. A quick examination of the code of both routines will show
	that the logic of these simple operations, so straightforward for the
	human eye, is complex.
}
function ij_line_crosses_rectangle(line:ij_line_type;rect:ij_rectangle_type):boolean;

const
	min_num_intersections=2;
	
var 
	num_intersections:integer;
	tl,tr,bl,br,q,p,intersection:ij_point_type;
	
	procedure action(a,b:ij_point_type);
	var edge:ij_line_type;
	begin
		edge.a:=a;edge.b:=b;
		intersection:=ij_line_line_intersection(edge,line);
		if ij_in_rectangle(intersection,rect) then begin
			if num_intersections=0 then p:=intersection
			else q:=intersection;
			inc(num_intersections);
		end;		
	end;

begin
	num_intersections:=0;
	if ij_separation(line.a,line.b)<>0 then begin
		if line.a.i=line.b.i then
			if (line.a.i>=rect.left) and (line.a.i<=rect.right) then
				num_intersections:=min_num_intersections;
		if line.a.j=line.b.j then
			if (line.a.j>=rect.top) and (line.a.j<=rect.bottom) then
				num_intersections:=min_num_intersections;
		if num_intersections<min_num_intersections then begin
			tl.i:=rect.left;tl.j:=rect.top;
			tr.i:=rect.right;tr.j:=rect.top;
			bl.i:=rect.left;bl.j:=rect.bottom;
			br.i:=rect.right;br.j:=rect.bottom;
			action(tl,tr);
			action(tr,br);
			action(br,bl);
			action(bl,tl);
			if num_intersections=min_num_intersections then 
				if ij_separation(p,q)=0 then
					num_intersections:=1;
		end;
	end;
	ij_line_crosses_rectangle:=(num_intersections>=min_num_intersections);
end;

{
	equal_ij_rectangles checks if two rectangles are identical.
}
function equal_ij_rectangles(a,b:ij_rectangle_type):boolean;
begin
	equal_ij_rectangles:=
		(a.left=b.left) and (a.right=b.right) and (a.top=b.top) and (a.bottom=b.bottom);
end;

{
	ij_clip_rectangle clips rect to a clip area, clip.
}
procedure ij_clip_rectangle(var rect:ij_rectangle_type;clip:ij_rectangle_type);
	procedure clip_up(var a,b:integer);begin if a<b then a:=b; end;
	procedure clip_down(var a,b:integer);begin if a>b then a:=b; end;
begin
	clip_down(rect.right,clip.right);
	clip_up(rect.right,clip.left);
	clip_down(rect.left,clip.right);
	clip_up(rect.left,clip.left);
	clip_down(rect.bottom,clip.bottom);
	clip_up(rect.bottom,clip.top);
	clip_down(rect.top,clip.bottom);
	clip_up(rect.top,clip.top);
end;

{
	ij_random_point returns a random ij_point_type lying within a
	rectangle. 
}
function ij_random_point(rect:ij_rectangle_type):ij_point_type;
var p:ij_point_type;
begin
	with rect,p do begin
		i:=round(random_0_to_1*(right-left))+left;
		j:=round(random_0_to_1*(bottom-top))+top;
	end;
	ij_random_point:=p;
end;

{
	3-D real-valued geometry
}
function xyz_origin:xyz_point_type;
var p:xyz_point_type;
begin
	p.x:=0;p.y:=0;p.z:=0;
	xyz_origin:=p;
end;

function xyz_random:xyz_point_type;
var p:xyz_point_type;
begin
	with p do begin
		x:=2*(random_0_to_1-0.5); 
		y:=2*(random_0_to_1-0.5); 
		z:=2*(random_0_to_1-0.5); 
	end;
	xyz_random:=p;
end;

function xyz_length(p:xyz_point_type):real;
var x:real;
begin
	x:=sqr(p.x)+sqr(p.y)+sqr(p.z);
	if x>0 then xyz_length:=sqrt(x)
	else xyz_length:=0;
end;

function xyz_dot_product(p,q:xyz_point_type):real;
begin
	xyz_dot_product:=p.x*q.x+p.y*q.y+p.z*q.z;
end;

function xyz_cross_product(p,q:xyz_point_type):xyz_point_type;
var c:xyz_point_type;
begin
	c.x:=p.y*q.z-p.z*q.y;
	c.y:=-(p.x*q.z-p.z*q.x);
	c.z:=p.x*q.y-p.y*q.x;
	xyz_cross_product:=c;
end;

function xyz_angle(p,q:xyz_point_type):real;
var c:real;
begin
	c:=xyz_dot_product(p,q)/xyz_length(p)/xyz_length(q);
	xyz_angle:=full_arctan(1/sqr(c)-1,1);
end;

function xyz_unit_vector(p:xyz_point_type):xyz_point_type;
var v:xyz_point_type;
begin
	if xyz_length(p)<>0 then begin
		v.x:=p.x/xyz_length(p);
		v.y:=p.y/xyz_length(p);
		v.z:=p.z/xyz_length(p);
	end else begin
		v.x:=1;v.y:=0;v.z:=0;
	end;
	xyz_unit_vector:=v;
end;

function xyz_scale(p:xyz_point_type;scale:real):xyz_point_type;
var s:xyz_point_type;
begin
	s.x:=p.x*scale;
	s.y:=p.y*scale;
	s.z:=p.z*scale;
	xyz_scale:=s;
end;

function xyz_sum(p,q:xyz_point_type):xyz_point_type;
var s:xyz_point_type;
begin
	s.x:=p.x+q.x;
	s.y:=p.y+q.y;
	s.z:=p.z+q.z;
	xyz_sum:=s;
end;

function xyz_difference(p,q:xyz_point_type):xyz_point_type;
var d:xyz_point_type;
begin
	d.x:=p.x-q.x;
	d.y:=p.y-q.y;
	d.z:=p.z-q.z;
	xyz_difference:=d;
end;

function xyz_separation(p,q:xyz_point_type):real;
var x:real;
begin
	x:=sqr(p.x-q.x)+sqr(p.y-q.y)+sqr(p.z-q.z);
	if x>0 then xyz_separation:=sqrt(x)
	else xyz_separation:=0;
end;

function xyz_z_plane(z:real):xyz_plane_type;
var plane:xyz_plane_type;
begin
	with plane do begin
		point.x:=0;point.y:=0;point.z:=z;
		normal.x:=0;normal.y:=0;normal.z:=1;
	end;
	xyz_z_plane:=plane;
end;

{
	unit_matrix sets the diagonal elements to 1 and
	all others to 0.
}
procedure unit_matrix(var M:matrix_type);
var i,j:integer;
begin
	for j:=1 to M.num_rows do
		for i:=1 to M.num_columns do
			if (i=j) then M[j,i]:=1 else M[j,i]:=0;
end;

{
	swap_matrix_rows exchanges two rows in a matrix.
}
procedure swap_matrix_rows(var M:matrix_type;row_1,row_2:integer);
var
	a,b:real;
	i:integer;	
begin
	for i:=1 to M.num_columns do begin
		a:=M[row_1,i];
		b:=M[row_2,i];
		M[row_1,i]:=b;
		M[row_2,i]:=a;
	end;
end;

{
	matrix_product sets M equal to the A.B (the matrix product of A and B).
}
procedure matrix_product(var A,B,M:matrix_type);

var
	i,j,k:integer;
	sum:real;

begin
	if (A.num_columns<>B.num_rows) 
		or (A.num_rows<>M.num_rows)
		or (B.num_columns<>M.num_columns) then begin
		report_error('Mismatched matrices in matrix_product.');
		exit;
	end;

	for j:=1 to A.num_rows do begin
		for i:=1 to B.num_columns do begin
			sum:=0;
			for k:=1 to A.num_columns do
				sum:=sum+A[j,k]*B[k,i];
			M[j,i]:=sum;
		end;
	end;
end;

{
	matrix_difference sets M equal to A-B.
}
procedure matrix_difference(var A,B,M:matrix_type);

var
	i,j:integer;
	
begin
	if (A.num_columns<>B.num_columns) 
		or (A.num_rows<>B.num_rows)
		or (A.num_columns<>M.num_columns) 
		or (A.num_rows<>M.num_rows) then begin
		report_error('Mismatched matrices in matrix_difference.');
		exit;
	end;

	for j:=1 to A.num_rows do begin
		for i:=1 to A.num_columns do begin
			M[j,i]:=A[j,i]-B[j,i];
		end;
	end;
end;

{
	matrix_inverse attempts to set M equal to the inverse of A. If A is of full
	rank, the routine will succeed. But if A is not of full rank, M will contain
	one or more rows of zeros. You can check the global variable
	matrix_rank_saved for the rank of the matrix, and matrix_determinant_saved
	for its determinant. Both these will be valid at the end of matrix_inverse.

	The routine uses Gausse-Jordan elimination to calculate the inverse matrix.
	The execution time of Gauss-Jordan elimination for randomly-populated
	matrices is of order n^3, where n is the number of rows and columns in the
	matrix.

	We measured matrix_inverse's execution time in the following way. For
	various values of n, we generated an nxn matrix containing random
	real-valued elements between -2.5 and +2.5. We inverted this matrix 100
	times. We generated a new random matrix, and inverted that 100 times, and so
	on, until we occupied the microprocessor for several seconds with all the
	inversions combined. We measured the total execution time and divided by the
	total number of inversions to obtain our estimate of a single inversion
	time. We compiled the matrix inverter with the GPC -O3 optimization and ran
	the test on a 1GHz iBook G3.
	
	n		time (us)	time/n*n*n (us)
	3		10			0.37		
	5		22			0.18
	7		53			0.15
	10		100			0.10			
	14		250			0.09
	20		820			0.10
	30		2300		0.09
	40		6000		0.09
	70		26000		0.08
	100		70000		0.07
	1000	130000000	0.13

	As we can see from the table, the execution time for n>70 is
	proportional to the third power of n. For smaller values of n, the
	time it takes to allocate space for the new matrix and populate the
	test matrix with random elements, is significant compared to the
	inversion time.
	
	Jim Bensinger ran the Matlab matrix inverter on a 100x100 matrix 
	with random elements as above, and its execution time was 50 ms,
	compared to our 70 ms.
}
procedure matrix_inverse(var A,M:matrix_type);

var
	n,rank:integer;
	B:matrix_type(A.num_rows,A.num_columns);
	determinant:real;

{
	swap exchanges row j with a row that contains the best available pivot element 
	in the i'th column of B.
}
	procedure swap(j,i:integer);
	var l,j_best:integer;
	begin
		j_best:=j;
		for l:=1 to n do 
			if abs(B[l,i]) > abs(B[j_best,i]) then
				if (l>j) or ((l<j) and (B[l,l]=0)) then 
					j_best:=l;
		if j_best<>j then begin
			swap_matrix_rows(M,j,j_best);
			swap_matrix_rows(B,j,j_best);
			determinant:=-determinant;
		end;
	end; 
	
{
	zero makes ill-conditioning in the matrix apparent to the elimination
	algorithm by setting certain small elements in column i of B to zero. The
	procedure assumes that there is no avilable pivot element in the i'th
	column.
}
	procedure zero(j,i:integer);
	var l:integer;
	begin
		for l:=1 to j-1 do 
			if (B[l,l]=0) then B[l,i]:=0;
		for l:=j to n do B[l,i]:=0;
	end;

var
	j,i,k,l:integer;
	factor:real;
	
begin
{
	Set the global variables.
}
	matrix_rank_saved:=0;
	matrix_determinant_saved:=0;
{
	Set the starting rank and determinant.
}
	rank:=0;
	determinant:=1;
{
	We use n as an abbreviation for A.num_rows = A.num_columns.
}
	n:=A.num_rows;
{
	Check A and M.
}
	if (A.num_columns<>n) then begin
		report_error('Matrix is not square in matrix_inverse.');
		exit;
	end;
	if (M.num_rows<>n) 
		or (M.num_columns<>n) then begin
		report_error('Matrix mismatch in matrix_inverse.');
		exit;
	end;
{
	Copy A to B and set M to the unit matrix. This is the starting point of the algorithm.
}
	B:=A;
	unit_matrix(M);
{
	Diagonalize B with Gauss-Jordan elimination, while at the same time applying every 
	operation to M, which evolves into a linear multiple of A.
}
	for j:=1 to n do begin
		swap(j,j);
		if abs(B[j,j])>small_real then begin
			for l:=1 to n do begin
				if (l<>j) then begin
					factor:=B[l,j]/B[j,j];
					for i:=1 to n do begin
						M[l,i]:=M[l,i]-factor*M[j,i];
						B[l,i]:=B[l,i]-factor*B[j,i];
					end;
					B[l,j]:=0;{avoid rounding errors}
				end
			end;
		end 
		else zero(j,j);
	end;
{
	Normalize B to the unit matrix, so M becomes the inverse of A, if such exists, and
	calculate the rank and determinant of the matrix.
}
	for j:=1 to n do begin
		if abs(B[j,j])>small_real then begin
			inc(rank);
			factor:=B[j,j];
			determinant:=determinant*factor;
			for i:=1 to n do begin
				M[j,i]:=M[j,i]/factor;
				B[j,i]:=B[j,i]/factor;
			end;
			B[j,j]:=1;{avoid rounding errors}
		end else B[j,i]:=0;
	end;
	if (rank<n) then determinant:=0;
{
	Store the matrix rank and determinant in global variables.
}
	matrix_determinant_saved:=determinant;
	matrix_rank_saved:=rank;
end;

{
	matrix_determinant calls matrix_inverse and returns 0 if the rank
	of the input matrix is less than its size. Otherwise it returns
	whatever matrix_inverse arrives at for the determinant.
}
function matrix_determinant(var M:matrix_type):real;

var
	determinant:real;
	B:matrix_type(M.num_rows,M.num_columns);

begin
	if M.num_rows=M.num_columns then begin
		matrix_inverse(M,B);
		if matrix_rank_saved=M.num_rows then 
			determinant:=matrix_determinant_saved 
		else 
			determinant:=0;
	end else 
		determinant:=0;
	matrix_determinant:=determinant;
end;

{
	xyz_matrix_determinant returns the determinant of a 3x3 matrix.
}
function xyz_matrix_determinant(A:xyz_matrix_type):real;
var determinant:real;
begin
	determinant:=
		A[1,1]*(A[2,2]*A[3,3]-A[2,3]*A[3,2])
		-A[1,2]*(A[2,1]*A[3,3]-A[2,3]*A[3,1])
		+A[1,3]*(A[2,1]*A[3,2]-A[2,2]*A[3,1]);
	xyz_matrix_determinant:=determinant;
end;

{
	xyz_matrix_inverse inverts a 3x3 matrix for geometry calculations.
	We could use matrix_inverse, and dynamically-allocated 3x3 matrices,
	but the time taken by the dynamic allocation of space for the
	matrices is far greater than the time taken to invert them (see data
	in the comments for matrix_inverse). This routine uses stack
	variables and a direct formula for the inverse of a 3x3 matrix for
	faster execution. If you pass it an ill-conditioned matrix, it
	returns a unit matrix and sets matrix_rank equal to 0.

	Execution time for this routine, when compiled with the GPC -O3
	option, and executed on a 1GHz iBook with matrices containing random
	elements between values -2.5 and +2.5 is only 1.5 us, compared to 8
	us for matrix_inverse with a 3x3 matrix.
}
function xyz_matrix_inverse(A:xyz_matrix_type):xyz_matrix_type;

var
	B:xyz_matrix_type;
	i,j,rank:integer;
	determinant:real;
	
begin
	matrix_determinant_saved:=0;
	matrix_rank_saved:=0;
	
	determinant:=
		A[1,1]*(A[2,2]*A[3,3]-A[2,3]*A[3,2])
		-A[1,2]*(A[2,1]*A[3,3]-A[2,3]*A[3,1])
		+A[1,3]*(A[2,1]*A[3,2]-A[2,2]*A[3,1]);
		
	if abs(determinant)>small_real then begin
		rank:=num_xyz_dimensions;
		B[1,1]:=(A[2,2]*A[3,3]-A[2,3]*A[3,2])/determinant;
		B[1,2]:=(A[1,3]*A[3,2]-A[1,2]*A[3,3])/determinant;
		B[1,3]:=(A[1,2]*A[2,3]-A[1,3]*A[2,2])/determinant;
		B[2,1]:=(A[2,3]*A[3,1]-A[2,1]*A[3,3])/determinant;
		B[2,2]:=(A[1,1]*A[3,3]-A[1,3]*A[3,1])/determinant;
		B[2,3]:=(A[1,3]*A[2,1]-A[1,1]*A[2,3])/determinant;
		B[3,1]:=(A[2,1]*A[3,2]-A[2,2]*A[3,1])/determinant;
		B[3,2]:=(A[1,2]*A[3,1]-A[1,1]*A[3,2])/determinant;
		B[3,3]:=(A[1,1]*A[2,2]-A[1,2]*A[2,1])/determinant;
	end else begin 
		report_error('Matrix inversion failed on singular matrix.');
		rank:=0;
		determinant:=0;
		for j:=1 to num_xyz_dimensions do
			for i:=1 to num_xyz_dimensions do
				if i=j then B[j,i]:=1
				else B[j,i]:=0;
	end;
	
	
	matrix_determinant_saved:=determinant;
	matrix_rank_saved:=rank;
	xyz_matrix_inverse:=B;
end;

{
	xyz_matrix_difference is a fast 3x3 version of matrix_difference.
	It returns A - B.
}
function xyz_matrix_difference(A,B:xyz_matrix_type):xyz_matrix_type;
var i,j:integer; C:xyz_matrix_type;
begin
	for j:=1 to num_xyz_dimensions do
		for i:=1 to num_xyz_dimensions do
			C[j,i]:=A[j,i]-B[j,i];
	xyz_matrix_difference:=C;
end;

{
	xyz_matrix_from_points takes three xyz_point_types and makes them the rows 
	of an xyz matrix. It returns a pointer to this new matrix.	
}
function xyz_matrix_from_points(p,q,r:xyz_point_type):xyz_matrix_type;
var M:xyz_matrix_type;
begin
	M[1,1]:=p.x;
	M[1,2]:=p.y;
	M[1,3]:=p.z;
	M[2,1]:=q.x;
	M[2,2]:=q.y;
	M[2,3]:=q.z;
	M[3,1]:=r.x;
	M[3,2]:=r.y;
	M[3,3]:=r.z;
	xyz_matrix_from_points:=M;
end;

{
	xyz_transform transforms a point in xyz-space using an xyz transform matrix.
}
function xyz_transform(M:xyz_matrix_type;p:xyz_point_type):xyz_point_type;
var t:xyz_point_type;
begin
	t.x:=M[1,1]*p.x+M[1,2]*p.y+M[1,3]*p.z;
	t.y:=M[2,1]*p.x+M[2,2]*p.y+M[2,3]*p.z;
	t.z:=M[3,1]*p.x+M[3,2]*p.y+M[3,3]*p.z;
	xyz_transform:=t;
end;

{
	xyz_point_line_vector returns the shortest vector from a point to a line.
}
function xyz_point_line_vector(point:xyz_point_type;line:xyz_line_type):xyz_point_type;
begin
	xyz_point_line_vector:=
		xyz_sum(
			xyz_difference(line.point,point),
			xyz_scale(
				xyz_unit_vector(line.direction),
				xyz_dot_product(
					xyz_difference(point,line.point),
					xyz_unit_vector(line.direction))));	
end;

{
	xyz_plane_plane_plane_intersection returns the point of intersection of three 
	xyz planes.
}
function xyz_plane_plane_plane_intersection(p,q,r:xyz_plane_type):xyz_point_type;

var 
	row_x,row_y,row_z,constants:xyz_point_type;
	M,N:xyz_matrix_type;

begin
	row_x:=xyz_unit_vector(p.normal);
	constants.x:=xyz_dot_product(row_x,p.point);
	row_y:=xyz_unit_vector(q.normal);
	constants.y:=xyz_dot_product(row_y,q.point);
	row_z:=xyz_unit_vector(r.normal);
	constants.z:=xyz_dot_product(row_z,r.point);
	M:=xyz_matrix_from_points(row_x,row_y,row_z);
	N:=xyz_matrix_inverse(M);
	xyz_plane_plane_plane_intersection:=xyz_transform(N,constants);
end;

{
	xyz_line_plane_intersection returns the point at the intersection of the
	specified line and plane.
}
function xyz_line_plane_intersection(line:xyz_line_type;plane:xyz_plane_type):xyz_point_type;

const
	small_move=1;
	min_length=small_move/10;
	
var 
	row_x,row_y,row_z,constants,p:xyz_point_type;
	M,N:xyz_matrix_type;

begin
{
	The first row of our matrix is a unit vector normal to the plane.
}
	row_x:=xyz_unit_vector(plane.normal);
	constants.x:=xyz_dot_product(row_x,plane.point);
{
	The second row is a vector perpendicular to the line that intersects
	the plane.
}
	p:=xyz_origin;
	if xyz_length(xyz_point_line_vector(p,line))<min_length then 
		p.x:=p.x+small_move;
	if xyz_length(xyz_point_line_vector(p,line))<min_length then 
		p.y:=p.y+small_move;
	row_y:=xyz_unit_vector(xyz_point_line_vector(p,line));
	constants.y:=xyz_dot_product(row_y,line.point);
{
	The third row is a vector perpendicular to the line the first vector
	we chose perpendicular to the line.
}
	row_z:=xyz_unit_vector(xyz_cross_product(line.direction,row_y));
	constants.z:=xyz_dot_product(row_z,line.point);
{
	Now we invert the matrix, multiply the constant vector, and get
	the intersection point.
}
	M:=xyz_matrix_from_points(row_x,row_y,row_z);
	N:=xyz_matrix_inverse(M);
	xyz_line_plane_intersection:=xyz_transform(N,constants);
end;

{
	xyz_point_plane_vector returns the shortest vector from a point to a plane.
}
function xyz_point_plane_vector(point:xyz_point_type;plane:xyz_plane_type):xyz_point_type;

var
	line:xyz_line_type;
	p:xyz_point_type;
	
begin
	line.point:=point;
	line.direction:=plane.normal;
	p:=xyz_line_plane_intersection(line,plane);
	xyz_point_plane_vector:=xyz_difference(p,point);
end;

{
	xyz_line_line_bridge returns the shortest link from the first line
	to the second line. We express the link as an xyz_line_type. We
	give the point in the first line that is closest to the second,
	and the vector that connects this point to the point in the second
	line that is closest to the first. The two lines must be skewed.
	Parallel lines will return the origin for a point, and a zero
	vector. We tested this routine with the following code. The code
	generates two random points, which are to form the bridge. It 
	creates two lines that run through the points, each perpendicular
	to the bridge and in random directions. It prints to the terminal
	the known bridge and the calculated bridge so you can compare them.
	
	var 
		a,b,c:xyz_line_type;
	begin
		for i:=1 to 10 do begin
			a.point:=xyz_random;
			b.point:=xyz_random;
			c.point:=a.point;
			c.direction:=xyz_difference(b.point,a.point);
			a.direction:=xyz_cross_product(c.direction,xyz_random);
			b.direction:=xyz_cross_product(c.direction,xyz_random);
			a.point:=xyz_sum(a.point,xyz_scale(a.direction,random_0_to_1));
			b.point:=xyz_sum(b.point,xyz_scale(b.direction,random_0_to_1));
			writeln(i:0);
			writeln(string_from_xyz_line(c));
			writeln(string_from_xyz_line(xyz_line_line_bridge(a,b)));
		end;
	end;

}
function xyz_line_line_bridge(p,q:xyz_line_type):xyz_line_type;

var
	p1,p2:xyz_plane_type;
	line:xyz_line_type;
	
begin
	p1.point:=p.point;
	p1.normal:=xyz_unit_vector(xyz_cross_product(p.direction,q.direction));
	p2.point:=q.point;
	p2.normal:=p1.normal;
	line.direction:=xyz_difference(
		xyz_point_plane_vector(xyz_origin,p2),
		xyz_point_plane_vector(xyz_origin,p1));
	p2.normal:=xyz_unit_vector(xyz_cross_product(p2.normal,q.direction));
	line.point:=xyz_line_plane_intersection(p,p2);
	xyz_line_line_bridge:=line;	
end;

{
	xyz_plane_plane_intersection returns the line of intersection of two
	planes.
}
function xyz_plane_plane_intersection(p,q:xyz_plane_type):xyz_line_type;

var 
	line:xyz_line_type;
	plane:xyz_plane_type;
	
begin
	line.direction:=xyz_unit_vector(xyz_cross_product(p.normal,q.normal));
	plane.normal:=line.direction;
	plane.point:=xyz_origin;
	line.point:=xyz_plane_plane_plane_intersection(p,q,plane);
	xyz_plane_plane_intersection:=line;
end;

{
	xyz_line_reflect returns the reflection of a ray in a mirror. The ray is
	represented by a line, and the mirror by a plane. The point given in the
	line is the mirror image of the point given in the original line. The 
	line returned by the routine uses for its point the intersection of the 
	original ray and the mirror plane. The direction is the direction of light 
	from line.point would take after striking xyz_line_reflect.point.
}
function xyz_line_reflect(line:xyz_line_type;plane:xyz_plane_type):xyz_line_type;

var 
	reflection:xyz_line_type;
	perpendicular,parallel,intersection:xyz_point_type;
	
begin
	intersection:=xyz_line_plane_intersection(line,plane);
	plane.normal:=xyz_unit_vector(plane.normal);
	if xyz_dot_product(plane.normal,xyz_difference(line.point,intersection))<0 then 
		plane.normal:=xyz_scale(plane.normal,-1);
	line.direction:=xyz_unit_vector(line.direction);
	perpendicular:=xyz_scale(plane.normal,xyz_dot_product(plane.normal,line.direction));
	parallel:=xyz_difference(line.direction,perpendicular);
	reflection.direction:=xyz_unit_vector(xyz_difference(parallel,perpendicular));
	reflection.point:=
		xyz_sum(
			intersection,
			xyz_scale(
				reflection.direction,
				-xyz_separation(intersection,line.point)));
	xyz_line_reflect:=reflection;
end;

{
	xyz_rotate rotates a point about the x, y, and z axes. First, we
	rotate the point by an angle rotation.x about the x-axis. Next, we
	rotate the point by rotation.y about the y-axis. Last, we rotate
	by rotation.z about the z-axis. Positive rotation about an axis is
	in the direction a right-handed screw would turn to move in the 
	positive direction of the axis.
}
function xyz_rotate(point,rotation:xyz_point_type):xyz_point_type;

var
	p:xyz_point_type;
	
begin
	{rotate about x-axis}
	p.x:=point.x;
	p.y:=point.y*cos(rotation.x)-point.z*sin(rotation.x);
	p.z:=point.y*sin(rotation.x)+point.z*cos(rotation.x);
	{rotate about y-axis}
	point:=p;
	p.x:=point.x*cos(rotation.y)+point.z*sin(rotation.y);
	p.y:=point.y;
	p.z:=-point.x*sin(rotation.y)+point.z*cos(rotation.y);
	{rotate about z-axis}
	point:=p;
	p.x:=point.x*cos(rotation.z)-point.y*sin(rotation.z);
	p.y:=point.x*sin(rotation.z)+point.y*cos(rotation.z);
	p.z:=point.z;
	{return result}
	xyz_rotate:=p;	
end;

{
	xyz_unrotate does the opposite of xyz_rotate.
}
function xyz_unrotate(point,rotation:xyz_point_type):xyz_point_type;

var
	p:xyz_point_type;
	
begin
	{rotate about z-axis}
	p.x:=point.x*cos(-rotation.z)-point.y*sin(-rotation.z);
	p.y:=point.x*sin(-rotation.z)+point.y*cos(-rotation.z);
	p.z:=point.z;
	{rotate about y-axis}
	point:=p;
	p.x:=point.x*cos(-rotation.y)+point.z*sin(-rotation.y);
	p.y:=point.y;
	p.z:=-point.x*sin(-rotation.y)+point.z*cos(-rotation.y);
	{rotate about x-axis}
	point:=p;
	p.x:=point.x;
	p.y:=point.y*cos(-rotation.x)-point.z*sin(-rotation.x);
	p.z:=point.y*sin(-rotation.x)+point.z*cos(-rotation.x);
	{return result}
	xyz_unrotate:=p;	
end;


{
	random_0_to_1 returns a real number betwen zero and one.
}
function random_0_to_1:real;
begin 
	random_0_to_1:=random; 
end;

{
	inc_num_outstanding_ptrs incrments num_outstanting_ptrs, and also
	reports the count to the user via gui_writeln if track_ptrs is
	true. The id string should give the name of the pointer, and caller 
	should give the name of the routine that called inc_num_oustanding_ptrs. 
	This routine, together with dec_num_outstanding_ptrs, can be paired with 
	every use of the Pascal new() and dispose() procedures to help you find 
	leaks in your code.
}
procedure inc_num_outstanding_ptrs(size:integer;caller:short_string);
var s:short_string='';
begin
	inc(num_outstanding_ptrs);
	if track_ptrs then begin
		writestr(s,'Allocated ',size:1,' bytes for ',caller,', ',
			num_outstanding_ptrs:1,' pointers outstanding.');
		gui_writeln(s);
	end;
end;

{
	dec_num_outstanding_ptrs is similar to dec_num_outstanting_ptrs, but
	decrements num_outstanding_ptrs.
}
procedure dec_num_outstanding_ptrs(size:integer;caller:short_string);
var s:short_string='';
begin
	dec(num_outstanding_ptrs);
	if track_ptrs then begin
		writestr(s,'Disposing of ',size:1,' bytes for ',caller,', ',
			num_outstanding_ptrs:1,' pointers outstanding.');
		gui_writeln(s);
	end;
end;

{
	start_timer sets the Utils timer variable equal to the current time,
	as returned by GetTimeStamp, and clears the mark_time_list.
}
procedure start_timer(id,caller:short_string);

var
	index:integer;
	ts:TimeStamp;
	s:short_string;
	
begin
	for index:=0 to max_num_time_marks do
		mark_time_list[index]:='';

	mark_time_index:=0;
	debug_counter:=0;
	start_time:=GetMicrosecondTime;
	UnixTimeToTimeStamp(start_time div us_per_s,ts);
	writestr(s,Time(ts),' ',0.0:12:6,'   ',id,' in ',caller);
	mark_time_list[mark_time_index]:=s;
	inc(mark_time_index);
end;

{
	mark_time adds an entry to the mark_time_list.
}
procedure mark_time(id,caller:short_string);

var
	s:short_string;
	t:longint;
	ts:TimeStamp;
	d:real;
	
begin
	if mark_time_index>=max_num_time_marks then exit;
	t:=GetMicrosecondTime;
	d:=(t-start_time)/us_per_s;
	UnixTimeToTimeStamp(t div us_per_s,ts);
	writestr(s,Time(ts),' ',d:12:6,'   ',id,' in ',caller);
	mark_time_list[mark_time_index]:=s;
	inc(mark_time_index);
end;

{
	report_time_marks writes a list of time marks stored in the
	mark_time_list. It calls gui_writeln with each line of output.
}
procedure report_time_marks;

var
	index:integer;
	s:short_string;
	
begin
	s:='';
	gui_writeln(s);
	s:='Timer Mark List:';
	gui_writeln(s);
	for index:=0 to mark_time_index-1 do begin
		writestr(s,index:5,'	',mark_time_list[index]);
		gui_writeln(s);
	end;
	writestr(s,'debug_counter=',debug_counter:1);
	gui_writeln(s);
	writestr(s,'debug_string="',debug_string,'"');
	gui_writeln(s);
end;

{
	report_error appens an error message to the global error_string. The text of
	the error message should be the contents of the string "s". The routine
	attaches error_prefix to "s" before it adds it to error_string. When
	append_errors is true, the routine appends the error to error_string on a
	new line. Otherwise it sets the error_string to the new error message. The
	error message passed in "s" should be a full sensence with a period at the
	end.
}
procedure report_error(s:short_string);

begin
	if (error_string='') or not append_errors then 
		error_string:=error_prefix+s
	else 
		error_string:=error_string+eol+error_prefix+s;
end;

{
	default_gui_draw does nothing.
}
procedure default_gui_draw(s:short_string); 
begin 
end;

{
	default_gui_support does nothing.
}
procedure default_gui_support(s:short_string);
begin
end;

{
	default_gui_wait writes a comment string to stdout and
	waits for a carriage return on stdin.
}
procedure default_gui_wait(s:short_string); 
begin
	if stdin_available and stdout_available then begin
		write(output,s,' (press return)');
		readln;
	end;
end;

{
	default_gui_writeln writes a string to stdout.
}
procedure default_gui_writeln(s:short_string); 
begin
	if stdout_available then writeln(output,s);
end;

{
	default_gui_readln reads a string from the keyboard.
}
function default_gui_readln(s:short_string):short_string;
var a:short_string;
begin
	if stdin_available then readln(input,a);
	default_gui_readln:=a;
end;

{
	new_byte_array allocates space for a new byte_array, and returns a
	pointer to that space.
}
function new_byte_array(size:integer):byte_array_ptr;
var b:byte_array_ptr;
begin
	b:=new(byte_array_ptr,size);
	inc_num_outstanding_ptrs(sizeof(b^),CurrentRoutineName);
	new_byte_array:=b;
end;

{
	dispose_byte array disposes of a byte_array.
}
procedure dispose_byte_array(b:byte_array_ptr);
begin
	dec_num_outstanding_ptrs(sizeof(b^),CurrentRoutineName);
	dispose(b);
end;

{
	read_file reads the contents of a file into a byte_array,
	and returns a byte_arrray_ptr. You specify the file with
	a string that gives the file name.
}
function read_file(name:short_string):byte_array_ptr;

var 
	b:byte_array_ptr;
	f:file;
	size:integer;
	
begin
	reset(f,name,1);
	if InOutRes<>0 then begin
		read_file:=nil;
		report_error('Failed to open file in read_file.');
		exit;
	end;
	size:=FileSize(f);
	b:=new_byte_array(size);
	if b=nil then begin
		read_file:=nil;
		report_error('Failed to allocate in read_file.');
		exit;
	end;
	BlockRead(f,b^[0],size);
	close(f);
	read_file:=b;
end;


{
	write_file writes the contents of a byte_array to disk,
	using the specified file name.
}
procedure write_file(name:short_string;b:byte_array_ptr);

var 
	f:file;
	
begin
	rewrite(f,name,1);
	if InOutRes<>0 then begin
		report_error('Failed to write file in write_file.');
		exit;
	end;
	BlockWrite(f,b^[0],b^.size);
	close(f);
end;

{
	Construct a new simplex with sides of length side_length. We assume that
	the first element in the simplex is already set. We re-calculate the error
	array.
}
procedure simplex_construct(var simplex:simplex_type;
	altitude:simplex_altitude_function_type);

var 
	i:integer;

begin
	with simplex do begin
		for i:=2 to n+1 do begin
			vertices[i]:=vertices[1];
			vertices[i,i-1]:=vertices[i,i-1]+construct_size;
		end;
		for i:=1 to n+1 do altitudes[i]:=altitude(vertices[i]);
	end;
end;

{
	Sort the simplex vertices into order of ascending altitude.
}
procedure simplex_sort(var simplex:simplex_type);

var
	i:integer;
	swapped:boolean;
	v:simplex_vertex_type(simplex.n);
	a:real;
	
begin
	with simplex do begin
		swapped:=true;
		while swapped do begin
			swapped:=false;
			for i:=1 to n do begin
				if altitudes[i]>altitudes[i+1] then begin
					v:=vertices[i];
					a:=altitudes[i];
					vertices[i]:=vertices[i+1];
					altitudes[i]:=altitudes[i+1];
					vertices[i+1]:=v;
					altitudes[i+1]:=a;
					swapped:=true;
				end;
			end;
		end;
	end;
end;

{
	simplex_volume returns the volume of the current simplex.
}
function simplex_volume(var simplex:simplex_type):real;

var
	M:matrix_type(simplex.n,simplex.n);
	i,j:integer;

begin
	with simplex do begin
		for j:=1 to n do begin
			for i:=1 to n do begin
				M[j,i]:=vertices[j+1,i]-vertices[1,i];
			end;
		end;
	end;
	simplex_volume:=abs(matrix_determinant(M));
end;

{
	simplex_size returns the length of the longest side in
	a simplex.
}
function simplex_size(var simplex:simplex_type):real;

var
	i,j,k:integer;
	max,s:real;

begin
	max:=0;
	with simplex do begin
		for j:=1 to n do begin
			for k:=j+1 to n+1 do begin
				s:=0;
				for i:=1 to n do 
					s:=s+sqr(vertices[j,i]-vertices[k,i]);
				if s>max then max:=s;
			end;
		end;
	end;
	simplex_size:=sqrt(max);
end;

{
	Here is our simplex fitting routine. It takes one simplex step, whereby a
	simplex shape in the fitting space is either reflected, extended, or
	contracted. As the fit converges, we re-construct the simplex to make sure
	we don't get stuck in a false convergance.
}
procedure simplex_step(var simplex:simplex_type;
	altitude:simplex_altitude_function_type);

	procedure add(var a,b:simplex_vertex_type);
	var i:integer; begin for i:=1 to a.n do a[i]:=a[i]+b[i]; end;
	procedure subtract(var a,b:simplex_vertex_type);
	var i:integer; begin for i:=1 to a.n do a[i]:=a[i]-b[i]; end;
	procedure scale(var a:simplex_vertex_type;s:real);
	var i:integer; begin for i:=1 to a.n do a[i]:=a[i]*s; end;

const
	reflect_scale=1;
	expand_scale=2;
	contract_scale=0.5;
	shrink_scale=0.5;
	report=false;
	small_size_factor=1e-5;
	
var 
	i,j:integer;
	v,v_center,v_contract,v_expand,v_reflect:simplex_vertex_type(simplex.n);
	a_reflect,a_contract,a_expand:real;
	
begin
{
	Sort the vertices in ascending altitude.
}
	simplex_sort(simplex);
{	
	Determine the center of mass of the first n vertices. The one remaining
	vertex, number n+1, is at the highest altitude following the sort.
}
	with simplex do begin
		v_center:=vertices[1];
		for i:=2 to n do add(v_center,vertices[i]);
		scale(v_center,1/n);
{
	Reflect the highest vertex through the center of mass of the others.
}
		v:=v_center;
		subtract(v,vertices[n+1]);
		scale(v,reflect_scale);
		add(v,v_center);
		v_reflect:=v;
		a_reflect:=altitude(v_reflect);
{
	If the altitude of the new vertex is somewhere between that of the the first
	n vertices, we keep it in place of the worste vertex.
}
		if (a_reflect>=altitudes[1]) and (a_reflect<altitudes[n]) then begin
			vertices[n+1]:=v_reflect;
			altitudes[n+1]:=a_reflect;
			if report then write('r');
		end;
{
	If the altitude of this new vertex is lower than all the other vertices, we
	try to expand our reflection in the hope of getting an even lower altitude.
	Otherwise we go back to the original reflected vertex and use is to replace
	the highest vertex.
}
		if (a_reflect<altitudes[1]) then begin
			v:=v_center;
			subtract(v,vertices[n+1]);
			scale(v,expand_scale);
			add(v,v_center);
			v_expand:=v;
			a_expand:=altitude(v_expand);
			if a_expand<a_reflect then begin
				vertices[n+1]:=v_expand;
				altitudes[n+1]:=a_expand;
				if report then write('e');
			end else begin
				vertices[n+1]:=v_reflect;
				altitudes[n+1]:=a_reflect;
				if report then write('r');
			end;
		end;
{
	If the reflected vertex is higher than all the others, we contract the simplex by
	moving the highest original verticex towards the center of mass of the
	others. If the contracted vertex is lower than the highest original vertex, we
	accept the contracted vertex and reject the highest original vertex. Otherwise,
	we have encountered a double-ridge and we must do something to get going
	again. We can shrink the entire simplex or re-construct a new one around the
	best vertex. The Nelder-Mead method proscribes the shrink. We have code to
	perform the shrink, but we find that re-constructing the simplex in this
	situation avoids convergeance in the wrong spot, so we use the re-construction
	instead of the shrinking.
}
		if (a_reflect>=altitudes[n]) then begin
			v:=v_center;
			subtract(v,vertices[n+1]);
			scale(v,contract_scale);
			add(v,vertices[n+1]);
			v_contract:=v;
			a_contract:=altitude(v_contract);
			if a_contract<=altitudes[n+1] then begin
				vertices[n+1]:=v_contract;
				altitudes[n+1]:=a_contract;
				if (simplex_size(simplex)<construct_size*small_size_factor) then 
					inc(done_counter);
				if report then write('c');
			end else begin
{
					for i:=2 to n+1 do begin
						subtract(vertices[i],vertices[1]);
						scale(vertices[i],shrink_scale);
						add(vertices[i],vertices[1]);
						altitudes[i]:=altitude(vertices[i]);
					end;
					if report then write('s');
}
				inc(done_counter);
				if done_counter<max_done_counter then begin
					simplex_construct(simplex,altitude);
					if report then write('x');
				end;
			end;
		end;
	end;
{
	Sort the vertices in order of ascending error again.
}
	simplex_sort(simplex);
end;

{
	bubble_sort arranges the elements of a list in increasing order, as
	defined by the "greater" function, by applying the "swap" function.
	
	The bubble sort algorithm usually completes in n*n time, where n is the
	length of the list. It is so simple, it's hardly worth making a library
	procedure for it. The reason we provide one is as a simple basis for the
	format of a sort routine, and to compare the bubble-sort with our quick-sort
	routine.

	The integers a and b are the indeces of an array between which you want the
	sort to take place. The bubble_sort will sort these elements in place and
	leave any other elements in the array undisturbed. The "swap" procedure must
	be defined by the bubble-sort user. It is a procedure that takes two
	integers, m and n. A call swap(m,n) exchanges elements m and n in the list.
	The "greater" function returns a boolean result and takes two integers m and
	n as parameters. If the m'th element in the list must come before the n'th
	element, then greater(m,n) should be true. Otherwise greater(m,n) is should
	be false. By means of swap(m,n) and greater(m,n), the bubble_sort routine,
	and also the quick_sort routine that comes later, are able to interact with
	lists of any type. There is no point in the bubble_sort or quick_sort routine
	where the actual value of any list element is used directly.
}
procedure bubble_sort(a,b:integer;
	swap:sort_swap_procedure_type;
	greater:sort_compare_function_type);

var
	swapped:boolean;
	n:integer;

begin
{
	Cover special cases of short lists.
}
	if b-a<=1 then exit;
	if (b-a)=2 then begin
		if greater(a,b) then swap(a,b);
		exit;
	end;
{
	Go through the list repeatedly, swapping neighbors that are 
	out of order, until we run through once without swapping any
	elements.
}
	swapped:=true;
	while swapped do begin
		swapped:=false;
		for n:=a to b-1 do begin
			if greater(n,n+1) then begin
				swap(n,n+1);
				swapped:=true;
			end;
		end;
	end;
end;

{
	quick_sort arranges the elements of a list in increasing order, as
	defined by the "greater" function, by applying the "swap" function.
	For an explanation of how to define the greater and swap functions
	for the quick_sort call, see the comments in the bubble-sort routine
	above.
	
	The quick sort algorithm usually operates in n.log(n) time, where n
	is the length of the list. The table below gives the average time to 
	sort a list of n integers, starting with random values between 1 and
	n in each element. We compare the bubble-sort to the quick-sort on the
	same computer (a 1 GHz PPC laptop) with the same list structure, record
	size, and swap function.
	
	n         Quick (us)  Bubble (us)
	1         0.1         0.1        
	10        6.2         4.1  
	100       75          490
	1000      1,000       56,000
	10000     13,000      5,300,000
	100000    150,000     610,000,000
	1000000   1,700,000   -
	10000000  19,000,000  -
	
	We find that the advantage of quick-sort is far less when the list is
	a concatination of several pre-sorted lists, or if the list is nearly-
	sorted to begin with.
}
procedure quick_sort(a,b:integer;
	swap:sort_swap_procedure_type;
	greater:sort_compare_function_type);

var
	m,n,p:integer;
	
begin
{
	Exit in redundant cases.
}
	if b<=a then exit;
{
	Pick a random pivot element and move it to the end of the list, 
	at location b. The random location picking avoids certain systematic
	delays in sorting caused by regular patterns in the original list.
}
	p:=round(random_0_to_1*(b-a)+a);
	swap(p,b);
{
	Move elements greater than the pivot element to the end of the list
	made up of elements a to b-1.
}
	m:=a;
	n:=b-1;
	while m<n do begin
		if greater(m,b) then begin
			swap(m,n);
			dec(n);
		end else begin
			inc(m);
		end;
	end;
{
	Put the pivot element into the list, with elements less than the pivot 
	on the left and those greater on the right.
}
	if greater(m,b) then p:=m else p:=m+1;
	swap(p,b);
{
	Sort the two sub-lists.
}
	quick_sort(a,p-1,swap,greater);
	quick_sort(p+1,b,swap,greater);
end;

{
	initialization sets up the utils variables.
}
initialization 

randomize;
gui_draw:=default_gui_draw;
gui_support:=default_gui_support;
gui_wait:=default_gui_wait;
gui_writeln:=default_gui_writeln;
gui_readln:=default_gui_readln;
big_endian:=check_big_endian;


{
	finalization does nothing.
}
finalization

end.