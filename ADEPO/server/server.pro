QT       += core network
QT       -= gui

TARGET = server
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG+= staticlib

INCLUDEPATH += ../eigen-eigen-ffa86ffb5570

SOURCES += \
    bdd.cpp \
    calcul_coord_bcam_system.cpp \
    changement_repere.cpp \
    helmert.cpp \
    img_coord_to_bcam_coord.cpp \
    lwdaq_client.cpp \
    mount_prism_to_global_prism.cpp \
    write_file_obs_mount_system.cpp \
    server.cpp

HEADERS += \
    adepo.h \
    bcam_params.h \
    bdd.h \
    calcul_coord_bcam_system.h \
    changement_repere.h \
    dual_spot.h \
    global_coord_prism.h \
    helmert.h \
    img_coord_to_bcam_coord.h \
    lwdaq_client.h \
    mount_coord_prism.h \
    mount_coord_spots.h \
    mount_prism_to_global_prism.h \
    spot.h \
    write_file_obs_mount_system.h \
    server.h

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.4.0/lib
  QMAKE_RPATH=
}


unix: LIBS += -L$$OUT_PWD/../server/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a
