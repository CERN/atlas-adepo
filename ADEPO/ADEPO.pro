HEADERS += \
    header/write_file_obs_mount_system.h \
<<<<<<< HEAD
=======
    header/write_bash_script.h \
    header/write_aquisifier_script.h \
    header/ui_ATLAS_BCAM.h \
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    header/spot.h \
    header/read_lwdaq_output.h \
    header/read_input.h \
    header/read_calibration_database.h \
    header/Point3f.h \
<<<<<<< HEAD
=======
    header/ouverture_projet.h \
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    header/mount_coord_spots.h \
    header/mount_coord_prism.h \
    header/liste_bcam_from_id_detector.h \
    header/img_coord_to_bcam_coord.h \
    header/detector.h \
<<<<<<< HEAD
=======
    header/detect_flash.h \
    header/converting_time_calibration.h \
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    header/clean_calib.h \
    header/calib2.h \
    header/calib1.h \
    header/calcul_coord_bcam_system.h \
    header/bdd.h \
    header/bcam.h \
<<<<<<< HEAD
    header/atlas_bcam.h \
    header/bcam_adaptateur.h \
    header/absolutes_distances.h \
    header/atlas_coordinates.h \
    header/helmert.h \
    header/bcam_params.h \
    header/changement_repere.h \
    header/mount_prism_to_global_prism.h \
    header/table_names.h \
    header/prism_correction.h

SOURCES += \
    src/write_file_obs_mount_system.cpp \
=======
    header/atlas_bcam.h

SOURCES += \
    src/write_tcl_script.cpp \
    src/write_file_obs_mount_system.cpp \
    src/write_bash_script.cpp \
    src/write_aquisifier_script.cpp \
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    src/spot.cpp \
    src/read_lwdaq_output.cpp \
    src/read_input.cpp \
    src/read_calibration_database.cpp \
    src/Point3f.cpp \
<<<<<<< HEAD
=======
    src/ouverture_projet.cpp \
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    src/mount_coord_spots.cpp \
    src/mount_coord_prism.cpp \
    src/liste_bcam_from_id_detector.cpp \
    src/img_coord_to_bcam_coord.cpp \
    src/detector.cpp \
<<<<<<< HEAD
=======
    src/detect_flash.cpp \
    src/converting_time_calibration.cpp \
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    src/clean_calib.cpp \
    src/calib2.cpp \
    src/calib1.cpp \
    src/calcul_coord_bcam_system.cpp \
    src/bdd.cpp \
    src/bcam.cpp \
    src/atlas_bcam.cpp \
<<<<<<< HEAD
    main.cpp \
    src/bcam_adaptateur.cpp \
    src/absolutes_distances.cpp \
    src/atlas_coordinates.cpp \
    src/helmert.cpp \
    src/bcam_params.cpp \
    src/changement_repere.cpp \
    src/mount_prism_to_global_prism.cpp \
    src/table_names.cpp \
    src/prism_correction.cpp

FORMS += \
    ATLAS_BCAM.ui \

QT += testlib
=======
    main.cpp

FORMS += \
    ATLAS_BCAM.ui
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
