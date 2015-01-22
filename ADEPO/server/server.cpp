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

Server::Server(Callback &callback) {
    QString appPath = Util::appDirPath();

    // connect to LWDAQ server
    lwdaq_client = new LWDAQ_Client("localhost", 1090, qApp);
    QObject::connect(lwdaq_client, SIGNAL(stateChanged()), qApp, SLOT(lwdaqStateChanged()));
    QObject::connect(lwdaq_client, SIGNAL(remainingTimeChanged()), qApp, SLOT(timeChanged()));

    QDir lwdaqDir = lwdaq_client->find(QDir(appPath));
    if (!lwdaqDir.exists()) {
        std::cerr << "FATAL: could not find LWDAQ directory up from " << appPath.toStdString() << std::endl;
        exit(1);
    } else {
        std::cout << "Found LWDAQ installation at " << lwdaqDir.absolutePath().toStdString() << std::endl;
    }

    resultFile = appPath.append("/").append(DEFAULT_RESULTS_FILE);
    scriptFile = appPath.append("/").append(DEFAULT_SCRIPT_FILE);

    lwdaq_client->init();

    previousState = LWDAQ_UNSET;
    needToCalculateResults = false;

    runMode = MODE_CLOSURE;
    adepoState = ADEPO_IDLE;

    waitingTimer = new QTimer(qApp);
    waitingTimer->setSingleShot(true);
    QObject::connect(waitingTimer, SIGNAL(timeout()), qApp, SLOT(startMonitoring()));

    updateTimer = new QTimer(qApp);
    updateTimer->setInterval(FAST_UPDATE_TIME*1000);
    updateTimer->setSingleShot(false);
    QObject::connect(updateTimer, SIGNAL(timeout()), qApp, SLOT(timeChanged()));

    QString configurationFile = appPath.append(CONFIGURATION_INPUT_FOLDER).append(CONFIGURATION_FILE);
    config.read(configurationFile);

    helmert(config, data);

    QString result = config.check();
    if (result != "") {
        std::cerr << result.toStdString() << std::endl;
        std::exit(1);
    }

    //lecture du fichier de calibration
    QString calibrationFile = appPath.append(CALIBRATION_INPUT_FOLDER).append(CALIBRATION_FILE);
    calibration.read(calibrationFile);

    // read reference file
    QString refFile = appPath.append(REFERENCE_INPUT_FOLDER).append(REFERENCE_FILE);
    reference.read(refFile);
}

void Server::startDAQ(QString runMode, int runTime, bool useAirpads)
{
    //ui->timeBox->value()
    //ui->airpadBox->currentText() == "ON"

    this->runMode = runMode;
    this->useAirpads = useAirpads;

    QString dir = Util::appDirPath();

    writeParamsFile(dir + "/" + DEFAULT_PARAM_FILE);

    writeSettingsFile(dir + "/" + DEFAULT_SETTINGS_FILE);

    //si un fichier de resultats existe deja dans le dossier LWDAQ, je le supprime avant
    std::cout << "*** Removing " << resultFile.toStdString() << std::endl;
    QFile file(resultFile);
    if (file.exists() && !file.remove()) {
        std::cout << "WARNING Cannot remove result file " << file.fileName().toStdString() << std::endl;
        std::cout << "WARNING Start aborted." << std::endl;
        return;
    }

//    setEnabled(false);

    std::cout << "Starting LWDAQ on " << config.getDriverIpAddress().toStdString() << std::endl;

    lwdaq_client->startRun(dir, runTime);
}

void Server::stopDAQ()
{
    needToCalculateResults = false;

    if (runMode == MODE_CLOSURE) {
//        waitingTimer->stop();
//        updateTimer->stop();
    }

    if (lwdaq_client->getState() == LWDAQ_IDLE) {
        adepoState = ADEPO_IDLE;
//        updateStatusBar();
    } else {
        lwdaq_client->stopRun();
    }

//    setEnabled(true);
}

void Server::lwdaqStateChanged() {
    std::cout << "state changed to " << lwdaq_client->getState().toStdString() << std::endl;
//    updateStatusBar();

    if (lwdaq_client->getState() == LWDAQ_IDLE) {
        if (needToCalculateResults) {
            // rename startup script file
            // TODO

            // calculate
            adepoState = ADEPO_CALCULATING;
//                updateStatusBar();
            calculateCoordinates();
            needToCalculateResults = false;
        }

        if (runMode == MODE_MONITORING) {
            adepoState = ADEPO_WAITING;
//                setEnabled(false);

//                waitingTimer->start(ui->waitingTime->value()*1000);
//                updateTimer->start();
        } else {
            adepoState = ADEPO_IDLE;
//                askQuestion = true;
//                setEnabled(true);
//                waitingTimer->stop();
//                updateTimer->stop();
        }
//            updateStatusBar();
    } else if (lwdaq_client->getState() == LWDAQ_RUN) {
        adepoState = ADEPO_RUN;
//            updateStatusBar();
//            setEnabled(false);
    } else if (lwdaq_client->getState() == LWDAQ_STOP) {
        adepoState = runMode == MODE_MONITORING ? ADEPO_WAITING : ADEPO_IDLE;
//            updateStatusBar();
//            ui->repeatButton->setEnabled(false);
//            ui->Boutton_lancer->setEnabled(false);
//            ui->nextMeasurement->setEnabled(false);
//            ui->boutton_arreter->setEnabled(false);
//            ui->stop->setEnabled(false);
//            ui->stopButton->setEnabled(false);
    } else if (lwdaq_client->getState() == LWDAQ_INIT) {
        adepoState = ADEPO_IDLE;
//            updateStatusBar();
//            ui->repeatButton->setEnabled(false);
//            ui->Boutton_lancer->setEnabled(false);
//            ui->nextMeasurement->setEnabled(false);
//            ui->boutton_arreter->setEnabled(false);
//            ui->stop->setEnabled(false);
//            ui->stopButton->setEnabled(false);
        needToCalculateResults = false;
    }

    previousState = lwdaq_client->getState();
}

void Server::timeChanged() {
//    updateStatusBar();
//    showBCAM(selectedBCAM, 0);
}


//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM + suavegarde            [----> ok
QString Server::calculateCoordinates()
{
   //je lis le fichier de sortie de LWDAQ qui contient les observations puis je stocke ce qui nous interesse dans la bdd
   int lecture_output_result = readLWDAQOutput();

   if(lecture_output_result == 0 )
   {
       return "Attention le fichier de resultats est inexistant ou illisible. Verifiez la connexion avec le driver. ";
   }

   //je fais la transformation du capteur CCD au systeme MOUNT. Attention, la lecture du fichier de calibration est deja faite !
   imgCoordToBcamCoord(calibration, setup, data);

   //je calcule les coordonnees du prisme en 3D dans le repere MOUNT
   calculCoordBcamSystem(config, calibration, setup, data);

   //je calcule les coordonnees du prisme en 3D dans le repere ATLAS
   mountPrismToGlobalPrism();

// TODO
//   calculateResults(data, results);

   std::cout << "Updating Results..." << std::endl;
// TODO
//   updateResults(results);

   //enregistrement du fichier qui contient les observations dans le repere CCD et dans le repere MOUNT : spots + prismes
   QDir(".").mkpath(Util::appDirPath().append("/Archive"));

   QString fileName = Util::appDirPath();
   fileName.append("/Archive/Observations_MOUNT_System_");

   // current date/time based on current system
   QString now = getDateTime();

   fileName = fileName.append(now).append(".txt");

   writeFileObsMountSystem(fileName, now);

//   display(ui->resultFileLabel, ui->resultFile, fileName);

//   settings.setValue(RESULT_FILE, fileName);

   //vidage des acquisitions
   data.clear();

   return "";
}


//fonction qui permet de generer un script d'acquisition                                            [---> ok
int Server::writeScriptFile(QString fileName, std::vector<BCAM> &bcams)
{
    QString ipAddress = config.getDriverIpAddress();

    //écriture dans un fichier
    std::ofstream file(fileName.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(file)
    {
        std::cerr << "Writing to " << fileName.toStdString() << std::endl;

        //écriture la partie du script qui gère l'enregistrement dans un fichier externe
        file<<"acquisifier: \n"
           <<"config: \n"
           <<"\t cycle_period_seconds 0 \n"
           <<"end. \n"
           <<"\n"
           <<"default: \n"
           <<"name: BCAM_Default \n"
           <<"instrument: BCAM \n"
           <<"default_post_processing: { \n"
           <<"if {![LWDAQ_is_error_result $result]} { \n"
           <<"append config(run_result) \"[lrange $result 1 2]\" ; \n"
           <<" } { \n"
           <<"append config(run_result) \" -1 -1 \" ; # append joue le meme role que 'set' \n"
           <<" } \n"
           <<"  set f [open $config(run_results) a] \n"
           <<" puts $f $result \n"
           <<" close $f \n"
           <<" LWDAQ_print $info(text) \"Appended modified result to [file tail $config(run_results)].\" blue ;  \n"
           <<" set suffix $iconfig(daq_source_device_element) \n"
           <<" regsub -all \" \" $suffix \"-\" suffix \n"
           <<" set fn [file join [file dirname $config(run_results)] $name-$suffix.gif] \n"
           <<" LWDAQ_write_image_file $iconfig(memory_name) $fn \n"
           <<" LWDAQ_print $info(text) \"Saved raw image to $fn\" blue ; \n"
           <<" } \n"
           <<"\n"
           <<"config: \n"
           <<"\t image_source daq \n"
           <<"\t analysis_enable 1 \n"
           <<"\t daq_flash_seconds 0.0000033 \n"
           <<"\t daq_ip_addr "<< ipAddress.toStdString() <<"\n"
           <<"\t daq_source_ip_addr * \n"
           <<"\t ambient_exposure_seconds 0 \n"
           <<"\t intensify exact \n"
           <<"end. \n"
           <<"\n";

        //écriture dans le fichier de la partie acquisition du script : un paragraphe par BCAM
        for(unsigned int i=0; i<bcams.size(); i++)
        {
            BCAM bcam = bcams.at(i);
            Prism prism = bcam.getPrism();
            int spots = prism.flashSeparate() ? 1 : 2;

            writeBCAMScript(config, file, bcam, spots, Util::getSourceDeviceElement(prism.isPrism(), prism.flashSeparate(), prism.getNumChip(), true));
            if (prism.flashSeparate()) {
                writeBCAMScript(config, file, bcam, spots, Util::getSourceDeviceElement(prism.isPrism(), prism.flashSeparate(), prism.getNumChip(), false));
            }
        }

        file.close();
        return 1;
    }
    else
    {
        std::cout << "Could not write script" << std::endl;
        return 0;
    }
}


int Server::writeBCAMScript(Configuration& config, std::ofstream &file, BCAM bcam, int spots, QString sourceDeviceElement) {

    Prism prism = bcam.getPrism();
    QString name = bcam.getName().append("_").append(prism.getName());
    int driverSocket = bcam.getDriverSocket();
    int muxSocket = bcam.getMuxSocket();
    int sourceDriverSocket = driverSocket;
    int sourceMuxSocket = muxSocket;

    int deviceElement = prism.getNumChip();
    int left = prism.getLeft();
    int right = prism.getRight();
    int top = prism.getTop();
    int bottom = prism.getBottom();
    QString adjustFlash = prism.flashAdjust() ? "1" : "0";

    if (!prism.isPrism()) {
        BCAMConfig bcamConfig = config.getBCAMConfig(prism.getName());
        sourceDriverSocket = bcamConfig.getDriverSocket();
        sourceMuxSocket = bcamConfig.getMuxSocket();
    }

    file<<"acquire: \n"
        <<"name: "<< name.toStdString() <<"\n"
        <<"instrument: BCAM \n"
        <<"result: None \n"
        <<"time: 0 \n"
        <<"config: \n"
        <<"\n"
        <<"\t daq_adjust_flash " << adjustFlash.toStdString() << " \n"
        <<"\t analysis_num_spots " << spots << " \n"
        <<"\t daq_driver_socket "<< driverSocket <<"\n"
        <<"\t daq_mux_socket "<< muxSocket <<"\n"
        <<"\t daq_source_mux_socket "<< sourceMuxSocket <<"\n"
        <<"\t daq_source_driver_socket "<< sourceDriverSocket <<"\n"
        <<"\t daq_device_element " << deviceElement << " \n"
        <<"\t daq_source_device_element \"" << sourceDeviceElement.toStdString() << "\" \n"
        <<"\t daq_image_left " << left << " \n"
        <<"\t daq_image_top " << top << " \n"
        <<"\t daq_image_right " << right << " \n"
        <<"\t daq_image_bottom " << bottom << " \n"
        <<"end. \n"
        <<"\n";

    return 0;
}


int Server::readLWDAQOutput()
{
    std::ifstream fichier((char*)resultFile.toStdString().c_str(), std::ios::in);
    if(fichier)
    {
        std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
        double savedSpotI = 0;
        double savedSpotJ = 0;
        bool savedSpotReady = false;

        while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
        {
            // take ending off the line
            ligne.erase(ligne.find_last_not_of(" \n\r\t")+1);

            if(!ligne.empty())
            {
                int nb_colonnes = std::count(ligne.begin(), ligne.end(), ' '); //je compte le nombre de colonnes dans le fichier

                switch(nb_colonnes)
                {
                case 6: // 1 spot, wait for second one...
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet + coordonnées images du spot
                    QString name = QString::fromStdString(strtok(buffer," "));
                    BCAM bcam = setup.getBCAM(name);
                    char *coord_i_ccd = strtok( NULL, " " );
                    char *coord_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }

                    if (savedSpotReady) {
                        DualSpot dsp(bcam, savedSpotI, savedSpotJ, atof(coord_i_ccd), atof(coord_j_ccd));
                        data.add(dsp);
                        savedSpotReady = false;
                    } else {
                        savedSpotI = atof(coord_i_ccd);
                        savedSpotJ = atof(coord_j_ccd);
                        savedSpotReady = true;
                    }
                    break;
                }

                case 12: // 2 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet + coordonnées images du premier spot
                    QString name = QString::fromStdString(strtok(buffer," "));
                    BCAM bcam = setup.getBCAM(name);
                    char *coord1_i_ccd = strtok( NULL, " " );
                    char *coord1_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord2_i_ccd = strtok( NULL, " " );
                    char *coord2_j_ccd = strtok( NULL, " " );
                    //ajout dans la base de donnees
                    DualSpot dsp(bcam,
                            atof(coord1_i_ccd), atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                    data.add(dsp);
//                    sp.print();
                    break;
                }

                case 24: // 4 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                    QString name = QString::fromStdString(strtok(buffer," "));
                    BCAM bcam = setup.getBCAM(name);
                    char *coord1_i_ccd = strtok( NULL, " " );
                    char *coord1_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord2_i_ccd = strtok( NULL, " " );
                    char *coord2_j_ccd = strtok( NULL, " " );
                    //ajout dans la base de donnees
                    DualSpot dsp1(bcam,
                             atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                    data.add(dsp1);
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord3_i_ccd = strtok( NULL, " " );
                    char *coord3_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord4_i_ccd = strtok( NULL, " " );
                    char *coord4_j_ccd = strtok( NULL, " " );
                    //ajout dans la base de donnees
                    DualSpot dsp2(bcam,
                             atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                    data.add(dsp2);
//                    sp1.print();
//                    sp2.print();
                    break;
                }

                case 36: // 6 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                    QString name = QString::fromStdString(strtok(buffer," "));
                    BCAM bcam = setup.getBCAM(name);
                    char *coord1_i_ccd = strtok( NULL, " " );
                    char *coord1_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord2_i_ccd = strtok( NULL, " " );
                    char *coord2_j_ccd = strtok( NULL, " " );
                    //ajout dans la base de donnees
                    DualSpot dsp1(bcam,
                             atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                    data.add(dsp1);
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord3_i_ccd = strtok( NULL, " " );
                    char *coord3_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord4_i_ccd = strtok( NULL, " " );
                    char *coord4_j_ccd = strtok( NULL, " " );
                    //ajout dans la base de donnees
                    DualSpot dsp2(bcam,
                             atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                    data.add(dsp2);
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord5_i_ccd = strtok( NULL, " " );
                    char *coord5_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }
                    //récupération des coordonnées images du second spot
                    char *coord6_i_ccd = strtok( NULL, " " );
                    char *coord6_j_ccd = strtok( NULL, " " );
                    //ajout dans la base de donnees
                    DualSpot dsp3(bcam,
                             atof(coord5_i_ccd), atof(coord5_j_ccd), atof(coord6_i_ccd), atof(coord6_j_ccd));
                    data.add(dsp3);
                    break;
                }

                default: // error
                {
                   return 0;
                }
                } // switch
            }
        }

        //affichage de la base de donnees qui contient les coordonnees image
        /*for(int i=0; i<base_donnees.Get_liste_spots().size(); i++)
        {
            base_donnees.Get_liste_spots().at(i).Affiche();
        }*/

        fichier.close();
        return 1;
    }
    else
    {
        return 0;
    }
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

//fonction qui ecrit un fichier tcl avec les parametres par defaut pour la fenetre Acquisifier      [---> ok
int Server::writeSettingsFile(QString settings_file)
{
    //écriture dans un fichier
    std::ofstream fichier(settings_file.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(!fichier) return 0;

    //écriture la partie du script qui lance l'acquisition automatique
    fichier<<"set Acquisifier_config(auto_load) \"0\" \n"
           <<"set Acquisifier_config(title_color) \"purple\" \n"
           <<"set Acquisifier_config(extended_acquisition) \"0\" \n"
           <<"set Acquisifier_config(auto_repeat) \"0\" \n"
           <<"set Acquisifier_config(analyze) \"0\" \n"
           <<"set Acquisifier_config(auto_run) \"0\" \n"
           <<"set Acquisifier_config(cycle_period_seconds) \"0\" \n"
           <<"set Acquisifier_config(daq_script) \""<<Util::appDirPath().append("/").append(scriptFile).toStdString()<<"\" \n"
           <<"set Acquisifier_config(run_results) \""<<resultFile.toStdString()<<"\" \n"
           <<"set Acquisifier_config(analysis_color) \"green\" \n"
           <<"set Acquisifier_config(auto_quit) \"0\" \n"
           <<"set Acquisifier_config(result_color) \"green\" \n"
           <<"set Acquisifier_config(num_steps_show) \"20\" \n"
           <<"set Acquisifier_config(num_lines_keep) \"1000\" \n"
           <<"set Acquisifier_config(restore_instruments) \"0\" \n";

      fichier.close();
      return 1;
}

//fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ   [----> ok
int Server::writeParamsFile(QString params_file)
{
    //écriture dans un fichier
    std::ofstream fichier(params_file.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(!fichier) return 0;

    fichier<<"#~ Settings pour les BCAMs"
           <<"set LWDAQ_info_BCAM(daq_password) \"no_password\" \n"
           <<"set LWDAQ_info_BCAM(ambient_exposure_seconds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(counter) \"0\" \n"
           <<"set LWDAQ_info_BCAM(verbose_description) \"  {Spot Position X (um)}  {Spot Position Y (um) or Line Rotation Anticlockwise (mrad)}  {Number of Pixels Above Threshold in Spot}  {Peak Intensity in Spot}  {Accuracy (um)}  {Threshold (counts)}\" \n"
           <<"set LWDAQ_info_BCAM(flash_max_tries) \"30\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_max) \"0.1\" \n"
           <<"set LWDAQ_info_BCAM(control) \"Idle\" \n"
           <<"set LWDAQ_info_BCAM(analysis_return_intensity) \"0\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_left) \"20\" \n"
           <<"set LWDAQ_info_BCAM(analysis_show_timing) \"0\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_bottom) \"243\" \n"
           <<"set LWDAQ_info_BCAM(extended_parameters) \"0.6 0.9 0 1\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_right) \"343\" \n"
           <<"set LWDAQ_info_BCAM(text) \".bcam.text\" \n"
           <<"set LWDAQ_info_BCAM(daq_source_device_type) \"2\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_step) \"0.000002\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_width) \"344\" \n"
           <<"set LWDAQ_info_BCAM(state_label) \".bcam.buttons.state\" \n"
           <<"set LWDAQ_info_BCAM(daq_source_ip_addr) \"*\" \n"
           <<"set LWDAQ_info_BCAM(analysis_pixel_size_um) \"10\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_height) \"244\" \n"
           <<"set LWDAQ_info_BCAM(window) \".bcam\" \n"
           <<"set LWDAQ_info_BCAM(analysis_show_pixels) \"0\" \n"
           <<"set LWDAQ_info_BCAM(name) \"BCAM\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_top) \"1\" \n"
           <<"set LWDAQ_info_BCAM(photo) \"bcam_photo\" \n"
           <<"set LWDAQ_info_BCAM(flash_num_tries) \"0\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_reduce) \"0.1\" \n"
           <<"set LWDAQ_info_BCAM(file_use_daq_bounds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(peak_min) \"100\" \n"
           <<"set LWDAQ_info_BCAM(zoom) \"1\" \n"
           <<"set LWDAQ_info_BCAM(analysis_return_bounds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(delete_old_images) \"1\" \n"
           <<"set LWDAQ_info_BCAM(daq_device_type) \"2\" \n"
           <<"set LWDAQ_info_BCAM(file_try_header) \"1\" \n"
           <<"set LWDAQ_info_BCAM(peak_max) \"180\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_transition) \"0.000030\" \n"
           <<"set LWDAQ_info_BCAM(daq_extended) \"0\" \n"
           <<"set LWDAQ_config_BCAM(analysis_threshold) \"10 #\" \n"
           <<"set LWDAQ_config_BCAM(daq_ip_addr) \""<<config.getDriverIpAddress().toStdString()<<"\" \n"
           <<"set LWDAQ_config_BCAM(daq_flash_seconds) \"0.000010\" \n"
           <<"set LWDAQ_config_BCAM(daq_driver_socket) \"5\" \n"
           <<"set LWDAQ_config_BCAM(analysis_num_spots) \"2\" \n"
           <<"set LWDAQ_config_BCAM(image_source) \"daq\" \n"
           <<"set LWDAQ_config_BCAM(daq_subtract_background) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_adjust_flash) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_device_element) \"3 4\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_mux_socket) \"1\" \n"
           <<"set LWDAQ_config_BCAM(file_name) \"./images/BCAM*\" \n"
           <<"set LWDAQ_config_BCAM(intensify) \"exact\" \n"
           <<"set LWDAQ_config_BCAM(memory_name) \"BCAM_0\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_driver_socket) \"8\" \n"
           <<"set LWDAQ_config_BCAM(analysis_enable) \"1\" \n"
           <<"set LWDAQ_config_BCAM(verbose_result) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_device_element) \"2\" \n"
           <<"set LWDAQ_config_BCAM(daq_mux_socket) \"1\" \n";

    fichier.close();
    return 1;
}



//fonction de transformation du repere ccd au repere BCAM (MOUNT)
void Server::imgCoordToBcamCoord(Calibration &calibration, Setup& setup, Data& data)
{
    bool found = false;
    for(unsigned int i=0; i<data.getDualSpots().size(); i++) //je parcours la base de donnees des coordonnees images
    {
        for (unsigned int j=0; j<calibration.getCalibs1().size(); j++) //je parcours la base de donnees qui contient les informations de calibration
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
                Point3f mount_sp1(coord_mount1(0,0), coord_mount1(0,1), coord_mount1(0,2));
                Point3f mount_sp2(coord_mount2(0,0), coord_mount2(0,1), coord_mount2(0,2));
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

void Server::calculCoordBcamSystem(Configuration& config, Calibration &calibration, Setup& setup, Data& data)
{
    bool found = false;
    for (unsigned int i=0; i<data.getMountCoordSpots().size(); i++) // je parcours la database qui contient les coord des observation dans le system MOUNT
    {
        MountCoordSpots spot = data.getMountCoordSpots().at(i);

        for (unsigned int j=0; j<calibration.getCalibs1().size(); j++) //je parcours la base de donnee de calibration 1
        {
            Calib1 calib1 = calibration.getCalibs1().at(j);

            // NumChip == 2 is Z+ direction
            int num_chip = setup.getBCAM(spot.getName()).getPrism().getNumChip();
            bool directionOk1 = ((num_chip == 2) && (calib1.getDirection() == 1)) || ((num_chip == 1) && (calib1.getDirection() == -1));

            for(unsigned int k=0; k<calibration.getCalibs2().size(); k++) //je parcours la base de donnee de calibration 2
            {
                Calib2 calib2k = calibration.getCalibs2().at(k);
                Calib2 calib2j = calibration.getCalibs2().at(j);

                bool directionOk2 = ((num_chip == 2) && (calib2k.getDirection() == 1)) || ((num_chip == 1) && (calib2k.getDirection() == -1));

                for(unsigned int l=0; l<config.getAbsoluteDistances().size(); l++) //je parcours la base de donnee des distances absolues
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
                        Point3f xyz(coordPrisme_x, coordPrisme_y, coordPrisme_z);
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
    for(unsigned int i=0; i<data.getMountCoordPrisms().size(); i++)
    {
        MountCoordPrism prism = data.getMountCoordPrisms().at(i);
        float airpad = useAirpads ? config.getDetector(prism.getBCAM().getName()).getAirpad() : 0.0f;

        for(unsigned int j=0; j<data.getBCAMParams().size(); j++)
        {
            BCAMParams params = data.getBCAMParams().at(j);

            if(prism.getBCAM().getName() == params.getBCAM())
            {
                 Point3f point_transforme = changeReference(prism.getCoordPrismMountSys(),
                                                            params.getTranslation(),
                                                            params.getRotation());
                 Point3f point_airpad(point_transforme.x(), point_transforme.y()+airpad, point_transforme.z());
                 GlobalCoordPrism pt_global(prism.getBCAM(), point_airpad, airpad);
                 data.add(pt_global);
                 found = true;
            }
        }
    }

    //affichage base de donnee des prismes dans le repere global
#ifdef ADEPO_DEBUG
    for(unsigned int k=0; k<data.getGlobalCoordPrisms().size(); k++)
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

    std::cout << "Writing results into " << fileName.toStdString() << std::endl;

    fichier<<"********** Fichier qui contient une sauvegarde des coordonnees images + coordonnees images transformees dans le repere BCAM (MOUNT) + coordonnees des prismes dans le repere MOUNT********** \n"
           <<"********************************************************************** Unite en metres (m)************************************************************************************************** \n"
           <<"\n";

        //premiere visee BCAM-Prisme de la liste des observations
        QString premier_objet_img= data.getDualSpots().at(0).getName();

        //sauvegarde des coordonnees images
        fichier<<"*******************************************************************coordonnees images dans le repere CCD *********************************************************************************** \n";
        for(unsigned int i=0; i<data.getDualSpots().size(); i++)
        {
            DualSpot spot1 = data.getDualSpots().at(i);
            if(i>0 && spot1.getName() == premier_objet_img) //si on a tout parcourut et on revient au premier objet ==> fin
                break;

            fichier<<spot1.getName().toStdString()<<"\n";
            for(unsigned int j=0; j<data.getDualSpots().size(); j++)
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
        for(unsigned int i=0; i<data.getMountCoordSpots().size(); i++)
        {
            MountCoordSpots spots1 = data.getMountCoordSpots().at(i);
//                std::cout << data.getMountCoordSpots().size() << " " << spots1.getName() << " " << premier_objet_mount << std::endl;
            if(i>0 && spots1.getName() == premier_objet_mount) //si on a tout parcourut et on revient au premier objet ==> fin
                break;

            fichier<<spots1.getName().toStdString()<<"\n";
            for(unsigned int j=0; j<data.getMountCoordSpots().size(); j++)
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

        for(unsigned int i=0; i<data.getMountCoordPrisms().size(); i++)
        {
            MountCoordPrism prism1 = data.getMountCoordPrisms().at(i);
            if(i>0 && prism1.getName() == premier_prisme_mount) //si on a tout parcourut et on revient au premier objet ==> fin
                break;

            fichier<<prism1.getName().toStdString()<<"\n";
            for(unsigned int j=0; j<data.getMountCoordPrisms().size(); j++)
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

        for(unsigned int i=0; i<data.getGlobalCoordPrisms().size(); i++)
        {
            GlobalCoordPrism prism1 = data.getGlobalCoordPrisms().at(i);
            if(i>0 && prism1.getName() == premier_prisme_atlas)
                break;

            fichier<<prism1.getName().toStdString()<<" "<<prism1.getAirpad()<<"\n";
            for(unsigned int j=0; j<data.getGlobalCoordPrisms().size(); j++)
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

        for(unsigned int i=0; i<data.getGlobalCoordPrisms().size(); i++)
        {
            GlobalCoordPrism prism1 = data.getGlobalCoordPrisms().at(i);
            if(i>0 && prism1.getName() == premier_prisme_atlas)
                break;

            Eigen::MatrixXd coord(Eigen::DynamicIndex,3);
            int ligne=0;

            for(unsigned int j=0; j<data.getGlobalCoordPrisms().size(); j++)
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
            for(unsigned int n=0; n<config.getPrismCorrections().size(); n++)
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

Point3f Server::changeReference(Point3f coord_sys1, Point3f translation, Point3f rotation)
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

    //transformation en point3f
    float x_sys2 = pt_sys2(0);
    float y_sys2 = pt_sys2(1);
    float z_sys2 = pt_sys2(2);

    Point3f pt_transforme(x_sys2, y_sys2, z_sys2);
    //pt_transforme.Affiche();

    //retourne le point transfrome
    return pt_transforme;
}

