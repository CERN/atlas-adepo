#include "header/detect_flash.h"
#include "header/write_aquisifier_script.h"
#include "header/read_lwdaq_output.h"

/*int detect_flash(bdd & base_donnees, data & base_donnees_data)
{

            //lancer 3 acquisitions
            std::string fichier_param_startup = "param_stratup.tcl";
            startup_script(fichier_param_startup);
            std::string fichier_acquisition_check = "check_acquisition.tcl";
            tcl_script(fichier_acquisition_check, base_donnees);

             //lancement du programme LWDAQ
             if(system("/home/daakir/Bureau/LWDAQ/lwdaq"))
                 return EXIT_SUCCESS;
             else
                 return EXIT_FAILURE;



            //arrêter LWDAQ seuleument !!! ???

            //lire le ficher de resultat
             std::string file_data_check = "check_data_acquisition.txt";
             //read_lwdaq_output(file_data_check,base_donnees, base_donnees_data);
             //if()
             //{

             //}

            //vérifier le std des 3 acquisitions

            //si std bon, relancer la vraie acquisition

            //si std mauvais, corriger et lancer la vraie acquisition


}*/
