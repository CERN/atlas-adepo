#-------------------------------------------------
#
# Project created by QtCreator 2015-03-31T13:48:47
#
#-------------------------------------------------

QMAKE_MAC_SDK = macosx10.11

QT       += core
QT       -= gui

TARGET = dip-dummy
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

INCLUDEPATH += $$PWD/../dip/include

SOURCES += dip_dummy.cpp
