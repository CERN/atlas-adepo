QT       += core network

TARGET = bridge
CONFIG   -= app_bundle

TEMPLATE = aux

HEADERS += \
    bridge.h \
    call.h \
    callback.h

unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a

SOURCES +=
