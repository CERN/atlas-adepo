#include "write_acquisifier_script.h"

int write_acquisifier_script(std::string nom_fichier_script, BDD &base_donnees)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_script.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        //écriture la partie du script qui gère l'enregistrement dans un fichier externe
        fichier<<"config: \n"
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
               <<" set fn [file join [file dirname $config(run_results)] $name\.lwdaq] \n"
               <<" LWDAQ_write_image_file $iconfig(memory_name) $fn \n"
               <<" LWDAQ_print $info(text) \"Saved raw image to [file tail $fn]\" blue ; \n"
               <<" } \n"
               <<"config: \n"
               <<"\t image_source daq \n"
               <<"\t analysis_enable 1 \n"
               <<"\t daq_adjust_flash 1 \n"
              <<"\t daq_flash_seconds 0.05 \n"
               <<"\t daq_ip_addr 10.0.0.37 \n"
               <<"\t daq_source_ip_addr * \n"
               <<"\t ambient_exposure_seconds 0 \n"
               <<"\t intensify exact \n"
               <<"end. \n";

        //écriture dans le fichier de la partie acquisition du script : un paragraphe par BCAM
        for(int i=0; i<base_donnees.Get_liste_BCAM().size(); i++)
        {
         fichier<<"acquire: \n"
                <<"name: "<<base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM().append("_").append(base_donnees.Get_liste_BCAM().at(i).Get_objet_vise())<<"\n"
                <<"instrument: BCAM \n"
                <<"result: None \n"
                <<"time: 0 \n"
                <<"config: \n";

         if(base_donnees.Get_liste_BCAM().at(i).Get_objet_vise().length() == 8)
                {
                    fichier<<"\t analysis_num_spots 2 \n"
                           <<"\t daq_mux_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_source_mux_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_device_element 2 \n"
                           <<"\t daq_source_device_element \"3 4\" \n";
                }
         else if(base_donnees.Get_liste_BCAM().at(i).Get_objet_vise().length() == 17)
                {
                    fichier<<"\t analysis_num_spots 4 \n"
                           <<"\t daq_mux_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_source_mux_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_device_element "<<base_donnees.Get_liste_BCAM().at(i).Get_num_chip()<<"\n";
                    if(base_donnees.Get_liste_BCAM().at(i).Get_num_chip() == 2)
                    {
                        fichier<<"\t daq_source_device_element \"3 4\" \n";
                    }
                    else
                    {
                         fichier<<"\t daq_source_device_element \"1 2\" \n";
                    }

                }
         else
                {
                    fichier<<"\t analysis_num_spots 2 \n"
                           <<"\t daq_mux_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux()<<"\n";

                    for(int j=0; j<base_donnees.Get_liste_BCAM().size(); j++)
                    {
                        if(base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM() == base_donnees.Get_liste_BCAM().at(j).Get_objet_vise())
                        {
                            fichier<<"\t daq_source_mux_socket "<<base_donnees.Get_liste_BCAM().at(j).Get_num_Port_Mux()<<"\n";
                            if(base_donnees.Get_liste_BCAM().at(i).Get_num_chip() == 2)
                            {
                                fichier<<"\t daq_device_element 2 \n"
                                       <<"\t daq_source_device_element \"1 2\" \n";
                            }
                            else
                            {
                                fichier<<"\t daq_device_element 1 \n"
                                       <<"\t daq_source_device_element \"3 4\" \n";
                            }
                        }
                    }


                }

                fichier<<"\t daq_driver_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Driver()<<"\n"
                        <<"\t daq_source_driver_socket "<<base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Driver()<<"\n"
                        <<"\t daq_image_left 20 \n"
                        <<"\t daq_image_top 1 \n"
                        <<"\t daq_image_right 343 \n"
                        <<"\t daq_image_bottom 243 \n";

                fichier<<"end. \n";
        }

        fichier.close();
        return 1;
    }

    else
    {
        return 0;
    }
}
