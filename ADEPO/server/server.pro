QT       += core network
# needs gui for slots ?
#QT       -= gui

TARGET = server
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

INCLUDEPATH += ../eigen-eigen-ffa86ffb5570

SOURCES += \
    helmert.cpp \
    lwdaq_client.cpp \
    server.cpp \
    server_call.cpp \
    write_params_file.cpp \
    write_setttings_file.cpp \
    write_script_file.cpp \
    read_lwdaq_output.cpp

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


INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a

