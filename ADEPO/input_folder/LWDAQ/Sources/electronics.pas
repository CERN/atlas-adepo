{
Routines for Analysis of Data Retrieved from Miscellaneous LWDAQ Devices
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

unit electronics;

interface

uses
	transforms,image_manip,images,utils;
	
var
	electronics_trace:xy_graph_ptr_type=nil;

function lwdaq_A2037_monitor(ip:image_ptr_type;
	t_min,t_max,v_min,v_max:real;
	ac_couple:boolean):short_string;

function lwdaq_A2053_gauge(ip:image_ptr_type;
	t_min,t_max,y_min,y_max:real;
	ac_couple:boolean;ref_bottom,ref_top:real;
	ave,stdev:boolean):short_string;

function lwdaq_A2053_flowmeter(ip:image_ptr_type;
	t_min,t_max,c_min,c_max:real;
	ref_bottom,ref_top:real):short_string;

function lwdaq_A2057_voltmeter(ip:image_ptr_type;
	t_min,t_max,v_min,v_max,v_trigger:real;
	ac_couple,positive_trigger,auto_calib:boolean):short_string;

function lwdaq_A2065_inclinometer(ip:image_ptr_type;
	v_trigger,v_min,v_max,harmonic:real):short_string;
	
function lwdaq_A3007_recorder(ip:image_ptr_type;command:short_string):long_string_ptr;

function lwdaq_A3008_rfpm(ip:image_ptr_type;
	v_min,v_max:real;rms:boolean):short_string;

function lwdaq_A2100_sampler(ip:image_ptr_type;command:short_string):long_string_ptr;


implementation


{
	image_byte returns the n'th byte after the first byte in the
	second row.
}
function image_byte(ip:image_ptr_type;n:integer):integer;
begin
	image_byte:=ip^.intensity[(n div ip^.i_size)+1,(n mod ip^.i_size)];
end;

{
	write_image_byte writes to the n'th byte after the first byte
	in the second row.
}
procedure write_image_byte(ip:image_ptr_type;b:byte;n:integer);
begin
	ip^.intensity[(n div ip^.i_size)+1,(n mod ip^.i_size)]:=b;
end;

{
	sample_A2037E_adc16 returns the voltage seen at the input of the
	sixteen-bit ACD of an A2037E for a given channel number and sample
	number. The routine finds the sample in an image (which acts as a block
	of ADC data). The first row of the image contains image dimensions and a
	results string, as is usual for LWDAQ images. The second and third rows
	(numbers 1 and 2) contain the ADC samples for channel zero. There are
	i_size samples per channel. If you specify channel zero, you can refer
	to samples as if they were all taken from a single channel much longer
	than i_size samples. The image will hold up to i_size*(j_size-1)/2
	samples.
}
function sample_A2037E_adc16(ip:image_ptr_type;channel_num,sample_num:integer):real;

const
	v_per_count=20/$10000; {+-10-V full range, signed sixteen bit output}
	sample_size=2; {bytes per adc sample}

var 
	i,j:integer;

begin
	j:=1+(channel_num*sample_size)+(sample_num*sample_size div ip^.i_size);
	i:=(sample_num*sample_size mod ip^.i_size);
	if (j>ip^.j_size-1) or (i>ip^.i_size-1) then
		sample_A2037E_adc16:=0
	else 
		sample_A2037E_adc16:=v_per_count*
			local_from_big_endian_shortint(
				shortint_ptr(pointer(@ip^.intensity[j,i]))^);
end;

{
	sample_A2037E_adc8 is similar to the adc16 routine, but each channel
	consists of only one row in the image, because the samples are each only
	one byte long. Once again, you can treat the image as one extended list
	of samples by specifying channel zero. The image will hold up to
	i_size*(j_size-1) samples.
}
function sample_A2037E_adc8(ip:image_ptr_type;channel_num,sample_num:integer):real;

const
	v_per_count=1/$100; {0..1 V unsigned output}
	v_offset=0.5; {added to input to place 0V in middle of ADC range}
	sample_size=1; {bytes per adc sample}

var 
	i,j:integer;

begin
	j:=1+(channel_num*sample_size)+(sample_num*sample_size div ip^.i_size);
	i:=(sample_num*sample_size mod ip^.i_size);
	if (j>ip^.j_size-1) or (i>ip^.i_size-1) then
		sample_A2037E_adc8:=0
	else 
		sample_A2037E_adc8:=v_per_count*ip^.intensity[j,i]-v_offset;
end;

{
	draw_oscilloscope_scale fills the overlay, so that it is white, and 
	draws an oscilloscope scale in it with the specified number of divisions
	across the width and height.
}
procedure draw_oscilloscope_scale(ip:image_ptr_type;num_divisions:integer);

const
	extents_per_width=2;
	scale_color=light_gray_color;
	
var
	div_extent,div_num:integer;
	rect:ij_rectangle_type;
	
begin
	fill_overlay(ip);
	if num_divisions<extents_per_width then exit;
	div_extent:=num_divisions div extents_per_width;
	for div_num:=0 to div_extent do begin
		rect.left:=0;
		rect.right:=ip^.i_size-1;
		rect.top:=round(div_num*one_half*ip^.j_size/div_extent);
		rect.bottom:=ip^.j_size-1-round(div_num*one_half*ip^.j_size/div_extent);
		display_ccd_rectangle(ip,rect,scale_color);
	end;
	for div_num:=0 to div_extent do begin
		rect.left:=round(div_num*one_half*ip^.i_size/div_extent);
		rect.right:=ip^.i_size-1-round(div_num*one_half*ip^.i_size/div_extent);
		rect.top:=0;
		rect.bottom:=ip^.j_size-1;
		display_ccd_rectangle(ip,rect,scale_color);
	end;
end;

{
	lwdaq_A2037_monitor analyzes sixteen-bit adc samples from the driver supplies
	to calculate the power supply currents and voltages.
}
function lwdaq_A2037_monitor(ip:image_ptr_type;
	t_min,t_max,v_min,v_max:real;
	ac_couple:boolean):short_string;


const
	num_divisions=10; {number of display divisions across width of height}
	rn=490; {average network resistance, some drivers use 470, some use 511}
	reference=5.03; {measured for our first lot of ZBR500s}
	beta=rn/(100000+rn); {divider with 100k}
	alpha=0.47; {current-monitoring resistance in ohms}
	gamma=alpha/2; {5-V current monitoring resistance in ohms}
	nigcf=(rn-4)/(rn-1); {negative input gain correction factor}

var 
	result,input_string:short_string='';
	p15V,p15I,p5V,p5I,n15V,n15I:xy_graph_ptr_type; {voltages in V, currents in mA}
	c_gain,d_gain:xy_graph_ptr_type;{properties of adc input}
	n:integer;
	rect:ij_rectangle_type;
	p15V_ave,p5V_ave,n15V_ave,period:real=0;
	sv,an,hv,fv,lt,tr:real;

begin
	lwdaq_A2037_monitor:='ERROR: Diagnostic analysis failed.';
	if not valid_image_ptr(ip) then exit;
	
	input_string:=ip^.results;
	sv:=read_real(input_string);
	an:=read_real(input_string);
	hv:=read_real(input_string);
	fv:=read_real(input_string);
	lt:=read_real(input_string);
	tr:=read_real(input_string);
	period:=read_real(input_string);
	if (period<=0) then period:=1;
	
	writestr(result,sv:1:0,' ',an:1:0,' ',hv:1:0,' ',fv:1:0,' ',lt:1:0,' ',tr:1:0);

	c_gain:=new_xy_graph(ip^.i_size);
	d_gain:=new_xy_graph(ip^.i_size);
	p15V:=new_xy_graph(ip^.i_size);
	p15I:=new_xy_graph(ip^.i_size);
	p5V:=new_xy_graph(ip^.i_size);
	p5I:=new_xy_graph(ip^.i_size);
	n15V:=new_xy_graph(ip^.i_size);
	n15I:=new_xy_graph(ip^.i_size);
	for n:=0 to ip^.i_size-1 do begin
		c_gain^[n].y:=(sample_A2037E_adc16(ip,1,n)-sample_A2037E_adc16(ip,8,n))
			/reference;
		d_gain^[n].y:=(sample_A2037E_adc16(ip,0,n)-sample_A2037E_adc16(ip,8,n))
			/(reference*beta);
		if d_gain^[n].y=0 then d_gain^[n].y:=1;
		p15V^[n].y:=(sample_A2037E_adc16(ip,3,n)-sample_A2037E_adc16(ip,8,n))
			/(d_gain^[n].y*beta);
		p15I^[n].y:=(sample_A2037E_adc16(ip,2,n)-sample_A2037E_adc16(ip,8,n)
			-c_gain^[n].y*p15V^[n].y)*mA_per_A/(d_gain^[n].y*alpha);
		p5V^[n].y:=(sample_A2037E_adc16(ip,5,n)-sample_A2037E_adc16(ip,8,n))
			/(d_gain^[n].y*beta);
		p5I^[n].y:=(sample_A2037E_adc16(ip,4,n)-sample_A2037E_adc16(ip,8,n)
			-c_gain^[n].y*p5V^[n].y)*mA_per_A/(d_gain^[n].y*gamma);
		n15V^[n].y:=-(sample_A2037E_adc16(ip,7,n)
			-sample_A2037E_adc16(ip,8,n))/(d_gain^[n].y*beta*nigcf);
		n15I^[n].y:=(sample_A2037E_adc16(ip,6,n)-sample_A2037E_adc16(ip,8,n)
			-c_gain^[n].y*n15V^[n].y)*mA_per_A/(d_gain^[n].y*alpha);
		c_gain^[n].x:=period*n;
		d_gain^[n].x:=period*n;
		p15V^[n].x:=period*n;
		p15I^[n].x:=period*n;
		p5V^[n].x:=period*n;
		p5I^[n].x:=period*n;
		n15V^[n].x:=period*n;
		n15I^[n].x:=period*n;
	end;
	p15V_ave:=average_xy_graph(p15V);
	p5V_ave:=average_xy_graph(p5V);
	n15V_ave:=average_xy_graph(n15V);
	writestr(result,result,' ',
		p15V_ave:5:3,' ',average_xy_graph(p15I):5:3,' ',
		p5V_ave:5:3,' ',average_xy_graph(p5I):5:3,' ',
		n15V_ave:5:3,' ',average_xy_graph(n15I):5:3,' ',
		average_xy_graph(c_gain):6:4,' ',average_xy_graph(d_gain):3:1);
		
	draw_oscilloscope_scale(ip,num_divisions);
	if ac_couple then begin
		display_real_graph(ip,p15V,yellow_color,
			t_min,t_max,v_min+p15V_ave,v_max+p15V_ave,0,0);
		display_real_graph(ip,p5V,red_color,
			t_min,t_max,v_min+p5V_ave,v_max+p5V_ave,0,0);
		display_real_graph(ip,n15V,green_color,
			t_min,t_max,v_min+n15V_ave,v_max+n15V_ave,0,0);
	end 
	else begin
		display_real_graph(ip,p15V,yellow_color,t_min,t_max,v_min,v_max,0,0);
		display_real_graph(ip,p5V,red_color,t_min,t_max,v_min,v_max,0,0);
		display_real_graph(ip,n15V,green_color,t_min,t_max,v_min,v_max,0,0);
	end;
	dispose_xy_graph(c_gain);
	dispose_xy_graph(d_gain);
	dispose_xy_graph(p15V);
	dispose_xy_graph(p15I);
	dispose_xy_graph(p5V);
	dispose_xy_graph(p5I);
	dispose_xy_graph(n15V);
	dispose_xy_graph(n15I);
	
	lwdaq_A2037_monitor:=result;
end;

{
	lwdaq_A2053_gauge takes adc samples from an A2053 or compatible device
	and converts them into sensor measurements. 
}
function lwdaq_A2053_gauge(ip:image_ptr_type;
	t_min,t_max,y_min,y_max:real;
	ac_couple:boolean;ref_bottom,ref_top:real;
	ave,stdev:boolean):short_string;

const
	num_divisions=10; 
	max_num_channels=30;
	ref_bottom_row=0;
	channel_row=1;
	ref_top_row=2;
	rows_per_channel=3;

var 
	result,input_string:short_string='';
	gauge:xy_graph_ptr_type; 
	n,channel_num,num_channels:integer;
	gauge_ave,ref_top_voltage,ref_bottom_voltage,period:real;
	rect:ij_rectangle_type;

begin
	lwdaq_A2053_gauge:='ERROR: Gauge analysis failed.';
	if not valid_image_ptr(ip) then exit;
	
	if abs(ref_top-ref_bottom)<small_real then begin
		report_error('ref_top=ref_bottom.');
		exit;
	end;

	input_string:=ip^.results;
	period:=read_real(input_string);
	if (period<=0) then period:=1;
	num_channels:=read_integer(input_string);
	if num_channels=0 then num_channels:=1;
	
	draw_oscilloscope_scale(ip,num_divisions);

	gauge:=new_xy_graph(ip^.i_size);
	
	for channel_num:=0 to num_channels-1 do begin
		ref_bottom_voltage:=0;
		for n:=0 to ip^.i_size-1 do
			ref_bottom_voltage:=ref_bottom_voltage
				+sample_A2037E_adc16(ip,ref_bottom_row
					+rows_per_channel*channel_num,n);
		ref_bottom_voltage:=ref_bottom_voltage/ip^.i_size;
				
		ref_top_voltage:=0;
		for n:=0 to ip^.i_size-1 do
			ref_top_voltage:=ref_top_voltage
				+sample_A2037E_adc16(ip,ref_top_row
					+rows_per_channel*channel_num,n);
		ref_top_voltage:=ref_top_voltage/ip^.i_size;

		if abs(ref_top_voltage-ref_bottom_voltage)<small_real then 
			ref_top_voltage:=ref_bottom_voltage+1;

		for n:=0 to ip^.i_size-1 do begin
			gauge^[n].y:=
				(sample_A2037E_adc16(ip,channel_row
						+rows_per_channel*channel_num,n)
							-ref_bottom_voltage)
				/(ref_top_voltage-ref_bottom_voltage)
				*(ref_top-ref_bottom) 
				+ref_bottom;
			gauge^[n].x:=period*n;
		end;
		gauge_ave:=average_xy_graph(gauge);

		if ac_couple then
			display_real_graph(ip,gauge,
				overlay_color_from_integer(channel_num),
				t_min,t_max,y_min+gauge_ave,y_max+gauge_ave,0,0)
		else 
			display_real_graph(ip,gauge,
				overlay_color_from_integer(channel_num),
				t_min,t_max,y_min,y_max,0,0);

		if ave then writestr(result,result,gauge_ave:5:3,' ');
		if stdev then writestr(result,result,stdev_xy_graph(gauge):5:3,' ');
	end;

	if electronics_trace<>nil then dispose_xy_graph(electronics_trace);
	electronics_trace:=gauge;

	lwdaq_A2053_gauge:=result;
end;

{
	lwdaq_A2053_flowmeter takes adc samples from an A2053 and converts them
	into temperature sensor measurements. It plots the temperatures in an
	oscilloscope display.
}
function lwdaq_A2053_flowmeter(ip:image_ptr_type;
	t_min,t_max,c_min,c_max:real;
	ref_bottom,ref_top:real):short_string;

const
	num_divisions=10; {number of display divisions across width of height}
	ambient_divisions=1;{number of divisions dedicated to ambient measurement}
	skip_divisions=1;{number of divisions to skip at cool-down start}
	min_num_cooling_samples=2;

var 
	result,input_string:short_string='';
	temperature,log_temperature,fit,log_fit:xy_graph_ptr_type; 
	log_temp_data:xyz_graph_ptr_type;
	num_ambient_samples,num_cooling_samples:integer;
	n,cooling_start_index:integer;
	ref_top_voltage,ref_bottom_voltage,period:real;
	slope,intercept,rms_residual,t_relative:real;
	peak_temp,start_temp,end_temp,ambient_temp:real;
	rect:ij_rectangle_type;

begin
	lwdaq_A2053_flowmeter:='ERROR: Flowmeter analysis failed.';
	if not valid_image_ptr(ip) then exit;
	
	if abs(ref_top-ref_bottom)<small_real then begin
		report_error('ref_top=ref_bottom.');
		exit;
	end;

	input_string:=ip^.results;
	period:=read_real(input_string);
	if (period<=0) then period:=1;
	draw_oscilloscope_scale(ip,num_divisions);

	ref_bottom_voltage:=0;
	for n:=0 to ip^.i_size-1 do
		ref_bottom_voltage:=ref_bottom_voltage
			+sample_A2037E_adc16(ip,0,n);
	ref_bottom_voltage:=ref_bottom_voltage/ip^.i_size;

	ref_top_voltage:=0;
	for n:=0 to ip^.i_size-1 do
		ref_top_voltage:=ref_top_voltage
			+sample_A2037E_adc16(ip,2,n);
	ref_top_voltage:=ref_top_voltage/ip^.i_size;
	
	if (ref_top_voltage=ref_bottom_voltage) then begin
		report_error('ref_top_voltage=ref_bottom_voltage.');
		exit;
	end;

	temperature:=new_xy_graph(ip^.i_size);
	for n:=0 to ip^.i_size-1 do begin
		temperature^[n].y:=
			(sample_A2037E_adc16(ip,1,n)-ref_bottom_voltage)
			/(ref_top_voltage-ref_bottom_voltage)
			*(ref_top-ref_bottom) 
			+ref_bottom;
		temperature^[n].x:=period*n;
	end;

	num_ambient_samples:=round(ambient_divisions*ip^.i_size/num_divisions)-1;
	cooling_start_index:=round(
		(ambient_divisions+skip_divisions)
		*ip^.i_size/num_divisions
		+2);
	num_cooling_samples:=ip^.i_size-cooling_start_index;
	if num_cooling_samples<min_num_cooling_samples then begin
		report_error('num_cooling_samples<min_num_cooling_samples.');
		exit;
	end;
	
	ambient_temp:=0;
	for n:=0 to num_ambient_samples-1 do
		ambient_temp:=ambient_temp+temperature^[n].y;
	ambient_temp:=ambient_temp/num_ambient_samples;
	peak_temp:=temperature^[num_ambient_samples+2].y;
	start_temp:=temperature^[ip^.i_size-num_cooling_samples].y;
	end_temp:=temperature^[ip^.i_size-1].y;
	log_temperature:=new_xy_graph(num_cooling_samples);
	for n:=0 to num_cooling_samples-1 do begin
		t_relative:=temperature^[n+cooling_start_index].y-ambient_temp;
		if t_relative>0 then
			log_temperature^[n].y:=ln(t_relative)
		else begin
			report_error('t_relative<=0 at n='
				+string_from_integer(n,1)+'.');
			exit;
		end;
		log_temperature^[n].x:=temperature^[n+cooling_start_index].x;
	end;
	straight_line_fit(log_temperature,slope,intercept,rms_residual);

	log_fit:=new_xy_graph(num_cooling_samples);
	for n:=0 to num_cooling_samples-1 do begin
		log_fit^[n].y:=log_temperature^[n].x*slope+intercept;
		log_fit^[n].x:=log_temperature^[n].x;
	end;

	rms_residual:=0;
	fit:=new_xy_graph(num_cooling_samples);
	for n:=0 to num_cooling_samples-1 do begin
		fit^[n].y:=exp(log_fit^[n].y)+ambient_temp;
		fit^[n].x:=log_fit^[n].x;
		rms_residual:=rms_residual
			+sqr(temperature^[n+cooling_start_index].y-fit^[n].y);
	end;
	rms_residual:=sqrt(rms_residual/num_cooling_samples);

	display_real_graph(ip,log_fit,green_color,t_min,t_max,0,0,0,0);
	display_real_graph(ip,log_temperature,red_color,t_min,t_max,0,0,0,0);
	display_real_graph(ip,fit,
		green_color,t_min,t_max,c_min+ambient_temp,c_max+ambient_temp,0,0);
	display_real_graph(ip,temperature,
		red_color,t_min,t_max,c_min+ambient_temp,c_max+ambient_temp,0,0);
	dispose_xy_graph(fit);
	dispose_xy_graph(log_fit);
	dispose_xy_graph(log_temperature);

	if electronics_trace<>nil then dispose_xy_graph(electronics_trace);
	electronics_trace:=temperature;

	writestr(result,-slope:8:6,' ',rms_residual:8:6,' ',
		ambient_temp:5:3,' ',
		peak_temp-ambient_temp:5:3,' ',
		start_temp-ambient_temp:5:3,' ',
		end_temp-ambient_temp:5:3);
	
	lwdaq_A2053_flowmeter:=result;
end;

{
	lwdaq_A2057_voltmeter takes sixten bit adc samples in an image, together with
	trigger parameters, plots an osciloscope output, and returns the averge, standard
	deviation and fundamental frequency of the input to the A2057. When auto_calib is
	set, the routine uses the 0-V and 5-V reference inputs to get the input voltage 
	correct.
}
function lwdaq_A2057_voltmeter(ip:image_ptr_type;
	t_min,t_max,v_min,v_max,v_trigger:real;
	ac_couple,positive_trigger,auto_calib:boolean):short_string;


const
	num_divisions=10; {number of display divisions across width and height}
	max_redundancy_factor=4; 
	min_redundancy_factor=1;
	max_num_channels=8;
	min_channel_gain=0.001;
	max_channel_gain=1000;
	
var 
	result,input_string:short_string='';
	trace,reference,transform:xy_graph_ptr_type;
	subset:x_graph_ptr_type;
	n,num_samples,num_channels,channel_num:integer;
	subset_size,redundancy_factor:integer;
	ave,stdev,period,frequency,amplitude:real=0;
	ref_top_V,ref_bottom_V,ref_bottom,ref_top,channel_gain:real=0;
	trigger:real;
	
begin
	lwdaq_A2057_voltmeter:='ERROR: Voltmeter analysis failed.';
	if not valid_image_ptr(ip) then exit;
	
	input_string:=ip^.results;
	period:=read_real(input_string);
	if (period<=0) then period:=1;
	ref_bottom_V:=read_real(input_string);
	ref_top_V:=read_real(input_string);
	if (abs(ref_top_V-ref_bottom_V)<small_real) and auto_calib then begin
		report_error('ref_bottom_V=ref_top_V with auto_calib.');
		exit;
	end;
	channel_gain:=read_real(input_string);
	if (abs(channel_gain)<min_channel_gain) or 
			(abs(channel_gain)>max_channel_gain) then begin
		report_error('Invalid channel_gain.');
		exit;
	end;
	redundancy_factor:=read_integer(input_string);
	if (redundancy_factor>max_redundancy_factor) or 
			(redundancy_factor<min_redundancy_factor) then begin
		report_error('Invalid redundancy_factor.');
		exit;
	end;
	num_channels:=read_integer(input_string);
	if (num_channels<1) or (num_channels>max_num_channels) then 
		num_channels:=1;
		
	draw_oscilloscope_scale(ip,num_divisions);

	if auto_calib then begin
		reference:=new_xy_graph(ip^.i_size);
		for n:=0 to ip^.i_size-1 do begin
			reference^[n].y:=sample_A2037E_adc16(ip,0,n);
			reference^[n].x:=n;
		end;
		ref_bottom:=average_xy_graph(reference);	
		for n:=0 to ip^.i_size-1 do begin
			reference^[n].y:=sample_A2037E_adc16(ip,redundancy_factor*num_channels+1,n);
			reference^[n].x:=n;
		end;
		ref_top:=average_xy_graph(reference);	
		dispose_xy_graph(reference);
		if abs(ref_top-ref_bottom)<small_real then begin
			report_error('ref_top=ref_bottom with auto_calib');
			exit;
		end;
	end;

	num_samples:=ip^.i_size*redundancy_factor;
	trace:=new_xy_graph(num_samples);

	for channel_num:=0 to num_channels-1 do begin
{
	Extract channel voltages from the image.
}
		for n:=0 to num_samples-1 do begin
			trace^[n].x:=period*n;
			trace^[n].y:=sample_A2037E_adc16(ip,redundancy_factor*channel_num+1,n);
		end;
{
	If we are asking for auto-calibration using the top and bottom reference
	voltages, adjust the trace voltage.
}
		if auto_calib then
			for n:=0 to num_samples-1 do
				trace^[n].y:=(trace^[n].y-ref_bottom)
					/ (ref_top-ref_bottom)
					* (ref_top_V-ref_bottom_V)
					/ channel_gain
					+ ref_bottom_V;
		ave:=average_xy_graph(trace);
		stdev:=stdev_xy_graph(trace);
{
	If we want to ac-couple the signal, subtract its average value now.
}
		if ac_couple then
			for n:=0 to num_samples-1 do
				trace^[n].y:=trace^[n].y-ave;
{
	Find the sample just before the trigger event.
}
		trigger:=0;
		n:=0;
		while (trigger=0) and (n<num_samples-1) do begin
			if (positive_trigger and 
				(trace^[n].y<=v_trigger) and 
				(trace^[n+1].y>v_trigger)) 
					or
				(not positive_trigger and 
				(trace^[n].y>=v_trigger) and 
				(trace^[n+1].y<v_trigger)) then begin
				trigger:=n;
			end;
			inc(n);
		end;
{
	If we have found a trigger, refine the trigger instant for fractions of a sample 
	period.
}
		if (trigger<>0) then begin
			n:=round(trigger);
			if abs(trace^[n+1].y-trace^[n].y)>small_real then 
				trigger:=n+(v_trigger-trace^[n].y)/(trace^[n+1].y-trace^[n].y);
		end;
{
	Use the trigger to offset the time axis of the trace, making the trigger instant
	the time zero instant.
}
		for n:=0 to num_samples-1 do trace^[n].x:=trace^[n].x-trigger*period;
{
	Display a graph of the voltage versus time, with time zero representing the moment
	of the first trigger.
}
		display_real_graph(ip,trace,
			overlay_color_from_integer(channel_num),
			t_min,t_max,v_min,v_max,0,0);
{
	Apply a fourier transform to the data to obtain the fundamental frequency, should
	such a frequency exist.
}
		subset_size:=1;
		while (subset_size<=num_samples/2.0) do subset_size:=subset_size*2;
		subset:=new_x_graph(subset_size);		
		for n:=0 to subset_size-1 do subset^[n]:=trace^[n].y;
		transform:=fft_real(subset);
		dispose_x_graph(subset);
		amplitude:=0;
		frequency:=0;
		for n:=1 to (subset_size div 2)-1 do begin
			if transform^[n].x>amplitude then begin
				amplitude:=transform^[n].x;
				frequency:=n/subset_size/period;
			end;
		end;
		dispose_xy_graph(transform);
{
	Add measurements to the result string.
}
		writestr(result,result,ave:fsr:fsd,' ',stdev:fsr:fsd,' ',
			frequency:fsr:fsd,' ',amplitude:fsr:fsd,' ');
	end;
{
	We make the final trace available with a global pointer, after disposing of the pre-existing
	trace, should it exist. Note that if we displayed more than one channel, only the final 
	channel's trace will be available.
}
	if electronics_trace<>nil then dispose_xy_graph(electronics_trace);
	electronics_trace:=trace;
	
	lwdaq_A2057_voltmeter:=result;
end;

{
	lwdaq_A2065_inclinometer takes an Inclinometer instrument image and
	calculates the amplitude of each eight-bit digitized waveform in the
	image. We specify the number of sinusoidal periods in each waveform,
	and the routine assumes that the period of all sinusoids is the same.
	The routine draws the waveforms in the image overlay for display by
	the Inclinometer.
	
}
function lwdaq_A2065_inclinometer(ip:image_ptr_type;
	v_trigger,v_min,v_max,harmonic:real):short_string;


const
	num_divisions=10; {number of display divisions across width and height}
	startup_skip=10; {gets over the ADC's pipeline}
	max_redundancy_factor=4; {protects routine from bad redundancy_factor integer}
	max_num_channels=20; {protects routine from bad num_channels integer}
	sample_size=2;{bytes per sample}
	
var 
	result,input_string:short_string='';
	trace:xy_graph_ptr_type;
	signal:x_graph_ptr_type;
	n,num_samples,num_channels,channel_num:integer;
	redundancy_factor,trigger:integer;
	amplitude,offset,period:real;
	
begin
	lwdaq_A2065_inclinometer:='ERROR: Inclinometer analysis failed.';
	if not valid_image_ptr(ip) then exit;
	
	draw_oscilloscope_scale(ip,num_divisions);

	input_string:=ip^.results;
	num_samples:=read_integer(input_string);
	if (num_samples>(ip^.j_size-1)*ip^.i_size/sample_size) or (num_samples<1) then begin
		report_error('Invalid num_samples.');
		exit;
	end;
	redundancy_factor:=read_integer(input_string);
	if (redundancy_factor>max_redundancy_factor) or (redundancy_factor<=1) then begin
		report_error('Invalid redundancy_factor.');
		exit;
	end;
	num_channels:=read_integer(input_string);
	if (num_channels>max_num_channels) or (num_channels<=0) then begin
		report_error('Invalid num_channels.');
		exit;
	end;

	trace:=new_xy_graph(num_samples);
	signal:=new_x_graph(num_samples);

	for channel_num:=0 to num_channels-1 do begin
		trigger:=startup_skip;
		n:=startup_skip;
		while n<num_samples*(redundancy_factor-1) do begin
			inc(n);
			if (sample_A2037E_adc16(
					ip,0,redundancy_factor*channel_num*num_samples+n)
				<= v_trigger) and (sample_A2037E_adc16(
					ip,0,redundancy_factor*channel_num*num_samples+n+1)
				> v_trigger) then begin
				trigger:=n;
			end;
		end;
		for n:=0 to num_samples-1 do begin
			trace^[n].x:=n;
			trace^[n].y:=sample_A2037E_adc16(ip,0,
				redundancy_factor*channel_num*num_samples+n+trigger);
			signal^[n]:=trace^[n].y;
		end;
		display_real_graph(ip,trace,
			overlay_color_from_integer(channel_num),
				0,num_samples-1,v_min,v_max,0,0);
		if (harmonic>0) then period:=num_samples/harmonic
		else period:=0;
		calculate_ft_term(period,signal,amplitude,offset);
		writestr(result,result,' ',amplitude:fsr:fsd);
	end;
	dispose_x_graph(signal);
{
	We make the trace available with a global pointer, after disposing of the pre-existing
	trace, should it exist.
}
	if electronics_trace<>nil then dispose_xy_graph(electronics_trace);
	electronics_trace:=trace;

	lwdaq_A2065_inclinometer:=result;
end;

{
	lwdaq_A3007_recorder analyzes four-byte Recorder Messages. It
	assumes that the first byte of the first image row is the first
	byte of a message. Each message takes the following form: an 
	eight-bit channel number, a sixteen-bit value, and an eight-bit 
	time stamp.
	
	In some cases, following aborted data acquisition, it is possible
	for the data block to be aligned incorrectly, so that the first
	byte of the block is not the first byte of a message, but instead
	the second, third, or fourth byte of an incomplete message. The
	routine does not handle such exceptions. Instead, shift the image
	data one byte to the left and try again.

	The routine returns a string whose contents depend upon the
	routine's command string. We refer to the instructions as they
	appear in the command string.

	The "plot" instruction tells the routine to plot all messages
	received from the channels you specify. The two parameters after
	the plot instruction specify the minimum and maximum values of the
	vertical axis. The next parameter is either AC or DC, to specify
	the display coupling. After these three, you add the identifiers
	of the channels you want to plot. To specify all channels, use a
	"*". The routine returns a summary result of the form "id_num
	num_message min/ave max/stdev" for each selected channel. For the
	clock message channel, id_num=0, the routine gives the start and
	end clock samples. For other channels, it gives the average and
	standard deviation of the samples received. The final two numbers
	in the summary result are the invalid_id code followed by the
	number of messages the routine did not plot.

	The "print" instruction returns the error_report string followed by
	the content of all messages, or a subrange of messages. In the
	event of analysis failure, "print" will assume messages are
	aligned with the first data byte in the image, and print out the
	contents of all messages, regardless of errors found. When
	analysis fails because there are too many messages in the image,
	the result string returned by print is likely to be cut off at the
	end. The "print" instruction tries to read first_message and 
	last_message out of the command string. If they are present, the
	routine uses these as the first and last message numbers it
	writes to its return string. Otherwise it returns all messages.
	
	The "extract" instruction tells the routine to return a string
	containing all messages from a specified channel. The routine
	returns each message on a separate line. On each line is the time
	of the message in ticks from the beginning of the image time
	interval, followed by the data value. The command writes
	the following numbers into ip^.results: the number of clock
	messages in the image and the number of samples it extracted.

	The "reconstruct" instruction tells the routine to reconstruct the
	signal from a particular channel, with the assumption that the
	transmission is periodic with some scattering of transmission
	instants to avoid systematic collisions. Where messages sare
	missing from the data, the routine adds substitute messages. It
	removes duplicate messages and messages that occur at invalid
	moments in time. The result of reconstruction is a sequence of
	messages with none missing and none extra. The instruction string
	for the "reconstruct" instruction begins with the word
	"reconstruct" and is followed by several paramters. The first
	parameter is the channel number of the message sequence you want
	to reconstruct. The second parameter is its nominal sampling
	period in clock ticks. The third parameter is the channel's
	transmission scatter in clock ticks on either side of the nominal
	transmission instant. Transmitters use random displacement of
	their transmission instant to avoid systematic collision with
	other transmitters. For the Subcutaneous Transmitter A3013A, the
	scatter is eight ticks on a Data Receiver A3018. The fourth
	parameter is the channel's most recent correct sample value, which
	we call the "standing value" of the channel. If you don't specify
	this parameter, "reconstruct" assumes it to be zero. After the
	fourth parameter, you have the option of specifying any unaccepted
	samples from previous data acquisitions. These you describe each
	with one number giving their sample number. The reconstruct
	routine assumes their timestamps are zero ticks. The result string
	contains the reconstructed message stream with one message per
	line. Each message is represented by the time it occured, in ticks
	after the first clock in the image time interval, and the message
	data value. The "reconstruct" command writes the following numbers
	into ip^.results: the number of clock messages in the image, the
	number of messages in the reconstructed messages stream, the
	number of rejected messages, the number of substitute messages,
	and any unaccepted message values it found in a transmission
	window that overlaps the end of the image time interval.

	The "clocks" instruction returns a the number of errors in the
	sequence of clock messages, the number of clock messages, the
	total number of messages from all channels, and the byte location
	clock messages specified by integers following the stats
	instruction. The command "clocks 0 100" might return "0 640 128 0
	500" when passed a 2560-byte block of messages containing 128
	valid clocks and 512 messages from non-clock channels. The last
	two numbers are the byte location of the 1st clock message and the
	byte location of the 101st clock message. A negative index specifies
	a clock message with respect to the end of the message block. Thus
	"-1" specifies the last clock message.
	
	The "list" instruction returns a list of channel numbers and 
	the number of samples in the channel. Channels with no samples
	are omitted from the list. The list takes the form of the channel
	numbers and numbers of samples separated by spaces.
	
	The "get" instruction performs no analysis of messages, but instead
	returns only the id, value, and timestamp of a list of messages. We
	Specify each message with its index. The first message it message 
	zero. A message index greater than the maximum number of messages 
	the image can hold, or less than zero, will return zero values for
	all parameters.
}
function lwdaq_A3007_recorder(ip:image_ptr_type;command:short_string):long_string_ptr;
	
const
	max_num_candidates=100;
	message_length=4;
	max_num_reports=5;
	num_divisions=0;
	min_sample=0;
	max_sample=65535;
	min_id=0;
	max_id=15;
	invalid_id=-1;
	clock_id=min_id;
	clock_period=256;
	min_period=16;
	max_period=1024;
	window_border=2;
	max_print_length=long_string_length-short_string_length;
	min_reconstruct_clocks=8;
	
type
	message_type=record
		id:integer;
		sample:integer;
		timestamp:integer;
		time:integer;
	end;
	message_array_type(length:integer) = array [0..length-1] of message_type;
	message_array_ptr_type=^message_array_type;
	
var 
	max_num_messages:integer=0;
	mp,msp:message_array_ptr_type;
	lsp:long_string_ptr;
	error_report:short_string;
	error_code:integer=0;
	instruction,word,message_string:short_string='';
	trace:xy_graph_ptr_type;
	num_samples,sample_num:integer=0;
	num_messages,message_num,message_index,num_bad_messages:integer=0;
	stack_height:integer=0;
	num_extra,num_remove,remove_index,restore_index:integer=0;
	ave,stdev,min,max:real;
	m:message_type;
	num_clocks,clock_num,clock_index,num_errors:integer=0;
	id_num,reconstruct_id,extract_id,standing_value,period:integer;
	sorted:boolean;
	id_valid:array [min_id..max_id] of boolean;
	ac_couple,display_active,was_in_window,blank_message:boolean;
	display_min,display_max:real;
	phase_histogram:array [0..max_period-1] of integer;
	phase_index,window_index:integer;
	window_extent,window_score,winning_window_score,window_phase:integer;
	candidate_list:array [0..max_num_candidates-1] of message_type;
	best_num,num_missing,num_bad,num_extracted:integer;
	smallest_deviation,deviation:integer;
	previous_id,previous_clock,previous_timestamp:integer;
	window_time,num_candidates:integer;
	first_message,last_message,firmware_version:integer;	
	unaccepted:short_string;

const
	id_offset=0;
	sample_offset=1;
	timestamp_offset=3;
	id_bits=4;
	byte_bits=8;
	id_mask=$0F;
	
	function image_message(ip:image_ptr_type;n:integer):message_type;
	var 
		m:message_type;
		byte_num:integer;
	begin
		byte_num:=n*message_length;
		m.id:=image_byte(ip,byte_num+id_offset);
		m.sample:=
			 $0100*image_byte(ip,byte_num+sample_offset)
			+$0001*image_byte(ip,byte_num+sample_offset+1);
		m.timestamp:=image_byte(ip,byte_num+timestamp_offset);
		m.time:=0;
		image_message:=m;
	end;
	
	procedure write_image_message(ip:image_ptr_type;m:message_type;n:integer);
	var byte_num:integer;
	begin
		byte_num:=n*message_length;
		write_image_byte(ip,m.id,byte_num+id_offset);
		write_image_byte(ip,m.sample div $100,byte_num+sample_offset);
		write_image_byte(ip,m.sample mod $100,byte_num+sample_offset+1);
		if m.id<>clock_id then
			write_image_byte(ip,m.timestamp,byte_num+timestamp_offset)
		else 
			write_image_byte(ip,firmware_version,byte_num+timestamp_offset)
	end;
	
	function new_message_array(length:integer):message_array_ptr_type;
	var
		mp:message_array_ptr_type;
	begin
		mp:=new(message_array_ptr_type,length);
		if mp=nil then begin
			report_error('Failed to allocate for message array.');
			exit;
		end;
		inc_num_outstanding_ptrs(sizeof(mp^),CurrentRoutineName);
		new_message_array:=mp;
	end;

	procedure dispose_message_array(mp:message_array_ptr_type);
	begin
		if mp=nil then exit;
		dec_num_outstanding_ptrs(sizeof(mp^),CurrentRoutineName);
		dispose(mp);
	end;

	
begin
{
	Allocate return string and check image pointer.
}
	lsp:=new_long_string;
	lwdaq_A3007_recorder:=lsp;
	lsp^:='ERROR: Recorder analysis failed.';
	if not valid_image_ptr(ip) then exit;
	ip^.results:='';
{
	Read the command out of the command string.
}
	instruction:=read_word(command);
{
	Put a limit on the number of messages and create the message array.
}
	max_num_messages:=trunc((sizeof(ip^.intensity)-ip^.i_size)/message_length)-1;
{
	The get instruction does not need a message array or any analysis. We 
	execute the instruction and then exit the recorder procedure.
}
	if instruction='get' then begin
		lsp^:='';
		word:=read_word(command);
		while word<>'' do begin
			message_num:=read_integer(word);
			if (message_num<0) or (message_num>=max_num_messages) then begin
				insert('0 0 0 ',lsp^,length(lsp^)+1);
			end else begin
				m:=image_message(ip,message_num);
				writestr(message_string,m.id:1,' ',m.sample:1,' ',m.timestamp:1,' ');
				insert(message_string,lsp^,length(lsp^)+1);
			end;
			word:=read_word(command);
		end;
		exit;
	end;
{
	Create a message array for use in analysis.
}
	mp:=new_message_array(max_num_messages);
	if mp=nil then exit;
{
	We scan through the messages in the image, and construct an array that is
	easier for us to manipulate in Pascal. We know we have reached the end of
	the messages when we hit a string of four zero bytes. We assign each
	messages in our new array a time of occurance, in units of clock ticks. Time
	zero occurs at the first clock message. (A clock message is a messages with
	ID zero.) Messages that occur before that have a negative time. We assume
	that the first byte of the first message is at byte zero in the image data.

	While we are going through the messages, we look for corruption of the image
	data. The value of the clock should increment from one message to the next,
	except when it jumps from its maximum value to zero. If we see a jump in the
	clock, we note a "clock error". Consecutive non-clock messages must have
	non-decreasing timestamps, with the exception of a drop to zero just before
	a clock message is stored. A deviation from this progression is a "timestamp
	error". A clock error can be the result of data acquisition failing to keep
	up with data recording. A timestamp error is almost always serious because
	it indicates a loss of one or more bytes of data from the recorder. The
	four-byte messages become misaligned with respect to the four-byte
	boundaries in the image. A timestamp error can also indicate actual
	corruption of data bits. We observe timestamp errors during electrical
	events like static discharge and power failure.

	We report on the first max_num_reports errors in detail and trust that the
	data acquisition software will attempt to correct the errors and restore the
	integrity of the data. 
}
	num_errors:=0;
	error_report:='';
	num_messages:=0;
	num_clocks:=0;
	blank_message:=false;
	previous_clock:=0;
	previous_timestamp:=0;
	previous_id:=0;
	firmware_version:=-1;
	while (not blank_message) and (num_messages<=mp^.length-1) do begin
		message_string:='';
		mp^[num_messages]:=image_message(ip,num_messages);
		with mp^[num_messages] do begin
			if (id=0) and (sample=0) and (timestamp=0) then begin
				blank_message:=true;
			end else begin
				if id=clock_id then begin 
					if (sample <> (previous_clock+1) mod (max_sample+1))
							and (num_clocks > 0) then
						writestr(message_string,
							'Clock Error: index=',num_messages:1,
							' current=',sample:1,
							' previous=',previous_clock:1,
							eol)
					else
						firmware_version:=timestamp;
					time:=num_clocks*clock_period;
					inc(num_clocks);
					previous_timestamp:=0;
					previous_clock:=sample;
				end else begin
					if (timestamp>=previous_timestamp) then begin
						time:=timestamp+(num_clocks-1)*clock_period;
					end else if (timestamp=0) then begin
						time:=num_clocks*clock_period;
					end else begin
						writestr(message_string,
							'Timestamp Error: index=',num_messages:1,
							' current=',timestamp:1,
							' previous=',previous_timestamp:1,
							eol);
						time:=previous_timestamp+(num_clocks-1)*clock_period;
					end;
					previous_timestamp:=timestamp;
					previous_id:=id;
				end;
				if message_string<>'' then begin
					inc(num_errors);
					if num_errors<=max_num_reports then
						insert(message_string,error_report,length(error_report)+1);
					if num_errors=max_num_reports then
						insert('No report on remaining errors.'+eol,
							error_report,length(error_report)+1);
				end;
				inc(num_messages);
			end;
		end;
	end;
{
	If print then we print the raw message contents to the screen. We do not
	abort the print instruction just because the data in the image is corrupted.
	The print command always returns a string describing the data. If the data
	contains an invalid sequence of clock messages, the print command declares
	this in its first line.
}
	if instruction='print' then begin
		writestr(lsp^,'Data Recorder Firmware Version ',firmware_version:1,'.',eol,
			'Total of ',num_messages:1,' messages and ',num_clocks:1,' clocks.',eol,
			'Encountered ',num_errors:1,' errors in data block.',eol);
		if error_report<>'' then insert(error_report,lsp^,length(lsp^)+1);
			
		first_message:=read_integer(command);
		if (first_message<0) then first_message:=0;
		if (first_message>num_messages-1) then first_message:=num_messages-1;			

		last_message:=read_integer(command);
		if (last_message<=first_message) or (last_message>=num_messages-1) then 
			last_message:=num_messages-1;

		writestr(message_string,
			'Messages ',first_message:1,
			' to ',last_message:1,' (index id value timestamp $hex):',eol);
		insert(message_string,lsp^,length(lsp^)+1);
		message_num:=first_message;
		while (message_num<=last_message) do begin
			with mp^[message_num] do writestr(message_string,
				message_num:5,' ',id:3,' ',sample:5,' ',timestamp:3,' $',
				string_from_decimal(id,16,2),
				string_from_decimal(sample,16,4),
				string_from_decimal(timestamp,16,2),eol);
			insert(message_string,lsp^,length(lsp^)+1);
			inc(message_num);
			if (length(lsp^)>max_print_length) and (message_num<last_message-1) then begin
				insert('...'+eol,lsp^,length(lsp^)+1);
				message_num:=last_message-1;
			end;
		end;
		insert('End of Messages',lsp^,length(lsp^)+1);
	end;
{
	If extract then return all the messages from the specified channel. Even if
	the clock messages sequence is invalid, extract will still try to retrieve 
	all the messages from the specified channel.
}
	if instruction='extract' then begin
		extract_id:=read_integer(command);
		if (extract_id<min_id) or (extract_id>max_id) then begin
			report_error('Invalid extract_id.');
			exit;
		end;
		num_extracted:=0;
		lsp^:='';
		for message_num:=0 to num_messages-1 do begin
			with mp^[message_num] do begin
				if id=extract_id then begin
					inc(num_extracted);
					writestr(message_string,time:1,' ',sample:1);
					if length(lsp^)>0 then message_string:=eol+message_string;
					insert(message_string,lsp^,length(lsp^)+1);
					if length(lsp^)>max_print_length then begin
						report_error('Too many messages for result string.');
						exit;
					end;
				end;
			end;
		end;
{
	Record the meta-data.
}
		writestr(ip^.results,num_clocks:1,' ',num_extracted:1);
	end;
{
	If clocks then we return the number of clock messages, and the
	byte index of the specified clock messages. We specify the n'th
	clock message in the data with the number n in the command. 
}
	if instruction='clocks' then begin
		writestr(lsp^,num_errors:1,' ',num_clocks:1,' ',num_messages:1,' ');
		word:=read_word(command);
		while word<>'' do begin
			clock_num:=read_integer(word);
			if clock_num<0 then clock_num:=num_clocks+clock_num;
			clock_index:=0;
			message_index:=-1;
			for message_num:=0 to num_messages-1 do begin
				if mp^[message_num].id=clock_id then begin
					if clock_index=clock_num then 
						message_index:=message_num;
					inc(clock_index);
				end;
			end;
			writestr(lsp^,lsp^,message_index:1,' ');
			word:=read_word(command);
		end;
	end;
{
	If reconstruct then read a message identifier and period from 
	the command string. Select all messages from this channel. Any
	messages occurring outside the transmission windows, or any 
	message that is farther from the previous sample than another
	sample in the same window, will be removed.
}
	if instruction='reconstruct' then begin
		if (num_clocks<min_reconstruct_clocks) then begin
			report_error('Too few clock messages for reconstruction.');
			dispose_message_array(mp);
			exit;
		end;
		reconstruct_id:=read_integer(command);
		if (reconstruct_id<min_id) or (reconstruct_id>max_id) then begin
			report_error('Invalid reconstruct_id.');
			dispose_message_array(mp);
			exit;
		end;
		period:=read_integer(command);
		if (period<min_period) or (period>max_period) then begin
			report_error('Invalid period.');
			dispose_message_array(mp);
			exit;
		end;
		window_extent:=read_integer(command);
		if (window_extent>=period/2) then begin
			report_error('Transmission scatter greater than half a period.');
			dispose_message_array(mp);
			exit;
		end;
		if (window_extent<0) then begin
			report_error('Transmission scatter negative.');
			dispose_message_array(mp);
			exit;
		end;
		window_extent:=window_extent+window_border;
		standing_value:=read_integer(command);
		if (standing_value<min_sample) or (standing_value>max_sample) then begin
			report_error('Invalid standing_value.');
			dispose_message_array(mp);
			exit;
		end;
{
	Create a message stack.
}
		msp:=new_message_array(max_num_messages);
		if msp=nil then begin
			dispose_message_array(mp);
			exit;
		end;
{
	We extract unaccepted values from the command string an place them at
	the front of the new message stack.
}
		stack_height:=0;	
		word:=read_word(command);
		while word<>'' do begin
			with msp^[stack_height] do begin
				id:=reconstruct_id;
				timestamp:=0;
				time:=0;
				sample:=read_integer(word);
				if (sample<min_sample) or (sample>max_sample) then begin
					report_error('Invalid sample.');
					dispose_message_array(mp);
					dispose_message_array(msp);
					exit;
				end;
			end;
			inc(stack_height);
			word:=read_word(command);
		end;
{
	Take messages from the reconstruct channel and put them in the
	message stack. We assume the messages are in chronological order.
}
		for message_num:=0 to num_messages-1 do begin
			if mp^[message_num].id=reconstruct_id then begin 
				msp^[stack_height]:=mp^[message_num];
				inc(stack_height);
			end
		end;
{
	We replace the old message array with the new messages stack. The
	new message array contains only messages from the reconstruct 
	channel.
}
		dispose_message_array(mp);
		mp:=msp;
		num_messages:=stack_height;
{
	Determine the phase of the transmission window. Each transmission
	window is window_extent*2+1 ticks wide, and separated by period
	ticks from its neighboring windows.
}
		for phase_index:=0 to period-1 do phase_histogram[phase_index]:=0;
		for message_num:=0 to num_messages-1 do
			inc(phase_histogram[mp^[message_num].time mod period]);
		winning_window_score:=0;
		window_phase:=0;
		for phase_index:=0 to period-1 do begin
			window_score:=0;
			for window_index:=-window_extent to window_extent do begin
				window_score:=window_score
					+ phase_histogram[(phase_index+window_index) mod period];
			end;
			if window_score>winning_window_score then begin
				winning_window_score:=window_score;
				window_phase:=phase_index;
			end;
		end;
{
	Set the location of the first transmission window. 
}
		if window_phase>=period-window_extent then
			window_time:=window_phase-period
		else 
			window_time:=window_phase;
{
	Run through transmission windows. In each window, make a list of 
	available samples. Ideally, there will be only one, and we accept
	it into our new list, which we are forming in the message stack.
	We set the standing value equal to its sample. But there may be 
	two or more messages. We pick the one that is closest to the 
	standing value, and we leave the standing value as it is. There
	may be no messages, in which case we insert a substitute message
	with the standing value at the center of the window. By this
	procedure, we also eliminate messages that fall outside the 
	windows.
}		
		msp:=new_message_array(max_num_messages);
		if msp=nil then begin
			dispose_message_array(mp);
			exit;
		end;
		stack_height:=0;
		num_missing:=0;
		num_bad:=0;
		message_num:=0;
		while window_time<num_clocks*clock_period-window_extent do begin
			num_candidates:=0;
			while (message_num<num_messages) and
					(mp^[message_num].time-window_time<=window_extent) and
					(num_candidates<max_num_candidates) do begin
				if abs(mp^[message_num].time-window_time)<=window_extent then begin
					candidate_list[num_candidates]:=mp^[message_num];
					inc(num_candidates);
				end;
				inc(message_num);
			end;
			
			if num_candidates=0 then begin
				inc(num_missing);
				with m do begin
					id:=reconstruct_id;
					sample:=standing_value;
					time:=window_time;
				end;
			end;
			if num_candidates=1 then begin
				m:=candidate_list[0];
				standing_value:=m.sample;
			end;
			if num_candidates>1 then begin
				best_num:=0;
				smallest_deviation:=max_sample-min_sample+1;
				for message_index:=0 to num_candidates-1 do begin
					deviation:=abs(candidate_list[message_index].sample-standing_value);
					if deviation<smallest_deviation then begin
						best_num:=message_index;
						smallest_deviation:=deviation;
					end;
				end;
				m:=candidate_list[best_num];
				num_bad:=num_bad+num_candidates-1;
			end;
			msp^[stack_height]:=m;
			inc(stack_height);
			window_time:=window_time+period;
		end;
{
	If the next transmission window lies across the end-point of this
	time interval, we save any messages from this window as unaccepted
	values. Right now, message_num points either to a non-existent 
	message past the end of the message list, or to the first of one
	or more messages that lie within a window that overlaps the end
	of the time interval. We will not accept these messages into the
	reconstructed signal because we must first compare them to any 
	messages that occur during the later part of the window. Thus
	we take these messages and put their sample values into a list
	of "unaccepted values" which we will write to the image results
	string for the next call to "reconstruct".
}
		unaccepted:='';
		while message_num<num_messages do begin
			writestr(unaccepted,unaccepted,mp^[message_num].sample,' ');
			inc(message_num);
		end;
{
	We are now finished with the previous message list, so we dispose of 
	it and replace it with our message stack.
}
		dispose_message_array(mp);
		mp:=msp;
		num_messages:=stack_height;
{
	Return the reconstructed message list in a string. Each line gives 
	the time and value of a message, in order of increasing time.
}
		lsp^:='';
		for message_num:=0 to num_messages-1 do begin
			with mp^[message_num] do begin
				writestr(message_string,time:1,' ',sample:1);
				if length(lsp^)>0 then message_string:=eol+message_string;
				insert(message_string,lsp^,length(lsp^)+1);
				if length(lsp^)>max_print_length then begin
					report_error('Too many messages for result string.');
					dispose_message_array(mp);
					exit;
				end;
			end;
		end;
{
	Record the meta-data.
}
		writestr(ip^.results,num_clocks:1,' ',num_messages:1,' ',
			num_bad:1,' ',num_missing:1,' ',unaccepted);
	end;
{
	If plot, we plot them on the screen and return a summary result for each
	specified channel or for all channels with samples, depending upon the
	command. Plot does not abort unless it receives an invalid command. It will
	plot data even when a clock error has occurred. I returns a list of active
	channels regardless of the state of the data.
}
 	if instruction='plot' then begin
		draw_oscilloscope_scale(ip,num_divisions);
 		display_min:=read_real(command);
 		display_max:=read_real(command);
 		ac_couple:=(read_word(command)='AC');

		word:=read_word(command);
 		if word='*' then begin
 			display_active:=true;
			for id_num:=min_id to max_id do id_valid[id_num]:=true;
 		end else begin
 			display_active:=false;
 			for id_num:=min_id to max_id do id_valid[id_num]:=false;
			while word<>'' do begin
				id_num:=read_integer(word);
				if (id_num<min_id) or (id_num>max_id) then begin
					report_error('Invalid id_num.');
					dispose_message_array(mp);
					exit;
				end;
				id_valid[id_num]:=true;	
				word:=read_word(command);
			end;
 		end;
 		
 		if num_errors>0 then
			for message_num:=0 to num_messages-1 do
				mp^[message_num].time:=message_num;
 		
		num_bad_messages:=0;
		
		lsp^:='';
		for id_num:=min_id to max_id do begin
			num_samples:=0;
			for message_num:=0 to num_messages-1 do
				if mp^[message_num].id=id_num then
					inc(num_samples);
			
			if id_valid[id_num] then begin
				if num_samples>0 then begin
					trace:=new_xy_graph(num_samples);
					sample_num:=0;
					for message_num:=0 to num_messages-1 do
						with mp^[message_num] do begin
							if id=id_num then begin
								trace^[sample_num].x:=time;
								trace^[sample_num].y:=sample;
								inc(sample_num);
							end;
						end;
					ave:=average_xy_graph(trace);
					stdev:=stdev_xy_graph(trace);
					min:=min_xy_graph(trace);
					max:=max_xy_graph(trace);
					if ac_couple then 
						display_real_graph(ip,trace,
							overlay_color_from_integer(id_num),
							mp^[0].time,mp^[num_messages-1].time,
							display_min+ave,display_max+ave,0,0)
					else 
						display_real_graph(ip,trace,
							overlay_color_from_integer(id_num),
							mp^[0].time,mp^[num_messages-1].time,
							display_min,display_max,0,0);
					dispose_xy_graph(trace);
				end else begin
					ave:=0;
					stdev:=0;
					min:=0;
					max:=0;
				end;
				if (num_samples>0) or (not display_active) then begin
					if id_num=0 then
						writestr(lsp^,lsp^,id_num:1,' ',num_clocks:1,' ',
							min:1:0,' ',max:1:0,' ')
					else
						writestr(lsp^,lsp^,id_num:1,' ',num_samples:1,' ',
							ave:1:1,' ',stdev:1:1,' ')
				end;
			end else begin
				if id_num<>clock_id then
					num_bad_messages:=num_bad_messages+num_samples;
			end;
		end;
		if not display_active then
			writestr(lsp^,lsp^,invalid_id:1,' ',num_bad_messages:1);
	end;
{
	If list, we list the channels that contain more than one sample, and the number
	of samples in each of these channels.
}
 	if instruction='list' then begin
		lsp^:='';
		for id_num:=min_id to max_id do begin
			num_samples:=0;
			for message_num:=0 to num_messages-1 do
				if mp^[message_num].id=id_num then
					inc(num_samples);
			if (num_samples>0) then
				writestr(lsp^,lsp^,id_num:1,' ',num_samples:1,' ');
		end;
 	end;	
 {
 	Dispose of the message array.
 }
	dispose_message_array(mp);
end;


{
	lwdaq_A2100_sampler analyzes and image containing four-byte samples. Each
	sample contains four bytes. The first byte is a channel number that
	identifies the source of the sample. The remaining three bytes are a 24-bit
	value. The most significant byte is first. Channel number 0 is reserved as a
	marker for the end of the sample sequence. The routine accepts a command
	string. The first word in the command string is the data format code. We use
	0 for unsigned 24-bit samples and 1 for signed (twos complement) samples.
	The next word is an instruction. We have "plot", "compare", and "extract".
	The words after are parameters particular to the instruction, as described
	below in the comments.
}
function lwdaq_A2100_sampler(ip:image_ptr_type;command:short_string):long_string_ptr;

const
	num_unsigned_div=1;
	num_signed_div=2;
	min_id=1;
	max_id=254;
	invalid_id=-1;
	end_id=0;
	record_length=4;
	id_offset=0;
	value_offset=1;

var
	lsp:long_string_ptr;
	format:integer=0;
	instruction,word,datum:short_string='';
	id_num,record_num,num_records,sample_num:integer=0;
	chosen:array [min_id..max_id] of boolean;
	num_samples:array [min_id..max_id] of integer;
	display_min,display_max:real;
	ac_couple,display_active:boolean;
	trace:xy_graph_ptr_type;
	max,min,ave,stdev,vref:real;
	id_1,id_2,start_num,end_num:integer=0;
	
	function record_id(ip:image_ptr_type;n:integer):integer;
	var 
		byte_num:integer;
	begin
		byte_num:=n*record_length;
		if byte_num<sizeof(ip^.intensity)-ip^.i_size-record_length then 
			record_id:=image_byte(ip,byte_num+id_offset)
		else 
			record_id:=0;
	end;

	function record_value(ip:image_ptr_type;n:integer):real;
	var 
		byte_num,value:integer;
	begin
		byte_num:=n*record_length;
		if (byte_num<sizeof(ip^.intensity)-ip^.i_size-record_length) then begin
			case format of 
				1: {
					Two's complement signed twenty-four bit. The value
					varies from -1 to +1.
				}
				begin
					value:=
						 image_byte(ip,byte_num+value_offset)*$10000
						+image_byte(ip,byte_num+value_offset+1)*$100
						+image_byte(ip,byte_num+value_offset+1+1);
					if (value>$007FFFFF) then 
						value:=value-$01000000;
					record_value:=value/$00800000;
				end;
				otherwise {
					Unsigned twenty-four bit. The value varies from
					0 to 1.
				}
				begin
					record_value:=
						 image_byte(ip,byte_num+value_offset)/$100
						+image_byte(ip,byte_num+value_offset+1)/$10000
						+image_byte(ip,byte_num+value_offset+1+1)/$1000000;
				end;
			end;
		end else begin 
			record_value:=0;
		end;
	end;
	
begin
{
	Allocate return string and check image pointer.
}
	lsp:=new_long_string;
	lwdaq_A2100_sampler:=lsp;
	lsp^:='ERROR: Sampler analysis failed.';
	if not valid_image_ptr(ip) then exit;
	ip^.results:='';
{
	Determine the number of samples in each channel.
}
	for id_num:=min_id to max_id do begin
		num_samples[id_num]:=0;
	end;
	record_num:=0;
	while record_id(ip,record_num)<>0 do begin
		inc(num_samples[record_id(ip,record_num)]);
		inc(record_num);
	end;
{
	Read the data format and the instruction out of the command string.
}
	format:=read_integer(command);
	instruction:=read_word(command);
{
	If plot then plot samples on screen and return the number of samples
	in each channel available, its average value, and its standard deviation. 
	We scale the recorded sample value with a reference voltage that we
	assume to correspond to record value $1000000.
}
	if instruction='plot' then begin
		case format of 
			1: draw_oscilloscope_scale(ip,num_signed_div);
			otherwise draw_oscilloscope_scale(ip,num_unsigned_div);
		end;
 		display_min:=read_real(command);
 		display_max:=read_real(command);
 		ac_couple:=(read_word(command)='AC');
 		vref:=read_real(command);

		word:=read_word(command);
 		if word='*' then begin
 			display_active:=true;
			for id_num:=min_id to max_id do chosen[id_num]:=true;
 		end else begin
 			display_active:=false;
			for id_num:=min_id to max_id do chosen[id_num]:=false;
			while word<>'' do begin
				id_num:=read_integer(word);
				if (id_num<min_id) or (id_num>max_id) then begin
					report_error('Invalid id_num.');
					exit;
				end;
				chosen[id_num]:=true;	
				word:=read_word(command);
			end;
 		end;
 		
		lsp^:='';
		for id_num:=min_id to max_id do begin
			if chosen[id_num] then begin
				if num_samples[id_num]>0 then begin
					trace:=new_xy_graph(num_samples[id_num]);
					sample_num:=0;
					record_num:=0;
					while record_id(ip,record_num)<>0 do begin
						if record_id(ip,record_num)=id_num then begin
							with trace^[sample_num] do begin
								y:=vref*record_value(ip,record_num);
								x:=sample_num;
							end;
							inc(sample_num);
						end;
						inc(record_num);
					end;
	
					ave:=average_xy_graph(trace);
					stdev:=stdev_xy_graph(trace);
					min:=min_xy_graph(trace);
					max:=max_xy_graph(trace);
					
					if ac_couple then 
						display_real_graph(ip,trace,
							overlay_color_from_integer(id_num),0,0,
							display_min+ave,display_max+ave,0,0)
					else 
						display_real_graph(ip,trace,
							overlay_color_from_integer(id_num),0,0,
							display_min,display_max,0,0);
					dispose_xy_graph(trace);
				end else begin
					ave:=0;
					stdev:=0;
					min:=0;
					max:=0;
				end;

				if (num_samples[id_num]>0) or (not display_active) then
					writestr(lsp^,lsp^,id_num:1,' ',
						num_samples[id_num]:1,' ',ave:1:6,' ',stdev:1:6,' ');
			end;
		end;
 	end;
{
	If compare then subtract the first-named channel from the second-named
	channel and determine the standard deviation of the resulting difference
	in volts as scaled by the voltage reference parameter. The comparison assumes
	that samples from the two channels are simultaneous and in chronological
	order, although they can be alternated in any way.
}
	if instruction='compare' then begin
 		vref:=read_real(command);
		id_1:=read_integer(command);
		id_2:=read_integer(command);

		if (num_samples[id_1]<=0) then begin
			report_error('no samples in channel '
				+string_from_integer(id_1,1)+'.');
			exit;
		end;
		if (num_samples[id_2]<=0) then begin
			report_error('no samples in channel '
				+string_from_integer(id_2,1)+'.');
			exit;
		end;
		if (num_samples[id_1]<>num_samples[id_2]) then begin
			report_error('channels '+string_from_integer(id_1,1)
				+' and '+string_from_integer(id_2,1)
				+' have different number of samples');
			exit;
		end;

		trace:=new_xy_graph(num_samples[id_1]);
		sample_num:=0;
		record_num:=0;
		while record_id(ip,record_num)<>0 do begin
			if record_id(ip,record_num)=id_1 then begin
				with trace^[sample_num] do begin
					y:=vref*record_value(ip,record_num);
					x:=sample_num;
				end;
				inc(sample_num);
			end;
			inc(record_num);
		end;

		sample_num:=0;
		record_num:=0;
		while record_id(ip,record_num)<>0 do begin
			if record_id(ip,record_num)=id_2 then begin
				with trace^[sample_num] do begin
					y:=y-vref*record_value(ip,record_num);
				end;
				inc(sample_num);
			end;
			inc(record_num);
		end;
		
		ave:=average_xy_graph(trace);
		stdev:=stdev_xy_graph(trace);
		
		writestr(lsp^,ave:1:6,' ',stdev:1:6);
	end;
{
	if extract then extract samples start_n to end_n from channel id and write
	them to the output string as real numbers. The first sample is number zero.
}
	if instruction='extract' then begin
 		vref:=read_real(command);
		id_num:=read_integer(command);
 		start_num:=read_integer(command);
 		end_num:=read_integer(command);

		if (num_samples[id_num]<=0) then begin
			report_error('no samples in channel '
				+string_from_integer(id_num,1)+'.');
			exit;
		end;
		if (num_samples[id_num]<end_num+1) then begin
			report_error('less than end_num+1 samples in channel '
				+string_from_integer(id_num,1)+'.');
			exit;
		end;
		if (start_num>end_num) then begin
			report_error('start_num > end_num.');
			exit;
		end;

		lsp^:='';
		sample_num:=0;
		record_num:=0;
		while record_id(ip,record_num)<>0 do begin
			if record_id(ip,record_num)=id_num then begin
				inc(sample_num);
				if (sample_num>=start_num) and (sample_num<=end_num) then begin
					writestr(datum,vref*record_value(ip,record_num):1:6,' ');
					lsp^:=lsp^+datum;
				end;
			end;
			inc(record_num);
		end;

	end;
end;


{
	lwdaq_A3008_rfpm plots and analyzes images from an A3008 radio frequency power
	meter.
}
function lwdaq_A3008_rfpm(ip:image_ptr_type;
	v_min,v_max:real;rms:boolean):short_string;


const
	num_divisions=10; 
	max_num_channels=30;
	
var 
	result,input_string,word:short_string='';
	trace:xy_graph_ptr_type;
	n,num_samples,num_channels,channel_num:integer;
	startup_skip:integer;
	max,min:real;
	
begin
	lwdaq_A3008_rfpm:='ERROR: RFPM analysis failed.';
	if not valid_image_ptr(ip) then exit;
	
	draw_oscilloscope_scale(ip,num_divisions);

	input_string:=ip^.results;
	num_samples:=read_integer(input_string);
	if (num_samples>(ip^.j_size-1)*ip^.i_size) or (num_samples<1) then begin
		report_error('Invalid num_samples.');
		exit;
	end;
	startup_skip:=read_integer(input_string);
	if (startup_skip>ip^.i_size) or (startup_skip<=0) then begin
		report_error('Invalid startup_skip.');
		exit;
	end;
	num_channels:=read_integer(input_string);
	if (num_channels>max_num_channels) or (num_channels<=0) then begin
		report_error('Invalid num_channels.');
		exit;
	end;

	trace:=new_xy_graph(num_samples);
	for channel_num:=0 to num_channels-1 do begin
		for n:=0 to num_samples-1 do begin
			trace^[n].x:=n;
			trace^[n].y:=sample_A2037E_adc8(ip,0,
				channel_num*(num_samples+startup_skip)+n+startup_skip);
		end;
		max:=max_xy_graph(trace);
		min:=min_xy_graph(trace);
		if rms then 
			writestr(result,result,' ',stdev_xy_graph(trace):fsr:fsd)
		else
			writestr(result,result,' ',(max-min):fsr:fsd);
		if (max<v_max) and (min>v_min) then 
			display_real_graph(ip,trace,
				overlay_color_from_integer(channel_num),
				0,num_samples-1,v_min,v_max,0,0);
	end;
{
	We make the trace available with a global pointer, after disposing of the pre-existing
	trace, should it exist.
}
	if electronics_trace<>nil then dispose_xy_graph(electronics_trace);
	electronics_trace:=trace;

	lwdaq_A3008_rfpm:=result;
end;


end.