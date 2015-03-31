#-------------------------------------------------
#
# Project created by QtCreator 2015-01-19T22:02:41
#
#-------------------------------------------------

QT       += core gui widgets network

TARGET = adepo-direct
TEMPLATE = app

SOURCES += main.cpp

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.4.1/lib
  QMAKE_RPATH=
  INCLUDEPATH += $$PWD/../log4cplus-slc6/include
  LIBS += -L$$PWD/../log4cplus-slc6/lib -llog4cplus
}

unix:mac{
  INCLUDEPATH += $$PWD/../log4cplus-macosx/include
  LIBS += -L$$PWD/../log4cplus-macosx/lib -llog4cplus
}

unix: LIBS += -L$$OUT_PWD/../client/ -lclient

INCLUDEPATH += $$PWD/../client
DEPENDPATH += $$PWD/../client

unix: PRE_TARGETDEPS += $$OUT_PWD/../client/libclient.a


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


unix: LIBS += -L$$OUT_PWD/../dip-dummy/ -ldip-dummy

INCLUDEPATH += $$PWD/../dip/include
DEPENDPATH += $$PWD/../dip-dummy

unix: PRE_TARGETDEPS += $$OUT_PWD/../dip-dummy/libdip-dummy.a

