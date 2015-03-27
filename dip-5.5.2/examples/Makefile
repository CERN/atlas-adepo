#
# Makefile for c++ examples
#

CC = g++
CFLAGS = -Wall -ansi -I ../include

DLIB = ../lib/libdip.so -lpthread -ldl

all:	Server Client

Client:	Client.cpp ../lib/libdip.so
	$(CC) $(CFLAGS) Client.cpp -L../lib $(DLIB) -o Client $(LIBS) 
	
Server:	Server.cpp ../lib/libdip.so
	$(CC) $(CFLAGS) Server.cpp -L../lib $(DLIB) -o Server $(LIBS) 
	
