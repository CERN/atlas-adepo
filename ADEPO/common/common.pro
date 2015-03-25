QT       += core
QT       -= gui

TARGET = common
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

SOURCES += \
    configuration.cpp \
    util.cpp \
    calibration.cpp \
    run.cpp \
    setup.cpp

HEADERS += \
    absolute_distances.h \
    atlas_coordinates.h \
    bcam.h \
    bcam_adapter.h \
    bcam_config.h \
    calib1.h \
    calib2.h \
    configuration.h \
    detector.h \
    prism.h \
    prism_correction.h \
    util.h \
    calibration.h \
    result.h \
    run.h \
    json_rpc.h \
    json_util.h \
    point3d.h \
    results.h \
    setup.h
