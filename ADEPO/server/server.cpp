#include <QDir>

#include "bridge.h"
#include "server.h"
#include "bcam_config.h"
#include "util.h"

#include "Eigen/Core"
#include "Eigen/LU"

#define bcam_tc255_center_x 1.720
#define bcam_tc255_center_y 1.220

#define mm2m 0.001
#define um2m 0.000001

Server::Server(Callback &callback, QObject *parent) : QObject(parent), callback(callback) {
    std::cout << "SERVER AppPath: " << Util::appPath().toStdString() << std::endl;
    std::cout << "SERVER InputPath: " << Util::inputPath().toStdString() << std::endl;
    std::cout << "SERVER WorkPath: " << Util::workPath().toStdString() << std::endl;

    // connect to LWDAQ server
    lwdaq_client = new LWDAQ_Client("localhost", 1090, this);
    connect(lwdaq_client, &LWDAQ_Client::stateChanged, this, &Server::lwdaqStateChanged);
    connect(lwdaq_client, &LWDAQ_Client::remainingTimeChanged, this, &Server::timeChanged);

    QDir lwdaqDir = lwdaq_client->find(QDir(Util::appPath()));
    if (!lwdaqDir.exists()) {
        qCritical() << "FATAL: could not find LWDAQ directory up from " << Util::appPath();
        exit(1);
    } else {
        std::cout << "SERVER Found LWDAQ installation at " << lwdaqDir.absolutePath().toStdString() << std::endl;
    }

    previousState = LWDAQ_UNKNOWN;
    needToCalculateResults = false;

    adepoState = ADEPO_UNKNOWN;

    waitingTimer = new QTimer(this);
    waitingTimer->setSingleShot(true);
    connect(waitingTimer, &QTimer::timeout, this, &Server::runDAQ);

    updateTimer = new QTimer(this);
    updateTimer->setInterval(FAST_UPDATE_TIME*1000);
    updateTimer->setSingleShot(false);
    connect(updateTimer, &QTimer::timeout, this, &Server::timeChanged);

    // connect to dip
    dipServer.connect();

    // read files
    config.read(Util::inputPath().append(CONFIGURATION_FILE));
    run.read(Util::workPath().append(RUN_FILE));

    helmert(config, data);

    QString result = config.check();
    if (result != "") {
        qCritical() << result;
        std::exit(1);
    }

    //lecture du fichier de calibration
    calibration.read(Util::inputPath().append(CALIBRATION_FILE));

    // read files
    offset.read(Util::workPath().append(OFFSET_FILE));
    reference.read(Util::workPath().append(REFERENCE_FILE));
    output.read(Util::workPath().append(OUTPUT_FILE));
    resultFile = Util::workPath().append(DEFAULT_RESULT_FILE);

    setup.init(run, config);
    dipServer.createPublishers(setup);

    std::cout << "SERVER Using " << run.getFileName().toStdString() << std::endl;

    lwdaq_client->init();
}

void Server::startDAQ()
{
    qDebug() << "SERVER start DAQ";

    writeParamsFile(Util::workPath().append(DEFAULT_PARAM_FILE));

    writeSettingsFile(Util::workPath().append(DEFAULT_SETTINGS_FILE),
                      Util::workPath().append(DEFAULT_SCRIPT_FILE),
                      Util::workPath().append(DEFAULT_RESULT_FILE));

    writeScriptFile(Util::workPath().append(DEFAULT_SCRIPT_FILE));

    qDebug() << "SERVER Connecting to LWDAQ on " << config.getDriverIpAddress();

    runDAQ();
}

void Server::runDAQ() {
    qDebug() << "SERVER run DAQ";
    needToCalculateResults = true;

    QFile file(Util::workPath().append(DEFAULT_RESULT_FILE));
    qDebug() << "*** Removing " << file.fileName();
    if (file.exists() && !file.remove()) {
        qWarning() << "SERVER Cannot remove result file " << file.fileName();
        qWarning() << "SERVER Start aborted.";
        return;
    }

    lwdaq_client->startRun(Util::workPath(), run.getAcquisitionTime());
}

void Server::stopDAQ()
{
    qDebug() << "SERVER stop DAQ";
    needToCalculateResults = false;

    if (run.getMode() == MODE_MONITORING) {
        waitingTimer->stop();
        updateTimer->stop();
    }

    if (lwdaq_client->getState() == LWDAQ_IDLE) {
        adepoState = ADEPO_IDLE;
    } else {
        lwdaq_client->stopRun();
    }

    run.setMode(MODE_CLOSURE);
    updateState();
}

void Server::lwdaqStateChanged() {
    qDebug() << "SERVER LWDAQ state changed to " << lwdaq_client->getState();

    if (lwdaq_client->getState() == LWDAQ_IDLE) {
        if (needToCalculateResults) {
            // calculate
            adepoState = ADEPO_CALCULATING;
            callback.changedResult(resultFile);
            updateState();
            calculateCoordinates();
            needToCalculateResults = false;
        }

        if (run.getMode() == MODE_MONITORING) {
            adepoState = ADEPO_WAITING;
            waitingTimer->start(run.getWaitingTime()*1000);
            updateTimer->start();
        } else {
            adepoState = ADEPO_IDLE;
            waitingTimer->stop();
            updateTimer->stop();
        }
        updateState();
    } else if (lwdaq_client->getState() == LWDAQ_RUN) {
        adepoState = ADEPO_RUN;
        updateState();
    } else if (lwdaq_client->getState() == LWDAQ_STOP) {
        adepoState = run.getMode() == MODE_MONITORING ? ADEPO_RUN : ADEPO_STOP;
        updateState();
    } else if (lwdaq_client->getState() == LWDAQ_CONNECTING) {
        adepoState = ADEPO_CONNECTING;
        updateState();
        needToCalculateResults = false;
    }

    previousState = lwdaq_client->getState();
}

void Server::timeChanged() {
    updateState(true);
}

void Server::updateState(bool timeChange) {
    if (!timeChange) {
        qDebug() << "SERVER state changed to (ADEPO) " << adepoState << " (LWDAQ) " << lwdaq_client->getState();
    }
    callback.changedState(adepoState, waitingTimer->remainingTime()/1000, lwdaq_client->getState(), lwdaq_client->getRemainingTime()/1000);
}

//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM + suavegarde            [----> ok
void Server::calculateCoordinates()
{
   //je lis le fichier de sortie de LWDAQ qui contient les observations puis je stocke ce qui nous interesse dans la bdd
   int lecture_output_result = readLWDAQOutput(resultFile);

   if(lecture_output_result == 0 )
   {
       qWarning() << "Output file cannot be found at " << resultFile;
       return;
   }

   //je fais la transformation du capteur CCD au systeme MOUNT. Attention, la lecture du fichier de calibration est deja faite !
   imgCoordToBcamCoord();

   //je calcule les coordonnees du prisme en 3D dans le repere MOUNT
   calculCoordBcamSystem();

   //je calcule les coordonnees du prisme en 3D dans le repere ATLAS
   mountPrismToGlobalPrism();

   calculateResults();

   dipServer.sendResults(output);

   output.write();

   qDebug() << "Updating Output...";
   callback.changedOutput(output.getFilename());

   //enregistrement du fichier qui contient les observations dans le repere CCD et dans le repere MOUNT : spots + prismes
   QDir(".").mkpath(Util::workPath().append("/Archive"));

   // current date/time based on current system
   QString now = getDateTime();

   writeFileObsMountSystem(Util::workPath().append("/Archive/Observations_MOUNT_System_").append(now).append(".txt"), now);

//   settings.setValue(RESULT_FILE, fileName);

   //vidage des acquisitions
   data.clear();
}



QString Server::getDateTime() {
    time_t now = time(0);
    tm* ltm = localtime(&now);

    // print various components of tm structure.
    int year = 1900 + ltm->tm_year;
    int month = 1 + ltm->tm_mon;
    int day = ltm->tm_mday;
    int hour = ltm->tm_hour;
    int min = ltm->tm_min;
    int sec = ltm->tm_sec;

    QString dateTime = QString("%1.%2.%3.%4.%5.%6").arg(year, 4).arg(month, 2, 10, QChar('0')).arg(day, 2, 10, QChar('0')).
            arg(hour, 2, 10, QChar('0')).arg(min, 2, 10, QChar('0')).arg(sec, 2, 10, QChar('0'));
    return dateTime;
}





//fonction de transformation du repere ccd au repere BCAM (MOUNT)
void Server::imgCoordToBcamCoord()
{
    bool found = false;
    for(int i=0; i<data.getDualSpots().size(); i++) //je parcours la base de donnees des coordonnees images
    {
        for (int j=0; j<calibration.getCalibs1().size(); j++) //je parcours la base de donnees qui contient les informations de calibration
        {
            DualSpot spot = data.getDualSpots().at(i);
            Calib1 calib1 = calibration.getCalibs1().at(j);
            // NumChip == 2 is Z+ direction
            int num_chip = setup.getBCAM(spot.getName()).getPrism().getNumChip();
            bool directionOk = ((num_chip == 2) && (calib1.getDirection() == 1)) || ((num_chip == 1) && (calib1.getDirection() == -1));
//            std::cout << spot.getBCAM() << " " << calib1.getBCAM() << " " << directionOk << " " <<  num_chip << " " << calib1.getCoordAxis().z() << std::endl;

            // check for name and direction.
            if (spot.getBCAM().getName() == calib1.getBCAM() && directionOk)
            {
                //transformation des coordonnees IMAGE vers le repere MOUNT

                Eigen::MatrixXd ccd1(1,3);       //vecteur des coordonnees images1
                ccd1(0,0)=spot.getSpot1().i()*um2m;
                ccd1(0,1)=spot.getSpot1().j()*um2m;
                ccd1(0,2)=0;
                //std::cout<<ccd<<std::endl;

                Eigen::MatrixXd ccd2(1,3);       //vecteur des coordonnees images2
                ccd2(0,0)=spot.getSpot2().i()*um2m;
                ccd2(0,1)=spot.getSpot2().j()*um2m;
                ccd2(0,2)=0;
                //std::cout<<ccd<<std::endl;

                Eigen::MatrixXd centre(1,3);    //vecteur du centre du ccd dans le systeme MOUNT
                centre(0,0)=bcam_tc255_center_x*mm2m;
                centre(0,1)=bcam_tc255_center_y*mm2m;
                centre(0,2)=0;
                //std::cout<<centre<<std::endl;

                Eigen::MatrixXd pivot(1,3);     //vecteur pivot
                pivot(0,0)=calib1.getCoordPivot().x()*mm2m;
                pivot(0,1)=calib1.getCoordPivot().y()*mm2m;
                pivot(0,2)=calib1.getCoordPivot().z()*mm2m;
                //std::cout<<pivot<<std::endl;

                Eigen::MatrixXd axis(1,3);      //vecteur axis
                axis(0.0)=calib1.getCoordAxis().x()*mm2m;
                axis(0,1)=calib1.getCoordAxis().y()*mm2m;
                axis(0,2)=calib1.getCoordAxis().z(); // NOTE, unit-less just gives direction of the bcam as 1 and -1
                //std::cout<<axis<<std::endl;

                Eigen::MatrixXd rotation(3,3);  //matrice rotation en fonction du signe de axis.z
                if(axis(0,2) > 0)
                {
                    rotation(0,0)=cos(-calib1.getCcdRotation()*mm2m);
                    rotation(1,0)=sin(-calib1.getCcdRotation()*mm2m);
                    rotation(2,0)=0;
                    rotation(0,1)=-sin(-calib1.getCcdRotation()*mm2m);
                    rotation(1,1)=cos(-calib1.getCcdRotation()*mm2m);
                    rotation(2,1)=0;
                    rotation(0,2)=0;
                    rotation(1,2)=0;
                    rotation(2,2)=1;
                }
                else
                {
                    rotation(0,0)=-cos(-calib1.getCcdRotation()*mm2m);
                    rotation(1,0)=sin(-calib1.getCcdRotation()*mm2m);
                    rotation(2,0)=0;
                    rotation(0,1)=sin(-calib1.getCcdRotation()*mm2m);
                    rotation(1,1)=cos(-calib1.getCcdRotation()*mm2m);
                    rotation(2,1)=0;
                    rotation(0,2)=0;
                    rotation(1,2)=0;
                    rotation(2,2)=1;
                }
                // std::cout<<rotation<<std::endl;

                //transformation1           //vecteur mount 1
                Eigen::MatrixXd coord_mount1(3,1);
                coord_mount1=(ccd1-centre)*rotation + pivot - calib1.getCcdToPivot()*mm2m*axis;
                //std::cout<<coord_mount<<std::endl;

                //transformation2           //vecteur mount 2
                Eigen::MatrixXd coord_mount2(3,1);
                coord_mount2=(ccd2-centre)*rotation + pivot - calib1.getCcdToPivot()*mm2m*axis;
                //std::cout<<coord_mount<<std::endl;

                //sauvegarde dans la base de donnee
                Point3d mount_sp1(coord_mount1(0,0), coord_mount1(0,1), coord_mount1(0,2));
                Point3d mount_sp2(coord_mount2(0,0), coord_mount2(0,1), coord_mount2(0,2));
                MountCoordSpots mount_couple_spots(spot.getBCAM(), mount_sp1, mount_sp2);
                data.add(mount_couple_spots);

                found = true;
            }
        }
    }

    //affichage de la base de donnees qui contient les observations transformees dans le repere MOUNT
#ifdef ADEPO_DEBUG
    for(unsigned int i=0; i<data.getMountCoordSpots().size(); i++)
    {
        data.getMountCoordSpots().at(i).print();
    }
#endif

    if (!found) {
        std::cout << "WARNING: no img_coord_to_bcam_coord found, some setup file may be missing..." << std::endl;
    }
}

void Server::calculCoordBcamSystem()
{
    bool found = false;
    for (int i=0; i<data.getMountCoordSpots().size(); i++) // je parcours la database qui contient les coord des observation dans le system MOUNT
    {
        MountCoordSpots spot = data.getMountCoordSpots().at(i);

        for (int j=0; j<calibration.getCalibs1().size(); j++) //je parcours la base de donnee de calibration 1
        {
            Calib1 calib1 = calibration.getCalibs1().at(j);

            // NumChip == 2 is Z+ direction
            int num_chip = setup.getBCAM(spot.getName()).getPrism().getNumChip();
            bool directionOk1 = ((num_chip == 2) && (calib1.getDirection() == 1)) || ((num_chip == 1) && (calib1.getDirection() == -1));

            for(int k=0; k<calibration.getCalibs2().size(); k++) //je parcours la base de donnee de calibration 2
            {
                Calib2 calib2k = calibration.getCalibs2().at(k);
                Calib2 calib2j = calibration.getCalibs2().at(j);

                bool directionOk2 = ((num_chip == 2) && (calib2k.getDirection() == 1)) || ((num_chip == 1) && (calib2k.getDirection() == -1));

                for(int l=0; l<config.getAbsoluteDistances().size(); l++) //je parcours la base de donnee des distances absolues
                {
                    AbsoluteDistances absolutes_distances = config.getAbsoluteDistances().at(l);

                    if(spot.getBCAM().getName() == calib1.getBCAM() && directionOk1 &&
                            spot.getBCAM().getName() == calib2k.getBCAM() && directionOk2 &&
                            spot.getName() == absolutes_distances.getName())
                    {
                        //calcul du mileu de la distance entre les 2 spots sur le ccd
                        float milieu_x = (spot.getCoord1().x() + spot.getCoord2().x())/2;
                        float milieu_y = (spot.getCoord1().y() + spot.getCoord2().y())/2;
                        float milieu_z = (spot.getCoord1().z() + spot.getCoord2().z())/2;

                        //focale 3D = distance entre point milieu et pivot
                        float focale = sqrt(pow(milieu_x - calib1.getCoordPivot().x()*mm2m,2) +
                                            pow(milieu_y - calib1.getCoordPivot().y()*mm2m,2) +
                                            pow(milieu_z - calib1.getCoordPivot().z()*mm2m,2));

                        //distances absolues
                        float D1 = (absolutes_distances.getDistances().x() + absolutes_distances.getDistances().y());   //deja en metre
                        float D2 = (absolutes_distances.getDistances().x() + absolutes_distances.getDistances().z()); //deja en metre

                        //si la distance est nulle ==> distance BCAM pour le calcul des coordonnees du prisme
                        if(D1 == 0 || D2 == 0)
                        {
                            float dist_sources = sqrt(pow(calib2j.getCoordFlash1().x() - calib2j.getCoordFlash2().x(),2) +
                                                      pow(calib2j.getCoordFlash1().y() - calib2j.getCoordFlash2().y(),2) +
                                                      pow(calib2j.getCoordFlash1().z() - calib2j.getCoordFlash2().z(),2));
                            float dist_cheep = sqrt(pow(spot.getCoord1().x() - spot.getCoord2().x(),2) +
                                                    pow(spot.getCoord1().y() - spot.getCoord2().y(),2) +
                                                    pow(spot.getCoord1().z() - spot.getCoord2().z(),2));
                            D1 = (dist_sources*mm2m*focale)/(dist_cheep);
                            D2 = D1;
                        }

                        //composante X
                        float a1_x = calib2k.getCoordFlash1().x()*mm2m + calib1.getCoordPivot().x()*mm2m;
                        float b1_x = spot.getCoord1().x() - calib1.getCoordPivot().x()*mm2m;
                        float c1_x = D1/focale;
                        float prisme_x1 = a1_x-b1_x*c1_x;

                        float a2_x = calib2k.getCoordFlash2().x()*mm2m + calib1.getCoordPivot().x()*mm2m;
                        float b2_x = spot.getCoord2().x() - calib1.getCoordPivot().x()*mm2m;
                        float c2_x = D2/focale;
                        float prisme_x2 = a2_x-b2_x*c2_x;

                        //composante Y
                        float a1_y = calib2k.getCoordFlash1().y()*mm2m + calib1.getCoordPivot().y()*mm2m;
                        float b1_y = spot.getCoord1().y() - calib1.getCoordPivot().y()*mm2m;
                        float c1_y = D1/focale;
                        float prisme_y1 = a1_y-b1_y*c1_y;

                        float a2_y = calib2k.getCoordFlash2().y()*mm2m + calib1.getCoordPivot().y()*mm2m;
                        float b2_y = spot.getCoord2().y() - calib1.getCoordPivot().y()*mm2m;
                        float c2_y = D2/focale;
                        float prisme_y2 = a2_y-b2_y*c2_y;

                        //composante Z
                        float a1_z = calib2k.getCoordFlash1().z()*mm2m + calib1.getCoordPivot().z()*mm2m;
                        float b1_z = spot.getCoord1().z() - calib1.getCoordPivot().z()*mm2m;
                        float c1_z = D1/focale;
                        float prisme_z1 = a1_z-b1_z*c1_z;

                        float a2_z = calib2k.getCoordFlash2().z()*mm2m + calib1.getCoordPivot().z()*mm2m;
                        float b2_z = spot.getCoord2().z() - calib1.getCoordPivot().z()*mm2m;
                        float c2_z = D2/focale;
                        float prisme_z2 = a2_z-b2_z*c2_z;

                        float coordPrisme_x = (prisme_x1+prisme_x2)/4;
                        float coordPrisme_y = (prisme_y1+prisme_y2)/4;
                        float coordPrisme_z = (prisme_z1+prisme_z2)/4;

                        //ajout dans la base de donnees (check multiplication by Z? )
//                        std::cout << spot.getName() << " " << calib1.getCoordAxis().z() << " " << num_chip << std::endl;
                        Point3d xyz(coordPrisme_x, coordPrisme_y, coordPrisme_z);
                        MountCoordPrism xyz_prism(spot.getBCAM(), xyz);
                        data.add(xyz_prism);
                        found = true;
                    }
                }

            }

        }
    }

    if (!found) {
        std::cout << "WARNING: No calcul_coord_bcam_system found, some setup file may be missing." << std::endl;
    }

    //affichage base donnee des coordonnees des prismes dans le systeme MOUNT
#ifdef ADEPO_DEBUG
    for(unsigned int i=0; i<data.getMountCoordPrisms().size(); i++)
    {
        data.getMountCoordPrisms().at(i).print();
    }
#endif
}

void Server::mountPrismToGlobalPrism()
{
    bool found = false;
    for(int i=0; i<data.getMountCoordPrisms().size(); i++)
    {
        MountCoordPrism prism = data.getMountCoordPrisms().at(i);
        float airpad = run.getAirpad() ? config.getDetector(prism.getBCAM().getName()).getAirpad() : 0.0f;

        for(int j=0; j<data.getBCAMParams().size(); j++)
        {
            BCAMParams params = data.getBCAMParams().at(j);

            if(prism.getBCAM().getName() == params.getBCAM())
            {
                 Point3d point_transforme = changeReference(prism.getCoordPrismMountSys(),
                                                            params.getTranslation(),
                                                            params.getRotation());
                 Point3d point_airpad(point_transforme.x(), point_transforme.y()+airpad, point_transforme.z());
                 GlobalCoordPrism pt_global(prism.getBCAM(), point_airpad, airpad);
                 data.add(pt_global);
                 found = true;
            }
        }
    }

    //affichage base de donnee des prismes dans le repere global
#ifdef ADEPO_DEBUG
    for(int k=0; k<data.getGlobalCoordPrisms().size(); k++)
    {
        data.getGlobalCoordPrisms().at(k).print();
    }
#endif

    if (!found) {
        std::cout << "WARNING: no mount_prism_to_global_prism found, some setup file may be missing..." << std::endl;
    }
}


int Server::writeFileObsMountSystem(QString fileName, QString datetime)
{
    //écriture dans un fichier
    std::ofstream fichier(fileName.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(!fichier)
    {
        std::cout << "WARNING Cannot write output file " << fileName.toStdString() << std::endl;
        return 0;
    }

  // setup default precision
    fichier<<std::fixed<<std::setprecision(8);

    qDebug() << "Writing results into " << fileName;

    fichier<<"********** Fichier qui contient une sauvegarde des coordonnees images + coordonnees images transformees dans le repere BCAM (MOUNT) + coordonnees des prismes dans le repere MOUNT********** \n"
           <<"********************************************************************** Unite en metres (m)************************************************************************************************** \n"
           <<"\n";

        //premiere visee BCAM-Prisme de la liste des observations
        QString premier_objet_img= data.getDualSpots().at(0).getName();

        //sauvegarde des coordonnees images
        fichier<<"*******************************************************************coordonnees images dans le repere CCD *********************************************************************************** \n";
        for(int i=0; i<data.getDualSpots().size(); i++)
        {
            DualSpot spot1 = data.getDualSpots().at(i);
            if(i>0 && spot1.getName() == premier_objet_img) //si on a tout parcourut et on revient au premier objet ==> fin
                break;

            fichier<<spot1.getName().toStdString()<<"\n";
            for(int j=0; j<data.getDualSpots().size(); j++)
            {
                DualSpot spot2 = data.getDualSpots().at(j);
                if(spot1.getName() == spot2.getName())
                {
                    fichier
                                   <<"Spot 1"<<" "<<std::setw(14)<<spot2.getSpot1().i()*um2m<<" "<<std::setw(14)<<spot2.getSpot1().j()*um2m<<"\n"
                                   <<"Spot 2"<<" "<<std::setw(14)<<spot2.getSpot2().i()*um2m<<" "<<std::setw(14)<<spot2.getSpot2().j()*um2m<<"\n";
                }
            }
        }

        fichier<<"\n"
               <<"\n"
               <<"****************************************************************coordonnees images transformees dans le repere MOUNT************************************************************************* \n";
        QString premier_objet_mount = data.getMountCoordSpots().at(0).getName();

        //sauvegarde des coordonnees images transformees dans le repere MOUNT
        for(int i=0; i<data.getMountCoordSpots().size(); i++)
        {
            MountCoordSpots spots1 = data.getMountCoordSpots().at(i);
//                std::cout << data.getMountCoordSpots().size() << " " << spots1.getName() << " " << premier_objet_mount << std::endl;
            if(i>0 && spots1.getName() == premier_objet_mount) //si on a tout parcourut et on revient au premier objet ==> fin
                break;

            fichier<<spots1.getName().toStdString()<<"\n";
            for(int j=0; j<data.getMountCoordSpots().size(); j++)
            {
                MountCoordSpots spots2 = data.getMountCoordSpots().at(j);
                if(spots1.getName() == spots2.getName())
                {
                    fichier<<"Spot 1"<<" "<<std::setw(14)<<spots2.getCoord1().x()<<" "<<std::setw(14)<<spots2.getCoord1().y()<<" "<<std::setw(14)<<spots2.getCoord1().z()<<"\n"
                           <<"Spot 2"<<" "<<std::setw(14)<<spots2.getCoord2().x()<<" "<<std::setw(14)<<spots2.getCoord2().y()<<" "<<std::setw(14)<<spots2.getCoord2().z()<<"\n";
                }
            }
        }

        fichier<<"\n"
               <<"\n"
               <<"*****************************************************************coordonnees du prisme dans le repere MOUNT********************************************************************************** \n";
        //sauvegarde des coordonnees du prisme dans le repere MOUNT pour chaque paire de spots
        QString premier_prisme_mount = data.getMountCoordPrisms().at(0).getName();

        for(int i=0; i<data.getMountCoordPrisms().size(); i++)
        {
            MountCoordPrism prism1 = data.getMountCoordPrisms().at(i);
            if(i>0 && prism1.getName() == premier_prisme_mount) //si on a tout parcourut et on revient au premier objet ==> fin
                break;

            fichier<<prism1.getName().toStdString()<<"\n";
            for(int j=0; j<data.getMountCoordPrisms().size(); j++)
            {
                MountCoordPrism prism2 = data.getMountCoordPrisms().at(j);
                if(prism1.getName() == prism2.getName())
                {
                    fichier<<std::setw(14)<<prism2.getCoordPrismMountSys().x()<<" "<<std::setw(14)<<prism2.getCoordPrismMountSys().y()<<" "<<std::setw(14)<<prism2.getCoordPrismMountSys().z()<<"\n";
                }
            }
        }

        fichier<<"\n"
               <<"\n"
               <<"*****************************************************************coordonnees du prisme dans le repere ATLAS********************************************************************************** \n";
        //sauvegarde des coordonnees du prisme dans le repere ATLAS pour chaque paire de spots
        QString premier_prisme_atlas = data.getGlobalCoordPrisms().at(0).getName();

        for(int i=0; i<data.getGlobalCoordPrisms().size(); i++)
        {
            GlobalCoordPrism prism1 = data.getGlobalCoordPrisms().at(i);
            if(i>0 && prism1.getName() == premier_prisme_atlas)
                break;

            fichier<<prism1.getName().toStdString()<<" "<<prism1.getAirpad()<<"\n";
            for(int j=0; j<data.getGlobalCoordPrisms().size(); j++)
            {
                GlobalCoordPrism prism2 = data.getGlobalCoordPrisms().at(j);
                if(prism1.getName() == prism2.getName())
                {
                    fichier<<std::setw(14)<<prism2.getCoordPrismMountSys().x()<<" "<<std::setw(14)<<prism2.getCoordPrismMountSys().y()<<" "<<std::setw(14)<<prism2.getCoordPrismMountSys().z()<<"\n";
                }
            }
        }
        fichier<<"\n"
               <<"\n"
               <<"*****************************************************************Rapport********************************************************************************** \n";
        //on parcourt tous les points transformes dans le repere global : moyenne + dispersion

        for(int i=0; i<data.getGlobalCoordPrisms().size(); i++)
        {
            GlobalCoordPrism prism1 = data.getGlobalCoordPrisms().at(i);
            if(i>0 && prism1.getName() == premier_prisme_atlas)
                break;

            Eigen::MatrixXd coord(Eigen::DynamicIndex,3);
            int ligne=0;

            for(int j=0; j<data.getGlobalCoordPrisms().size(); j++)
            {
                GlobalCoordPrism prism2 = data.getGlobalCoordPrisms().at(j);
                if(prism1.getName() == prism2.getName())
                {
                    coord(ligne,0)=prism2.getCoordPrismMountSys().x();
                    coord(ligne,1)=prism2.getCoordPrismMountSys().y();
                    coord(ligne,2)=prism2.getCoordPrismMountSys().z();
                    ligne=ligne+1;
                }
            }
            Eigen::MatrixXd result_mean(1,3); //resultat de la moyenne
            result_mean=coord.colwise().sum()/ligne; //somme de chaque colonne / par le nombre de lignes

            Eigen::MatrixXd result_var(ligne,3); //calcul de la variance
            for(int k=0; k<ligne; k++)
            {
                result_var(k,0)=(coord(k,0)-result_mean(0,0))*(coord(k,0)-result_mean(0,0));
                result_var(k,1)=(coord(k,1)-result_mean(0,1))*(coord(k,1)-result_mean(0,1));
                result_var(k,2)=(coord(k,2)-result_mean(0,2))*(coord(k,2)-result_mean(0,2));
            }

            Eigen::MatrixXd result_std_square(1,3); //calcul de l'ecart-type au carre
            result_std_square=result_var.colwise().sum()/ligne;

            Eigen::MatrixXd result_std(1,3);       //calcul de l'ecart-type
            for(int m=0; m<3; m++)
            {
                result_std(0,m) = sqrt(result_std_square(0,m));
            }

            //nomenclature dans le repere ATLAS
            GlobalCoordPrism prism = prism1;
            QString name_bcam_atlas = config.getName(prism.getBCAM().getName());
            QString name_prism_atlas = config.getName(prism.getPrism().getName());
            float airpad = prism1.getAirpad();

            //delta selon composantes axiales
            float delta_x=0;
            float delta_y=0;
            float delta_z=0;
            //ajout de la constante de prisme
            for(int n=0; n<config.getPrismCorrections().size(); n++)
            {
                PrismCorrection correction = config.getPrismCorrections().at(n);
                if(prism1.getPrism().getName() == correction.getPrism())
                {
                    delta_x = correction.getDelta().x();
                    delta_y = correction.getDelta().y();
                    delta_z = correction.getDelta().z();
                }
            }
            //enregistrement dans le fichier de resultats
            QString name = name_bcam_atlas.append("_").append(name_prism_atlas);
            fichier<<std::left<<std::setw(30)<<name.toStdString()<<" "<<datetime.toStdString()<<" "
                 <<std::right<<std::setw(14)<<result_mean(0,0)+delta_x<<" "<<std::setw(14)<<result_mean(0,1)+delta_y<<" "<<std::setw(14)<<result_mean(0,2)+delta_z<<" "
                 <<std::setw(14)<<result_std(0,0)<<" "<<std::setw(14)<<result_std(0,1)<<" "<<std::setw(14)<<result_std(0,2)
                 <<" "<<airpad<<" VRAI \n";
        }

    fichier.close();
    return 1;
}

Point3d Server::changeReference(Point3d coord_sys1, Point3d translation, Point3d rotation)
{

    float x_sys1 = coord_sys1.x();
    float y_sys1 = coord_sys1.y();
    float z_sys1 = coord_sys1.z();

    //vecteur point dans systeme 1
    Eigen::MatrixXd pt_sys1(1,3); pt_sys1.setZero();
    pt_sys1(0,0)=x_sys1; pt_sys1(0,1)=y_sys1; pt_sys1(0,2)=z_sys1;
    /*std::cout<<"pt_sys1"<<std::endl;
    std::cout<<pt_sys1<<std::endl;
    std::cout<<"---------->"<<std::endl;*/

    float Tx0 = translation.x();
    float Ty0 = translation.y();
    float Tz0 = translation.z();

    //vecteur translation
    Eigen::MatrixXd T(1,3); T.setZero();
    T(0,0)=Tx0; T(0,1)=Ty0; T(0,2)=Tz0;
    /*std::cout<<"translation"<<std::endl;
    std::cout<<T<<std::endl;
    std::cout<<"---------->"<<std::endl;*/

    float phi0 = rotation.x();
    float teta0 = rotation.y();
    float psi0 = rotation.z();

    /*std::cout<<teta0<<std::endl;
    std::cout<<phi0<<std::endl;
    std::cout<<psi0<<std::endl;*/

    //definition de la matrice rotation
    float a11=cos(teta0)*cos(phi0);
    float a12=cos(teta0)*sin(phi0);
    float a13=-sin(teta0);
    float a21=sin(psi0)*sin(teta0)*cos(phi0)-cos(psi0)*sin(phi0);
    float a22=sin(psi0)*sin(teta0)*sin(phi0)+cos(psi0)*cos(phi0);
    float a23=cos(teta0)*sin(psi0);
    float a31=cos(psi0)*sin(teta0)*cos(phi0)+sin(psi0)*sin(phi0);
    float a32=cos(psi0)*sin(teta0)*sin(phi0)-sin(psi0)*cos(phi0);
    float a33=cos(teta0)*cos(psi0);

    Eigen::MatrixXd R(3,3); R.setZero();
    R(0,0)=a11; R(0,1)=a12; R(0,2)=a13;
    R(1,0)=a21; R(1,1)=a22; R(1,2)=a23;
    R(2,0)=a31; R(2,1)=a32; R(2,2)=a33;
    /*std::cout<<"rotation"<<std::endl;
    std::cout<<R<<std::endl;
    std::cout<<"---------->"<<std::endl;*/

    //vecteur point dans le systeme 2
    Eigen::MatrixXd pt_sys2;
    pt_sys2=T.transpose() + R*pt_sys1.transpose();
    //std::cout<<"pt_sy2"<<std::endl;
    //std::cout<<pt_sys2<<std::endl;
    //std::cout<<"---------->"<<std::endl;

    //transformation en Point3d
    float x_sys2 = pt_sys2(0);
    float y_sys2 = pt_sys2(1);
    float z_sys2 = pt_sys2(2);

    Point3d pt_transforme(x_sys2, y_sys2, z_sys2);
    //pt_transforme.Affiche();

    //retourne le point transfrome
    return pt_transforme;
}

