#include "atlas_bcam.h"

//fonction qui permet de generer un script d'acquisition                                            [---> ok
int ATLAS_BCAM::write_script_file(QString nom_fichier_script_acquisition, std::vector<BCAM> &liste_temp_bcam)
{
    //écriture dans un fichier
    std::ofstream fichier(nom_fichier_script_acquisition.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        std::cerr << "Writing to " << nom_fichier_script_acquisition.toStdString() << std::endl;

        //écriture la partie du script qui gère l'enregistrement dans un fichier externe
        fichier<<"acquisifier: \n"
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
               <<" set fn [file join [file dirname $config(run_results)] $name.gif] \n"
               <<" LWDAQ_write_image_file $iconfig(memory_name) $fn \n"
               <<" LWDAQ_print $info(text) \"Saved raw image to $fn\" blue ; \n"
               <<" } \n"
               <<"\n"
               <<"config: \n"
               <<"\t image_source daq \n"
               <<"\t analysis_enable 1 \n"
               <<"\t daq_flash_seconds 0.0000033 \n"
               <<"\t daq_adjust_flash 1 \n"
               <<"\t daq_ip_addr "<<m_bdd.getDriverIpAddress()<<"\n"
               <<"\t daq_source_ip_addr * \n"
               <<"\t ambient_exposure_seconds 0 \n"
               <<"\t intensify exact \n"
               <<"end. \n"
               <<"\n";

        //écriture dans le fichier de la partie acquisition du script : un paragraphe par BCAM
        for(unsigned int i=0; i<liste_temp_bcam.size(); i++)
        {
            // on separe les visees BCAM-Prisme des visees BCAM-BCAM
            if(liste_temp_bcam.at(i).getPrisms().length() == 14)
            { //configuration de visee BCAM-BCAM
                fichier<<"acquire: \n"
                       <<"name: "<<liste_temp_bcam.at(i).getName().append("_").append(liste_temp_bcam.at(i).getPrisms())<<"\n"
                       <<"instrument: BCAM \n"
                       <<"result: None \n"
                       <<"time: 0 \n"
                       <<"config: \n"
                       <<"\n"
                       <<"\t analysis_num_spots 2 \n"
                       <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                       <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n";

                BCAM* bcam = m_bdd.getBCAM(liste_temp_bcam.at(i).getPrisms());

                fichier<<"\t daq_source_mux_socket "<<bcam->getMuxSocket()<<"\n"
                       <<"\t daq_source_driver_socket "<<bcam->getDriverSocket()<<"\n";
                if(liste_temp_bcam.at(i).getNumChip() == 2)
                {
                    fichier<<"\t daq_device_element 2 \n"
                           <<"\t daq_source_device_element \"1 2\" \n";
                }
                else
                {
                    fichier<<"\t daq_device_element 1 \n"
                           <<"\t daq_source_device_element \"3 4\" \n";
                }

                fichier<<"\t daq_image_left 20 \n"
                       <<"\t daq_image_top 1 \n"
                       <<"\t daq_image_right 343 \n"
                       <<"\t daq_image_bottom 243 \n"
                        <<"end. \n"
                       <<"\n";
            }

            else //configuration BCAM-Prisme
            {
                fichier<<"acquire: \n"
                       <<"name: "<<liste_temp_bcam.at(i).getName().append("_").append(liste_temp_bcam.at(i).getPrisms())<<"\n"
                       <<"instrument: BCAM \n"
                       <<"result: None \n"
                       <<"time: 0 \n"
                       <<"config: \n";

               if(liste_temp_bcam.at(i).getPrisms().length() == 5)
               { //cas de 1 bcam qui vise 1 prisme (port source et port enregistreure sont les memes)
                    fichier<<"\t analysis_num_spots 2 \n"
                         <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                          <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                          <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n"
                          <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n"
                          <<"\t daq_device_element "<<liste_temp_bcam.at(i).getNumChip()<<"\n";
                    if(liste_temp_bcam.at(i).getNumChip() == 2)
                    {
                       fichier<<"\t daq_source_device_element \"3 4\" \n";
                    }
                    else
                    {
                        fichier<<"\t daq_source_device_element \"1 2\" \n";
                    }
                    fichier<<"\t daq_image_left 20 \n"
                          <<"\t daq_image_top 1 \n"
                          <<"\t daq_image_right 343 \n"
                          <<"\t daq_image_bottom 243 \n"
                           <<"end. \n"
                          <<"\n";
               }
               else if(liste_temp_bcam.at(i).getPrisms().length() == 11)
               { //cas de 1 bcam qui vise 2 prismes (port source et port enregistreure sont les memes)
                   fichier<<"\t analysis_num_spots 4 \n"
                         <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                         <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n"
                          <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                          <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n"
                          <<"\t daq_device_element "<<liste_temp_bcam.at(i).getNumChip()<<"\n";
                   if(liste_temp_bcam.at(i).getNumChip() == 2)
                   {
                       fichier<<"\t daq_source_device_element \"3 4\" \n";
                   }
                   else
                   {
                        fichier<<"\t daq_source_device_element \"1 2\" \n";
                   }
                   fichier<<"\t daq_image_left 20 \n"
                          <<"\t daq_image_top 1 \n"
                          <<"\t daq_image_right 343 \n"
                          <<"\t daq_image_bottom 243 \n"
                           <<"end. \n"
                          <<"\n";
               }
               else
               { //cas d'une BCAM qui vise 3 prismes (port source et port enregistreure sont les memes)
                   fichier<<"\t analysis_num_spots 6 \n"
                          <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n"
                          <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).getMuxSocket()<<"\n"
                          <<"\t daq_device_element "<<liste_temp_bcam.at(i).getNumChip()<<"\n"
                          <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                          <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).getDriverSocket()<<"\n"
                          <<"\t daq_image_left 20 \n"
                          <<"\t daq_image_top 1 \n"
                          <<"\t daq_image_right 343 \n"
                          <<"\t daq_image_bottom 243 \n";
                   if(liste_temp_bcam.at(i).getNumChip() == 2)
                   {
                       fichier<<"\t daq_source_device_element \"3 4\" \n";
                   }
                   else
                   {
                       fichier<<"\t daq_source_device_element \"1 2\" \n";
                   }
                   fichier<<"\t daq_image_left 20 \n"
                          <<"\t daq_image_top 1 \n"
                          <<"\t daq_image_right 343 \n"
                          <<"\t daq_image_bottom 243 \n"
                          <<"end. \n"
                          <<"\n";
                }
            }
        }

        fichier.close();
        return 1;
    }
    else
    {
        std::cout << "Could not write script" << std::endl;
        return 0;
    }
}


