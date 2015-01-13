QT       += core gui widgets testlib network

TARGET = adepo

TEMPLATE = app

INCLUDEPATH += $$PWD/../eigen-eigen-ffa86ffb5570

SOURCES +=

HEADERS +=

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.4.0/lib
  QMAKE_RPATH=
}

unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a


unix: LIBS += -L$$OUT_PWD/../server/ -lserver

INCLUDEPATH += $$PWD/../server
DEPENDPATH += $$PWD/../server

unix: PRE_TARGETDEPS += $$OUT_PWD/../server/libserver.a


unix: LIBS += -L$$OUT_PWD/../client/ -lclient

INCLUDEPATH += $$PWD/../client
DEPENDPATH += $$PWD/../client

unix: PRE_TARGETDEPS += $$OUT_PWD/../client/libclient.a
