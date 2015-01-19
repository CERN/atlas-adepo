QT       += core network
QT       -= gui

TARGET = server
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

INCLUDEPATH += ../eigen-eigen-ffa86ffb5570

SOURCES += \
    data.cpp \
    helmert.cpp \
    lwdaq_client.cpp \
    server.cpp \
    main.cpp \
    server_call.cpp

HEADERS += \
    adepo.h \
    bcam_params.h \
    data.h \
    dual_spot.h \
    global_coord_prism.h \
    lwdaq_client.h \
    mount_coord_prism.h \
    mount_coord_spots.h \
    spot.h \
    server.h

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.4.0/lib
  QMAKE_RPATH=
}


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a


unix: LIBS += -L$$OUT_PWD/../bridge/ -lbridge

INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge

unix: PRE_TARGETDEPS += $$OUT_PWD/../bridge/libbridge.a
