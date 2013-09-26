{
	TCL/TK Command Line Implementations of Pascal Routines 
	Copyright (C) 2004-2012 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
	
	This program is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2 of the License, or (at your
	option) any later version.
	
	This program is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the GNU
	General Public License for more details.
	
	You should have received a copy of the GNU General Public License along
	with this program; if not, write to the Free Software Foundation, Inc.,
	59 Temple Place - Suite 330, Boston, MA	02111-1307, USA.
}

program lwdaq;

{
	lwdaq is the interface between our Pascal libraries and TCL/TK. It
	provides init_Lwdaq, which TCL/TK calls when it loads the lwdaq
	dynamic library. init_Lwdaq installs TCL commands, each of which has
	a name beginning with lwdaq in lower-case letters. The lower-case
	letters distinguish these commands from those that we define in
	TCL/TK scripts, which have names that begin with LWDAQ.

	This is a program instead of a unit, even though we compile it into
	a dynamic library. The GPC compiler expects a main program if it is
	to include the _p_initialize routine in the compiled object. We will
	need this routine to be present in the lwdaq.o object when we link
	the final lwdaq.so dynamic library with GCC.

	For a list of routines registered with TCL by this library, scroll
	down to lwdaq_init.

	At the top of each command-line function declaration you will find a
	comment in braces that describes the function. This comment will be
	extracted from lwdaq.pas automatically by our Command Maker script,
	and inserted into an HTML document. The comments appear as they are,
	in the HTML manual, and so include their own HTML tags, and even
	anchors.
}

uses
	utils,images,transforms,image_manip,rasnik,spot,
	tcltk,electronics,bcam,wps,shadow;

const
	version_num='7.7';
	package_name='lwdaq';

{	
	initialize_pascal starts up the run-time library and calls the
	initialization routines of all units. The routine is in the
	pascal run-time library, libgpc.a.
}
procedure initialize_pascal (argc:integer;argv,envp:pointer);
	external name '_p_initialize';

{
	initialize_main is a procedure provided by the pascal compiler. A
	call to this procedure initializes all the units.
}
procedure initialize_main;
	external name '_p__M0_init';

{
	finalize_pascal shuts down the run-time library. We don't use
	it at all in our current code, but we include it here in case
	we use it in some later version. We used it in an early version
	of this shared library.
}
procedure finalize_pascal;
	external name '_p_finalize';
		
{
	The following variables we use to implement the utils gui routines for
	analysis procedures.
}
var
	gui_photo_name:short_string='none';
	gui_zoom:real=1.0;
	gui_intensify:short_string='exact';
	gui_text_name:short_string='stdout';
	gui_interp_ptr:pointer=nil;
	gui_wait_ms:integer=-1;
{
	The following long string variable allows us to dispose of a long 
	string before we copy it into the TCL results string. We copy the 
	dynamically-allocated long string into this static variable, dispose
	of the dynamic long string, and then copy the long string out of
	the static variable. If we don't do this, then we run into trouble
	when we turn on our pointer-tracking. The pointer tracking uses
	Tcl_Eval and Tcl_PutMessage to execute print commands in the TCL
	interpreter. These print commands set the TCL results string to 
	an empty string, cancelling our execution of Tcl_SetReturnLongString.
}
var
	lwdaq_long_string:long_string;
{
	Here we have various global variables that store data for repeated
	use by lwdaq library functions. Passing parameters into and out of
	the library routines is time-consuming because it requires conversion
	from strings to real numbers and back again. If we pass a list of
	reference points one time, for example, and store it in a global
	list, we can later refer to this list without passing it again.
}
var
	nearest_neighbor_library_ptr:matrix_ptr=nil;
	
{
	lwdaq_gui_draw draws the named image into the TK photo named
	gui_photo_name. The routine calls lwdaq_draw, which, like all the
	lwdaq TclTk commands, clears the global error_string. We save the
	initial value of error_string so we can restore it after the 
	update. This restoration means we can call lwdaq_gui_draw anywhere
	in our code without deleting the existing error_string.
}
procedure lwdaq_gui_draw(s:short_string); 
var c:short_string;saved_error_string:short_string;error:integer;
begin
	if (gui_photo_name<>'none') and (gui_interp_ptr<>nil) then begin
		saved_error_string:=error_string;
		c:=' lwdaq_draw '+s+' '+gui_photo_name 
			+' -intensify '+gui_intensify
			+' -zoom '+string_from_real(gui_zoom,1,2);
		error:=Tcl_Eval(gui_interp_ptr,c);
		c:='LWDAQ_update';
		error:=Tcl_Eval(gui_interp_ptr,c);
		error_string:=saved_error_string;
	end else
		default_gui_draw(s);
end;

{
	lwdaq_gui_wait pauses for gui_wait_ms milliseconds. If gui_wait_ms
	is -1, the routine opens a window and asks the user to press the
	button before returning.
}
procedure lwdaq_gui_wait(s:short_string); 
var c:short_string;error:integer;
begin
	if (gui_interp_ptr<>nil) then begin
		if (gui_wait_ms>=0) then 
			c:='LWDAQ_wait_ms '+string_from_integer(gui_wait_ms,1)
		else 
			c:='LWDAQ_button_wait "'+s+'"';
		error:=Tcl_Eval(gui_interp_ptr,c);
	end;
end;

{
	lwdaq_gui_support passes control to the graphical user interface to perform
	support for display updates and mouse clicks.
}
procedure lwdaq_gui_support(s:short_string);
var c:short_string;error:integer;
begin
	if (gui_interp_ptr<>nil) then begin
		c:='LWDAQ_support';
		error:=Tcl_Eval(gui_interp_ptr,c);
	end;
end;

{
	lwdaq_gui_writeln writes a string to a text device using the LWDAQ_print
	routine. The LWDAQ_print routine accepts file names, text widget names, 
	and the names of the standard output (stdout) and standard error (stderr) 
	channels. The name used by lwdaq_gui_writeln is the name stored in the global
	lwdaq_text_name variable.
}
procedure lwdaq_gui_writeln(s:short_string); 
var c:short_string;error:integer;
begin
	c:='LWDAQ_print '+gui_text_name+' "'+s+'"';
	error:=Tcl_Eval(gui_interp_ptr,c);
end;

{
<p>lwdaq_config sets global variables that control the operation of the lwdaq analysis libraries. If you specify no options, lwdaq_config returns a string giving you the current values of all the options, <i>except</i> the -eol option. Each option requires a value, which will be assigned to the global variable names in the option. Here are the options and their expected value types. Boolean variables you specify with 0 for false and 1 for true.</p>

<center><table cellspacing=1 border>
<tr><th>Option</th><th>Type</th><th>Function</th></tr>
<tr><td>-stdout_available</td><td>Boolean</td><td>standard output channel is available</td></tr>
<tr><td>-stdin_available</td><td>Boolean</td><td>standard input channel is available</td></tr>
<tr><td>-track_ptrs</td><td>Boolean</td><td>track memory allocation</td></tr>
<tr><td>-text_name</td><td>String</td><td>text window in which to print messages</td></tr>
<tr><td>-photo_name</td><td>String</td><td>photo in which to draw images and graphs</td></tr>
<tr><td>-zoom</td><td>Real</td><td>display zoom for images</td></tr>
<tr><td>-intensify</td><td>String</td><td>intensification type for images,<br>
			none, mild, strong, or exact.</td></tr>
<tr><td>-wait_ms</td><td>Integer</td><td>milliseconds to pause during lwdaq_gui_wait</td></tr>
<tr><td>-gamma_correction</td><td>Real</td><td>image drawing gamma correction</td></tr>
<tr><td>-rggb_red_scale</td><td>Real</td><td>image drawing red brightness</td></tr>
<tr><td>-rggb_blue_scale</td><td>Real</td><td>image drawing blue brightness</td></tr>
<tr><td>-fsr</td><td>Integer</td><td>field size for real numbers returned in strings.</td></tr>
<tr><td>-fsd</td><td>Integer</td><td>decimal places for real numbers returned in strings.</td></tr>
<tr><td>-eol</td><td>String</td><td>end of line characters for text windows and files.</td>
<tr><td>-append_errors</td><td>Boolean</td><td>Append errors to the global error string<br>
	instead of over-writing with latest error.</td>
</table></center>

<p>The analysis routines can write to TK text windows, and draw in TK photos through -text_name and -photo_name. During execution, they can pause to allow you to view the intermediate results for -wait_ms millisconds. If you set -wait_ms to -1, TK will open a window with a Continue button in it, which you must click before the analysis proceeds.</p>

<p>The <a href="http://www.cgsd.com/papers/gamma.html">gamma correction</a></td> sets the gray scale image display gamma correction used by lwdaq_draw and lwdaq_rggb_draw. By default it is 1.0, which gives us a linear relationship between the image pixel intensity and the display pixel intensity. The <i>rggb_red_scale</i> and <i>rggb_blue_scale</i> parameters determine how we increase the brightness of the red and blue component of the display pixel with respect to the green component. By default, these are also 1.0.</p>

<p>Many routines return real numbers in strings. These real numbers will have a fixed number of decimal places equal to the global Pascal variable <i>fsd</i> and a total field size equal to the global Pascal variable <i>fsr</i>.</p> 

<p>The global error_string variable is used by all the command routines in lwdaq.pas. Each command routine resets error_string and checks it when it's finished. If error_string is not empty, the routine will return an error condition and error_string will be its result. The append_errors option tells the analysis library to append new errors to error_string instead of over-writing previous errors with the new error. By default, append_errors is false.</p>
}
function lwdaq_config(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	vp:pointer;
	
begin
	error_string:='';
	lwdaq_config:=Tcl_Error;

	if (not odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_config ?option value?".');
		exit;
	end;
	
	if argc=1 then begin
		Tcl_SetReturnShortString(interp,
			' -stdout_available '+string_from_boolean(stdout_available)
			+' -stdin_available '+string_from_boolean(stdin_available)
			+' -append_errors '+string_from_boolean(append_errors)
			+' -track_ptrs '+string_from_boolean(track_ptrs)
			+' -text_name '+gui_text_name
			+' -photo_name '+gui_photo_name
			+' -zoom '+string_from_real(gui_zoom,1,2)
			+' -intensify '+gui_intensify
			+' -wait_ms '+string_from_integer(gui_wait_ms,0)
			+' -gamma_correction '+string_from_real(gamma_correction,0,1)
			+' -rggb_blue_scale '+string_from_real(rggb_blue_scale,0,1)
			+' -rggb_red_scale '+string_from_real(rggb_red_scale,0,1)
			+' -fsr '+string_from_integer(fsr,0)
			+' -fsd '+string_from_integer(fsd,0));
	end else begin
			arg_index:=1;
			while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-stdout_available') then stdout_available:=Tcl_ObjBoolean(vp)
		else if (option='-stdin_available') then stdin_available:=Tcl_ObjBoolean(vp)
		else if (option='-append_errors') then append_errors:=Tcl_ObjBoolean(vp)
		else if (option='-track_ptrs') then track_ptrs:=Tcl_ObjBoolean(vp)
		else if (option='-text_name') then gui_text_name:=Tcl_ObjShortString(vp)
		else if (option='-photo_name') then gui_photo_name:=Tcl_ObjShortString(vp)
		else if (option='-zoom') then gui_zoom:=Tcl_ObjReal(vp)
		else if (option='-intensify') then gui_intensify:=Tcl_ObjShortString(vp)
		else if (option='-wait_ms') then gui_wait_ms:=Tcl_ObjInteger(vp)
		else if (option='-gamma_correction') then gamma_correction:=Tcl_ObjReal(vp)
		else if (option='-rggb_blue_scale') then rggb_blue_scale:=Tcl_ObjReal(vp)
		else if (option='-rggb_red_scale') then rggb_red_scale:=Tcl_ObjReal(vp)
		else if (option='-fsr') then fsr:=Tcl_ObjInteger(vp)
		else if (option='-fsd') then fsd:=Tcl_ObjInteger(vp)
		else if (option='-eol') then eol:=Tcl_ObjShortString(vp)
		else begin 
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-stdout_available ? -stdin_available ? -append_errors ?'
				+' -track_ptrs ? -text_name ? -photo_name ? -wait_ms ?'
				+' -gamma_correction ? -rggb_red_scale ? -rggb_blue_scale ?'
				+' -fsr ? -fsd ? -eol ? -zoom ? -intensify ?".'); 
			exit;
		end;
			end;
	end;

	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_config:=Tcl_OK;	
end;

{
<p>lwdaq_image_create creates a new image and returns a unique name for the image, by which the interpreter can identify the image to other lwdaq routines.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-name</td><td>Specify the name for the image.</td></tr>
<tr><td>-results</td><td>Set the image results string.<td></td></tr>
<tr><td>-width</td><td>The width of the image in pixels.</td></tr>
<tr><td>-height</td><td>The height of the image in pixels</td></tr>
<tr><td>-data</td><td>Pixel intensity values as a binary array of bytes.</td></tr>
<tr><td>-left</td><td>Left column of analysis bounds.</td></tr>
<tr><td>-right</td><td>Right column of analysis bounds.</td></tr>
<tr><td>-top</td><td>Topm row of analysis bounds.</td></tr>
<tr><td>-bottom</td><td>Bottom row of analysis bounds.</td></tr>
<tr><td>-try_header</td><td>Try the image data for a legitimate lwdaq-format header.</td></tr>
</table>

<p>The above table lists the options accepted by lwdaq_image_create, and their functions. If you use the -name option and provide the name of a pre-existing image in the lwdaq image list, lwdaq_image_create deletes the pre-existing image. If you specify "-data $value", the routine copies $value into the image's intensity array, starting at the first pixel of the first row. When you combine "-data $value" with "-try_header 1", the routine looks at the first bytes in $value to see if it contains a valid image header, specifying image width and height, as well as analysis bounds and a results string. When the routine looks for the header, it assumes that the bytes in the header specify two-byte integers in big-endian order.</p>

<p>If you have -try_header 0, or if the routine's effort to find a header fails, lwdaq_image_create will look at the values you specify for the analysis bounds with the -left, -top, -right, and -bottom options. A value of &minus;1 directs the routine to place the boundary at the edge of the image. The default values for these options are all &minus;1.</p>
}
function lwdaq_image_create(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	max_side=10000;
	min_side=10;
	
var 
	option:short_string;
	arg_index:integer;
	width,height,data_size,copy_size:integer=-1;
	left,right,top,bottom:integer=-1;
	try_header:boolean=false;
	ihp:image_header_ptr_type;
	data_obj,data_ptr:pointer=nil;
	name:short_string='';
	results:short_string='';
	ip:image_ptr_type=nil;
	vp:pointer=nil;
	char_index:integer;
	q:integer;

begin
	error_string:='';
	lwdaq_image_create:=Tcl_Error;

	if (argc<3) or (not odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_image_create option value ?option value?".');
		exit;
	end;
	
	arg_index:=1;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-name') then name:=Tcl_ObjShortString(vp)
		else if (option='-results') then results:=Tcl_ObjShortString(vp)
		else if (option='-width') then width:=Tcl_ObjInteger(vp)
		else if (option='-height') then height:=Tcl_ObjInteger(vp)
		else if (option='-data') then data_obj:=vp
		else if (option='-left') then left:=Tcl_ObjInteger(vp)
		else if (option='-right') then right:=Tcl_ObjInteger(vp)
		else if (option='-top') then top:=Tcl_ObjInteger(vp)
		else if (option='-bottom') then bottom:=Tcl_ObjInteger(vp)
		else if (option='-try_header') then try_header:=Tcl_ObjBoolean(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-name -width -height -data -left -top'
				+' -bottom -right -results -try_header".');
			exit;
		end;
	end;

	if data_obj<>nil then begin
		data_ptr:=Tcl_GetByteArrayFromObj(data_obj,data_size);
		if data_size<0 then begin
			Tcl_SetReturnShortString(interp,'Data size less than zero.');
			exit;
		end;
		
		ihp:=pointer(data_ptr);
		if try_header then begin
			q:=local_from_big_endian_shortint(ihp^.j_max)+1;
			if (q>0) then height:=q;
			q:=local_from_big_endian_shortint(ihp^.i_max)+1;
			if (q>0) then width:=q;
		end;

		if (width<=0) and (height<=0) then begin
			width:=trunc(sqrt(data_size));
			if sqr(width)<data_size then width:=width+1;
			height:=width;
		end;

		if (width<=0) and (height>0) then begin
			width:=trunc(data_size/height);
			if width*height<data_size then width:=width+1;
		end;

		if (width>0) and (height<=0) then begin
			height:=trunc(data_size/width);
			if width*height<data_size then height:=height+1;
		end;

		if width<min_side then width:=min_side;
		if width>max_side then width:=max_side;
		if height<min_side then height:=min_side;
		if height>max_side then height:=max_side;

		if (width*height>data_size) then copy_size:=data_size
		else copy_size:=(width*height);
	end;
	
	if (data_obj=nil) and try_header then begin
		Tcl_SetReturnShortString(interp,'Specified -try_header 1 without -data $value.');
		exit;
	end;
	
	ip:=new_image(height,width);
	if ip=nil then begin 
		Tcl_SetReturnShortString(interp,'Failed to allocate memory for new image.');
		exit;
	end;
	
	if data_ptr<>nil then begin
		block_move(data_ptr,@ip^.intensity,copy_size);
	end;
	
	if try_header then begin
		q:=local_from_big_endian_shortint(ihp^.left);
		if (q>=0) then left:=q;
	end;
	if (left<0) or (left>=width) then left:=0;
	ip^.analysis_bounds.left:=left;
	
	if try_header then begin
		q:=local_from_big_endian_shortint(ihp^.right);
		if (q>left) then right:=q;
	end;
	if (right<=left) or (right>=width) then right:=width-1;
	ip^.analysis_bounds.right:=right;

	if try_header then begin
		q:=local_from_big_endian_shortint(ihp^.top);
		if (q>=0) then top:=q;
	end;
	if (top<1) or (top>=height) then top:=1;
	ip^.analysis_bounds.top:=top;
	
	if try_header then begin
		q:=local_from_big_endian_shortint(ihp^.bottom);
		if (q>top) then bottom:=q;
	end;
	if (bottom<=top) or (bottom>=height) then bottom:=height-1;
	ip^.analysis_bounds.bottom:=bottom;
	
	ip^.results:=results;
	if try_header and (ip^.results='') then begin
		char_index:=0;
		while (char_index<short_string_length) 
				and (ihp^.results[char_index]<>chr(0)) do begin
			ip^.results:=ip^.results+ihp^.results[char_index];
			inc(char_index);
		end;
	end;
	
	if name<>'' then begin
		while valid_image_name(name) do
			dispose_image(image_ptr_from_name(name));
		ip^.name:=name;
	end;
	
	if error_string='' then Tcl_SetReturnShortString(interp,ip^.name)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_create:=Tcl_OK;
end;

{
<p>lwdaq_draw transfers the named image into the named TK photo. You pass the lwdaq image name followed by the tk photo name, and then your options in the form ?option value?. When the routine draws the image, it over-writes the first few pixels in the first image row with a header block containing the image dimensions, its analysis bounds, and its results string.</p>

<p>The -intensify option can take four values: mild, strong, exact, and none. Mild intensification displays anything darker than four standard deviations below the mean intensity as black, and anything brighter than four standard deviations above the mean intensity as white. In between black and white the display is linear with pixel brightness. Strong intensification does the same thing, but for a range of two standard deviations from the mean. Exact displays the darkest spot in the image as black and the brightest as white. In all three cases, we calculate the mean, standard deviation, minimum, and maximum intensity of the image within the <i>analysis bounds</i>, not across the entire image.</p>

<p>The -zoom option scales the image as we draw it in the TK photo. If the TK photo is initially smaller than the size required by the zoomed image, the TK photo will expand to accommodate the zoomed image. But if the TK photo is initially larger than required, the TK photo will not contract to the smaller size of the zoomed image. The -zoom option can take any value between 0.1 and 10. But the effective value of -zoom is dicated by the requirements of sub-sampling. If -zoom is greater than 1, we round it to the nearest integer, <i>e</i>, and draw each image pixel on the screen as a block of <i>e</i>&times;<i>e</i> pixels. If -zoom is less than 1, we round its inverse to the nearest integer, <i>c</i>. We draw only one pixel out of every <i>c</i> pixels in the TK photo. If -zoom = 0.3, we draw every third pixel. If -zoom = 0.4, we draw every third pixel if your computer rounds 1/0.4 to 3, or every second pixel if your computer rounds 1/0.4 to 2. With -zoom = 0.0, we draw every tenth pixel.</p>

<p>With -clear set to 1, lwdaq_draw clears the overlay in the lwdaq image before drawing in the TK photo. The overlay may contain a graph or oscilloscope display, or analysis indicator lines. If you don't want these to be displayed, set -clear to 1. But note that whatever was in the overlay will be lost.</p>

<p>By default, -show_bounds is 1, and the routine draws a blue rectangle to show the the image analysis boundaries, which are used by image analysis routines like lwdaq_rasnik and lwdaq_bcam. But with -show_bounds set to 0, this blue rectangle is not drawn. If you want to be sure that you don't have a blue rectangle drawn over your gray-scale image, you should also specify -clear 1, so that lwdaq_draw will clear the image overlay of any pre-existing blue rectangles.</p>
}
function lwdaq_draw(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	min_zoom=0.1;
	max_zoom=10;
	
var 
	option:short_string;
	arg_index,char_index:integer;
	width,height,data_size:integer=0;
	image_name,photo_name,intensify:short_string='';
	ip:image_ptr_type=nil;
	zoom:real=1;
	vp,ph:pointer=nil;
	pib:Tk_PhotoImageBlock;
	subsampleX,subsampleY,zoomX,zoomY:integer;
	draw_width,draw_height:integer;
	clear,rggb:boolean=false;
	show_bounds:boolean=true;
	saved_bounds:ij_rectangle_type;

begin
	error_string:='';
	lwdaq_draw:=Tcl_Error;
		
	if (argc<3)	or (not odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_draw image photo ?option value?".');
		exit;
	end;
		
	image_name:=Tcl_ObjShortString(argv[1]);
	photo_name:=Tcl_ObjShortString(argv[2]);
	arg_index:=3;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-intensify') then intensify:=Tcl_ObjShortString(vp)
		else if (option='-zoom') then zoom:=Tcl_ObjReal(vp)
		else if (option='-clear') then clear:=Tcl_ObjBoolean(vp)
		else if (option='-show_bounds') then show_bounds:=Tcl_ObjBoolean(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-intensify -zoom -clear -show_bounds".');
			exit;
		end;
	end;
	
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	embed_image_header(ip);

	if intensify='exact' then ip^.intensification:=exact_intensify
	else if intensify='mild' then ip^.intensification:=mild_intensify
	else if intensify='strong' then ip^.intensification:=strong_intensify
	else if intensify='exact_rggb' then begin 
		ip^.intensification:=exact_intensify;
		rggb:=true;
	end else if intensify='mild_rggb' then begin
		ip^.intensification:=mild_intensify;
		rggb:=true;
	end else if intensify='strong_rggb' then begin
		ip^.intensification:=strong_intensify;
		rggb:=true;
	end else if intensify='rggb' then begin
		ip^.intensification:=no_intensify;
		rggb:=true;
	end else ip^.intensification:=no_intensify;
	
	ph:=Tk_FindPhoto(interp,photo_name);
	if ph=nil then begin
		Tcl_SetReturnShortString(interp,'Photo "'+photo_name+'" does not exist.');
		exit;
	end;
	
	if clear then clear_overlay(ip);
	if show_bounds then
		draw_overlay_rectangle(ip,ip^.analysis_bounds,blue_color);
	if rggb then draw_rggb_image(ip)
	else draw_image(ip);
	with pib do begin
		pixelptr:=@drawing_space_ptr^[0];
		width:=ip^.i_size;
		height:=ip^.j_size;
		pitch:=width*sizeof(drawing_space_pixel_type);
		pixelSize:=sizeof(drawing_space_pixel_type);
		offset[red]:=0;
		offset[green]:=offset[red]+sizeof(byte);
		offset[blue]:=offset[green]+sizeof(byte);
		offset[alpha]:=offset[blue]+sizeof(byte);
	end;
	if zoom<min_zoom then zoom:=min_zoom;
	if zoom>max_zoom then zoom:=max_zoom;
	if zoom>=1 then begin
		subsampleX:=1;
		subsampleY:=1;
		zoomX:=round(zoom);
		zoomY:=round(zoom);
		draw_width:=pib.width*zoomX;
		draw_height:=pib.height*zoomY;
	end else begin
		subsampleX:=round(1/zoom);
		subsampleY:=round(1/zoom);
		zoomX:=1;
		zoomY:=1;
		draw_width:=round(pib.width/subsampleX);
		draw_height:=round(pib.height/subsampleY);
	end;
	
	Tk_PhotoSetSize(interp,ph,draw_width,draw_height);
	Tk_PhotoBlank(ph);
{$ifdef TCLTK_8_5}
	Tk_PhotoPutZoomedBlock(interp,ph,@pib,0,0,
		draw_width,draw_height,
		zoomX,zoomY,subsampleX,subsampleY,1);
{$else}
	Tk_PhotoPutZoomedBlock(ph,@pib,0,0,
		draw_width,draw_height,
		zoomX,zoomY,subsampleX,subsampleY,1);
{$endif}
	
	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_draw:=Tcl_OK;
end;

{
<p>lwdaq_image_contents returns a byte array containing the intensity array from the named image. In the first line of the image the routine records the image dimensions, analysis boundry, and results string. The integers are two-bytes long, and we use big-endian byte ordering, so the high-order byte is first.</p>

<p>If you specify -truncate 1, the routine removes all trailing zero-bytes from the data. When we create a new image to accomodate the same data later, we clear the image intensity array before we copy in the new data, so the image is re-constructed faithfully. This truncation is effective at reducing the size of data files from instruments that don't fill the intensity array with real data, but instead use the intensity array as a place to store one-dimensional data, and use the overlay as a white-board upon which to render the data (like the Voltmeter). If you specify -data_only 1, the routine chops off the leading row of data, leaving only the data from the first pixel of the first row onwards, which is the block of data operated upon by our lwdaq_data_manipulate routines. If you specify -record_size larger than 1, the routine makes sure that the size of the block it returns is divisible by the record size.</p>
}
function lwdaq_image_contents(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	image_name:short_string='';
	ip,cip:image_ptr_type;
	vp:pointer;	
	char_index,i,j,ci,cj:integer;
	truncate,data_only:boolean=false;
	copy_size:integer=0;
	record_size:integer=1;
	cp:pointer;

begin
	error_string:='';
	lwdaq_image_contents:=Tcl_Error;
	
	if (argc<2) then begin
			Tcl_SetReturnShortString(interp,
				'Wrong number of arguments, must be "lwdaq_image_contents image".');
		 exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;

	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-truncate') then truncate:=Tcl_ObjBoolean(vp)
		else if (option='-data_only') then data_only:=Tcl_ObjBoolean(vp)
		else if (option='-record_size') then record_size:=Tcl_ObjInteger(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-truncate -data_only -record_size".');
			exit;
		end;
	end;

	embed_image_header(ip);
	
	if truncate then begin
		with ip^ do begin
			j:=j_size-1;
			i:=i_size-1;
			copy_size:=sizeof(ip^.intensity);
			while (j>0) and (intensity[j,i]=0) do begin
				if i=0 then begin
					dec(j);
					i:=i_size-1;
				end else begin
					dec(i);
				end;
				dec(copy_size);
			end;
		end;
	end
	else copy_size:=sizeof(ip^.intensity);
	
	if data_only then begin
		copy_size:=copy_size-ip^.i_size;
		cp:=@ip^.intensity[1,0];
	end else begin
		cp:=@ip^.intensity[0,0];
	end;
	
	if record_size>1 then
		if (copy_size mod record_size) > 0 then
			copy_size:=copy_size+record_size-(copy_size mod record_size);
	
	if error_string='' then Tcl_SetReturnByteArray(interp,cp,copy_size)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_contents:=Tcl_OK;
end;

{
<p>lwdaq_image_destroy disposes of an image. You can specify multiple images, or image name patterns with * and ? wild cards. You can enter multiple image names on the command line, too.</p>
}
function lwdaq_image_destroy(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	image_name:short_string='';
	vp:pointer;	

begin
	error_string:='';
	lwdaq_image_destroy:=Tcl_Error;
	
	if (argc<2) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_image_destroy image".');
		exit;
	end;
	
	for arg_index:=1 to argc-1 do begin
		image_name:=Tcl_ObjShortString(argv[arg_index]);
		dispose_named_images(image_name);
	end;
	
	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_destroy:=Tcl_OK;
end;

{
<p>lwdaq_photo_contents returns a byte array containing gray-scale intensity array corresponding to a tk photo. The routine uses the red intensity as the gray-scale intensity, which will work in a purely gray-scale image, and assumes that the red intensity is an 8-bit number.<p>

<p>The routine embeds the image dimensions in the first four pixels of the image by over-writing them with j_size-1 and i_size-1 each as two-byte integers in big-endian format. If the image is one that has been previously stored or drawn by lwdaq routines, the first twelve pixels of the first line will already contain the image dimensions, plus the analysis boundaries, all encoded as two-byte big-endian integers. Because the routine already knows for sure what the image dimensions are, it over-writes dimensions in the first row. But it does not over-write the analysis boundaries. These may be correct or incorrect. You can pass this routine's result to lwdaq_image_create, and have the image-creating routine check the first twelve bytes for valid analysis bounds, or ignore these bounds and use newly-specified bounds.</p>

<p>To assemble the 8-bit gray-scale image, the routine uses the lwdaq scratch image. If the routine were to allocate and dispose of an image, the printing activity of the disposal when -track_ptrs is set to 1 would alter the TCL return string.</p>
}
function lwdaq_photo_contents(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	photo_name:short_string='';
	ip:image_ptr_type;
	vp,ph:pointer=nil;	
	ihp:image_header_ptr_type=nil;
	char_index:integer;
	pib:Tk_PhotoImageBlock;
	i,j,r:integer=0;
	pp:^intensity_pixel_type;
	
begin
	error_string:='';
	lwdaq_photo_contents:=Tcl_Error;
	
	if (argc<2) then begin
			Tcl_SetReturnShortString(interp,
				'Wrong number of arguments, must be "lwdaq_photo_contents photo".');
		exit;
	end;
		
	photo_name:=Tcl_ObjShortString(argv[1]);
	ph:=Tk_FindPhoto(interp,photo_name);
	if ph=nil then begin
		Tcl_SetReturnShortString(interp,'Photo "'+photo_name+'" does not exist.');
		exit;
	end;
	r:=Tk_PhotoGetImage(ph,@pib);
	with pib do begin
		dispose_named_images(scratch_image_name);
		ip:=new_image(height,width);
		ip^.name:=scratch_image_name;
		pp:=pointer(pixelptr);
		for j:=0 to height-1 do begin
			for i:=0 to width-1 do begin
				ip^.intensity[j,i]:=pp^;
				pp:=pointer(cardinal(pp)+pixelSize);
			end;
		end;
	end;
	with ip^ do begin
		ihp:=pointer(@intensity);
		ihp^.i_max:=big_endian_from_local_shortint(i_size-1);
		ihp^.j_max:=big_endian_from_local_shortint(j_size-1);
	end;
	
	if error_string='' then 
		Tcl_SetReturnByteArray(interp,@ip^.intensity,sizeof(ip^.intensity))
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_photo_contents:=Tcl_OK;
end;

{
<p>lwdaq_image_characteristics returns features of the image: the left, top, right, and bottom edges of the analysis boundries, the average, standard deviation, maximum, and minimum values of intensity, and the height and width of the image.</p>
}
function lwdaq_image_characteristics(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	image_name,result:short_string='';
	ip:image_ptr_type;
	vp:pointer;	

begin
	error_string:='';
	lwdaq_image_characteristics:=Tcl_Error;
	
	if (argc<2) then begin
			Tcl_SetReturnShortString(interp,
				'Wrong number of arguments, must be "lwdaq_image_characteristics image".');
			exit;
	end;
		
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	with ip^.analysis_bounds do
		writestr(result,left:1,' ',top:1,' ',right:1,' ',bottom:1,' ',
			image_average(ip):3:1,' ',image_amplitude(ip):3:1,' ',
			image_maximum(ip):3:1,' ',image_minimum(ip):3:1,' ',
			ip^.j_size:1,' ',ip^.i_size:1);

	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_characteristics:=Tcl_OK;
end;

{
<p>lwdaq_image_histogram returns a histogram of image intensity within the analysis bounds of an image. The histogram takes the form of an x-y graph in a space-delimited string, with the x-coordinate representing intensity, and the y-coordinate representing frequency. Suppose we apply the histogram routine to a 20&times;20 image and we assume that the pixel intensities range from 0 to 3. The string "0 100 1 210 2 40 3 50" confirms that there are 400 pixels in the image, 100 with intensity 0, 210 with intensity 1, and so on.</p>
}
function lwdaq_image_histogram(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	image_name:short_string='';
	lsp:long_string_ptr;
	hp:xy_graph_ptr_type;
	ip:image_ptr_type;
	vp:pointer;	
	i:integer;

begin
	error_string:='';
	lwdaq_image_histogram:=Tcl_Error;
	
	if (argc<2) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_image_histogram image".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	hp:=image_histogram(ip);
	lsp:=new_long_string;
	lsp^:='';
	for i:=0 to hp^.num_points-1 do
		writestr(lsp^,lsp^,hp^[i].x:1:0,' ',hp^[i].y:1:0,' ');
	dispose_xy_graph(hp);
	lwdaq_long_string:=lsp^;
	dispose_long_string(lsp);
	
	if error_string='' then Tcl_SetReturnLongString(interp,lwdaq_long_string)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_histogram:=Tcl_OK;
end;

{
<p>lwdaq_image_profile returns a list of the average intensity in the analysis boundaries along the row or column directions.  The profile takes the form of series of numbers in a space-delimited decimal string. The first number of a row profile is the average intensity of pixels in the leftmost column of the analysis boundaries. The last number is the average intensity of the right-most column. The first number of a column profile is the average intensity of the topmost row in the analysis boundaries. The last number is the average intensity of the bottom row. To obtain the row profile, use option -row 1, which is the default. To obtain the column profile, use -row 0.</p>
}
function lwdaq_image_profile(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	image_name:short_string='';
	lsp:long_string_ptr;
	pp:x_graph_ptr_type;
	ip:image_ptr_type;
	vp:pointer;	
	i:integer;
	row:boolean=true;

begin
	error_string:='';
	lwdaq_image_profile:=Tcl_Error;
	
	if (argc<2) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_image_profile image".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-row') then row:=Tcl_ObjBoolean(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-row".');
			exit;
		end;
	end;

	if row then pp:=image_profile_row(ip)
	else pp:=image_profile_column(ip);
	lsp:=new_long_string;
	lsp^:='';
	for i:=0 to pp^.num_points-1 do writestr(lsp^,lsp^,pp^[i]:fsr:fsd,' ');
	dispose_x_graph(pp);
	lwdaq_long_string:=lsp^;
	dispose_long_string(lsp);
	
	if error_string='' then Tcl_SetReturnLongString(interp,lwdaq_long_string)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_profile:=Tcl_OK;
end;

{
<p>lwdaq_image_exists returns a list of images in the lwdaq image list that match the image_name pattern you pass to the routine. If you pass "*", it will return a list of all existing images. If there are no matching images, lwdaq_image_exists returns an empty string.</p>
}
function lwdaq_image_exists(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	result:short_string='';
	arg_index:integer;
	image_name:short_string='*';
	ip:image_ptr_type;
	vp:pointer;	
	verbose:boolean=false;

begin
	error_string:='';
	lwdaq_image_exists:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_image_exists image ?option value?".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);

	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-verbose') then verbose:=Tcl_ObjBoolean(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-verbose".');
			exit;
		end;
	end;

	write_image_list(result,image_name,verbose);
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_exists:=Tcl_OK;
end;

{
<p>lwdaq_image_results returns an image's results string, which may be up to short_string_length characters long.</p>
}
function lwdaq_image_results(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	image_name:short_string='';
	ip:image_ptr_type;
	vp:pointer;	

begin
	error_string:='';
	lwdaq_image_results:=Tcl_Error;
	
	if (argc<2) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_image_results image".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	if error_string='' then Tcl_SetReturnShortString(interp,ip^.results)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_image_results:=Tcl_OK;
end;

{
<p>lwdaq_image_manipulate returns the name of a new image derived from one or more images passed to lwdaq_image_manipulate. If we set the -replace option to 1, the routine replaces the original image with the new image. The command takes the name of an image in the LWDAQ image list, and the name of a manipulation to be performed upon this image. The currently-supported manipulations are as follows.</p>

<table border cellspacing=2>
<tr><th>Manipulation</th><th>Function</th></tr>
<tr><td>none</td><td>No manipulation of pixels, the new image is the old image.</td></tr>
<tr><td>copy</td><td>Copy the image into a new image.</td></tr>
<tr><td>crop</td><td>Crop the image to its analysis boundaries.</td></tr>
<tr><td>shrink_<i>n</i></td><td>Shrink the image by an integer factor <i>n</i>, where values 2, 3, and 4 are supported.</td></tr>
<tr><td>enlarge_<i>n</i></td><td>Enlarge the image by an integer factor <i>n</i>, where values 2, 3, and 4 are supported.</td></tr>
<tr><td>invert</td><td>Turn image upside-down by reversing order of pixels. Top-left becomes bottom-right.</td></tr>
<tr><td>reverse_rows</td><td>Reverse the order of the rows. The top row becomes the bottom row.</td></tr>
<tr><td>grad_i</td><td>Magnitude of the horizontal intensity derivative.</td></tr>
<tr><td>grad_i_s</td><td>Horizontal intensity derivative, signed.</td></tr>
<tr><td>grad_j</td><td>Magnitude of the vertical intensity derivative.</td></tr>
<tr><td>grad_j_s</td><td>Vertical intensity derivative, signed.</td></tr>
<tr><td>grad</td><td>Magnitude of the intensity gradient.</td></tr>
<tr><td>negate</td><td>Negate the image. Each pixel will have value max_intensity &minus; original_intensity.</td></tr>
<tr><td>smooth</td><td>Smooth with 3&times;3 box filter and add contrast.</td></tr>
<tr><td>combine</td><td>Replaces a portion of the image.</td></tr>
<tr><td>subtract</td><td>Subtract a second image from the first image.</td></tr>
<tr><td>bounds_subtract</td><td>Subtract a second image from the first within the analysis bounds.</td></tr>
<tr><td>subtract_row</td><td>Subtract the row average intensity from all pixels in each row.</td></tr>
<tr><td>rasnik</td><td>Create an artificial rasnik pattern in the image.</td></tr>
<tr><td>transfer_overlay</td><td>Transfer the overlay of a second image into the overlay of the first image.</td></tr>
<tr><td>soec</td><td>Swap odd and even columns.</td></tr>
</table>
<b>Table:</b> Manipulation Codes and their Functions. All codes create a new image, except for <i>none</i>. With -replace 1 the old image will be replaced by the new image. With -replace 0, the new image will be distinct, with a distinct name.

<p>The <i>none</i> manipulation does nothing. It does not return a new image. Instead, the <i>none</i> manipulation allows us to manipulate an existing image's analysis boundaries, result string, and overlay pixels.</p>

<p>The <i>copy</i> manipulation makes a copy of an image. By default, the name of the copy will be the name of the original, which is inconvenient. So we should use the -name option with <i>copy</i> to specify a name for the copy. As always, when we specify a name, all existing images with that name will be deleted to make way for the new image, thus assuring us that the new image is the only one with its name. With the -replace option we disturb the behavior of the <i>copy</i> manipulationg by deleting the original image and replacing it with the copy.</p>

<p>The <i>smooth</i> manipulation applies a 3&times;3 average filter to the image within the analysis boundaries. The value of pixel (i, j) in the new image will be proportional to the sum of the pixels (i-1..i+1, j-1..j+1) in the original image. One of the potential benifits of smoothing is to attenuate stochastic noise. We would like the smoothing to attenuate quantization noise in very dim images. But if we add the nine pixels in the 3&times;3 block together and dividing by nine to obtain their average, we find that our average itself suffers from quantization noise. For example, suppose eight pixels have value 100 and the ninth is 101. The average should be 100.1, but this will be rounded to 100. The smooth routine calculates the average value of the nine pixels and stores them in an array of real values. Once the array is complete, the routine tranforms the minimum to maximum range in the real-valued array into the pixel value range in the final image. If the smoothed values ranged from 98 to 102 and the final image pixels can be 0 to 255, the smooth routine transforms 98 to 0 and 102 to 255. Thus we obtain the best possible contrast in the final image, and we do the best we can to remove quantization noise.</p>

<p>The <i>combine</i> manipulation allows you to write over the data in an image, starting with the <i>offset</i>'th pixel. You specify <i>offset</i> after the data. The manipulation copies the entire contents of an <i>m</i>-byte binary block into the image, starting at pixel <i>offset</i>, and ending at pixel <i>offset+m-1</i>. If the copy goes past the end of the image array, the manipulation aborts without doing anything, and returns an error.</p>

<p>The <i>crop</i> manipulation extracts the pixels inside the analysis boundaries of the original image, and creates a new image containing only these pixels. The dimensions of the new image will be those of the original analysis boundaries, but with one extra row at the top to accommodate an image header when we save to disk. The new analysis boundaries will include the entire image except for row zero.</p>

<p>The <i>subtract</i> manipulation requires you to name a second image, which will be subtracted from the first to create a third image. The two images must have the same dimensions. All pixels in the second images will be subtracted from the first image. The third image, being the difference, will be the same dimensions as the first two.</p>

<p>The <i>bounds_subtract</i> manipulation is like <i>subtract</i>, but applies the subtraction only within the
analysis bounds of the first image. Elsewhere, the difference image is equal to the first image.</p>

<p>The <i>subtract_row</i> manipulation does not require a second images. It is a type of filter function, whereby we subtract the average intensity of each row from the pixels in the row. We thus remove a slope of intensity from top to bottom in the image.</p>

<p>The <i>grad</i> manipulations either return an absolute intensity gradient or a signed intensity gradient. We calculate the horizontal gradient at pixel (i,j) by subtracting the intensity of pixel (i-1,j) from that of pixel (i+1,j). The vertical gradient is (i,j+1) minus (i,j-1). When we return the magnitude of the gradient, the intensity of the gradient image is simply the absolute value of the gradient. When we return the signed gradient, we offset the gradient image intensity by mid_intensity, which is 128 for eight-bit gray scale images. Thus an intensity of 128 means zero gradient, and an intensity of 138 means +10. When the gradient exceeds 127 or -128, we clip its value to 255 and 0 respectively. For more details, see the image_filter and subsequent routine in <a href="../../Software/Sources/image_manip.pas">image_manip.pas</a>.</p>

<p>The <i>rasnik</i> manipulation draws a rasnik pattern in the image. We specify the rasnik pattern with a string of seven numbers: origin.x, origin.y, pattern_x_width, pattern_y_width, rotation, sharpness, and noise amplitude. The origin is the image coordinates of the top-left corner of one of the squares in the chessboard. Units are pixels, not mircons. The x and y width of the squares are in the near-horizontal and near-vertical direction respectively. Units are pixels again. The rotation is counter-clockwise in milliradians of the pattern with respect to the sensor. With sharpness 1, the pattern has sinusoidal intensity variation from black to white. With sharpness less than 1, the amplitude of the sinusoidal variation decreases in proportion. With sharpness greater than one, the sinusoidal amplitude increases in proportion, but is clipped to black and white intensity, so that we obtain a sharply-defined chessboard. With sharpness 0.01 we obtain an image with alternating circles of intensity one count above and below the middle intensity, set in a field of middle intensity, as shown <a href="../../Devices/Rasnik/Sharpness_001.jpg">here</a>. When we differentiate such an image in the horizontal direction, we get <a href="../../Devices/Rasnik/Sharpness_001_grad_i.gif">this</a>, which defeats our frequency-based rasnik analysis. We can add noise to our simulated image with the noise amplitude parameter. If we set this to 1.0, we add a random number between 0.0 and 1.0 to each pixel.</p>

<p>The <i>transfer_overlay</i> manipulation copies the overlay of a second image into the overlay of the first. This manipulation is the only one operating upon the image ovelays. Each image has an overlay area whose colors we draw on top of the image when we display the image on the screen. Thus we can use the overlay to mark features in the image without corrupting the image itself. The overlay transfer scales the original overlay so that it fits into the rectangle of the new image. We can shrink a large image by a factor of four, analyze the quarter-sized image, record the results of analysis in the overlay, and transfer the overlay back into the original full-sized image. The transfer will make sure that the markings are aligned correctly with the features in the original image.</p>

<p><pre>lwdaq_image_manipulate image_name rasnik "0 0 20 30 2 10" -replace 1</pre></p>

<p>In the above example, the the existing image would be replaced by a new image containing a rasnik pattern with origin at the top-left corner of the top-left pixel in the image, each square 20 pixels wide and 30 pixels high, rotated by 2 mrad anti-clockwise, with sharp edges.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-name</td><td>The name of the new image will be $value.</td></tr>
<tr><td>-results</td><td>Set the new image results string to $value.</td></tr>
<tr><td>-replace</td><td>If $value is 1, delete the original image and replace it with the new one. 0 by default.</td></tr>
<tr><td>-clear</td><td>if $value is 1, clear overlay of final image, 0 by default.</td></tr>
<tr><td>-fill</td><td>if $value is 1, fill overlay of final image with white, 0 by default.</td></tr>
<tr><td>-paint</td><td>paint the overlay within the analysis bounds with eight-bit color $value, 0 by default.</td></tr>
<tr><td>-bottom</td><td>Set the bottom of the analysis bounds to $value.</td></tr>
<tr><td>-top</td><td>Set the top of the analysis bounds to $value.</td></tr>
<tr><td>-left</td><td>Set the left of the analysis bounds to $value.</td></tr>
<tr><td>-right</td><td>Set the rigth of the analysis bounds to $value.</td></tr>
</table>

<p>With -name you specify the name of the new image created by the manipulation, or the existing image if there is no new image created by the manipulation. Any pre-existing images with this name will be destroyed before the name change occurs.</p>

<p>With -replace 0, the manipulation creates a new image and returns its name. With -replace 1, the manipulation over-writes data in the old image and returns the old image name.</p>

<p>The -paint option instructs lwdaq_image_manipulate to paint the entire area within the analysis bounds with the color given by $value. This value should be a number between 0 and 255. The value 0 is for transparant. Other than the 0-value, the number will be treated like an eight-bit RGB code, with the top three bits for red, the middle three for green, and the bottom three for blue. Thus $E0 (hex E0) is red, $1C is green, and $03 is blue. Note that paint does not convert $value into one of LWDAQ's standard graph-plotting colors, as defined in the overlay_color_from_integer routine of images.pas, and used in <a href="#lwdaq_graph">lwdaq_graph</a>.</p>

<p>In addition to the pixel manipulations, we also have options to change other secondary properties of the image. The table above shows the available manipulation options, each of which is followed by a value in the command line, in the format ?option value?.</p>

<p>When you specify the analysis bounds, a value of &minus;1 is the code for "do nothing". The boundary will remain as it was. This use of the &minus;1 code contasts with that of lwdaq_image_create, where &minus;1 directs lwdaq_image_create to move the boundary to the edge of the image.</p>
}
function lwdaq_image_manipulate(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	image_name,second_image_name:short_string='';
	name,result:short_string='';
	manipulation:short_string='none';
	results:short_string=null_code;
	left,right,top,bottom,paint:integer=-1;
	replace:boolean=false;
	clear,fill:boolean=false;
	ip,nip,ip_2:image_ptr_type;
	data_obj,data_ptr:pointer=nil;
	vp:pointer;	
	data_size,offset:integer=-1;

begin
	error_string:='';
	lwdaq_image_manipulate:=Tcl_Error;
{
	This routine needs at least three arguments: the routine name, the image name, and
	the manipulation name.
}
	if (argc<3) then begin
		Tcl_SetReturnShortString(interp,'Wrong number of arguments, must be '
			+'"lwdaq_image_manipulate image_name manipulation ?option value?".');
		exit;
	end;
{
	Get the image name and manipulation name.
}
	arg_index:=1;
	image_name:=Tcl_ObjShortString(argv[arg_index]);
	inc(arg_index);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	manipulation:=Tcl_ObjShortString(argv[arg_index]);
	inc(arg_index);
{
	Perform the specified manipulation.
}
	if manipulation='copy' then nip:=image_copy(ip)
	else if manipulation='grad_i' then nip:=image_grad_i(ip)
	else if manipulation='grad_i_s' then nip:=image_filter(ip,-1,0,1,0,1,0,1)
	else if manipulation='grad_j' then nip:=image_grad_j(ip)
	else if manipulation='grad_j_s' then nip:=image_filter(ip,0,1,0,-1,0,1,1)
	else if manipulation='grad' then nip:=image_grad(ip)
	else if manipulation='smooth' then nip:=image_filter(ip,1,1,1,1,1,1,0)
	else if manipulation='shrink_2' then nip:=image_shrink(ip,2)
	else if manipulation='enlarge_2' then nip:=image_enlarge(ip,2)
	else if manipulation='shrink_3' then nip:=image_shrink(ip,3)
	else if manipulation='enlarge_3' then nip:=image_enlarge(ip,3)
	else if manipulation='shrink_4' then nip:=image_shrink(ip,4)
	else if manipulation='enlarge_4' then nip:=image_enlarge(ip,4)
	else if manipulation='negate' then nip:=image_negate(ip)
	else if manipulation='invert' then nip:=image_invert(ip)
	else if manipulation='crop' then nip:=image_crop(ip)
	else if manipulation='reverse_rows' then nip:=image_reverse_rows(ip)
	else if manipulation='soec' then nip:=image_soec(ip)
	else if manipulation='subtract_row' then nip:=image_subtract_row_average(ip)
	else if (manipulation='subtract') or (manipulation='bounds_subtract') 
			or (manipulation='transfer_overlay') then begin
		if argc<arg_index+1 then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, must be '
			+'"lwdaq_image_manipulate image_name '+manipulation
			+' second_image ?option value?".');
			exit;
		end;
		second_image_name:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		ip_2:=image_ptr_from_name(second_image_name);
		if not valid_image_ptr(ip_2) then begin
			Tcl_SetReturnShortString(interp,'Image "'+second_image_name+'" does not exist.');
			exit;
		end;
		if manipulation='subtract' then nip:=image_subtract(ip,ip_2)
		else if manipulation='bounds_subtract' then nip:=image_bounds_subtract(ip,ip_2)
		else begin
			image_transfer_overlay(ip,ip_2);
			nip:=ip;
		end;
	end else if manipulation='none' then begin 
		nip:=ip;
	end else if manipulation='rasnik' then begin
		nip:=ip;
		if argc<arg_index+1 then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, must be '
			+'"lwdaq_image_manipulate image_name rasnik commands ?option value?".');
			exit;
		end;
		rasnik_simulated_image(nip,Tcl_ObjShortString(argv[arg_index]));
		inc(arg_index);
	end else begin
		Tcl_SetReturnShortString(interp,'Bad manipulation "'+manipulation
			+'", must be one of "copy crop subtract negate '
			+'subtract_bounds subtract_row '
			+'invert reverse_rows soec grad_i grad_i_s grad_j '
			+ 'grad_j_s grad smooth rasnik shrink_2 enlarge_2 '
			+ 'shrink_3 enlarge_3 shrink_4 enlarge_4 none".');
		exit;
	end;
{
	Scan the command arguments for option specifiers and record their values.
	If we encounter an invalid argument beginning with a hyphen, we report
	an error.
}
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-name') then name:=Tcl_ObjShortString(vp)
		else if (option='-results') then results:=Tcl_ObjShortString(vp)
		else if (option='-replace') then replace:=Tcl_ObjBoolean(vp)
		else if (option='-bottom') then bottom:=Tcl_ObjInteger(vp)
		else if (option='-top') then top:=Tcl_ObjInteger(vp)
		else if (option='-left') then left:=Tcl_ObjInteger(vp)
		else if (option='-right') then right:=Tcl_ObjInteger(vp)
		else if (option='-clear') then clear:=Tcl_ObjBoolean(vp)
		else if (option='-fill') then fill:=Tcl_ObjBoolean(vp)
		else if (option='-paint') then paint:=Tcl_ObjInteger(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-name -results -replace -bottom -top -left -right -clear -paint".');
			exit;
		end;
	end;
{
	Perform the option modifications to the new image.
}
	if replace and (nip<>ip) then begin
		nip^.name:=ip^.name;
		dispose_image(ip);
	end;
	if results<>null_code then nip^.results:=results;
	if left<>-1 then begin
		if (left>0) and (left<nip^.i_size) then
			nip^.analysis_bounds.left:=left
		else
			nip^.analysis_bounds.left:=0;
	end;
	if right<>-1 then begin
		if (right>left) and (right<nip^.i_size) then
			nip^.analysis_bounds.right:=right
		else 
			nip^.analysis_bounds.right:=nip^.i_size-1;
	end;
	if top<>-1 then begin
		if (top>1) and (top<nip^.j_size) then
			nip^.analysis_bounds.top:=top
		else
			nip^.analysis_bounds.top:=1;
	end;
	if bottom<>-1 then begin
		if (bottom>top) and (bottom<nip^.j_size) then
			nip^.analysis_bounds.bottom:=bottom
		else
			nip^.analysis_bounds.bottom:=nip^.j_size-1;
	end;
	if name<>'' then begin
		while valid_image_name(name) do
			dispose_image(image_ptr_from_name(name));
		nip^.name:=name;
	end;
	if clear then clear_overlay(nip);
	if fill then fill_overlay(nip);
	if paint>=0 then paint_overlay_bounds(nip,paint);
{
	If we encountered no errors, return the name of the new image.
	Otherwise return the error message and dispose of any new image
	we may have created.
}
	if error_string='' then Tcl_SetReturnShortString(interp,nip^.name)
	else begin
		Tcl_SetReturnShortString(interp,error_string);
		if nip<>ip then dispose_image(nip);
	end;
	lwdaq_image_manipulate:=Tcl_OK;
end;

{
<p>lwdaq_data_manipulate operates upon the data in an image, and we intend it for use with instruments that store one-dimensional arrays of data in an image's intensity array. Our convention, when using the intensity array in this way, is to start storing data in the first column of the second row. This leaves the first row free for header information when we store the image to disk. We refer to the block of memory starting with the first byte of the second row, and ending with the last byte of the last row, as the <i>data space</i>. We specify bytes in the data space with their <i>byte address</i>, which is zero at the first byte in the data space. The routine returns a byte array in the case of the <i>read</i> manipulation, or an empty string otherwise. In the event of an error, it returns an error description. The <i>write</i>, <i>shift</i>, and <i>clear</i> manipulations affect the data in the image.</p>

<table border cellspacing=2>
<tr><th>Manipulation</th><th>Function</th></tr>
<tr><td>write</td><td>Writes a block of data into the data space.</td></tr>
<tr><td>read</td><td>Reads a block of data from the data space.</td></tr>
<tr><td>shift</td><td>Shifts data towards start of data space.</td></tr>
<tr><td>clear</td><td>Clears the data.</td></tr>
<tr><td>none</td><td>No action.</td></tr>
</table>

<p>The <i>write</i> function requires two parameters: the data you wish to write to the data space and the byte address at which you want the first byte of your data to be written. The following command writes the contents of <i>data</i> to the data space of the image named <i>image_name</i> starting at the first byte in the data space (which is the first pixel in the second row).</p>

<pre>lwdaq_data_manipulate image_name write 0 $data</pre>

<p>The <i>read</i> function requires two parameters: the number of bytes you wish to read from the data space and the byte address at which you want to start reading. The following command reads 10000 bytes starting at byte address 100, and returns them as a byte array. If the image has 100 pixels per row, the first byte the routine reads will be the first pixel in the third row of the image.</p>

<pre>lwdaq_data_manipulate image_name read 100 10000</pre>

<p>The following commands read 200 bytes from the image, starting with the 50'th byte, and transforms them into a list of signed integers, on the assumption that the 200 bytes represent 100 consecutive, two-byte signed binary values with the most significant byte first (big-endian byte ordering).</p>

<pre>lwdaq_data_manipulate image_name read 50 200
</pre>
<p>The <i>shift</i> function requires one parameter: the number of bytes to the left by which you want the data to be shifted. Shifting to the left is in the direction of the start of the data space. If you specify a negative shift, the routine shifts the data to the right, in the direction of the end of the data space.</p>

<p>The <i>clear</i> function takes no parameters. It clears all the byte in the data space to zero.</p>
}
function lwdaq_data_manipulate(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	option:short_string;
	arg_index:integer;
	image_name:short_string='';
	manipulation:short_string='none';
	ip,nip:image_ptr_type;
	data_obj,data_ptr:pointer=nil;
	vp:pointer;	
	data_size,byte_address:integer=-1;
	shift:integer=0;
	
begin
	error_string:='';
	lwdaq_data_manipulate:=Tcl_Error;
{
	This routine needs at least three arguments: the routine name, the image name, and
	the manipulation name.
}
	if (argc<3) then begin
		Tcl_SetReturnShortString(interp,'Wrong number of arguments, must be '
			+'"lwdaq_data_manipulate image_name manipulation ?parameters?".');
		exit;
	end;
{
	Get the image name and manipulation name.
}
	arg_index:=1;
	image_name:=Tcl_ObjShortString(argv[arg_index]);
	inc(arg_index);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	manipulation:=Tcl_ObjShortString(argv[arg_index]);
	inc(arg_index);
{
	Perform the specified manipulation.
}
	if manipulation='write' then begin
		if argc<arg_index+2 then begin
			Tcl_SetReturnShortString(interp,'Specify byte_address and data.');
			exit;
		end;
		byte_address:=Tcl_ObjInteger(argv[arg_index]);
		inc(arg_index);
		if byte_address<0 then begin
			Tcl_SetReturnShortString(interp,'Start address less than zero.');
			exit;
		end;
		data_obj:=argv[arg_index];
		inc(arg_index);
		data_ptr:=Tcl_GetByteArrayFromObj(data_obj,data_size);
		if data_size<0 then begin
			Tcl_SetReturnShortString(interp,'Data size less than zero.');
			exit;
		end;
		if byte_address+data_size>sizeof(ip^.intensity)-ip^.i_size then begin
			Tcl_SetReturnShortString(interp,'Data extends past end of image "'
				+image_name+'".');
			exit;
		end;
		block_move(data_ptr,
			pointer(integer(@ip^.intensity[1,0])+byte_address),
			data_size);
		Tcl_SetReturnShortString(interp,'');
	end else if manipulation='read' then begin
		if argc<arg_index+2 then begin
			Tcl_SetReturnShortString(interp,'Specify data size and byte address.');
			exit;
		end;
		byte_address:=Tcl_ObjInteger(argv[arg_index]);
		inc(arg_index);
		if byte_address<0 then begin
			Tcl_SetReturnShortString(interp,'Start address less than zero.');
			exit;
		end;
		data_size:=Tcl_ObjInteger(argv[arg_index]);
		inc(arg_index);
		if data_size<0 then begin
			Tcl_SetReturnShortString(interp,'Requested data size less than zero.');
			exit;
		end;
		if byte_address+data_size>sizeof(ip^.intensity)-ip^.i_size then begin
			Tcl_SetReturnShortString(interp,'Requested data extends past end of image "'
				+image_name+'".');
			exit;
		end;
		Tcl_SetReturnByteArray(interp,
			pointer(integer(@ip^.intensity[1,0])+byte_address),
			data_size);
	end else if manipulation='shift' then begin
		if argc<arg_index+1 then begin
			Tcl_SetReturnShortString(interp,'Specify shift in bytes, positive left.');
			exit;
		end;
		shift:=Tcl_ObjInteger(argv[arg_index]);
		nip:=new_image(ip^.j_size,ip^.i_size);
		if nip=nil then begin
			Tcl_SetReturnShortString(interp,'Failed to allocate memory for new image.');
			exit;
		end;
		if shift>0 then begin
			block_move(pointer(integer(@ip^.intensity[1,0])+shift),
				@nip^.intensity[1,0],
				sizeof(ip^.intensity)-ip^.i_size-shift);
		end else begin
			block_move(@ip^.intensity[1,0],
				pointer(integer(@nip^.intensity[1,0])+shift),
				sizeof(ip^.intensity)-ip^.i_size-shift);
		end;
		block_move(@nip^.intensity[1,0],@ip^.intensity[1,0],sizeof(ip^.intensity)-ip^.i_size);
		dispose_image(nip);
		Tcl_SetReturnShortString(interp,'');
	end else if manipulation='clear' then begin
		with ip^ do block_clear(@intensity[1,0],sizeof(ip^.intensity)-ip^.i_size);
		Tcl_SetReturnShortString(interp,'');
	end else if manipulation='none' then begin 
		{no action}
	end else begin
		Tcl_SetReturnShortString(interp,'Bad manipulation "'+manipulation
			+'", must be one of "read write shift clear none".');
		exit;
	end;
{
	If we have an error, return error string and report okay to interpreter.
}
	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_data_manipulate:=Tcl_OK;
end;


{
<p>lwdaq_rasnik analyzes rasnik images. Specify the image with -image_name as usual. The routine clears the image overlay for its own use. The routine takes the following options, each of which you specify by giving the option name followed by its value, ?option value?. See the <a href="">Rasnik Instrument</a> for a description of the options.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-reference_code</td><td>Selects the analysis reference point.</td></tr>
<tr><td>-reference_x_um</td><td>x-coordinate of reference point when -reference_code=3.</td></tr>
<tr><td>-reference_y_um</td><td>y-coordinate of reference point when -reference_code=3.</td></tr>
<tr><td>-orientation_code</td><td>Selects the analysis orientation code.</td></tr>
<tr><td>-square_size_um</td><td>Tells the analysis the mask square size (assumed square).</td></tr>
<tr><td>-pixel_size_um</td><td>Tells the analysis the pixel size (assumed square)</td></tr>
<tr><td>-show_timinig</td><td>If 1, print timing report to gui text window.</td></tr>
<tr><td>-show_fitting</td><td>If <> 0, show fitting stages with delay $value ms.</td></tr>
<tr><td>-pattern_only</td><td>If 1, return pattern description not rasnik measurement.</td></tr>
</table>

<p>See the <a href="http://alignment.hep.brandeis.edu/Electronics/LWDAQ/Manual.html#Rasnik">Rasnik Instrument</a> Manual for more information about the option values, in particular the reference and orientation code meanings.</p>

<p>With the -pattern_only option set, the routine returns a description of the chessboard pattern it finds in the image. The result string contains seven numbers: origin.x, origin.y, pattern_x_width, pattern_y_width, rotation, error, and extent. The origin values are the image coordinates of the top-left corner of one of the squares in the chessboard. Units are pixels, not mircons. The next two numbers are the  width of the squares in the near-horizontal direction and their width in the near-vertical direction. Units are again pixels. The rotation is counter-clockwise in milliradians. The error is an estimate of the fitting accuracy in pixel widths. The extent is the number of squares from the image center over which the pattern extends.</p> 
}
function lwdaq_rasnik(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	rnw=8;rnd=3;
		
var 
	ip,iip,jip:image_ptr_type=nil;
	image_name,result:short_string='';
	pp:rasnik_pattern_ptr_type=nil;
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	show_fitting,show_timing,pattern_only:boolean=false;
	square_size_um:real=120;
	pixel_size_um:real=10;
	reference_code,orientation_code:integer=0;
	rp:rasnik_ptr_type;
	reference_x_um,reference_y_um:real=0;
		
begin
	error_string:='';
	lwdaq_rasnik:=Tcl_Error;		

	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_rasnik image ?option value?".');
		exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-show_fitting') then show_fitting:=Tcl_ObjBoolean(vp)
		else if (option='-show_timing') then show_timing:=Tcl_ObjBoolean(vp)
		else if (option='-pattern_only') then pattern_only:=Tcl_ObjBoolean(vp)
		else if (option='-reference_code') then reference_code:=Tcl_ObjInteger(vp)
		else if (option='-orientation_code') then orientation_code:=Tcl_ObjInteger(vp)
		else if (option='-square_size_um') then square_size_um:=Tcl_ObjReal(vp)
		else if (option='-pixel_size_um') then pixel_size_um:=Tcl_ObjReal(vp)
		else if (option='-reference_x_um') then reference_x_um:=Tcl_ObjReal(vp)
		else if (option='-reference_y_um') then reference_y_um:=Tcl_ObjReal(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-reference_code -orientation_code'
				+' -square_size_um -pixel_size_um -reference_x_um -reference_y_um'
				+' -show_fitting".');
			exit;
		end;
	end;

	start_timer('generating image derivatives',CurrentRoutineName);
	iip:=image_grad_i(ip);
	jip:=image_grad_j(ip);
	mark_time('clearing overlay',CurrentRoutineName);
	clear_overlay(ip);
	mark_time('starting rasnik_find_pattern',CurrentRoutineName);
	pp:=rasnik_find_pattern(iip,jip,show_fitting);
	if show_fitting then begin
		rasnik_display_pattern(ip,pp,false);
		gui_draw(ip^.name);
		gui_wait('Approximate pattern from slices.');
	end;
	mark_time('starting rasnik_refine_pattern',CurrentRoutineName);
	rasnik_refine_pattern(pp,iip,jip,show_fitting);
	mark_time('starting rasnik_adjust_pattern_parity',CurrentRoutineName);
	rasnik_adjust_pattern_parity(ip,pp);
	if pattern_only then begin
		result:=string_from_rasnik_pattern(pp);
		mark_time('starting rasnik_display_pattern',CurrentRoutineName);
		rasnik_display_pattern(ip,pp,show_fitting);
	end else begin
		mark_time('starting rasnik_identify_pattern_squares',CurrentRoutineName);
		rasnik_identify_pattern_squares(ip,pp);
		mark_time('starting rasnik_identify_code_squares',CurrentRoutineName);
		rasnik_identify_code_squares(ip,pp);
		mark_time('starting rasnik_analyze_code',CurrentRoutineName);
		rasnik_analyze_code(pp,orientation_code);
		mark_time('starting rasnik_from_pattern',CurrentRoutineName);
		rp:=rasnik_from_pattern(ip,pp,reference_code,reference_x_um,reference_y_um,
			square_size_um,pixel_size_um);
		mark_time('starting rasnik_display_pattern',CurrentRoutineName);
		rasnik_display_pattern(ip,pp,show_fitting);
		rasnik_display_reference_point(ip,reference_code,reference_x_um,reference_y_um,
			pixel_size_um);
		writestr(result,string_from_rasnik(rp));
		mark_time('starting to dispose pointers',CurrentRoutineName);
		dispose_rasnik(rp);
	end;

	dispose_rasnik_pattern(pp);
	dispose_image(iip);
	dispose_image(jip);
	mark_time('done',CurrentRoutineName);
	if show_timing then report_time_marks;
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_rasnik:=Tcl_OK;
end;

{
<p>lwdaq_rasnik_shift takes in a rasnik result string and shifts it to a new reference point. The routine gets the old reference point from the results string, and re-calculates the rasnik measurement using the x and y coordinates you specify with -reference_x_um and -reference_y_um.</p>
}
function lwdaq_rasnik_shift(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	rnw=8;rnd=3;
		
var 
	ref:xy_point_type;
	old_result,result:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	rasnik:rasnik_type;
	reference_x_um,reference_y_um:real=0;
	source_name:short_string='';
		
begin
	error_string:='';
	lwdaq_rasnik_shift:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_rasnik_shift old_result ?option value?".');
		exit;
	end;
	
	old_result:=Tcl_ObjShortString(argv[1]);
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-reference_x_um') then reference_x_um:=Tcl_ObjReal(vp)
		else if (option='-reference_y_um') then reference_y_um:=Tcl_ObjReal(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-reference_x_um -reference_y_um".');
			exit;
		end;
	end;
	
	source_name:=read_word(old_result);
	rasnik:=rasnik_from_string(old_result);
	ref.x:=reference_x_um;
	ref.y:=reference_y_um;
	rasnik:=rasnik_shift_reference_point(rasnik,ref);
	result:=source_name+' '+string_from_rasnik(@rasnik);
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_rasnik_shift:=Tcl_OK;
end;

{
<p>lwdaq_bcam finds spots in images. It is called by the BCAM Instrument and the Dosimeter Instrument. The routine clears the image overlay for its own use.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-num_spots</td><td>The number of spots the analysis should find.</td></tr>
<tr><td>-threshold</td><td>Criteria for finding spots, including threshold specification.</td></tr>
<tr><td>-color</td><td>Color for spot outlining in overlay, default red.</td></tr>
<tr><td>-pixel_size_um</td><td>Tells the analysis the pixel size (assumed square)</td></tr>
<tr><td>-show_timinig</td><td>If 1, print timing report to gui text window.</td></tr>
<tr><td>-show_pixels</td><td>If 1, mark pixels above threshold.</td></tr>
<tr><td>-analysis_type</td><td>Selects the centroid, ellipse, or line finder.</td></tr>
<tr><td>-sort_code</td><td>Selects the analysis type.</td></tr>
<tr><td>-return_bounds</td><td>If 1, return spot bounds only.</td></tr>
<tr><td>-return_intensity</td><td>If 1, return spot intensity only.</td></tr>
</table>

<p>The lwdaq_bcam routine makes a list of spots in the image. The -threshold string tells lwdaq_bcam how to distinguish background pixels from spot pixels. At the very least, the -threshold string must specify a threshold intensity, or a means of calculating a threshold intensity. All the spot-locating routines called by lwdaq_bcam use the <i>net intensity</i> of pixels, which is the image intensity minus the threshold intensity, with negative values clipped to zero.</p>

<p>The -threshold string must begin with an integer, <i>t</i>. After <i>t</i> there can be a non-numerical character, which we call the <i>threshold symbol</i>. If there is no threshold symbol, the routine assumes the "*" symbol has been omitted from the string. The "*" symbol tells the routine to use <i>t</i> directly as the intensity threshold. The string "20 *" means the threshold is pixel intensity 20. When combined with the "*" symbol, the threshold must be between 0 and 255 for eight-bit images.</p>

<p>The "%" symbol means that the number is a percentage. The threshold is the minimum image intensity plus a precentage of the difference between the maximum and minimum intensities. The "#" symbol means that the threshold will be the average intensity plus a percentage of the difference between the maximum and average intensities. The "$" symbol means the threshold is a certain number of counts above the average intensity.</p>

<p>Following the symbol or threshold we have two optional parameters that restrict the routine's choice of spots. The first parameter must be an integer. It specifies the required number of pixels above threshold in a spot for acceptance by the routine. Any spots with fewer than this number will be ignored. Their pixels will be marked white in the overlay.</p>

<p>The second parameter must be a real number. It specifies the maximum eccentricity of the spot, which is the maximum ratio of width to height, or height to width. Spots that have greater eccentricity will be rejected by the routine. The second parameter cannot be included without the first, but if you use 0 for the first, the routine ignores the first parameter and moves on to the second.</p>

<p>The lwdaq_bcam routine identifies all distinct sets of contiguous pixels above threshold, eliminates those that do not meet the test criteria, determines the position and total net intensity of each remaining set, sorts them in order of decreasing total net intensity, and eliminates all but the first -num_spots sets. The <i>total net intensity</i> is the sum of the net intensities of all the pixels in the set. By default, the routine returns the position of each spot in microns with respect to the top-left corner of the image. To convert from pixels to microns, the routine uses -pixel_size_um, and assumes the pixels are square. There are several ways that lwdaq_bcam can calculate the spot position from the net intensity of its pixels.</p>

<pre>spot_use_centroid=1;
spot_use_ellipse=2;
spot_use_vertical_line=3;</pre>

<p>With analysis_type=1, which is the default, the position of the spot is the weighted centroid of its net intensity. With analysis_type=2, the routine fits an ellipse to the edge of the spot. The position is the center of the ellipse. With analysis_type=3 the routine fits a straight line to the net intensity of the spot and returns the intersection of this straight line with the top of the CCD instead of <i>x</i>, and the anti-clockwise rotation of this line in milliradians instead of <i>y</i>.</p>

<p>With return_bounds=1, the routine returns as its result string only the boundaries around the spots. It chooses the same boundaries it draws in the image overlay. Each spot boundary is given as four integers: left, top, right, and bottom. The left and right integers are column numbers. The top and bottom integers are row numbers. Each spot gets four numbers, and these make up the result string, separated by spaces. With return_intensity=1, the routine returns only the total net intensity of of each spot, which is the sum of the net intensity of every pixel in the spot. The return_intensity option is over-ridden by the return_bounds option.</p>

<p>The sort_code has the following meanings, and dictates the order in which the spots are returned in the result string.</p>

<pre>
spot_decreasing_total_intensity=1;
spot_increasing_x=2;
spot_increasing_y=3;
spot_decreasing_x=4;
spot_decreasing_y=5;
spot_decreasing_max_intensity=6;
spot_decreasing_size=7;
</pre>

<p>Thus with spot_decreasing_x as the value for sort_code, the routine sorts the num_spots brightest spots in order of decreasing <i>x</i> position, which means spots on the right of the image will appear first in the result string. With spot_decreasing_total_intensity, which is the default, the spot with the highest total net intensity comes first. But with spot_decreasing_max_intensity, the spot with the highest maximum intensity comes first. With spot_decreasing_size, the spot with the largest number of pixels comes first.</p>

<p><small><b>Example:</b> We have three spots: big, medium, and small. The big one has 1000 pixels with intensity 45 counts. The medium one has 100 pixels with intensity 100 counts. The small one has 10 pixels with intensity 120 counts. We set the threshold at 40 counts. Their total net intensities are 5000, 6000, and 800 respectively. Their maximum intensities are 45, 100, and 120 respectively. With spot_decreasing_total_intensity, the second spot will come first. With spot_decreasing_max_intensity, the third spot will come first. With spot_decreasing_size, the first spot will come first.</small></p>

<p>With show_pixels=0, which is the default value, the routine draws red boxes around the spots. These boxes are of the same size as the spots, or a little bigger if the spots are small. If num_spots=1, the routine draws a cross centered on the spot instead of a box around it. When show_pxels=1, the routine marks all the pixels in each spot, so you can see the pixels that are above threshold and contiguous.</p>

<p>The color we use to mark the image with the results of analysis is given in the <i>-color</i> option. You specify the color with an integer. Color codes 0 to 15 specity a set of distinct colors, shown <a href="http://alignment.hep.brandeis.edu/Electronics/LWDAQ/HTML/Plot_Colors.jpg">here</a>.</p>

<p>See the <a href="http://alignment.hep.brandeis.edu/Electronics/LWDAQ/Manual.html#BCAM">BCAM Instrument</a> Manual for more information about the option values.</p>
}
function lwdaq_bcam(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	rnw=8;rnd=3;
		
var 
	ip,nip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index,spot_num:integer;
	vp:pointer;	
	show_timing,show_pixels,return_bounds,return_intensity:boolean=false;
	pixel_size_um:real=10;
	color:integer=0;
	num_spots,analysis_type,sort_code:integer=1;
	slp:spot_list_ptr_type;
	spot:spot_type;
	threshold:short_string='50';

		
begin
	error_string:='';
	lwdaq_bcam:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_bcam image ?option value?".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-show_timing') then show_timing:=Tcl_ObjBoolean(vp)
		else if (option='-pixel_size_um') then pixel_size_um:=Tcl_ObjReal(vp)
		else if (option='-threshold') then threshold:=Tcl_ObjShortString(vp)			
		else if (option='-num_spots') then num_spots:=Tcl_ObjInteger(vp)			
		else if (option='-analysis_type') then analysis_type:=Tcl_ObjInteger(vp)			
		else if (option='-sort_code') then sort_code:=Tcl_ObjInteger(vp)
		else if (option='-return_bounds') then return_bounds:=Tcl_ObjBoolean(vp)
		else if (option='-return_intensity') then return_intensity:=Tcl_ObjBoolean(vp)
		else if (option='-show_pixels') then show_pixels:=Tcl_ObjBoolean(vp)
		else if (option='-color') then color:=Tcl_ObjInteger(vp)			
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'-threshold -pixel_size_um -show_timing -num_spots -color'
				+'-analysis_type -sort_code -show_pixels -return_bounds -return_intensity".');
			exit;
		end;
	end;
	
	if image_name='' then begin
		Tcl_SetReturnShortString(interp,'Specify an image name with -image_name.');
		exit;
	end;
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	mark_time('finding spots',CurrentRoutineName);
	clear_overlay(ip);
	slp:=spot_list_find(ip,num_spots,threshold,pixel_size_um);
	spot_list_sort(slp,sort_code);
	mark_time('measuring positions',CurrentRoutineName);
	if slp<>nil then begin
		case analysis_type of 
			spot_use_ellipse:begin
				for spot_num:=1 to slp^.num_valid_spots do
					spot_ellipse(ip,slp^.spots[spot_num]);
				if not show_pixels then clear_overlay(ip);
				spot_list_display_ellipses(ip,slp,overlay_color_from_integer(color));
			end;
			spot_use_vertical_line:begin
				for spot_num:=1 to slp^.num_valid_spots do
					spot_vertical_line(ip,slp^.spots[spot_num]);
				if not show_pixels then clear_overlay(ip);
				spot_list_display_vertical_lines(ip,slp,overlay_color_from_integer(color));
			end;
			otherwise begin
				if not show_pixels then clear_overlay(ip);
				if num_spots>1 then 
					spot_list_display_bounds(ip,slp,overlay_color_from_integer(color));
				if num_spots=1 then 
					spot_list_display_crosses(ip,slp,overlay_color_from_integer(color));
			end;
		end;
	end;
	mark_time('done',CurrentRoutineName);
	
	if return_bounds then
		result:=bounds_string_from_spot_list(slp)
	else if return_intensity then
		result:=intensity_string_from_spot_list(slp)
	else 
		result:=string_from_spot_list(slp);
	dispose_spot_list_ptr(slp);
	if num_spots=0 then result:="";
	if show_timing then report_time_marks;
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_bcam:=Tcl_OK;
end;

{
<p>lwdaq_wps analyzes wps images. It clears the overlay for its own use. We describe the analysis in our <a href="http://www.opensourceinstruments.com/WPS/WPS1/">WPS1 Manual</a>.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-pixel_size_um</td><td>Width and height of image pixels in microns.</td></tr>
<tr><td>-reference_um</td><td>Location of reference line in microns below top edge of top row.</td></tr>
<tr><td>-show_timinig</td><td>If 1, print timing report to gui text window, default zero.</td></tr>
<tr><td>-show_edges</td><td>If 1, show edge pixesls in image, defalut zero</td></tr>
<tr><td>-num_wires</td><td>The number of wires you want the routine to find.</td></tr>
<tr><td>-pre_smooth</td><td>Smooth the image before you take the derivative.</td></tr>
<tr><td>-merge</td><td>Merge aligned edge clusters.</td></tr>
<tr><td>-threshold</td><td>Criteria for finding spots, including threshold specification.</td></tr>
pixels.</td></tr>
</table>

<p>The -threshold string is used in the same way as in <a href="#lwdaq_bcam">lwdaq_bcam</a>. It can contain an intensity threshold or it can define a means to calculate the threshold. The string can also specify the minimum number of pixels a spot must contain, and its maximum eccentricity. Spots that do not meet these criteria will be marked as invalid. In this case, note that the threshold intensity will be applied to the horizontal gradient of the wire image, not the image itself.</p>

<p>With -pre_smooth set to 1, the routine smooths the original image with a box filter before it applies the gradient and threshold. We use -pre_smooth when noise is obscuring the larger edge features in a wire image.</p>

<p>With -merge set to 1, the routine checks for edge pixel clusters that are closely aligned, and merges these together. We use -merge when image contrast is so poor that the edge pixels along one side of a wire image can break into two or more separate clusters.</p>

<p>The wire positions are given with respect to a horizontal reference line drawing <i>reference_um</i> microns down from the top edge of the top image row. With <i>show_edges</i> equal to zero (the default value), the routine plots the image's horizontal intensity profile in green and the derivative profile in yellow. But when you set <i>show_edges</i> to 1, the routine no longer plots these two graphs, but instead displays the spots it finds in the derivative image, overlayed upon the original image. The edges of a wire will be covered with colored pixels. White pixels are ones that were part of spots that did not satisfy the -threshold critera.</p>
}
function lwdaq_wps(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	rnw=8;rnd=3;
	spots_per_wire=2;
		
var 
	ip,iip,sip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index:integer;
	reference_um:real=0;
	spot_num,num_spots:integer;
	vp:pointer;	
	show_timing,show_edges,pre_smooth,merge:boolean=false;
	pixel_size_um:real=10;
	num_wires,i,j:integer=1;
	slp:spot_list_ptr_type;
	pp:x_graph_ptr_type;
	saved_bounds:ij_rectangle_type;
	ref_line:ij_line_type;
	threshold:short_string='50';
		
begin
	error_string:='';
	lwdaq_wps:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_wps image ?option value?".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-show_timing') then show_timing:=Tcl_ObjBoolean(vp)
		else if (option='-show_edges') then show_edges:=Tcl_ObjBoolean(vp)
		else if (option='-pixel_size_um') then pixel_size_um:=Tcl_ObjReal(vp)
		else if (option='-reference_um') then reference_um:=Tcl_ObjReal(vp)
		else if (option='-num_wires') then num_wires:=Tcl_ObjInteger(vp)
		else if (option='-pre_smooth') then pre_smooth:=Tcl_ObjBoolean(vp)
		else if (option='-merge') then merge:=Tcl_ObjBoolean(vp)
		else if (option='-threshold') then threshold:=Tcl_ObjShortString(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'-pixel_size_um -show_timing -num_wires '
				+'-threshold -show_edges -pre_smooth".');
			exit;
		end;
	end;
	
	if image_name='' then begin
		Tcl_SetReturnShortString(interp,'Specify an image name with -image_name.');
		exit;
	end;
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
{
	Generate the derivative image and find spots above threshold in this new
	image.
}
	start_timer('generating derivative image',CurrentRoutineName);
	if pre_smooth then begin
		sip:=image_filter(ip,1,1,1,1,1,1,0);
		iip:=image_grad_i(sip);
		dispose_image(sip);
	end else begin
		iip:=image_grad_i(ip);
	end;
	mark_time('finding spots',CurrentRoutineName);
	num_spots:=spots_per_wire*num_wires;
	slp:=spot_list_find(iip,num_spots,threshold,pixel_size_um);
{
	Merge similar spots if requested.
}
	if merge then begin
		mark_time('merging edge clusters',CurrentRoutineName);
		spot_list_merge(iip,slp,"vertical");
	end;
{
	Sort the spots from left to right.
}
	spot_list_sort(slp,spot_increasing_x);
{
	Fit lines to the spots.
}
	mark_time('calculating vertical lines',CurrentRoutineName);
	for spot_num:=1 to num_spots do
		if slp<>nil then spot_vertical_line(iip,slp^.spots[spot_num]);
{
	Display graphical results of analysis.
}
	if show_edges then begin
		mark_time('displaying edges',CurrentRoutineName);
		for j:=ip^.analysis_bounds.top to ip^.analysis_bounds.bottom do
			for i:=ip^.analysis_bounds.left to ip^.analysis_bounds.right do 
				ip^.overlay[j,i]:=iip^.overlay[j,i];
	end else begin
		mark_time('displaying derivative profile',CurrentRoutineName);
		saved_bounds:=ip^.analysis_bounds;
		pp:=image_profile_row(iip);
		ip^.analysis_bounds:=iip^.analysis_bounds;
		display_profile_row(ip,pp,yellow_color);
		ip^.analysis_bounds:=saved_bounds;
		dispose_x_graph(pp);
		mark_time('displaying intensity profile',CurrentRoutineName);
		pp:=image_profile_row(ip);
		display_profile_row(ip,pp,green_color);
		ip^.analysis_bounds:=saved_bounds;
		dispose_x_graph(pp);
	end;
	mark_time('displaying lines',CurrentRoutineName);
	spot_list_display_vertical_lines(ip,slp,red_color);
	ref_line.a.i:=ip^.analysis_bounds.left;
	ref_line.a.j:=round(reference_um/pixel_size_um);
	ref_line.b.i:=ip^.analysis_bounds.right;
	ref_line.b.j:=round(reference_um/pixel_size_um);
	display_ccd_line(ip,ref_line,blue_color);	
{
	Shift x-position of lines so that each line position is given
	as the intersection of the line and a horizontal line reference_um
	microns down from the top row in the image.
}
	for spot_num:=1 to num_spots do 
		with slp^.spots[spot_num] do
			if valid then
				x:=x+reference_um*y/mrad_per_rad;
{
	Dispose of the spot list and return the numerical results.
}
	mark_time('done',CurrentRoutineName);
	result:=string_from_spot_list(slp);
	dispose_spot_list_ptr(slp);
	dispose_image(iip);
	if num_spots=0 then result:="";
	if show_timing then report_time_marks;
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_wps:=Tcl_OK;
end;

{
<p>lwdaq_calibration takes as input an apparatus measurement and a device calibration, and returns a parameter calculation. The routine calls parameter_calculation in the <a href="http://alignment.hep.brandeis.edu/Software/Sources/bcam.pas">bcam.pas</a>. This routine supports bcam cameras and bcam sources for all types of bcam and both j_plates and k_plates.</p>
}
function lwdaq_calibration(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

const
	rnw=8;rnd=3;
		
var 
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	calib_str,app_str,param_str,ct:short_string='';
	verbose,check:boolean=false;
	app:apparatus_measurement_type;
	calib:device_calibration_type;
		
begin
	error_string:='';
	lwdaq_calibration:=Tcl_Error;
	
	if (argc<3) or (not odd(argc)) then begin
		Tcl_SetReturnShortString(interp,'Wrong number of arguments, must be ' 
			+'"lwdaq_image_calibration device_calibration apparatus_measurement'
			+' ?option value?".');
		exit;
	end;
	
	arg_index:=3;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-verbose') then verbose:=Tcl_ObjBoolean(vp)
		else if (option='-check') then check:=Tcl_ObjBoolean(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-verbose -check".');
			exit;
		end;
	end;
	
	calib_str:=Tcl_ObjShortString(argv[1]);
	calib:=device_calibration_from_string(calib_str);
	app_str:=Tcl_ObjShortString(argv[2]);
	app:=apparatus_measurement_from_string(app_str);
	
	if app.calibration_type<>calib.calibration_type then begin
		report_error('Apparatus measurement type "'
			+app.calibration_type
			+'" does not match device calibration type "'
			+calib.calibration_type+'" in '
			+CurrentRoutineName);
	end;

	ct:=calib.calibration_type;
	
	if (ct='black_polar_fc') 
			or (ct='black_polar_rc') 
			or (ct='blue_polar_fc') 
			or (ct='blue_polar_rc') 
			or (ct='black_h_fc') 
			or (ct='black_h_rc') 
			or (ct='blue_h_fc') 
			or (ct='blue_h_rc')
			or (ct='black_azimuthal_c') 
			or (ct='blue_azimuthal_c') then begin
		param_str:=bcam_camera_calib(calib,app,verbose,check);
	end;
	
	if (ct='black_polar_fs') 
			or (ct='blue_polar_fs') 
			or (ct='black_polar_rs') 
			or (ct='blue_polar_rs')
			or (ct='black_h_fs') 
			or (ct='blue_h_fs') 
			or (ct='black_h_rs') 
			or (ct='blue_h_rs')
			or (ct='black_fiber_rs') 
			or (ct='blue_fiber_rs')
			or (ct='black_azimuthal_s') 
			or (ct='blue_azimuthal_s') then begin
		param_str:=bcam_sources_calib(calib,app,verbose,check);
	end;
	
	if (ct='j_plate')
			or (ct='k_plate') then begin
		param_str:=bcam_jk_calib(calib,app,verbose,check);
	end;
	
	if error_string='' then Tcl_SetReturnShortString(interp,param_str)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_calibration:=Tcl_OK;
end;

{
<p>lwdaq_diagnostic analyzes sixteen-bit adc samples from the driver supplies. It assumes that five numbers specifying the relay software version, the driver assembly number, the driver hardware version, the controller firmware version, and the data transfer speed are all saved in the input image's results string. The routine leaves these numbers in the results string after it is done.</p>
}
function lwdaq_diagnostic(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	v_min,v_max,t_min,t_max:real=0;
	ac_couple:boolean=false;
	 
begin
	error_string:='';
	lwdaq_diagnostic:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_diagnostic image ?option value?".');
		exit;
	 end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-v_min') then v_min:=Tcl_ObjReal(vp)			
		else if (option='-v_max') then v_max:=Tcl_ObjReal(vp)			
		else if (option='-t_max') then t_max:=Tcl_ObjReal(vp)			
		else if (option='-t_min') then t_min:=Tcl_ObjReal(vp)			
		else if (option='-ac_couple') then ac_couple:=Tcl_ObjBoolean(vp)			
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-v_max -v_min -t_max -t_min -ac_couple".');
			exit;
		end;
	end;
	
	result:=lwdaq_A2037_monitor(ip,t_min,t_max,v_min,v_max,ac_couple);
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_diagnostic:=Tcl_OK;
end;

{
<p>lwdaq_voltmeter analyzes image data for the Voltmeter instrument. We pass the routine an image name and it returns either a string of characteristics of the voltages recorded in the image, or the voltages themselves. It plots the voltages in the image overlay, according to plot ranges passed to the routine. The display looks like an oscilloscope, and provides a software trigger.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-v_min</td><td>The minimum voltage for the display.</td></tr>
<tr><td>-v_max</td><td>The maximum voltage for the display.</td></tr>
<tr><td>-t_min</td><td>The minimum time for the display.</td></tr>
<tr><td>-t_max</td><td>The maximum time for the display.</td></tr>
<tr><td>-ac_couple</td><td>Whether to subtract the average value from display.</td></tr>
<tr><td>-positive_trigger</td><td>Trigger on positive-going transition.</td></tr>
<tr><td>-v_trigger</td><td>The trigger voltage for display and extraction.</td></tr>
<tr><td>-auto_calib</td><td>Use the device's reference voltages.</td></tr>
<tr><td>-values</td><td>Return the voltage values rather than characteristics.</td></tr>
</table>

<p>The lwdaq_voltmeter routine calls lwdaq_A2057_voltmeter to analyze the samples in the image. The image results string must contain some information about the samples that will allow the analysis to parse the voltages into reference samples and signal samples. The results string will contain 5 numbers. The first two are the bottom and top reference voltages available on the LWDAQ device. In the case of the A2057 these are 0 V and 5 V, but they could be some other value on another device. The third number is the gain applied to the signal. The fourth number is the data acquisition redundancy factor, which is the number of samples recorded divided by the width of the image. Because we will use a software trigger, we want to give the routine a chance to find a trigger and still have enough samples to plot one per image column. Suppose the image contains 200 columns, then we might record 600 samples so that any trigger occuring in the first 400 samples will leave us with 200 samples after the trigger to plot on the screen. In this case, our redundancy factor is 3. The fifth number is the number of channels from which we have recorded.</p>

<p>The result string "0.0 5.0 10 3 2" indicates 0 V and 5 V references, a gain of 10, a redundancy factor of 3 and two channels. The channels will be plotted with the usual LWDAQ <a href="http://alignment.hep.brandeis.edu/Electronics/LWDAQ/HTML/Plot_Colors.jpg">colors</a>, with the first channel being color zero.</p>

<p>The analysis assumes the samples are recorded as sixteen-bit numbers taking up two bytes, with the most significant byte first (big-endian short integer). The first byte of the recorded signal should be the first pixel in the second row of the image, which is pixel (0,1). If <i>n</i> is the image width and <i>r</i> is the redundancy factory, the first <i>n</i> samples (therefore 2<i>n</i> bytes) are samples of the bottom reference voltage. After that come <i>nr</i> samples from each channel recorded (therefore 2<i>nr</i> bytes from each channel). Last of all are <i>n</i> samples from the top reference.</p>

<p>The analysis uses the bottom and top reference values to calibrate the recorded signals, which are otherwise poorly defined in their correspondance between integer values and voltages. We turn on the calibration with the auto_calib option.</p>

<p>The recorded signal from the last channel to be analysed can be returned as a string. Each point consists of a time and a voltage. We instruct the analysis to return the points rather than characteristics with the values option. The following line of code extracts the signal of the last channel. Time zero will be the trigger instant if a trigger was detected, and the first sample otherwise. Thus the returned string contains more data than is plotted by the voltmeter analysis in the image overlay. It contains all the samples recorded.</p>

<pre>set trace [lwdaq_voltmeter image_name -values 1 -auto_calib 1]</pre>

<p>When the values option is not set, as is the case by default, the analysis returns four numbers for each channel recorded. The first number is the average value of the signal. The second is its standard deviation. You can obtain the root mean square of the signal by adding the square of the average and the standard deviation, and taking the square root. The third number is an estimate of the fundamental frequency of the recorded signal, if such a frequency exists, in Hertz, as obtained from a discrete fourier transform. To obtain the discrete fourier transform, we use a subset of the data containing an exact power of two number of samples. We pass this exact power of two number of samples to our fast fourier transform routine. The fourth number is the amplitude of this fundamental frequency.</p>
}
function lwdaq_voltmeter(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name,result:short_string='';
	option,s:short_string;
	lsp:long_string_ptr;
	arg_index,n:integer;
	vp:pointer;	
	v_min,v_max,v_trigger,t_min,t_max:real=0;
	ac_couple,auto_calib,positive_trigger,values:boolean=false;
	 
begin
	error_string:='';
	lwdaq_voltmeter:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_voltmeter image ?option value?".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-v_min') then v_min:=Tcl_ObjReal(vp)			
		else if (option='-v_max') then v_max:=Tcl_ObjReal(vp)			
		else if (option='-v_trigger') then v_trigger:=Tcl_ObjReal(vp)			
		else if (option='-t_max') then t_max:=Tcl_ObjReal(vp)			
		else if (option='-t_min') then t_min:=Tcl_ObjReal(vp)			
		else if (option='-ac_couple') then ac_couple:=Tcl_ObjBoolean(vp)			
		else if (option='-positive_trigger') then positive_trigger:=Tcl_ObjBoolean(vp)			
		else if (option='-auto_calib') then auto_calib:=Tcl_ObjBoolean(vp)			
		else if (option='-values') then values:=Tcl_ObjBoolean(vp)			
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'-v_max -v_min -t_max -t_min -ac_couple -auto_calib -values".');
			exit;
		end;
	end;
	result:=lwdaq_A2057_voltmeter(ip,t_min,t_max,v_min,v_max,v_trigger,
		ac_couple,positive_trigger,auto_calib);
		
	if error_string='' then begin
		if values then begin
			lsp:=new_long_string;
			lsp^:='';
			if electronics_trace<>nil then begin
				for n:=0 to electronics_trace^.num_points-1 do begin
					writestr(s,electronics_trace^[n].x:fsr:fsd,
						' ',electronics_trace^[n].y:fsr:fsd,' ');
					insert(s,lsp^,length(lsp^)+1);
				end;
			end;
			lwdaq_long_string:=lsp^;
			dispose_long_string(lsp);
			Tcl_SetReturnLongString(interp,lwdaq_long_string)
		end else begin
			Tcl_SetReturnShortString(interp,result);
		end;
	end else 
		Tcl_SetReturnShortString(interp,error_string);
	lwdaq_voltmeter:=Tcl_OK;
end;

{
<p>lwdaq_rfpm analyzes images from an RFPM instrument.</p>
}
function lwdaq_rfpm(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	v_min,v_max,v_trigger,t_min,t_max:real=0;
	rms:boolean=false;
	 
begin
	error_string:='';
	lwdaq_rfpm:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_rfpm image ?option value?".');
		exit;
	end;
	
	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-v_min') then v_min:=Tcl_ObjReal(vp)			
		else if (option='-v_max') then v_max:=Tcl_ObjReal(vp)			
		else if (option='-rms') then rms:=Tcl_ObjBoolean(vp)			
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-v_max -v_min -rms".');
			exit;
		end;
	end;
	result:=lwdaq_A3008_rfpm(ip,v_min,v_max,rms);
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_rfpm:=Tcl_OK;
end;

{
<p>lwdaq_inclinometer analyzes an image returned by the Inclinometer instrument. It returns the amplitude of harmonics in signals recorde in an image.</p>
}
function lwdaq_inclinometer(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	v_min,v_max,v_trigger:real=0;
	harmonic:real=1;

begin
	error_string:='';
	lwdaq_inclinometer:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_inclinometer image ?option value?".');
		exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-v_min') then v_min:=Tcl_ObjReal(vp)			
		else if (option='-v_max') then v_max:=Tcl_ObjReal(vp)	
		else if (option='-harmonic') then harmonic:=Tcl_ObjReal(vp)	
		else if (option='-v_trigger') then v_trigger:=Tcl_ObjReal(vp)	
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-v_trigger -v_max -v_min -harmonic".');
			exit;
		end;
	end;
	result:=lwdaq_A2065_inclinometer(ip,v_trigger,v_min,v_max,harmonic);
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_inclinometer:=Tcl_OK;
end;

{
<p>lwdaq_recorder steps through the pixels of an image looking for valid messages from an asynchronous transmitter such as the Subcutaneous Transmitter (<a href="http://www.opensourceinstruments.com/Electronics/A3013/M3013.html">A3013</a>) as received by a Data Receiver (<a href="http://www.opensourceinstruments.com/Electronics/A3018/M3018.html">A3018</a>). It draws the signals it discovers in the image overlay. See the <a href="http://www.opensourceinstruments.com/Electronics/A3018/Recorder.html">Recorder Instrument</a> Manual for details.</p>
}
function lwdaq_recorder(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name:short_string='';
	lsp:long_string_ptr;
	command,instruction:short_string='';
	error:integer;

begin
	error_string:='';
	lwdaq_recorder:=Tcl_Error;
	
	if argc<>3 then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_recorder image command".');
		exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	command:=Tcl_ObjShortString(argv[2]);
	
	lsp:=lwdaq_A3007_recorder(ip,command);
	lwdaq_long_string:=lsp^;
	dispose_long_string(lsp);
	
	if error_string='' then Tcl_SetReturnLongString(interp,lwdaq_long_string)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_recorder:=Tcl_OK;
end;

{
<p>lwdaq_sampler steps through the pixels of an image looking for valid samples from a sampling circuit like the ADC Tester (<a href="http://alignment.hep.brandeis.edu/Electronics/A2100/M2100.html">A2100</a>).</p>
}
function lwdaq_sampler(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name:short_string='';
	lsp:long_string_ptr;
	command,instruction:short_string='';
	error:integer;

begin
	error_string:='';
	lwdaq_sampler:=Tcl_Error;
	
	if argc<>3 then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_sampler image command".');
		exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	command:=Tcl_ObjShortString(argv[2]);
	
	lsp:=lwdaq_A2100_sampler(ip,command);
	lwdaq_long_string:=lsp^;
	dispose_long_string(lsp);
	
	if error_string='' then Tcl_SetReturnLongString(interp,lwdaq_long_string)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_sampler:=Tcl_OK;
end;

{
<p>lwdaq_gauge analyzes sixteen-bit adc values by calling lwdaq_A2053_gauge. The routine assumes that two numbers specifying the sample period and the number of channels sampled are saved in the input image's results string. The routine leaves these numbers in the results string after it is done. For each gauge channel in the image, the routine returns a result, according to the result specifiers. With -ave 1, the result for each channel includes the average gauge value. With -stdev 1, the result includes the standard deviation of the gauge value. With both set to zero, the result is an empty string. The default values for ave and stdev are 1 and 0 respectively.</p>
}
function lwdaq_gauge(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	y_min,y_max,t_min,t_max:real=0;
	ref_bottom:real=0;
	ref_top:real=100;
	ac_couple,stdev:boolean=false;
	ave:boolean=true;
	
begin
	error_string:='';
	lwdaq_gauge:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_gauge image ?option value?".');
		exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-y_min') then y_min:=Tcl_ObjReal(vp)			
		else if (option='-y_max') then y_max:=Tcl_ObjReal(vp)			
		else if (option='-t_max') then t_max:=Tcl_ObjReal(vp)			
		else if (option='-t_min') then t_min:=Tcl_ObjReal(vp)			
		else if (option='-ref_bottom') then ref_bottom:=Tcl_ObjReal(vp)			
		else if (option='-ref_top') then ref_top:=Tcl_ObjReal(vp)			
		else if (option='-ac_couple') then ac_couple:=Tcl_ObjBoolean(vp)			
		else if (option='-stdev') then stdev:=Tcl_ObjBoolean(vp)			
		else if (option='-ave') then ave:=Tcl_ObjBoolean(vp)			
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
						+'"image -y_max -y_min -t_max -t_min -ac_couple -stdev -ave".');
			exit;
		end;
	end;
	result:=lwdaq_A2053_gauge(ip,t_min,t_max,y_min,y_max,
		ac_couple,ref_bottom,ref_top,
		ave,stdev);
		
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_gauge:=Tcl_OK;
end;

{
<p>lwdaq_flowmeter analyzes sixteen-bit adc values by calling lwdaq_A2053_flowmeter. It assumes that two numbers specifying the sample period and the number of channels sampled are saved in the input image's results string. The routine leaves these numbers in the results string after it is done.</p>
}
function lwdaq_flowmeter(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	image_name,result:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	c_min,c_max,t_min,t_max:real=0;
	ref_bottom:real=15.38;
	ref_top:real=25.69;
	 
begin
	error_string:='';
	lwdaq_flowmeter:=Tcl_Error;
	
	if (argc<2) or (odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_flowmeter image ?option value?".');
		exit;
	end;

	image_name:=Tcl_ObjShortString(argv[1]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-c_min') then c_min:=Tcl_ObjReal(vp)			
		else if (option='-c_max') then c_max:=Tcl_ObjReal(vp)			
		else if (option='-t_max') then t_max:=Tcl_ObjReal(vp)			
		else if (option='-t_min') then t_min:=Tcl_ObjReal(vp)			
		else if (option='-ref_bottom') then ref_bottom:=Tcl_ObjReal(vp)			
		else if (option='-ref_top') then ref_top:=Tcl_ObjReal(vp)			
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
						+'"-c_max -c_min -t_max -t_min".');
			exit;
		end;
	end;
	result:=lwdaq_A2053_flowmeter(ip,t_min,t_max,c_min,c_max,ref_bottom,ref_top);
	
	if error_string='' then Tcl_SetReturnShortString(interp,result)
	else Tcl_SetReturnShortString(interp,error_string);
	lwdaq_flowmeter:=Tcl_OK;
end;

{
<p>lwdaq_graph takes a string of numbers and plots them in the image overlay, displaying them by means of lines between the consecutive points. The string of numbers may contain x-y value pairs, or x values only or y values only. The default is x-y values. With <i>y_only</i> = 1 it assumes y values only and assigns x-value 0 to the first y-value, 1 to the next, and so on. With <i>x_only</i> = 1 it assumes x values only an assigns y-value 0 to the first x-value, -1 to the next, and so on. The negative-going x-values are consistent with the negative-going vertical image coordinates, so that x_only is useful for plotting image properties on top of an image, such as vertical intensity profile. Thus the following code plots the vertical and horizontal intensity profiles in an image overlay</p>

<pre><small><small>set profile [lwdaq_image_profile imagname -row 1]
lwdaq_graph $profile imagname -y_only 1 -color 3
set profile [lwdaq_image_profile imagname -row 0]
lwdaq_graph $profile imagname -x_only 1 -color 4</small></small></pre>

<p>The graph will fill the analysis boundaries of the image unless you set <i>entire</i> = 1, in which case the graph will fill the entire image.</p>

<p>You can specify the values of x and y that correspond to the edges of the plotting area with <i>x_min</i>, <i>x_max</i>, <i>y_min</i>, and <i>y_max</i>. By default, however, the routine will stretch of compress the plot to fit exactly in the available space.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-x_min</td><td>x at left edge, if 0 with x_max = 0, use minimum value of x, default 0</td></tr>
<tr><td>-x_max</td><td>x at right edge, if 0 with x_min = 0, use maximum value of x, default 0</td></tr>
<tr><td>-y_min</td><td>y at bottom edge, if 0 with y_max = 0, use minimum value of y, default 0</td></tr>
<tr><td>-y_max</td><td>y at top edge, if 0 with y_min = 0, use maximum value of y, default 0</td></tr>
<tr><td>-ac_couple</td><td>1 add average y-value to y_min and y_max, default 0</td></tr>
<tr><td>-color</td><td>integer code for the color, default 0</td></tr>
<tr><td>-clear</td><td>1, clear image overlay before plotting, default 0</td></tr>
<tr><td>-fill</td><td>1, fill image overlay before plotting, default 0</td></tr>
<tr><td>-x_div</td><td>&gt; 0, plot vertical divisions spaced by this amount, default 0</td></tr>
<tr><td>-y_div</td><td>&gt; 0, plot horizontal divisions spaced by this amount, default 0.</td></tr>
<tr><td>-y_only</td><td>1, data is y-values only, default 0.</td></tr>
<tr><td>-x_only</td><td>1, data is x-values only, default 0.</td></tr>
<tr><td>-entire</td><td>1 use entire image for plot, 0 use analysis bounds, default 0.</td></tr>
</table>

<p>The color codes for the graph give 255 unique colors. You can try them out to see which ones you like. The colors 0 to 15 specify a set of distinct colors, as shown <a href="http://alignment.hep.brandeis.edu/Electronics/LWDAQ/HTML/Plot_Colors.jpg">here</a>. The remaining colors are eight-bit RGB codes. If you don't specify a color, the plot will be red.</p>

}
function lwdaq_graph(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	ip:image_ptr_type=nil;
	gp:xy_graph_ptr_type=nil;
	gpy:x_graph_ptr_type=nil;
	image_name:short_string='';
	option:short_string;
	arg_index:integer;
	vp:pointer;	
	x_min,x_max,y_min,y_max:real=0;
	x_div,y_div:real=0;
	num_points,point_num:integer=0;
	lsp:long_string_ptr;
	color:integer=0;
	clear,entire,fill,ac_couple,y_only,x_only:boolean=false;
	x,y:real;
	saved_bounds:ij_rectangle_type;
	average:real;
	
begin
	error_string:='';
	lwdaq_graph:=Tcl_Error;
	
	if (argc<3) or (not odd(argc)) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_graph data image ?option value?".');
		exit;
	end;

	arg_index:=3;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-x_min') then x_min:=Tcl_ObjReal(vp)			
		else if (option='-x_max') then x_max:=Tcl_ObjReal(vp)			
		else if (option='-y_max') then y_max:=Tcl_ObjReal(vp)			
		else if (option='-y_min') then y_min:=Tcl_ObjReal(vp)			
		else if (option='-color') then color:=Tcl_ObjInteger(vp)			
		else if (option='-clear') then clear:=Tcl_ObjBoolean(vp)			
		else if (option='-entire') then entire:=Tcl_ObjBoolean(vp)			
		else if (option='-fill') then fill:=Tcl_ObjBoolean(vp)			
		else if (option='-x_div') then x_div:=Tcl_ObjReal(vp)			
		else if (option='-y_div') then y_div:=Tcl_ObjReal(vp)
		else if (option='-y_only') then y_only:=Tcl_ObjBoolean(vp)
		else if (option='-x_only') then x_only:=Tcl_ObjBoolean(vp)
		else if (option='-ac_couple') then ac_couple:=Tcl_ObjBoolean(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-x_max -x_min -y_max -y_min -clear -color -x_div -y_div '
				+'"-fill -entire -y_only".');

			exit;
		end;
	end;
	
	image_name:=Tcl_ObjShortString(argv[2]);
	ip:=image_ptr_from_name(image_name);
	if not valid_image_ptr(ip) then begin
		Tcl_SetReturnShortString(interp,'Image "'+image_name+'" does not exist.');
		exit;
	end;
	if clear then clear_overlay(ip);
	if fill then fill_overlay(ip);
	if entire then begin
		saved_bounds:=ip^.analysis_bounds;
		with ip^.analysis_bounds do begin
			left:=0;
			top:=0;
			right:=ip^.i_size-1;
			bottom:=ip^.j_size-1;
		end;
	end;

	lsp:=Tcl_ObjLongString(argv[1]);
	if y_only then begin
		gpy:=read_x_graph(lsp^);
		gp:=new_xy_graph(gpy^.num_points);
		for point_num:=0 to gpy^.num_points-1 do begin
			gp^[point_num].x:=point_num;
			gp^[point_num].y:=gpy^[point_num];
		end;
		dispose_x_graph(gpy);
	end;
	if x_only then begin 
		gpy:=read_x_graph(lsp^);
		gp:=new_xy_graph(gpy^.num_points);
		for point_num:=0 to gpy^.num_points-1 do begin
			gp^[point_num].y:=-point_num;
			gp^[point_num].x:=gpy^[point_num];
		end;
		dispose_x_graph(gpy);
	end;
	if (not y_only) and (not x_only) then 
		gp:=read_xy_graph(lsp^);

	if ac_couple then begin
		average:=average_xy_graph(gp);
		display_real_graph(ip,gp,overlay_color_from_integer(color),
			x_min,x_max,y_min+average,y_max+average,x_div,y_div);
	end else 
		display_real_graph(ip,gp,overlay_color_from_integer(color),
			x_min,x_max,y_min,y_max,x_div,y_div);
	dispose_xy_graph(gp);
	dispose_long_string(lsp);
	if entire then ip^.analysis_bounds:=saved_bounds;

	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_graph:=Tcl_OK;
end;

{
<p>lwdaq_filter applies a recursive filter to a sampled signal. The samples are passed to lwdaq_filter as a string of space-delimited real numbers. By default, lwdaq_filter assumes every number in the string is a sample. With the -tv_format option set to 1, lwdaq_filter assumes every other number in the string is a uniformly-spaced sample, in the form "t v ", where "t" is time and "v" is the sample. In this case, lwdaq_filter reads the v-values only.</p>

<p>The routine returns its answer as a string of space-delimited real numbers. By default, lwdaq_filter returns a signal with as many samples as it received, separated by spaces, and formatted withe the global fsr (field size real) and fsd (field size decimal) values. With -tv_format set to 1, lwdaq_filter copies the t-values from the input string, so as to create an output string with the same t-values, but processed v-values.</p>

<table border cellspacing=2>
<tr><th>Option</th><th>Function</th></tr>
<tr><td>-tv_format</td><td>if 0, data points "v", otherwise "t v", default 0</td></tr>
<tr><td>-ave_start</td><td>if 1, over-write first sample with average, default 0</td></tr>
</table>

<p>We define the digital signal processing we with lwdaq_filter to perform by means of two strings. The first string gives the coefficients a[0]..a[n] by which the input values x[0]..x[k-n] are multiplied before adding to b[k]. The second string gives the coefficients b[1]..b[n] by which the previous outputs y[1]..y[k-n] are multiplied before adding to b[k].</p>
}
function lwdaq_filter(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	vt_signal:xy_graph_ptr_type=nil;
	signal,filtered:x_graph_ptr_type=nil;
	a_list,b_list,point_string,option:short_string='';
	arg_index,point_num:integer;
	vp:pointer;	
	lsp:long_string_ptr;
	tv_format,ave_start:boolean=false;
	
begin
	error_string:='';
	lwdaq_filter:=Tcl_Error;
{
	Check the argument list.
}
	if (argc<4) or odd(argc) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_filter data a_list b_list ?option value?".');
		exit;
	end;
{
	Determine the options.
}
	arg_index:=4;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-tv_format') then tv_format:=Tcl_ObjBoolean(vp)		
		else if (option='-ave_start') then ave_start:=Tcl_ObjBoolean(vp)	
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-tv_format -ave_start".');
			exit;
		end;
	end;
{
	Read the data into a graph and get the command string.
}
	arg_index:=1;
	lsp:=Tcl_ObjLongString(argv[arg_index]);
	if tv_format then begin
		vt_signal:=read_xy_graph(lsp^);
		signal:=new_x_graph(vt_signal^.num_points);
		for point_num:=0 to signal^.num_points-1 do
			signal^[point_num]:=vt_signal^[point_num].y;
	end else begin
		signal:=read_x_graph(lsp^);
	end;
	if ave_start then
		signal^[0]:=average_x_graph(signal);
	inc(arg_index);
	a_list:=Tcl_ObjShortString(argv[arg_index]);
	inc(arg_index);
	b_list:=Tcl_ObjShortString(argv[arg_index]);
	inc(arg_index);
{
	Call the dsp routine on the signal.
}
	filtered:=recursive_filter(signal,a_list,b_list);	
{
	Prepare the output data.
}
	if filtered<>nil then begin
		lsp^:='';
		for point_num:=0 to filtered^.num_points-1 do begin
			if tv_format then 
				writestr(point_string,vt_signal^[point_num].x:fsr:fsd,' ',
					filtered^[point_num]:fsr:fsd,' ')
			else
				writestr(point_string,filtered^[point_num]:fsr:fsd,' ');
			insert(point_string,lsp^,length(lsp^)+1);
		end;
		dispose_x_graph(filtered);
		lwdaq_long_string:=lsp^;
		dispose_long_string(lsp);
		Tcl_SetReturnLongString(interp,lwdaq_long_string);
	end;
{
	Dispose of pointers and check for errors.
}
	dispose_x_graph(signal);
	if tv_format then dispose_xy_graph(vt_signal);	
	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_filter:=Tcl_OK;
end;

{
<p>lwdaq_fft applies a fast fourier tranfsorm to a waveform and returns the complete <a href="http://en.wikipedia.org/wiki/Discrete_Fourier_transform">discrete fourier transform</a> (DFT). In general, the DFT transforms a set of <i>N</i> complex-valued samples and returns a set of <i>N</i> complex-valued frequency components. We assume the samples, are uniformly-spaced with respect to some one-dimensional quantity such as time or distance. The <i>sample period</i> is the separation of the samples in this one-dimensional quantity. We denote the sample period with <i>T</i> and the one-dimensional quantity we denote as <i>t</i>. We denote the sample at <i>t</i> = <i>nT</i> with <i>x<sub>n</sub></i>, where <i>n</i> is an integer such taht 0&le;<i>n</i>&le;<i>N</i>&minus;1. We denote the transform components <i>X<sub>k</sub></i>, where <i>k</i> is an integer such that 0&le;<i>k</i>&le;<i>N</i>&minus;1. Each transform component represents a complex sinusoidal function in <i>t</i>. The <i>k</i>'th sinusoid, <i>S<sub>k</sub></i>, has frequency <i>k</i>/<i>NT</i>. Its magnitude and phase are given by <i>X<sub>k</sub></i>.</p>

<big>
<p>
<i>S<sub>k</sub></i> = 
<i>X<sub>k</sub></i> e<sup>2&pi;<i>kt</i>/<i>NT</i></sup>
</p>
</big>

<p>In the text-book definition of the <a href="http://en.wikipedia.org/wiki/Discrete_Fourier_transform">discrete fourier transform</a>, <i>X<sub>k</sub></i> is <i>N</i> times larger, and we must divide by <i>N</i> to obtain the sinusoidal amplitude. But we pre-scaled our components by 1/<i>N</i> so we return the sinusoidal comonents directly. If we express <i>X<sub>k</sub></i> as a magnitude, <i>A<sub>k</sub></i>, and a phase &Phi;<sub>k</sub>, we get the following expression for the sinusoid.</p>

<big>
<p>
<i>S<sub>k</sub></i> = 
<i>A<sub>k</sub></i> e<sup>2&pi;<i>kt</i>/<i>NT</i>+&Phi;<sub>k</sub></sup>
</p>

<p>
<i>S<sub>k</sub></i> = 
<i>A<sub>k</sub></i>cos(2&pi;<i>kt</i>/<i>NT</i>+&Phi;<sub>k</sub>)
+<i>i</i><i>A<sub>k</sub></i>sin(2&pi;<i>kt</i>/<i>NT</i>+&Phi;<sub>k</sub>)
</p>
</big>

<p>When our inputs <i>x<sub>n</sub></i> are real-valued, we find that the the <i>k</i>'th component of the transform is the complex conjugate of component <i>N</i>&minus;<i>k</i>. A feature of all discrete transform is <i>X<sub>k</sub></i> = <i>X<sub>k&minus;N</sub></i>. Thus <i>X<sub>N&minus;k</sub></i> = <i>X<sub>&minus;k</sub></i>, the component with frequency &minus;<i>k</i>/<i>NT</i>. We observe that cos(<i>v</i>) = cos(&minus;<i>v</i>) and sin(<i>v</i>) = &minus;sin(&minus;<i>v</i>), so the &minus;<i>k</i>'th component is the complex conjugate of the <i>k</i>'th component. This means that the <i>N</i>&minus;<i>k</i>'th component is equal to the <i>k</i>'th component.</p>

<big>
<p>
<i>S<sub>k</sub></i> + <i>S<sub>&minus;k</sub></i> = 
2<i>A<sub>k</sub></i>cos(2&pi;<i>kt</i>/<i>NT</i>+&Phi;<sub>k</sub>)
</p>
</big>

<p>The 0'th and <i>N</i>/2'th components we cannot sum together using the above trick. But these components always have phase 0 or &pi; when the inputs are real-valued. We can represent them with two real-valued numbers, where the magnitude of the number is the magnitude of the component and the sign is the phase 0 or &pi;.</p>

<p>The <i>lwdaq_fft</i> routine will accept <i>N</i> complex-valued samples in the form <i>x<sub>n</sub></i> = <i>u</i>+<i>iv</i> and return <i>N</i> complex-valued components in the form <i>X<sub>k</sub></i> = <i>U</i>+<i>iV</i>. We specify complex-valued input with option "-complex 1". The default option, however, is "-complex 0", which specifies real-valued input and returns <i>N</i>/2 real-valued components. We obtain the <i>N</i>/2 components by adding each <i>X<sub>k</sub></i> to its complex conjugate <i>X<sub>N&minus;k</sub></i>. We express these real-valued frequency components with two numbers each, 2<i>A<sub>k</sub></i> and &Phi;<sub>k</sub>. These represent a cosine with amplitude 2<i>A<sub>k</sub></i>, angular frequency 2&pi;<i>k</i>/<i>NT</i> (rad/s), and phase shift &Phi;<sub>k</sub> (rad).</p>

<p>The 0'th component of the real-valued transform is an exception. It contains two numbers, but neither of them is a phase. One is the magnitude of the 0'th component, which is the DC component, and the <i>N</i>/2'th component, which is the Nyquist-frequency component.</p>

<p>The <i>lwdaq_fft</i> routine insists upon <i>N</i> being a power of two so that the fast fourier transform algorithm can divide the problem in half repeatedly until it arrives at transforms of length 1. For the fast fourier transform algorithm itself, see the <i>fft</i> routine in <a href="http://alignment.hep.brandeis.edu/Software/Sources/utils.pas">utils.pas</a>. For its real-valued wrapper see <i>fft_real</i>.</p>

<pre>
lwdaq_config -fsr 1 -fsd 2
lwdaq_fft "1 1 1 1 1 1 1 0"
0.88 0.13 0.25 -2.36 0.25 -1.57 0.25 -0.79 
</pre>

<p>In the example, we supply the routine with eight real-valued samples and obtain a transform of sixteen numbers. The first number tells us the magnitude and phase of the 0-frequency component. This number is equal to the average value of the samples, and is often called the "DC-component". The second number gives us the Nyquist-frequency component, which is the component with period two sample intervals. Here, the Nyquist-frequency component is the 4-frequency component with period N/4 (N=8). We multiply a cosine by this mangnitude and we obtain the 4-frequency component of the transform. Its phase can be either +&pi; or &minus;&pi;, and so is represented by the signe of the component magnitude.</p>

<p>The remaining components in the tranform, 1 through 3, are each represented by two numbers, a magnitude, <i>a</i>, and a phase <i>&Phi;</i>. We obtain the value of component <i>k</i> at time <i>t</i> with <i>a</i>cos(2&pi;<i>kt</i>/<i>NT</i>+&Phi;). If we use sample number, <i>n</i>, instead of time, the component is <i>a</i>cos(2&pi;<i>kn</i>/<i>N</i>+&Phi;).</p>

<pre>
lwdaq_fft "1 0 1 0 1 0 1 0 1 0 1 0 1 0 0 0" -complex 1
0.88 0.00 -0.09 -0.09 -0.00 -0.13 0.09 -0.09 0.13 0.00 0.09 0.09 0.00 0.13 -0.09 0.09 
</pre>

<p>We submit the same data to the complex version of the transform by accompanying each sample with a zero phase, so as to indicate a real value with a complex number. The result is a transform that is equivalent to our first, abbreviated transform. You can see the <i>N</i>/4 component as "0.13 0.00" and the 0 component as "0.88 00". There are two <i>N</i>/1 frequency components "-0.09 -0.09" and "-0.09 0.09". Their magnitude is 0.127 and their phases are &minus;3&pi;/4 and &minus;&pi;/4. When we add these magnitudes together we obtain the <i>N</i>/1 component of the real-valued transform, which is 0.25 as shown above. The phase of the <i>N</i>/1 component is &minus;3&pi;/4 = &minus;2.36 radians, which is also what we see in the real-valued transform above.</p>

<p>Here is another example. In this case, the <i>N</i>/4 component is zero, as is the 0 component.</p>

<pre>
lwdaq_fft "1 1 1 1 -1 -1 -1 -1"
0.00 0.00 1.31 -1.18 0.00 0.00 0.54 -0.39 
lwdaq_fft "1 0 1 0 1 0 1 0 -1 0 -1 0 -1 0 -1 0" -complex 1
0.00 0.00 0.25 -0.60 0.00 0.00 0.25 -0.10 0.00 0.00 0.25 0.10 0.00 0.00 0.25 0.60 
</pre>

<p>If the samples were taken over 1 s, the eight components represent frequencies 0, 1, 2, and 3 Hz. So we see the square wave of frequency 1 Hz has harmonics at 1 Hz and 3 Hz. The fourier series expansion of a square wave has harmonics of amplitude 4/<i>n</i>&pi; for the <i>n</i>'th harmonic. The first harmonic in the fourier series would have amplitude 1.27. Our 1-Hz component has amplitude 1.31. The discrete fourier transform is an exact representation of the original data, but it does not provide all the harmonics of the fourier series. Therefore, the existing harmonics are not exactly of the same amplitude as those in the fourier series.</p>

<p>The phases of the components in our example are also correct. The first harmonic is offset by &minus;1.18 radians, which means it is a cosine delayed by 1.18/2&pi; = 0.188 of a period, or 1.5 samples. We see that a cosine delayed by 1.5 samles will reach its maximum between samples 1 and 2, which matches our input data. In the example below, we change the phase of the input by &pi; and we see the phase of the fundamental harmonic changes by &pi;.</p>

<pre>
lwdaq_fft "1 1 1 1 0 0 0 0"
0.50 0.00 0.65 -1.18 0.00 0.00 0.27 -0.39 
lwdaq_fft "0 0 0 0 1 1 1 1"
0.50 0.00 0.65 1.96 0.00 0.00 0.27 2.75 
</pre>

<p>We can use <i>lwdaq_fft</i> to perform the inverse transform, but we must invoke the "-inverse 1" option or else the inverse does not come out quite right.</p>

<pre>
set dft [lwdaq_fft "1 0 1 0 1 0 1 0 -1 0 -1 0 -1 0 -1 0" -complex 1]
0.00 0.00 0.25 -0.60 0.00 0.00 0.25 -0.10 0.00 0.00 0.25 0.10 0.00 0.00 0.25 0.60 
lwdaq_fft $dft -complex 1
0.12 0.00 -0.12 0.00 -0.12 0.00 -0.12 0.00 -0.12 0.00 0.12 -0.00 0.12 -0.00 0.12 -0.00 
lwdaq_fft $dft -complex 1 -inverse 1
1.00 0.00 0.99 -0.00 1.00 -0.00 0.99 -0.00 -1.00 0.00 -0.99 0.00 -1.00 0.00 -0.99 0.00 
</pre>

<p>The "-inverse 1" option reverses the order of the input components, which is a trick for getting the forward transform to act like an inverse transform, and then multiplies the resulting sample-values by <i>N</i> to account for the fact that our <i>lwdaq_fft</i> routine scales its frequency components by 1/<i>N</i> to make them correspond to sinusoidal amplitudes. The reversal of the input components and the scaling takes place in <i>fft_inverse</i> of <a href="http://alignment.hep.brandeis.edu/Software/Sources/utils.pas">utils.pas</a>.</p>

<p>We can also invert our compact magnitude-phase transforms, which we derive from real-valued inputs with the "-complex 0" option (the default).</p>

<pre>
set dft [lwdaq_fft "1 1 1 1 -1 -1 -1 -1"]
0.00 0.00 1.31 -1.18 0.00 0.00 0.54 -0.39 
lwdaq_fft $dft -inverse 1
1.00 1.00 1.01 1.00 -1.00 -1.00 -1.01 -1.00 
</pre>

<p>Note the rounding errors we see because we are using only two decimal places in our examples. For the real-valued inverse transform code, see <i>fft_real_inverse</i> in <a href="http://alignment.hep.brandeis.edu/Software/Sources/utils.pas">utils.pas</a>.</p>

<p>The fft, like all discrete fourier transforms, assumes that the <i>N</i> samples are the entire period of a repeating waveform. The <i>N</i> components of the transform, when inverted, give us an exact reproduction of the original <i>N</i> samples. As you are looking at the signal represented by the N samples, be aware that any difference between the 0'th sample and the (<i>N</i>-1)'th sample amounts to a discontinuity at the end of the repeating waveform. A ramp from 0 to 1000 during the <i>N</i> samples gives rise to a sudden drop of 1000. This sudden drop appears as power in all frequency components.</p>

<p>One way to remove end steps is to apply a <a href="http://en.wikipedia.org/wiki/Window_function">window function</a> to the data before you take the fourier transform. We provide a linear window function with the "-window <i>w</i>" option, where we apply the window function to the first <i>w</i> samples and the final <i>w</i> samples. This window function is the same one we provide separately in our <a href="#window_function">window function</a> routine. We recommend you calculate <i>w</i> as a fraction of <i>N</i> when you call <i>lwdaq_fft</i>. We suggest starting <i>w</i> = <i>N</i>/10. We implement the window function only for real-valued samples passed to the forward transform. If you try to apply the window function during the inverse transform or when passing complex samples to the forward transform, <i>lwdaq_fft</i> returns an error. That's not to say that there is no point in applying a window function in these other circumstances, but our linear window function does not have any obvious utility or meaning when so applied.</p>

<p>Some data contains occasional error samples, called <i>spikes</i> or <i>glitches</i>. At some point in our data analysis, we must eliminate these glitches. The <i>lwdaq_fft</i> "-glitch <i>x</i>" option allows you to specify the size of the sample-to-sample change that should be treated as a glitch. The <i>lwdaq_fft</i> routine calls <i>glitch_filter</i> from <a href="http://alignment.hep.brandeis.edu/Software/Sources/utils.pas">utils.pas</a>. We provide this routine at the command line with the <a href="#glitch_filter">glitch_filter</a> library command. Any sample that differs by <i>x</i> or more from the previous sample will be over-written by the previous sample, which becomes the <i>standing value</i>. We keep replacing the data with the standing value until the data differs by less than <i>x</i> from the standing value. The "-glitch" option is compatible only with real-valued data passed to the forward transform. A threshold value of 0 disables the filter.</p>
}
function lwdaq_fft(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var 
	gp,ft:xy_graph_ptr_type=nil;
	gpx:x_graph_ptr_type=nil;
	option:short_string='';
	arg_index,k,n:integer;
	vp:pointer;	
	lsp:long_string_ptr;
	complex,inverse:boolean=false;
	window:integer=0;
	glitch:real=0;
	p:xy_point_type;
	s:short_string;
	
begin
	error_string:='';
	lwdaq_fft:=Tcl_Error;
{
	Check the argument list.
}
	if (argc<2) or odd(argc) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be "lwdaq_fft data ?option value?".');
		exit;
	end;
{
	Determine the options.
}
	arg_index:=2;
	while (arg_index<argc-1) do begin
		option:=Tcl_ObjShortString(argv[arg_index]);
		inc(arg_index);
		vp:=argv[arg_index];
		inc(arg_index);
		if (option='-complex') then complex:=Tcl_ObjBoolean(vp)	
		else if (option='-inverse') then inverse:=Tcl_ObjBoolean(vp)
		else if (option='-window') then window:=Tcl_ObjInteger(vp)
		else if (option='-glitch') then glitch:=Tcl_ObjReal(vp)
		else begin
			Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
				+'"-complex -inverse -window -glitch".');
			exit;
		end;
	end;
{
	Check for incompatible options.
}
	if ((window<>0) or (glitch<>0)) and (inverse or complex) then begin
		Tcl_SetReturnShortString(interp,
			'"-window" and "-glitch" cannot be used with "-complex" or "-inverse".');
		exit;
	end;
{
	The forward transform.
}
	if not inverse then begin
		lsp:=Tcl_ObjLongString(argv[1]);
		if complex then begin
			gp:=read_xy_graph(lsp^);
			ft:=fft(gp);
			dispose_xy_graph(gp);
		end else begin
			gpx:=read_x_graph(lsp^);
			if glitch>0 then glitch_filter(gpx,glitch);
			if window>0 then window_function(gpx,window);
			ft:=fft_real(gpx);
			dispose_x_graph(gpx);
		end;
		lsp^:='';
		if ft<>nil then begin
			for k:=0 to ft^.num_points-1 do begin
				writestr(s,ft^[k].x:fsr:fsd,' ',ft^[k].y:fsr:fsd,' ');
				insert(s,lsp^,length(lsp^)+1);
			end;
			dispose_xy_graph(ft);
		end;
	end;
{
	The reverse transform.
}
	if inverse then begin
		lsp:=Tcl_ObjLongString(argv[1]);
		ft:=read_xy_graph(lsp^);
		lsp^:='';
		if complex then begin
			gp:=fft_inverse(ft);
			dispose_xy_graph(ft);
			if gp<>nil then begin
				for n:=0 to gp^.num_points-1 do begin
					writestr(s,gp^[n].x:fsr:fsd,' ',gp^[n].y:fsr:fsd,' ');
					insert(s,lsp^,length(lsp^)+1);
				end;
				dispose_xy_graph(gp);
			end;
		end else begin
			gpx:=fft_real_inverse(ft);
			dispose_xy_graph(ft);
			if gpx<>nil then begin
				for n:=0 to gpx^.num_points-1 do begin
					writestr(s,gpx^[n]:fsr:fsd,' ');
					insert(s,lsp^,length(lsp^)+1);
				end;
				dispose_x_graph(gpx);
			end;
		end;
	end;
{
	Return result or error as required.
}
	lwdaq_long_string:=lsp^;
	dispose_long_string(lsp);
	Tcl_SetReturnLongString(interp,lwdaq_long_string);
	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq_fft:=Tcl_OK;
end;

{
<p>The <i>lwdaq</i> command acts as an entry point into our analysis libraries, making various math functions available at the TCL command line. You specify the routine we wish to call, and pass arguments to the routine in strings or byte arrays or both. Most routines return results as text strings in which real numbers are encoded in characters with a fixed number of decimal places, as defined by the global constants <i>fsr</i> and <i>fsd</i>. You can set both of these with <i>lwdaq_config</i>. Beware that these routines can round small values to zero. In the comments below, we assume that <i>fsr</i> is 8, and <i>fsd</i> is 6.</p>
}
function lwdaq (data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;

var
	option,result,s:short_string='';
	slope,intercept,rms_residual,position,interpolation:real;
	threshold:real;
	amplitude,offset,average,time_constant:real;
	a,b:sinusoid_type;
	gp,ft:xy_graph_ptr_type;
	gpx,frequencies,signal,filtered:x_graph_ptr_type;
	lsp:long_string_ptr;
	M,N:matrix_ptr;
	num_rows,num_elements,num_columns:integer;
	i,extent:integer;
	
begin
	error_string:='';
	lwdaq:=Tcl_Error;
		
	if (argc<2) then begin
		Tcl_SetReturnShortString(interp,
			'Wrong number of arguments, must be: "lwdaq option ?args?".');
		exit;
	end;

	option:=Tcl_ObjShortString(argv[1]);
	if option='bcam_from_global_point' then begin
{
<p>Transforms a point in global coordinates to a point in BCAM coordinates. The point in BCAM coordinates is returned as a string of three numbers, the BCAM <i>x</i>, <i>y</i>, and <i>z</i> coordinates of the point. You specify the point in global coordinates with the <i>point</i> parameter, which also takes the form of a string of three numbers, these numbers being the global <i>x</i>, <i>y</i>, and <i>z</i> coordinates of the point whose BCAM coordinates we want to determine. You specify how the BCAM and global coordinate systems relate to one another with the <i>mount</i> string. The <i>mount</i> string contains the global coordinates of the BCAM's kinematic mounting balls. You specify the coordinates of the cone, slot, and flat balls, and for each ball we give its <i>x</i>, <i>y</i>, and <i>z</i> coordinates. In the following example, we transform the global point (0,1,0) into BCAM coordinates when our cone, slot and flat balls have coordinates (0,1,0), (-1,1,-1), and (1,1,-1).</p>

<pre>
lwdaq bcam_from_global_point "0 1 0" "0 1 0 -1 1 -1 1 1 -1"
0.000000 0.000000 0.000000
</pre>

<p>For a description of the BCAM coordinate system, and how it is defined with respect to a BCAM's kinematic mounting balls, consult the BCAM <a href="http://alignment.hep.brandeis.edu/Devices/BCAM/User_Manual.html">User Manual</a>. We usually use millimeters to specify coordinates, because we use millimeters in our BCAM camera and source calibration constants. But the routine will work with any units of length, so long as we use the same units for both the point and the mount strings.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq bcam_from_global_point point mount".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz(
				bcam_from_global_point(
					xyz_from_string(Tcl_ObjShortString(argv[2])),
					kinematic_mount_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='global_from_bcam_point' then begin
{
<p>Transforms a point in global coordinates to a point in BCAM coordinates. It is the inverse of <a href="#bcam_from_global_point">bcam_from_global_point</a>. You pass it the global coordinates of a point in the <i>point</i> string, and the coordinates of the BCAM's kinematic mounting balls with the <i>mount</i> string. The routine returns the global coordinates of the point.</p>

<pre>
lwdaq global_from_bcam_point "0 1 0" "0 1 0 -1 1 -1 1 1 -1"
0.000000 2.000000 0.000000
</pre>

<p>For a description of the BCAM coordinate system, and how it is defined with respect to a BCAM's kinematic mounting balls, consult the BCAM <a href="http://alignment.hep.brandeis.edu/Devices/BCAM/User_Manual.html">User Manual</a>.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq global_from_bcam_point point mount".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz(
				global_from_bcam_point(
					xyz_from_string(Tcl_ObjShortString(argv[2])),
					kinematic_mount_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='bcam_from_global_vector' then begin
{
<p>Transforms a vector in global coordinates to a vector in BCAM coordinates. See <a href="#bcam_from_global_point">bcam_from_global_point</a> for more details.</p>

<pre>
lwdaq bcam_from_global_vector "0 1 0" "0 1 0 -1 1 -1 1 1 -1"
0.000000 1.000000 0.000000
</pre>

<p>For a description of the BCAM coordinate system, and how it is defined with respect to a BCAM's kinematic mounting balls, consult the BCAM <a href="http://alignment.hep.brandeis.edu/Devices/BCAM/User_Manual.html">User Manual</a>.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq bcam_from_global_vector vector mount".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz(
				bcam_from_global_vector(
					xyz_from_string(Tcl_ObjShortString(argv[2])),
					kinematic_mount_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='global_from_bcam_vector' then begin
{
<p>Transforms a vector in global coordinates to a vector in BCAM coordinates. It is the inverse of <a href="#bcam_from_global_vector">bcam_from_global_vector</a>.</p>

<pre>
lwdaq global_from_bcam_vector "0 1 0" "0 1 0 -1 1 -1 1 1 -1"
0.000000 1.000000 0.000000
</pre>

<p>For a description of the BCAM coordinate system, and how it is defined with respect to a BCAM's kinematic mounting balls, consult the BCAM <a href="http://alignment.hep.brandeis.edu/Devices/BCAM/User_Manual.html">User Manual</a>.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq global_from_bcam_vector vector mount".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz(
				global_from_bcam_vector(
					xyz_from_string(Tcl_ObjShortString(argv[2])),
					kinematic_mount_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='bcam_source_bearing' then begin
{
<p>Calculates the line upon which a light source must lie for its image to be centered at <i>spot_center</i>. The line is returned as a string containing six numbers. The first three numbers are the coordinates of the BCAM pivot point in BCAM coordinates in millimeters. The last three numbers are a unit vector in the direction of the line. The BCAM itself we describe with its calibration constants in the <i>camera</i> string. The <i>camera</i> string contains nine elements, as described in the <a href="http://alignment.hep.brandeis.edu/Devices/BCAM/User_Manual.html">BCAM User Manual</a>. The <i>camera</i> string specifies length in millimeters and rotation in milliradians.</p>

<pre>
lwdaq bcam_source_bearing "1.72 1.22" "P0001 1 0 0 0 0 1 75 0"
1.000000 0.000000 0.000000 0.000000 0.000000 1.000000
</pre>

<p>The first element in the <i>camera</i> string is the name of the camera, even though this calculation does not use the camera name. In the example above, P0001 is the camera name, the pivot point is at (1,0,0) in BCAM coordinates, the camera axis is parallel to the BCAM <i>z</i>-axis,  the pivot point is 75 mm from the lens, and the CCD rotation is zero. We transform point (1.72, 1.22)  on the CCD (dimensions are millimeters) into a bearing that passes through the pivot point (1,0,0) in the direction (0,0,1). The point (1.72,1.22) is our aribitrarily-chosen center of the CCD in all currently-available BCAMs (it is close to the center of the TC255P image sensor, but not exactly at the center). The BCAM camera axis is the line passing through the CCD center and the pivot point.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq bcam_source_bearing spot_center camera".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz_line(
				bcam_source_bearing(
					xy_from_string(Tcl_ObjShortString(argv[2])),
					bcam_camera_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='bcam_source_position' then begin
{
<p>Calculates the BCAM coordinates of a light source whose image is centered at <i>spot_center</i>, and which itself lies in the plane <i>z</i> = <i>bcam_z</i> in BCAM coordinates. The routine is similar to <a href="#bcam_source_bearing">bcam_source_bearing</a>, but we specify the BCAM <i>z</i>-coordinate of the source as well, in millimeters. The routine determines the position of the source by calling <a href="#bcam_source_breagin">bcam_source_bearing</a> and intersecting the source bearing with the <i>z</i>=<i>range</i> plane. We specify the BCAM calibration constants in the <i>camera</i> string.</p>

<pre>
lwdaq bcam_source_position "1.72 1.22" 1000 "P0001 1 0 0 0 0 1 75 0"
1.000000 0.000000 1000.000000
</pre>

<p>Here we see the source is at (1, 0, 1000) in BCAM coordinates, where all three coordinates are in millimeters. You specify the BCAM itself with its calibration constants using the <i>camera</i> string, just as for <a href="#bcam_source_bearing">bcam_source_bearing</a>.</p>
}
		if (argc<>5) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq bcam_source_position spot_center bcam_z camera".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz(
				bcam_source_position(
					xy_from_string(Tcl_ObjShortString(argv[2])),
					Tcl_ObjReal(argv[3]),
					bcam_camera_from_string(Tcl_ObjShortString(argv[4])))));
	end 
	else if option='bcam_image_position' then begin
{
<p>Calculates the image coordinates of the image generated by a light source at location <i>source_position</i> in BCAM coordinates. We specify the BCAM itself with the <i>camera</i> string, which contains the BCAM's calibration constants. The routine determines the image position by drawing a line from the source through the pivot point and instersecting this line with the plane of the image sensor. The orientation and location of the image sensor is given by the camera calibration constants. The image coordinate origin is the top-left corner of the image sensor as seen on the screen. The units of image coordinats are microns, with x going left-right and y going top-bottom.</p>

<pre>
lwdaq bcam_image_position "1 0 1000" "P0001 1 0 0 0 0 1 75 0"
1.720000 1.220000
</pre>

<p>Here we see the image is at (1.72,1.22) in image coordinates, which is the center of a TC255P image sensor. You specify the BCAM itself with its calibration constants using the <i>camera</i> string, just as for <a href="#bcam_source_bearing">bcam_source_bearing</a>.</p>

<pre>
lwdaq bcam_image_position "1 0 1000" "P0001 1 0 0 0 0 1 100 0"
1.720000 1.220000
lwdaq bcam_image_position "1.1 0 1000" "P0001 1 0 0 0 0 1 100 0"
</pre>

<p>Here we see movement of 1 mm at a range ten times the pivot-ccd distance causing a 100-um move on the image.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq bcam_image_position source_position camera".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xy(
				bcam_image_position(
					xyz_from_string(Tcl_ObjShortString(argv[2])),
					bcam_camera_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='wps_wire_plane' then begin
{
<p>Calculates the plane that must contain the center-line of a wire given the position and rotation of a wire image in a WPS camera. The units for wire position are millimeters, and for rotation are milliradians. We use the camera's calibration constants to determine the plane. We specify the plane in WPS coordinates, which are defined in the same way as BCAM coordinates, using the positions of the WPS (or BCAM) mounting balls. For a description of the BCAM coordinate system, consult the BCAM <a href="http://alignment.hep.brandeis.edu/Devices/BCAM/User_Manual.html">User Manual</a>.</p>

<pre>
lwdaq wps_wire_plane "1.720 1.220" "0.000" "Q0131_1 0 0 0 -10 0 0 0 0 0"
0.000000 0.000000 0.000000 0.000000 0.000000 1.000000
</pre>

<p>The image position in our example is 1.720 mm from the right and 1.220 mm from the top. This is at the nominal center point of a TC255 image sensor. The wire is rotated by 0 mrad anti-clockwise in the image. The first element in the <i>camera</i> string is the name of the camera, even though this calculation does not use the camera name. In the example above, Q0131_1 is the camera name. It is camera number one on the WPS with serial number Q0131. In this example, the camera pivot point is at (0,0,0) in WPS coordinates, which puts it at the center of the cone ball supporting the WPS. That's clearly impossible, but we're just using simple numbers to illustrate the routine. The center of the image sensor (the CCD) is at (-10,0,0). The x-axis runs directly through the pivot point and the center of the sensor. The rotation of the sensor is (0,0,0), which means the x-axis is perpendicular to the sensor surface. Here is another example.</p>

<pre>
lwdaq wps_wire_plane "1 1.220" "10.000" "Q0131_1 0 0 0 -10 0 0 0 0 0"
0.000000 0.000000 0.000000 0.071811 0.009974 0.997368
</pre>

<p>The routine calculates the plane that contains the center of the image and the pivot point. It specifies the plane as the pivot point, which is a point in the plane, and a normal to the plane. The first three numbers in the result are the coordinates of the pivot point. The last three numbers are the normal to the plane. The normal is a unit vector.</p>
}
		if (argc<>5) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq wps_source_plane wire_center wire_rotation camera".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz_plane(
				wps_wire_plane(
					xy_from_string(Tcl_ObjShortString(argv[2])),
					Tcl_ObjReal(argv[3])/mrad_per_rad,
					wps_camera_from_string(Tcl_ObjShortString(argv[4])))));
	end 
	else if option='xyz_plane_plane_intersection' then begin
{
<p>Determines the line along which two planes intersect. We specify each plane with a point in the plane and a normal to the plane, making six numbers for each plane.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq xyz_plane_plane_intersection plane_1 plane_2".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz_line(
				xyz_plane_plane_intersection(
					xyz_plane_from_string(Tcl_ObjShortString(argv[2])),
					xyz_plane_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='xyz_line_plane_intersection' then begin
{
<p>Determines the point at which a line and a plane intersect. We specify the line with a point and a direction. We specify the plane with a point and a normal vector.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq xyz_line_plane_intersection line plane".');
			exit;
		end;
		Tcl_SetReturnShortString(interp,
			string_from_xyz(
				xyz_line_plane_intersection(
					xyz_line_from_string(Tcl_ObjShortString(argv[2])),
					xyz_plane_from_string(Tcl_ObjShortString(argv[3])))));
	end 
	else if option='straight_line_fit' then begin
{
<p>Fits a straight line to <i>data</i>, where <i>data</i> contains a string of numbers, alternating between <i>x</i> and <i>y</i> coordinates. The routine returns a string of three numbers: slope, intercept, and rms residual. The rms residual is the standard deviation of the difference between the straight line and the data, in the <i>y</i>-direction. The data "0 3 1 5 2 7 5 13" would represent a straight line with slope 2, intercept 3, and rms residual 0. The result would be "2.000000 3.000000 0.000000".</p>
}
		if (argc<>3) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq straight_line_fit data".');
			exit;
		end;
		lsp:=Tcl_ObjLongString(argv[2]);
		gp:=read_xy_graph(lsp^);
		straight_line_fit(gp,slope ,intercept,rms_residual);
		dispose_xy_graph(gp);
		dispose_long_string(lsp);
		writestr(s,slope:fsr:fsd,' ',intercept:fsr:fsd,' ',rms_residual:fsr:fsd);
		Tcl_SetReturnShortString(interp,s);
	end 
	else if option='ave_stdev' then begin
{
<p>Calculates the average, standard deviation, maximum, and minimum of <i>data</i>, where <i>data</i> contains a string of numbers. The routine returns values separated by spaces, and formatted to <a href="#lwdaq_config">fsd</a> significant figures.</p>
}
		if (argc<>3) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq ave_stdev data".');
			exit;
		end;
		lsp:=Tcl_ObjLongString(argv[2]);
		gpx:=read_x_graph(lsp^);
		writestr(s,average_x_graph(gpx):fsr:fsd,' ',
			stdev_x_graph(gpx):fsr:fsd,' ',
			max_x_graph(gpx):fsr:fsd,' ',
			min_x_graph(gpx):fsr:fsd);
		dispose_x_graph(gpx);
		dispose_long_string(lsp);
		Tcl_SetReturnShortString(interp,s);
	end 
	else if option='linear_interpolate' then begin
{
<p>Interpolates between the two-dimensional points of <i>x_y_data</i> to obtain an estimate of <i>y</i> at <i>x</i>=<i>x_position</i>. If we pass "2.5" for the x position, and "0 0 10 10" for the x-y data, the routine will return "2.500000".</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq linear_interpolate x_position x_y_data".');
			exit;
		end;
		position:=Tcl_ObjReal(argv[2]);
		lsp:=Tcl_ObjLongString(argv[3]);
		gp:=read_xy_graph(lsp^);
		linear_interpolate(gp,position,interpolation);
		dispose_xy_graph(gp);
		dispose_long_string(lsp);
		writestr(s,interpolation:fsr:fsd);
		Tcl_SetReturnShortString(interp,s);
	end 
	else if option='nearest_neighbor' then begin
{
<p>Finds the closest point to <i>p</i> in a library of points. The point and the members of the library are all points in an <i>n</i>-dimensional space. When we call this routine, we can specify the library with the after the point by passing another string containing the library of <i>m</i> points. If we don't pass the library, the routine uses the library most recently passed. The routine stores the library in a global array so that it can use it again. We pass the point <i>p</i> as a string of <i>n</i> real numbers. The library we pass as a string of <i>m</i>&times;<i>n</i> real numbers separated by spaces. The value returned by the routine is an integer that specifies the library point that is closest to the <i>p</i>. The first library point we specify with integer 1 (one) and the last with integer <i>m</i>.</p>
}
		if (argc<>3) and (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq nearest_neighbor point ?library?".');
			exit;
		end;
		lsp:=Tcl_ObjLongString(argv[2]);
		num_columns:=word_count(lsp^);
		M:=new(matrix_ptr,1,num_columns);
		read_matrix(lsp^,M^);
		dispose_long_string(lsp);
		if argc=4 then begin
			lsp:=Tcl_ObjLongString(argv[3]);
			num_elements:=word_count(lsp^);
			if (num_elements mod num_columns) <> 0 then begin
				Tcl_SetReturnShortString(interp,
					'Library mismatch, num_elements mod num_columns <> 0.');
				exit;
			end;
			if (num_elements = 0) then begin
				Tcl_SetReturnShortString(interp,
					'Library error, num_elements = 0.');
				exit;
			end;
			if nearest_neighbor_library_ptr<>nil then 
				dispose(nearest_neighbor_library_ptr);
			nearest_neighbor_library_ptr:=
				new(matrix_ptr,num_elements div num_columns,num_columns);
			read_matrix(lsp^,nearest_neighbor_library_ptr^);
			dispose_long_string(lsp);
		end;
		if nearest_neighbor_library_ptr=nil then begin
			Tcl_SetReturnShortString(interp,'No library defined.');
			exit;
		end;
		writestr(s,nearest_neighbor(M^,nearest_neighbor_library_ptr^):1);
		dispose(M);
		Tcl_SetReturnShortString(interp,s);
	end 
	else if option='sum_sinusoids' then begin
{
<p>Adds two sinusoidal waves of the same frequency together. You specify the two waves with their amplitude and phase. The phase must be in radians. The amplitude is dimensionless. The result contains the amplitude and phase of the sum of the two waves. If we pass the numbers "1 0 1 0.1" to the routine, it will return "1.997500 0.050000".</p>
}
		if (argc<>6) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq sum_sinusoids a.amplitude a.phase b.amplitude b.phase".');
			exit;
		end;
		a.amplitude:=Tcl_ObjReal(argv[2]);
		a.phase:=Tcl_ObjReal(argv[3]);
		b.amplitude:=Tcl_ObjReal(argv[4]);
		b.phase:=Tcl_ObjReal(argv[5]);
		a:=sum_sinusoids(a,b);
		writestr(s,a.amplitude:fsr:fsd,' ',a.phase:fsr:fsd,' ');
		Tcl_SetReturnShortString(interp,s);
	end 
	else if option='frequency_components' then begin
{
<p>Calculates components of the <a href="http://en.wikipedia.org/wiki/Discrete_Fourier_transform">discrete fourier transform</a> of a real-valued waveform by repeated calls to <i>frequency_component</i> in <a href="http://alignment.hep.brandeis.edu/Software/Sources/utils.pas">utils.pas</a>. We specify the <i>M</i> components we want to calculate with a string of <i>M</i> frequencies, each of which is a multiple of the fundamental frequency of the waveform, 1/<i>NT</i>. The frequencies provided by a full discrete fourier transform of <i>N</i> real samples are <i>k</i>/<i>NT</i> for <i>k</i> such that 0&le;<i>k</i>&le;<i>N</i>&minus;1. If we want to obtain all <i>N</i>/2 components, we can use our <a href="#lwdaq_fft">lwdaq_fft</a> routine instead. The <i>frequency_components</i> routine is designed to provide a small number of components for real-valued input data.</p>

<pre>
lwdaq_config -fsr 1 -fsd 2
lwdaq frequency_components "0 1 2 3 4 5" "0 0 0 0 1 1 1 1"
0.50 0.00 0.65 3.50 0.00 -1.91 0.27 0.83 0.00 0.00 0.27 0.30 
</pre>

<p>Here we ask for components with frequencies "0 1 2 3 4 5" and we specify data "0 0 0 0 1 1 1 1". The routine returns a string containg the amplitude, <i>a</i>, and phase, &phi;, of each specified component, separated by spaces.</p>

<p>Because the <i>frequency_component</i> routine accepts only real-valued inputs, we are certain that component <i>k</i> for <i>K</i>&gt;0 will be the complex conjugate of component <i>N</i>&minus;<i>k</i>, which means the two components add together to form one component of double the maginitude but with the same phase as component <i>k</i>. Thus <i>frequency_component</i> doubles the magnitude of the <i>k</i>'th component for <i>k</i> equal to 1, 2,..<i>N</i>/2&minus;1 and leaves the phase unchanged.</p>

<p>The phase, &phi;, is in units of <i>T</i>, and refers to the phase of a sinusoid, so that the frequency component is</p>

<p><i>a</i>sin(2&pi;(<i>t</i>&minus;&phi;)<i>f</i>/<i>N</i>)</p>

<p>where <i>f</i> is the frequency we specified and <i>t</i> is the quantity that separates the samples. The quantity <i>t</i> might be time or distance.</p>

<p>The frequency need not be an integer, but if it is an integer, then this frequency will be one of those defined for the discrete fourier transform. There are times when choosing an exact frequency outside that finite set of periods is useful. For example, if we have 512 samples taken over 1 s, the discrete fourier transform contains components with frequencies 1 Hz, 2 Hz,.. 255 Hz. If we want to look for a signal at 33.3 Hz, we will find that the discrete fourier transform spreads 33.3 Hz into 33 Hz and 34 Hz, but neither component has the correct amplitude. By specifying a frequency of 33.3 Hz, we will obtain a more accurate estimate of a 33.3 Hz signal. Most of the time, however, the value of the transform outside the frequencies defined in the discrete transform is unreliable.</p>

<p>To improve its accuracy, the routine subtracts the average value of the waveform from each sample before it calculates the frequency components. To further improve the accuracy of the transform, we can apply a <a href="http://en.wikipedia.org/wiki/Window_function">window function</a> to <i>waveform</i> before it we call <i>frequency_component</i>. The window function smooths off the first and final few samples so that they converge upon the waveform's average value. We provide a linear window function with <a href="#window_function">window_function</a>.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq frequency_components frequencies waveform".');
			exit;
		end;
		lsp:=Tcl_ObjLongString(argv[2]);
		frequencies:=read_x_graph(lsp^);
		dispose_long_string(lsp);
		lsp:=Tcl_ObjLongString(argv[3]);
		signal:=read_x_graph(lsp^);
		average:=average_x_graph(signal);
		for i:=0 to signal^.num_points-1 do signal^[i]:=signal^[i]-average;
		lsp^:='';
		for i:=0 to frequencies^.num_points-1 do begin
			if frequencies^[i]=0 then begin
				amplitude:=average;
				offset:=0;
			end else begin
				frequency_component(frequencies^[i],signal,amplitude,offset);
			end;
			writestr(s,amplitude:fsr:fsd,' ',offset:fsr:fsd,' ');
			insert(s,lsp^,length(lsp^)+1);
		end;
		dispose_x_graph(signal);
		dispose_x_graph(frequencies);
		lwdaq_long_string:=lsp^;
		dispose_long_string(lsp);
		Tcl_SetReturnLongString(interp,lwdaq_long_string);
	end 
	else if option='window_function' then begin
{
<p>Applies a linear <a href="http://en.wikipedia.org/wiki/Window_function">window function</a> to a series of samples. The window function affects the first and last <i>extent</i> samples in <i>data</i>. The window function calculates the average value of the data, and then scales the deviation of the first and last <i>extent</i> samples so that the first sample and the last sample are now equal to the average, while the deviation of the other affected samples increases linearly up to the edge of the affected sample range. The function returns a new data string with the same number of samples, but the first and last samples are guaranteed to be the same. The window function is useful for preparing data for fourier transforms.</p>

<p>As an example, we would have:</p>

<pre>
lwdaq_config -fsd 2 -fsr 1
lwdaq window_function 5 "0 0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1"
0.50 0.40 0.30 0.20 0.10 0.00 0.00 0.00 0.00 0.00 1.00 1.00 1.00 1.00 1.00 0.90 0.80 0.70 0.60 0.50 
</pre>

<p>Here we see a step function being windowed so that the ends are at the average value. Note that we set the <i>fsd</i> (field size decimal) and <i>fsr</i> (field size real) configuration parameters so that we can get the output data all on one line.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq window_function extent data".');
			exit;
		end;
		extent:=Tcl_ObjInteger(argv[2]);
		lsp:=Tcl_ObjLongString(argv[3]);
		gpx:=read_x_graph(lsp^);
		window_function(gpx,extent);
		lsp^:='';
		for i:=0 to gpx^.num_points-1 do begin
			writestr(s,gpx^[i]:fsr:fsd,' ');
			insert(s,lsp^,length(lsp^)+1);
		end;
		dispose_x_graph(gpx);
		lwdaq_long_string:=lsp^;
		dispose_long_string(lsp);
		Tcl_SetReturnLongString(interp,lwdaq_long_string);
	end 
	else if option='glitch_filter' then begin
{
<p>Applies a glitch filter to a sequence of real-valued samples. Any change in sample value that is equal to or greater than <i>threshold</i> will be assumed to be a glitch. This sample is replaced in the data sequence with the previous sample's value. We continue until the sample returns to within less than <i>threshold</i> of the standing value. A threshold value of 0 disables the filter.</p>

<p>As an example, we would have:</p>

<pre>
lwdaq_config -fsd 2 -fsr 1
lwdaq glitch_filter 4.8 "0 0 7 0 1 2 3 20 20 -30 8 6"
0.00 0.00 0.00 0.00 1.00 2.00 3.00 3.00 3.00 3.00 3.00 6.00 
</pre>

<p>Here we see a glitch in the third sample being removed. We also see three glitches removed, but then what looks like it might be a good data point, at 8, removed from the data and replaced with the standing value.</p>
}
		if (argc<>4) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq glitch_filter threshold data".');
			exit;
		end;
		threshold:=Tcl_ObjReal(argv[2]);
		lsp:=Tcl_ObjLongString(argv[3]);
		gpx:=read_x_graph(lsp^);
		glitch_filter(gpx,threshold);
		lsp^:='';
		for i:=0 to gpx^.num_points-1 do begin
			writestr(s,gpx^[i]:fsr:fsd,' ');
			insert(s,lsp^,length(lsp^)+1);
		end;
		dispose_x_graph(gpx);
		lwdaq_long_string:=lsp^;
		dispose_long_string(lsp);
		Tcl_SetReturnLongString(interp,lwdaq_long_string);
	end 
	else if option='matrix_inverse' then begin
{
<p>Calculates the inverse of a square matrix. You pass the original matrix as a string of real numbers in <i>matrix</i>. The first number should be the top-left element in the matrix, the second number should be the element immediately to the right of the top-left element, and so on, proceeding from left to right, and then downwards to the bottom-right element. The command deduces the dimensions of the matrix from the number of elements, which must be an integer square. For more information about the matrix inverter, see matrix_inverse in utils.pas. The "lwdaq matrix_inverse" routine is inefficient in its use of the matrix_inverse function. The routine spends most of its time translating between TCL strings and Pascal floating point numbers. A 10x10 matrix inversion with random elements takes 1800 &mu;s on our 1 GHz iBook, of which only 100 &mu;s is spent calculating the inverse. The routine returns the inverse as a string of real numbers, in the same format as the original <i>matrix</i>.</p>
}
		if (argc<>3) then begin
			Tcl_SetReturnShortString(interp,'Wrong number of arguments, should be '
				+'"lwdaq matrix_inverse matrix".');
			exit;
		end;
		lsp:=Tcl_ObjLongString(argv[2]);
		num_elements:=word_count(lsp^);
		num_rows:=trunc(sqrt(num_elements));
		if sqrt(num_elements)-num_rows>small_real then begin
			Tcl_SetReturnShortString(interp,'Non-square matrix.');
			exit;
		end;
		M:=new(matrix_ptr,num_rows,num_rows);
		N:=new(matrix_ptr,num_rows,num_rows);
		read_matrix(lsp^,M^);
		matrix_inverse(M^,N^);
		lsp^:='';
		write_matrix(lsp^,N^);
		dispose(M);
		dispose(N);
		lwdaq_long_string:=lsp^;
		dispose_long_string(lsp);
		Tcl_SetReturnLongString(interp,lwdaq_long_string);
	end 
	else begin
		Tcl_SetReturnShortString(interp,'Bad option "'+option+'", must be one of '
			+' "ave_stdev bcam_from_global_point global_from_bcam_point'
			+' global_from_bcam_vector bcam_from_global_vector'
			+' bcam_source_bearing bcam_source_position bcam_image_position'
			+' wps_wire_plane xyz_plane_plane_intersection xyz_line_plane_intersection'
			+' straight_line_fit sum_sinusoids linear_interpolate'
			+' frequency_components window_function glitch_filter'
			+' matrix_inverse nearest_neighbor".');
		exit;
	end;
	
	if error_string<>'' then Tcl_SetReturnShortString(interp,error_string);
	lwdaq:=Tcl_OK;
end;


{
	lwdaq_init initializes the pascal run-time system, sets the initial values
	of all variables declared in this program and all its units, and installs
	the lwdaq commands in the tcl interpreter.
}
function lwdaq_init(interp:pointer):integer;
	attribute (name='Lwdaq_Init');

var
	p:pointer;
		
begin
{
	We try to initialize the TCL and TK stub libraries if USE_TCL_STUBS is defined,
	as it might be by a compiler option -DUSE_TCL_STUBS.
}
{$ifdef USE_TCL_STUBS}
	p:=tcl_initstubs(interp,'8.1',0);
	if (p=nil) then begin
		lwdaq_init:=Tcl_Error;
		exit;
	end;
	p:=tk_initstubs(interp,'8.1',0);
	if (p=nil) then begin
		lwdaq_init:=Tcl_Error;
		exit;
	end;
{$endif}
		
	initialize_pascal(0,nil,nil);
	initialize_main;	 
	
	gui_interp_ptr:=interp;
	gui_draw:=lwdaq_gui_draw;
	gui_writeln:=lwdaq_gui_writeln;
	gui_wait:=lwdaq_gui_wait;
	gui_support:=lwdaq_gui_support;
	
	p:=tcl_createobjcommand(interp,'lwdaq',lwdaq,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_config',lwdaq_config,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_draw',lwdaq_draw,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_graph',lwdaq_graph,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_filter',lwdaq_filter,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_fft',lwdaq_fft,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_create',lwdaq_image_create,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_contents',lwdaq_image_contents,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_characteristics',lwdaq_image_characteristics,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_histogram',lwdaq_image_histogram,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_profile',lwdaq_image_profile,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_exists',lwdaq_image_exists,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_results',lwdaq_image_results,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_destroy',lwdaq_image_destroy,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_image_manipulate',lwdaq_image_manipulate,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_data_manipulate',lwdaq_data_manipulate,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_photo_contents',lwdaq_photo_contents,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_rasnik',lwdaq_rasnik,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_rasnik_shift',lwdaq_rasnik_shift,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_wps',lwdaq_wps,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_bcam',lwdaq_bcam,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_diagnostic',lwdaq_diagnostic,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_gauge',lwdaq_gauge,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_flowmeter',lwdaq_flowmeter,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_voltmeter',lwdaq_voltmeter,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_rfpm',lwdaq_rfpm,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_inclinometer',lwdaq_inclinometer,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_recorder',lwdaq_recorder,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_calibration',lwdaq_calibration,0,nil);
	p:=tcl_createobjcommand(interp,'lwdaq_sampler',lwdaq_sampler,0,nil);
	lwdaq_init:=tcl_pkgprovide(interp,package_name,version_num);
end;

{
	lwdaq_unload deletes the above commands from the interpreter.
}
function lwdaq_unload(interp:pointer;flags:integer):integer;
	attribute (name='Lwdaq_Unload');

begin
	lwdaq_unload:=Tcl_Error;
end;

{
	lwdaq_safeinit returns an error because we don't have a 
	safe version of the initialization.
}
function lwdaq_safeinit(interp:pointer):integer;
	attribute (name='Lwdaq_SafeInit');

begin
	lwdaq_safeinit:=Tcl_Error;
end;

{
	lwdaq_safeunload returns an error because we don't have a
	safe version of the unload.
}
function lwdaq_safeunload(interp:pointer;flags:integer):integer;
	attribute (name='Lwdaq_SafeUnload');

begin
	lwdaq_safeunload:=Tcl_Error;
end;

{
		The main part of the program we never use. See the comments at the top.
}
begin
end.
