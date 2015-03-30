#
# Makefile for c++ examples
#

CC = g++
CFLAGS = -Wall -ansi -I ../include

DLIB = ../lib64/libdip.so -lpthread -ldl

all:	Server Client

Client:	Client.cpp ../lib64/libdip.so
	$(CC) $(CFLAGS) Client.cpp -L../lib64 $(DLIB) -o Client $(LIBS) 
	
Server:	Server.cpp ../lib64/libdip.so
	$(CC) $(CFLAGS) Server.cpp -L../lib64 $(DLIB) -o Server $(LIBS) 
	
