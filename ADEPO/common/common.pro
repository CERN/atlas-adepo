QT       += core
QT       -= gui

TARGET = adepo-common
CONFIG   -= app_bundle

TEMPLATE = lib
CONFIG += staticlib

SOURCES += \
    read_input.cpp \
    util.cpp

HEADERS += \
    absolute_distances.h \
    atlas_coordinates.h \
    bcam_adapter.h \
    bcam_config.h \
    configuration.h \
    detector.h \
    point3f.h \
    prism.h \
    prism_correction.h \
    read_input.h \
    util.h
