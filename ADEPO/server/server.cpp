#include <QDir>

#include "server.h"
#include "bcam_config.h"
#include "util.h"

//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM + suavegarde            [----> ok
std::string Server::calculateCoordinates()
{
   //je lis le fichier de sortie de LWDAQ qui contient les observations puis je stocke ce qui nous interesse dans la bdd
   int lecture_output_result = readLWDAQOutput(resultFile, m_bdd, setup);

   if(lecture_output_result == 0 )
   {
       return "Attention le fichier de resultats est inexistant ou illisible. Verifiez la connexion avec le driver. ";
   }
   /*else if(lecture_output_result == 2)
   {
       std::string str = m_bdd.Get_driver_ip_adress();
       QString message = QString::fromStdString("ERROR: Failed to connect to : %1").arg(str);
       QMessageBox::critical(this,"Attention", message);
   }*/
   else
   {
   //je fais la transformation du capteur CCD au systeme MOUNT. Attention, la lecture du fichier de calibration est deja faite !
   img_coord_to_bcam_coord(m_bdd, calibration, setup);

   //je calcule les coordonnees du prisme en 3D dans le repere MOUNT
   calcul_coord_bcam_system(m_bdd, config, calibration, setup);

   //je calcule les coordonnees du prisme en 3D dans le repere ATLAS
   mount_prism_to_global_prism(m_bdd, config, ui->airpadBox->currentText() == "ON");

   calculateResults(m_bdd, results);

   std::cout << "Updating Results..." << std::endl;
   updateResults(results);

   //enregistrement du fichier qui contient les observations dans le repere CCD et dans le repere MOUNT : spots + prismes
   QDir(".").mkpath(Util::appDirPath().append("/Archive"));

   QString fileName = Util::appDirPath();
   fileName.append("/Archive/Observations_MOUNT_System_");

   // current date/time based on current system
   QString now = getDateTime();

   fileName = fileName.append(now).append(".txt");

   write_file_obs_mount_system(fileName, now, m_bdd, config);

   display(ui->resultFileLabel, ui->resultFile, fileName);

   settings.setValue(RESULT_FILE, fileName);

   //vidage des acquisitions
   m_bdd.clear();
   }
}


//fonction qui permet de generer un script d'acquisition                                            [---> ok
int Server::write_script_file(Configuration& config, QString fileName, std::vector<BCAM> &bcams)
{
    std::string ipAddress = config.getDriverIpAddress();

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
           <<"\t daq_ip_addr "<< ipAddress <<"\n"
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

            write_bcam_script(file, bcam, spots, Util::getSourceDeviceElement(prism.isPrism(), prism.flashSeparate(), prism.getNumChip(), true));
            if (prism.flashSeparate()) {
                write_bcam_script(file, bcam, spots, Util::getSourceDeviceElement(prism.isPrism(), prism.flashSeparate(), prism.getNumChip(), false));
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


int Server::write_bcam_script(std::ofstream &file, BCAM bcam, int spots, std::string sourceDeviceElement) {

    Prism prism = bcam.getPrism();
    std::string name = bcam.getName().append("_").append(prism.getName());
    int driverSocket = bcam.getDriverSocket();
    int muxSocket = bcam.getMuxSocket();
    int sourceDriverSocket = driverSocket;
    int sourceMuxSocket = muxSocket;

    int deviceElement = prism.getNumChip();
    int left = prism.getLeft();
    int right = prism.getRight();
    int top = prism.getTop();
    int bottom = prism.getBottom();
    std::string adjustFlash = prism.flashAdjust() ? "1" : "0";

    if (!prism.isPrism()) {
        BCAMConfig bcamConfig = config.getBCAMConfig(prism.getName());
        sourceDriverSocket = bcamConfig.getDriverSocket();
        sourceMuxSocket = bcamConfig.getMuxSocket();
    }

    file<<"acquire: \n"
        <<"name: "<< name <<"\n"
        <<"instrument: BCAM \n"
        <<"result: None \n"
        <<"time: 0 \n"
        <<"config: \n"
        <<"\n"
        <<"\t daq_adjust_flash " << adjustFlash << " \n"
        <<"\t analysis_num_spots " << spots << " \n"
        <<"\t daq_driver_socket "<< driverSocket <<"\n"
        <<"\t daq_mux_socket "<< muxSocket <<"\n"
        <<"\t daq_source_mux_socket "<< sourceMuxSocket <<"\n"
        <<"\t daq_source_driver_socket "<< sourceDriverSocket <<"\n"
        <<"\t daq_device_element " << deviceElement << " \n"
        <<"\t daq_source_device_element \"" << sourceDeviceElement << "\" \n"
        <<"\t daq_image_left " << left << " \n"
        <<"\t daq_image_top " << top << " \n"
        <<"\t daq_image_right " << right << " \n"
        <<"\t daq_image_bottom " << bottom << " \n"
        <<"end. \n"
        <<"\n";

    return 0;
}


int Server::readLWDAQOutput(QFile &file, BDD & base_donnees, Setup& setup)
{
    std::ifstream fichier((char*)file.fileName().toStdString().c_str(), std::ios::in);
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
                    std::string name = strtok(buffer," ");
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
                        base_donnees.add(dsp);
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
                    std::string name = strtok(buffer," ");
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
                    base_donnees.add(dsp);
//                    sp.print();
                    break;
                }

                case 24: // 4 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                    std::string name = strtok(buffer," ");
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
                    base_donnees.add(dsp1);
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
                    base_donnees.add(dsp2);
//                    sp1.print();
//                    sp2.print();
                    break;
                }

                case 36: // 6 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                    std::string name = strtok(buffer," ");
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
                    base_donnees.add(dsp1);
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
                    base_donnees.add(dsp2);
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
                    base_donnees.add(dsp3);
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
           <<"set Acquisifier_config(daq_script) \""<<Util::appDirPath().append("/").append(fichier_script).toStdString()<<"\" \n"
           <<"set Acquisifier_config(run_results) \""<<resultFile.fileName().toStdString()<<"\" \n"
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
           <<"set LWDAQ_config_BCAM(daq_ip_addr) \""<<config.getDriverIpAddress()<<"\" \n"
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



