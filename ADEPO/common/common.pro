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
    setup.cpp \
    reference.cpp

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
    point3f.h \
    prism.h \
    prism_correction.h \
    util.h \
    calibration.h \
    setup.h \
    reference.h \
    result.h