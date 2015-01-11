QT       += core gui widgets testlib websockets

TARGET = adepo-client

TEMPLATE = app

INCLUDEPATH += $$PWD/../eigen-eigen-ffa86ffb5570

SOURCES += \
    atlas_bcam.cpp \
    main.cpp \
    read_write_ref.cpp

HEADERS += \
    atlas_bcam.h \
    float_table_widget_item.h \
    read_write_ref.h \
    result.h

FORMS += \
    ATLAS_BCAM.ui

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.4.0/lib
  QMAKE_RPATH=
}

unix: LIBS += -L$$OUT_PWD/../common/ -ladepo-common

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libadepo-common.a


unix: LIBS += -L$$OUT_PWD/../server/ -ladepo-server

INCLUDEPATH += $$PWD/../server
DEPENDPATH += $$PWD/../server

unix: PRE_TARGETDEPS += $$OUT_PWD/../server/libadepo-server.a
