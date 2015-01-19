#-------------------------------------------------
#
# Project created by QtCreator 2015-01-19T22:02:41
#
#-------------------------------------------------

QT       += core gui widgets network

TARGET = adepo-client
TEMPLATE = app

SOURCES += main.cpp \
    socket_server.cpp


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

HEADERS += \
    socket_server.h

