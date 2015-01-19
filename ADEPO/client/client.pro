QT       += core gui widgets testlib network

TARGET = client
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

SOURCES += \
    client_callback.cpp \
    client.cpp

HEADERS += \
    float_table_widget_item.h \
    client.h

FORMS += \
    client.ui


INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a



