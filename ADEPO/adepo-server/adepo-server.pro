#-------------------------------------------------
#
# Project created by QtCreator 2015-01-19T21:51:16
#
#-------------------------------------------------

QT       += core network websockets

QT       -= gui

TARGET = adepo-server
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app

SOURCES += main.cpp \
    socket_server.cpp

HEADERS += \
    socket_server.h

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.4.2/lib
  QMAKE_LFLAGS += -Wl,--rpath=$$PWD/../dip/lib64
  QMAKE_RPATH=
  INCLUDEPATH += $$PWD/../log4cplus-slc6/include
  LIBS += -L$$PWD/../dip/lib64 -ldip -llog4cplus
}

unix:mac{
  INCLUDEPATH += $$PWD/../log4cplus-macosx/include
  LIBS += -L$$OUT_PWD/../dip-dummy/ -ldip-dummy
  LIBS += -L$$PWD/../log4cplus-macosx/lib -llog4cplus
}

INCLUDEPATH += $$PWD/../dip/include
DEPENDPATH += $$PWD/../dip-dummy

unix: LIBS += -L$$OUT_PWD/../server/ -lserver

INCLUDEPATH += $$PWD/../server
DEPENDPATH += $$PWD/../server

unix: PRE_TARGETDEPS += $$OUT_PWD/../server/libserver.a


INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a


