# LWDAQ Makefile for MacOS, Linux, and Windows. 
# =============================================

# This Makefile requires the GNU Pascal Compiler (GPC)
# and the GNU C Compiler (GCC) to be available at the 
# command prompt. If you are going to compile for 
# non-native platforms (such as compiling for PowerPC
# on an Intel Mac), you will need the cross-compiler
# versions of both GPC and GCC installed.

# Determine the operating system. Our Default
# operating system is Unix.
OS = Unix
ifneq ($(shell uname -a | grep -i Darwin),)
	OS = MacOS
endif
ifneq ($(shell uname -a | grep -i Windows),)
	OS = Windows
endif
ifneq ($(shell uname -a | grep -i Linux),)
	OS = Linux
endif

# Determine the local architecture. Our default is 32-bit Intel.
ARCH = x86_32
ifneq ($(shell uname -a | grep -i powerpc),)
	ARCH = ppc_32
endif
ifneq ($(shell uname -a | grep -i x86_64),)
	ARCH = x86_64
endif

# Force compile of 32-bit libraries on some 64-bit platforms.
ifeq ($(OS),MacOS)
	ifeq ($(ARCH),x86_64)
		ARCH = x86_32
	endif
endif
ifeq ($(OS),Windows)
	ifeq ($(ARCH),x86_64)
		ARCH = x86_32
	endif
endif

# Determine the location of the TCL/TK libraries and the
# GCC libraries. On Unix, we assume the libraries are in one 
# of the default library paths. On MacOS, Linux, and Windows,
# we use the libraries bundled in LWDAQ.app.
TCLTK_LIB =
GCC_LIB = -lm
GCC_FLAGS = 
GPC_FLAGS = 
GPC_MAIN_FLAGS = 
ifeq ($(OS),MacOS)
	SO = -dynamiclib
	ifeq ($(ARCH),ppc_32)
		TCLTK_LIB = \
			-F../LWDAQ.app/Contents/Frameworks \
			-framework Tcl \
			-framework Tk
		GCC_LIB = -Wl,-syslibroot,/Developer/SDKs/MacOSX10.4u.sdk/
		GCC_FLAGS = -mmacosx-version-min=10.4
		GPC_FLAGS = 
		GPC_MAIN_FLAGS = -Wl,-macosx_version_min,10.4
	endif
	ifeq ($(ARCH),x86_32)
		TCLTK_LIB = \
			-F../LWDAQ.app/Contents/Frameworks \
			-framework Tcl \
			-framework Tk
		GCC_LIB = -Wl,-syslibroot,/Developer/SDKs/MacOSX10.6.sdk/
		GCC_FLAGS = -mmacosx-version-min=10.6 -m32
		GPC_FLAGS = 
		GPC_MAIN_FLAGS = -Wl,-macosx_version_min,10.6
	endif
	ifeq ($(ARCH),x86_64)
		TCLTK_LIB = \
			-F../LWDAQ.app/Contents/Frameworks \
			-framework Tcl \
			-framework Tk
		GCC_LIB = -Wl,-syslibroot,/Developer/SDKs/MacOSX10.6.sdk/
		GCC_FLAGS = -mmacosx-version-min=10.6 -m32
		GPC_FLAGS = 
		GPC_MAIN_FLAGS = -Wl,-macosx_version_min,10.6
	endif
endif
ifeq ($(OS),Windows)
	SO = -shared
	ifeq ($(ARCH),x86_32)
		TCLTK_LIB = \
			../LWDAQ.app/Contents/Windows/bin/tcl85.dll \
			../LWDAQ.app/Contents/Windows/bin/tk85.dll 
		GCC_LIB = 
		GCC_FLAGS =
		GPC_FLAGS =
		GPC_MAIN_FLAGS = 
		LIBRARY_PATH=/c/mingw/lib
		export LIBRARY_PATH
	endif
	ifeq ($(ARCH),x86_64)
		TCLTK_LIB = \
			../LWDAQ.app/Contents/Windows/bin/tcl85.dll \
			../LWDAQ.app/Contents/Windows/bin/tk85.dll 
		GCC_LIB = 
		GCC_FLAGS =
		GPC_FLAGS = 
		GPC_MAIN_FLAGS = 
	endif
endif
ifeq ($(OS),Linux)
	SO = -shared
	ifeq ($(ARCH),x86_32)
		TCLTK_LIB = \
			-L../LWDAQ.app/Contents/Linux/x86_32/lib -ltcl8.5 \
			-L../LWDAQ.app/Contents/Linux/x86_32/lib -ltk8.5
		GCC_LIB = -lm
		GCC_FLAGS = 
		GPC_FLAGS = 
		GPC_MAIN_FLAGS = 
	endif
	ifeq ($(ARCH),x86_64)
		TCLTK_LIB = \
			-L../LWDAQ.app/Contents/Linux/x86_64/lib -ltcl8.5 \
			-L../LWDAQ.app/Contents/Linux/x86_64/lib -ltk8.5
		GCC_LIB = -lm
		GCC_FLAGS = -fPIC
		GPC_FLAGS = -fPIC
		GPC_MAIN_FLAGS = 
	endif
endif

# Specify Pascal compiler options. We recommend -O3 for faster
# code, but the compile takes twice as long. You can use 
# -DUSE_TCL_STUBS to set the USE_TCL_STUBS symbol when you compile 
# lwdaq.o, and so add the TCL and TK stub table initialization 
# routine to the LWDAQ initialization routine. See note below
# on stub libraries, and notes on the same subject in lwdaq.pas.
# In production versions of the code we might choose to disable 
# range checking, so as to avoid unecessary program crashes. Disable 
# range checking with --no-range-checking option. You can force
# the compiler options from the shell that calls "make" by 
# assigning and exporting a non-empty option string.
GPC_OPTIONS = -O3

# Determine the location of the pascal library. We do this
# by calling GPC at the command prompt and asking it to tell
# us where the library is.
PAS_LIB = $(shell gpc --print-file-name=libgpc.a)

# Name and location of the LWDAQ shared library.
LWDAQ = ../LWDAQ.app/Contents/LWDAQ/lwdaq.so_$(OS)_$(ARCH)

# Name and location of ANALYSIS static library.
ANALYSIS = analysis.a

# Where are the Pascal sources?
SRC_DIR = ../Sources

# Objects required by LWDAQ and ANALYSIS.
OBJA = utils.o images.o transforms.o image_manip.o rasnik.o \
	spot.o bcam.o wps.o electronics.o shadow.o
	
# Objects required only by LWDAQ.
OBJB = tcltk.o lwdaq.o

# Objects required only by ANALYSIS.
OBJC = analysis.o

# Define the default products of a call to this makefile.
products: $(LWDAQ)

# Compile the Pascal console program. The console program
# declares the Pascal units that are defined by $(OBJA),
# so GPC needs to see the units and their GPI files during
# compilation. The compiler takes care of the two-level
# names used by the linker, and allows you to call from
# p.pas any routine exported by any OBJA unit by using
# the name under which it is declared in the code. We 
# could, however, use ANALYSIS as our source of routines.
# In that case, we would have to force GPC to export
# the OBJA routines needed by p.pas under fixed names
# using the "attribute (name=thename)" directive, just as we do 
# for routines needed by c.c and cpp.cpp. An example of such 
# a routine is Dispose_Image in images.pas. In p.pas, we would 
# declare external routines with the "external name 'thename'"
# directive. We could then compile p.pas to an object file
# with "gpc -c -o p.o p.pas", then link p.p to ANALYSIS with
# gcc or gpc. For more details see "Mixing Pascal, Fortran, 
# and C with GCC"
p: p.pas $(OBJA)
	gpc -o p.exe p.pas $(OBJA) $(GPC_OPTIONS) $(GCC_LIB) $(GPC_FLAGS) $(GPC_MAIN_FLAGS)

# Compile the C console program. In c.c we declare 
# external routines that we will call from ANALYSIS. In
# the objects that go into ANALYSIS, we force fixed names
# upon these same routines with Pascal's "attribute 
# (name=thename)" directive. If you want to use a routine
# from the ANALYSIS that has not fixed name, you must
# edit the Pascal source file and fix the name. For example,
# if you want to use error_function from utils.pas, you
# add "attribute (name=Error_Function);" after the initial
# declaration of the routine in utils.pas, and re-compile.
# For more details see "Mixing Pascal, Fortran, and C with GCC".
c: c.c $(ANALYSIS)
	gcc -o c.exe c.c $(ANALYSIS) $(GCC_LIB) $(GCC_FLAGS)

# Compile the C++ console program. For more details see
# comments above for c and p products, and "Mixing Pascal, 
# Fortran, and C with GCC
cpp: cpp.cpp $(ANALYSIS)
	g++ -o cpp.exe cpp.cpp $(ANALYSIS) $(GCC_LIB) $(GCC_FLAGS)

# Compile the LWDAQ shared library. We instruct gcc
# to create a dynamic library (shared library) that a program
# can load at run-time. The library will include all the
# routines declared in OBJA, OBJB, the TCLTK libraries and
# the Pascal run-time libraries. The lwdaq.o object, which is
# among those listed in OBJB, is a Pascal main program and
# so includes the Pascal initialization routines for all
# pascal units and the run-time library. If you want
# to use the TCL and TK stubs, you have to tell the linker
# not to export symbols from the TCL and TK stub libraries.
# You add "-Wl,--exclude-libs,tclstub84.lib" if the TCL stub
# library is in the default directory and named tclstub84.lib.
# You add a similar command for the TK stub library. You will
# still get a couple of warnings during the link, but they
# are harmless. The "-Wl" option forwards its arguments to the
# linker. The linker is the "ld" utility.
$(LWDAQ): $(OBJA) $(OBJB)
	gcc $(SO) -o $(LWDAQ) $(OBJA) $(OBJB) $(TCLTK_LIB) $(PAS_LIB) $(GCC_LIB) $(GCC_FLAGS) 

# Construct the ANALYSIS static library. We copy the 
# GPC run-time library archive and add all the OBJA and OBJC
# objects to this archive. 
$(ANALYSIS): $(OBJA) $(OBJC)
	cp $(PAS_LIB) $(ANALYSIS)
	ar -r $(ANALYSIS) $(OBJA) $(OBJC)
	ranlib $(ANALYSIS)
	
# Compile ANALYSIS on its own with the target name "analysis".
analysis: $(ANALYSIS)
	
# Compile analysis.pas. This file is a Pascal main program, so gpc generates
# initializers for the other pascal units used by analysis.pas and places
# them in the object file. By default, gpc creates a routine called _main, 
# and this routine will conflict with the _main genterated by any main program 
# that you try to link with analysis.o. So we rename the main routine as 
# Analysis_Main to avoid this conflict.
analysis.o: $(SRC_DIR)/analysis.pas
	gpc -c -o $@ $< $(GPC_OPTIONS) $(GPC_FLAGS) --gpc-main=Analysis_Main	

# Compile any other pascal source files. 
%.o: $(SRC_DIR)/%.pas
	gpc -c -o $@ $< $(GPC_OPTIONS) $(GPC_FLAGS)

# Clean up the intermediate files.
clean: 
	rm *.o *.gpi *.exe *.a
	
# Remove all existing products.
remove:
	rm $(LWDAQ) $(ANALYSIS)
