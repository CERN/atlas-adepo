HEADERS += \
    header/write_file_obs_mount_system.h \
    header/write_bash_script.h \
    header/write_aquisifier_script.h \
    header/ui_ATLAS_BCAM.h \
    header/spot.h \
    header/read_lwdaq_output.h \
    header/read_input.h \
    header/read_calibration_database.h \
    header/Point3f.h \
    header/ouverture_projet.h \
    header/mount_coord_spots.h \
    header/mount_coord_prism.h \
    header/liste_bcam_from_id_detector.h \
    header/img_coord_to_bcam_coord.h \
    header/detector.h \
    header/detect_flash.h \
    header/converting_time_calibration.h \
    header/clean_calib.h \
    header/calib2.h \
    header/calib1.h \
    header/calcul_coord_bcam_system.h \
    header/bdd.h \
    header/bcam.h \
    header/atlas_bcam.h

SOURCES += \
    src/write_tcl_script.cpp \
    src/write_file_obs_mount_system.cpp \
    src/write_bash_script.cpp \
    src/write_aquisifier_script.cpp \
    src/spot.cpp \
    src/read_lwdaq_output.cpp \
    src/read_input.cpp \
    src/read_calibration_database.cpp \
    src/Point3f.cpp \
    src/ouverture_projet.cpp \
    src/mount_coord_spots.cpp \
    src/mount_coord_prism.cpp \
    src/liste_bcam_from_id_detector.cpp \
    src/img_coord_to_bcam_coord.cpp \
    src/detector.cpp \
    src/detect_flash.cpp \
    src/converting_time_calibration.cpp \
    src/clean_calib.cpp \
    src/calib2.cpp \
    src/calib1.cpp \
    src/calcul_coord_bcam_system.cpp \
    src/bdd.cpp \
    src/bcam.cpp \
    src/atlas_bcam.cpp \
    main.cpp

FORMS += \
    ATLAS_BCAM.ui
