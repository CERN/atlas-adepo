#-------------------------------------------------
#
# Project created by QtCreator 2015-01-19T22:02:41
#
#-------------------------------------------------

QT       += core gui widgets network websockets

TARGET = adepo-client
TEMPLATE = app

SOURCES += main.cpp \
    socket_client.cpp

HEADERS += \
    socket_client.h

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.5.1/lib
  QMAKE_RPATH=
}

unix: LIBS += -L$$OUT_PWD/../client/ -lclient

INCLUDEPATH += $$PWD/../client
DEPENDPATH += $$PWD/../client

unix: PRE_TARGETDEPS += $$OUT_PWD/../client/libclient.a


INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a


