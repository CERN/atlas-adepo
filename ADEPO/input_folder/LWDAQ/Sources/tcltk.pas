{
Interface Between TCL/TK and Pascal
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

unit Tcltk;

interface

uses
	utils;

const
	Tcl_Error=1;
	Tcl_OK=0;
	Tcl_MaxArgs=100;
	Tcl_ArgChar='-';

type
	Tcl_ArgList = array [0..Tcl_MaxArgs] of pointer;
	Tcl_CmdProc=
		function(data,interp:pointer;argc:integer;var argv:Tcl_ArgList):integer;
	Tcl_CmdDeleteProc=procedure(data:pointer);
	Tk_PhotoPixelElement=(red,green,blue,alpha);
	Tk_PhotoImageBlock=record
		pixelptr:pointer;
		width,height,pitch,pixelSize:integer;
		offset:array [Tk_PhotoPixelElement] of integer;
	end;
	
{
	Direct calls to Tcl/TK library commands.
}
function Tcl_CreateObjCommand (interp:pointer;s:CString;cmd:Tcl_CmdProc;
	data:integer;delete_proc:Tcl_CmdDeleteProc):pointer;
	external name 'Tcl_CreateObjCommand';
function Tcl_EvalFile (interp:pointer;s:CString):integer;
	external name 'Tcl_EvalFile';
function Tcl_GetByteArrayFromObj(obj_ptr:pointer;var size:integer):pointer;
	external name 'Tcl_GetByteArrayFromObj';
function Tcl_GetObjResult (interp:pointer):pointer;
	external name 'Tcl_GetObjResult';
function Tcl_GetStringFromObj (obj_ptr:pointer;var size:integer):CString;
	external name 'Tcl_GetStringFromObj';
function Tcl_GetVar(interp:pointer;name:CString;flags:integer):CString;
	external name 'Tcl_GetVar';
function Tcl_Eval (interp:pointer;s:CString):integer;
	external name 'Tcl_Eval';
function Tcl_InitStubs (interp:pointer;s:CString;e:integer):pointer;
	external name 'Tcl_InitStubs';
function Tcl_NewByteArrayObj(bp:pointer;size:integer):pointer;
	external name 'Tcl_NewByteArrayObj';
function Tcl_PkgProvide (interp:pointer;name:CString;version:CString):integer;
	external name 'Tcl_PkgProvide';
procedure Tcl_SetByteArrayObj(obj_ptr,bp:pointer;size:integer);
	external name 'Tcl_SetByteArrayObj';
procedure Tcl_SetObjResult (interp,obj_ptr:pointer);
	external name 'Tcl_SetObjResult';
procedure Tcl_SetStringObj (obj_ptr:pointer;s:CString;l:integer);
	external name 'Tcl_SetStringObj';
function Tcl_SetVar(interp:pointer;name:CString;value:CString;flags:integer):CString;
	external name 'Tcl_SetVar';
function Tk_FindPhoto(interp:pointer;imageName:CString):pointer;
	external name 'Tk_FindPhoto';
function Tk_InitStubs (interp:pointer;s:CString;e:integer):pointer;
	external name 'Tk_InitStubs';
procedure Tk_PhotoBlank(handle:pointer);
	external name 'Tk_PhotoBlank';
procedure Tk_PhotoSetSize(inerp:pointer;handle:pointer;width,height:integer);
	external name 'Tk_PhotoSetSize';
function Tk_PhotoGetImage(handle,blockptr:pointer):integer;
	external name 'Tk_PhotoGetImage';
{$ifdef TCLTK_8_5}
procedure Tk_PhotoPutBlock(interp,handle,blockptr:pointer;x,y,width,height,comprule:integer);
	external name 'Tk_PhotoPutBlock';
procedure Tk_PhotoPutZoomedBlock(interp,handle,blockptr:pointer;x,y,width,height,
		zoomX,zoomY,subsampleX,subsampleY,comprule:integer);
	external name 'Tk_PhotoPutZoomedBlock';
{$else}
procedure Tk_PhotoPutBlock(handle,blockptr:pointer;x,y,width,height,comprule:integer);
	external name 'Tk_PhotoPutBlock';
procedure Tk_PhotoPutZoomedBlock(handle,blockptr:pointer;x,y,width,height,
		zoomX,zoomY,subsampleX,subsampleY,comprule:integer);
	external name 'Tk_PhotoPutZoomedBlock';
{$endif}
{
	Tcl routines implemented as macros in the C header file, here re-constructed
	in pascal.
}
function Tcl_IsShared(obj_ptr:pointer):integer;
procedure Tcl_DecRefCount(obj_ptr:pointer);
procedure Tcl_IncRefCount(obj_ptr:pointer);

{
	Indirect calls to Tcl/TK commands. These are not in the TCL/TK libraries.
}
function Tcl_ObjBoolean(obj_ptr:pointer):boolean;
function Tcl_ObjInteger(obj_ptr:pointer):integer;
function Tcl_ObjReal(obj_ptr:pointer):real;
function Tcl_ObjShortString(obj_ptr:pointer):short_string;
function Tcl_ObjLongString(obj_ptr:pointer):long_string_ptr;
function Tcl_RefCount(obj_ptr:pointer):integer;
procedure Tcl_SetReturnShortString(interp:pointer;s:short_string);
procedure Tcl_SetReturnLongString(interp:pointer;var s:string);
procedure Tcl_SetReturnByteArray(interp,bp:pointer;size:integer);


implementation

{
	Tcl_RefCount returns the number of users of the specified object.
}
function Tcl_RefCount(obj_ptr:pointer):integer;
begin Tcl_RefCount:=integer_ptr(obj_ptr)^; end;

{
	Tcl_IsShared returns 1 if the specified object has more than one
	user, and zero otherwise.
}
function Tcl_IsShared(obj_ptr:pointer):integer;
begin 
   if (Tcl_RefCount(obj_ptr)>1) then Tcl_IsShared:=1
   else Tcl_IsShared:=0;
end;

{
	Tcl_IncRefCount registers another user with an object.
}
procedure Tcl_IncRefCount(obj_ptr:pointer);
begin inc(integer_ptr(obj_ptr)^); end;

{
	Tcl_DecRefCount unregisters a user from an object.
}
procedure Tcl_DecRefCount(obj_ptr:pointer);
begin dec(integer_ptr(obj_ptr)^); end;

{
	Tcl_ObjShortString returns a short string from a TCL object. 
	If the string is too long, we return an empty string.
}
function Tcl_ObjShortString(obj_ptr:pointer):short_string;
var size:integer;
begin
	Tcl_ObjShortString:=short_string_from_c_string(Tcl_GetStringFromObj(obj_ptr,size));
	if size>short_string_length then Tcl_ObjShortString:='';
end;

{
	Tcl_ObjLongString returns a pointer to a file string from a TCL object. 
	If the string is too long, we return an empty string.
}
function Tcl_ObjLongString(obj_ptr:pointer):long_string_ptr;
var fp:long_string_ptr;size:integer;
begin
	fp:=long_string_from_c_string(Tcl_GetStringFromObj(obj_ptr,size));
	if size>long_string_length then fp^:='';
	Tcl_ObjLongString:=fp;
end;

{
	Tcl_ObjBoolean returns true if the string representation
	of the specified object satisfies boolean_from_string.
}
function Tcl_ObjBoolean(obj_ptr:pointer):boolean;
begin
	Tcl_ObjBoolean:=boolean_from_string(Tcl_ObjShortString(obj_ptr))
end;

{
	Tcl_ObjInteger returns the integer representation of
	the specified object. If the object has no integer
	representation, then the routine returns zero.
}
function Tcl_ObjInteger(obj_ptr:pointer):integer;
var okay:boolean;
begin
	Tcl_ObjInteger:=integer_from_string(Tcl_ObjShortString(obj_ptr),okay);
end;

{
	Tcl_ObjReal returns the real-number representation of
	the specified object. If the object has no real-number
	representation, then the routine returns zero.
}
function Tcl_ObjReal(obj_ptr:pointer):real;
var okay:boolean;
begin
	Tcl_ObjReal:=real_from_string(Tcl_ObjShortString(obj_ptr),okay);
end;

{
	Tcl_SetReturnShortString sets the interpreter return object equal
	to the specified short string.
}
procedure Tcl_SetReturnShortString(interp:pointer;s:short_string);
begin
	Tcl_SetStringObj(Tcl_GetObjResult(interp),s,-1);
end;

{
	Tcl_SetReturnLongString sets the interpreter return object
	equal to the contents of the specified long string.
}
procedure Tcl_SetReturnLongString(interp:pointer;var s:string);
begin
	Tcl_SetStringObj(Tcl_GetObjResult(interp),s,-1);
end;

{
	Tcl_SetReturnByteArray sets the interpreter return object equal
	to the specified byte array object.
}
procedure Tcl_SetReturnByteArray(interp,bp:pointer;size:integer);
begin
	Tcl_SetByteArrayObj(Tcl_GetObjResult(interp),bp,size);
end;

end.