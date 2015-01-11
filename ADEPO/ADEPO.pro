HEADERS += \
    header/adepo.h \
    header/write_file_obs_mount_system.h \
    header/read_lwdaq_output.h \
    header/read_input.h \
    header/read_calibration_database.h \
    header/Point3f.h \
    header/mount_coord_spots.h \
    header/mount_coord_prism.h \
    header/img_coord_to_bcam_coord.h \
    header/detector.h \
    header/clean_calib.h \
    header/calib2.h \
    header/calib1.h \
    header/calcul_coord_bcam_system.h \
    header/bdd.h \
    header/bcam.h \
    header/atlas_bcam.h \
    header/bcam_adaptateur.h \
    header/absolutes_distances.h \
    header/atlas_coordinates.h \
    header/helmert.h \
    header/bcam_params.h \
    header/changement_repere.h \
    header/mount_prism_to_global_prism.h \
    header/prism_correction.h \
    header/result.h \
    header/lwdaq_client.h \
    header/adepo.h \
    header/global_coord_prism.h \
    header/float_table_widget_item.h \
    header/read_write_ref.h \
    header/prism.h \
    header/bcam_config.h \
    header/dual_spot.h \
    header/spot.h

SOURCES += \
    src/write_file_obs_mount_system.cpp \
    src/read_lwdaq_output.cpp \
    src/read_input.cpp \
    src/read_calibration_database.cpp \
    src/img_coord_to_bcam_coord.cpp \
    src/clean_calib.cpp \
    src/calcul_coord_bcam_system.cpp \
    src/atlas_bcam.cpp \
    src/main.cpp \
    src/helmert.cpp \
    src/changement_repere.cpp \
    src/mount_prism_to_global_prism.cpp \
    src/lwdaq_client.cpp \
    src/bdd.cpp \
    src/read_write_ref.cpp \
    src/write_script.cpp

FORMS += \
    ATLAS_BCAM.ui \

INCLUDEPATH += ./header
INCLUDEPATH += ./eigen-eigen-ffa86ffb5570

QT += core gui network widgets testlib websockets

QMAKE_MAC_SDK = macosx10.9
QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.7

unix:!mac{
  QMAKE_LFLAGS += -Wl,--rpath=/det/ti/PosMov/Qt5.3.0-x86/5.3/gcc/lib
  QMAKE_RPATH=
}
