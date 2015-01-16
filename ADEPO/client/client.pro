QT       += core gui widgets testlib network

TARGET = adepo-client

TEMPLATE = app

SOURCES += \
    atlas_bcam.cpp \
    main.cpp \
    read_write_ref.cpp \
    client_callback.cpp

HEADERS += \
    atlas_bcam.h \
    float_table_widget_item.h \
    read_write_ref.h \
    result.h

FORMS += \
    ATLAS_BCAM.ui


unix: LIBS += -L$$OUT_PWD/../common/ -lcommon

INCLUDEPATH += $$PWD/../common
DEPENDPATH += $$PWD/../common

unix: PRE_TARGETDEPS += $$OUT_PWD/../common/libcommon.a


unix: LIBS += -L$$OUT_PWD/../bridge/ -lbridge

INCLUDEPATH += $$PWD/../bridge
DEPENDPATH += $$PWD/../bridge

unix: PRE_TARGETDEPS += $$OUT_PWD/../server/libserver.a

unix: LIBS += -L$$OUT_PWD/../server/ -lserver

INCLUDEPATH += $$PWD/../server
DEPENDPATH += $$PWD/../server

unix: PRE_TARGETDEPS += $$OUT_PWD/../server/libserver.a
