#-------------------------------------------------
#
# Project created by QtCreator 2015-01-19T22:02:41
#
#-------------------------------------------------

QT       += core gui widgets network

TARGET = adepo
TEMPLATE = app

SOURCES += main.cpp


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


