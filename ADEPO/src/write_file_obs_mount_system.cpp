
#include "header/write_file_obs_mount_system.h"

int write_file_obs_mount_system(std::string save_obs_mount_system, bdd &base_donnees)
{

    //écriture dans un fichier
    std::ofstream fichier((char*)save_obs_mount_system.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        fichier<<"********** Fichier qui contient une sauvegarde des coordonnees images transformees dans le repere BCAM (MOUNT) ********** \n"
              <<"**************************************************** Unite en metres (m)************************************************** \n";



            for(int j=0; j<base_donnees.Get_liste_mount_coord_spots().size(); j++)
            {
                    fichier<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_id()<<"\n";
                    fichier<<"Spot 1"<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord1().Get_X()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord1().Get_Y()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord1().Get_Z()<<"\n";
                    fichier<<"Spot 2"<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord2().Get_X()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord2().Get_Y()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord2().Get_Z()<<"\n";

            }

        fichier.close();
        return 1;
    }


    else
    {
           return 0;
    }
}
