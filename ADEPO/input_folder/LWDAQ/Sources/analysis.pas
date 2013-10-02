{
	Main Program for use with Analysis Shared Library Copyright (C)
	2007 Kevan Hashemi, hashemi@brandeis.edu, Brandeis University
	
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

program analysis;

{
	This is a program instead of a unit, even though we compile it into
	a library. Because it is a program, GPC includes in the object code
	the _p_initialize routine, which initializes the run-time library, and
	creates _p__M0_init, which calls the initialization routines of all the
	units that analysis refers to. The analysis_init calls both these routines
	and so sets up the run-time library and the analysis library. Any 
	program using the analysis library must call analysis_init before calling
	any other routine from the libraray.
	
	Be warned that GPC, when compiling this file, is likely to create a
	routine called _main, which will clash with the _main routine of your
	main program.
}

uses
	utils,images,transforms,image_manip,rasnik,
	spot,shadow,electronics,bcam;

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
	
	Ulrich Landgraaf provides the following solution to the change in
	the name of the pascal initialization routine that takes place in the
	2005 release of GPC. In earlier releases of GPC, the routine was
	called _init_pascal_main_program, but later the name changed to
	_p__M0_init, to conform to a two-level naming scheme.
}
{$ifdef __GPC_RELEASE__}
	{$if __GPC_RELEASE__ > 20050000}
		 {$define INIT_CALL '_p__M0_init'}
	{$else}
		 {$define INIT_CALL 'init_pascal_main_program'}
	{$endif}
{$else}
		 {$define INIT_CALL 'init_pascal_main_program'}
{$endif}
procedure initialize_main;
		external name INIT_CALL;

{
	analysis_init initializes the run-time library and
	analysis units.
}
procedure analysis_init;
	attribute (name='Analysis_Init');

begin
	initialize_pascal(0,nil,nil);
	initialize_main;
end;

{
	hello_world is a diagnostic procedure that writes to the 
	console.
}
procedure hello_world; 
	attribute (name='Hello_World');

begin
	writeln('Analysis: Hello.');
end;

{
	The main body of the program is empty, and serves no purpose.
}
begin
end.
