QT       += core network
# needs gui for slots ?
#QT       -= gui

TARGET = server
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

unix:!mac{
  INCLUDEPATH += $$PWD/../log4cplus-slc6/include
}

unix:mac{
  INCLUDEPATH += $$PWD/../log4cplus-macosx/include
}

INCLUDEPATH += $$PWD/../eigen-eigen
INCLUDEPATH += $$PWD/../dip/include
DEPENDPATH += $$PWD/../dip-dummy

SOURCES += \
    lwdaq_client.cpp \
    helmert.cpp \
    server.cpp \
    server_call.cpp \
    write_params_file.cpp \
    write_script_file.cpp \
    read_lwdaq_output.cpp \
    calculate_results.cpp \
    write_settings_file.cpp

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
    server.h \
    dip_error_handler.h \
    dip_server.h


INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a

