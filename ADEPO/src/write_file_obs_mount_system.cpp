#include "header/write_file_obs_mount_system.h"
#include "header/changement_repere.h"
#include "eigen-eigen-ffa86ffb5570/Eigen/Eigen"
#include "math.h"
#include "eigen-eigen-ffa86ffb5570/Eigen/Core"
#include "iostream"
#include "ctime"
#include "sstream"

#define um2m 0.000001

int write_file_obs_mount_system(std::string save_obs_mount_system, bdd &base_donnees)
{

    //écriture dans un fichier
    std::ofstream fichier((char*)save_obs_mount_system.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        fichier<<"********** Fichier qui contient une sauvegarde des coordonnees images + coordonnees images transformees dans le repere BCAM (MOUNT) + coordonnees des prismes dans le repere MOUNT********** \n"
               <<"********************************************************************** Unite en metres (m)************************************************************************************************** \n"
               <<"\n";

            //premiere visee BCAM-Prisme de la liste des observations
            std::string premier_objet_img= base_donnees.Get_liste_spots().at(0).Get_nom_BCAM_Objet();

            //sauvegarde des coordonnees images
            fichier<<"*******************************************************************coordonnees images dans le repere CCD *********************************************************************************** \n";
            for(unsigned int i=0; i<base_donnees.Get_liste_spots().size(); i++)
            {
                if(i>0 && base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet() == premier_objet_img) //si on a tout parcourut et on revient au premier objet ==> fin
                    break;

                fichier<<base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet()<<"\n";
                for(unsigned int j=0; j<base_donnees.Get_liste_spots().size(); j++)
                {
                    if(base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet() == base_donnees.Get_liste_spots().at(j).Get_nom_BCAM_Objet())
                    {
                                fichier<<"Spot 1"<<" "<<base_donnees.Get_liste_spots().at(j).Get_i1_CCD()*um2m<<" "<<base_donnees.Get_liste_spots().at(j).Get_j1_CCD()*um2m<<"\n"
                                       <<"Spot 2"<<" "<<base_donnees.Get_liste_spots().at(j).Get_i2_CCD()*um2m<<" "<<base_donnees.Get_liste_spots().at(j).Get_j2_CCD()*um2m<<"\n";
                    }
                }
            }

            fichier<<"\n"
                   <<"\n"
                   <<"****************************************************************coordonnees images transformees dans le repere MOUNT************************************************************************* \n";
            std::string premier_objet_mount = base_donnees.Get_liste_mount_coord_spots().at(0).Get_id();

            //sauvegarde des coordonnees images transformees dans le repere MOUNT
            for(unsigned int i=0; i<base_donnees.Get_liste_mount_coord_spots().size(); i++)
            {
                if(i>0 && base_donnees.Get_liste_mount_coord_spots().at(i).Get_id() == premier_objet_mount) //si on a tout parcourut et on revient au premier objet ==> fin
                    break;

                fichier<<base_donnees.Get_liste_mount_coord_spots().at(i).Get_id()<<"\n";
                for(unsigned int j=0; j<base_donnees.Get_liste_mount_coord_spots().size(); j++)
                {
                    if(base_donnees.Get_liste_mount_coord_spots().at(i).Get_id() == base_donnees.Get_liste_mount_coord_spots().at(j).Get_id())
                    {
                        fichier<<"Spot 1"<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord1().Get_X()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord1().Get_Y()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord1().Get_Z()<<"\n"
                               <<"Spot 2"<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord2().Get_X()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord2().Get_Y()<<" "<<base_donnees.Get_liste_mount_coord_spots().at(j).Get_coord2().Get_Z()<<"\n";
                    }
                }
            }

            fichier<<"\n"
                   <<"\n"
                   <<"*****************************************************************coordonnees du prisme dans le repere MOUNT********************************************************************************** \n";
            //sauvegarde des coordonnees du prisme dans le repere MOUNT pour chaque paire de spots
            std::string premier_prisme_mount = base_donnees.Get_liste_mount_coord_prism().at(0).Get_id();

            for(unsigned int i=0; i<base_donnees.Get_liste_mount_coord_prism().size(); i++)
            {
                if(i>0 && base_donnees.Get_liste_mount_coord_prism().at(i).Get_id() == premier_prisme_mount) //si on a tout parcourut et on revient au premier objet ==> fin
                    break;

                fichier<<base_donnees.Get_liste_mount_coord_prism().at(i).Get_id()<<"\n";
                for(unsigned int j=0; j<base_donnees.Get_liste_mount_coord_prism().size(); j++)
                {
                    if(base_donnees.Get_liste_mount_coord_prism().at(i).Get_id() == base_donnees.Get_liste_mount_coord_prism().at(j).Get_id())
                    {
                        fichier<<base_donnees.Get_liste_mount_coord_prism().at(j).Get_coord_prism_mount_sys().Get_X()<<" "<<base_donnees.Get_liste_mount_coord_prism().at(j).Get_coord_prism_mount_sys().Get_Y()<<" "<<base_donnees.Get_liste_mount_coord_prism().at(j).Get_coord_prism_mount_sys().Get_Z()<<"\n";
                    }
                }
            }

            fichier<<"\n"
                   <<"\n"
                   <<"*****************************************************************coordonnees du prisme dans le repere ATLAS********************************************************************************** \n";
            //sauvegarde des coordonnees du prisme dans le repere ATLAS pour chaque paire de spots
            std::string premier_prisme_atlas = base_donnees.Get_liste_global_coord_prism().at(0).Get_id();

            for(unsigned int i=0; i<base_donnees.Get_liste_global_coord_prism().size(); i++)
            {
                if(i>0 && base_donnees.Get_liste_global_coord_prism().at(i).Get_id() == premier_prisme_atlas)
                    break;

                fichier<<base_donnees.Get_liste_global_coord_prism().at(i).Get_id()<<"\n";
                for(unsigned int j=0; j<base_donnees.Get_liste_global_coord_prism().size(); j++)
                {
                    if(base_donnees.Get_liste_global_coord_prism().at(i).Get_id() == base_donnees.Get_liste_global_coord_prism().at(j).Get_id())
                    {
                        fichier<<base_donnees.Get_liste_global_coord_prism().at(j).Get_coord_prism_mount_sys().Get_X()<<" "<<base_donnees.Get_liste_global_coord_prism().at(j).Get_coord_prism_mount_sys().Get_Y()<<" "<<base_donnees.Get_liste_global_coord_prism().at(j).Get_coord_prism_mount_sys().Get_Z()<<"\n";
                    }
                }
            }
            fichier<<"\n"
                   <<"\n"
                   <<"*****************************************************************Rapport********************************************************************************** \n";
            //on parcourt tous les points transformes dans le repere global : moyenne + dispersion
            // current date/time based on current system
            time_t now = time(0);
            tm *ltm = localtime(&now);
            // print various components of tm structure.
            float year = 1900 + ltm->tm_year;
            float month = 1 + ltm->tm_mon;
            float day = ltm->tm_mday;
            float hour = ltm->tm_hour;
            float min = ltm->tm_min;
            float sec = ltm->tm_sec;

            for(unsigned int i=0; i<base_donnees.Get_liste_global_coord_prism().size(); i++)
            {
                if(i>0 && base_donnees.Get_liste_global_coord_prism().at(i).Get_id() == premier_prisme_atlas)
                    break;

                Eigen::MatrixXd coord(Eigen::DynamicIndex,3);
                int ligne=0;

                for(unsigned int j=0; j<base_donnees.Get_liste_global_coord_prism().size(); j++)
                {
                    if(base_donnees.Get_liste_global_coord_prism().at(i).Get_id() == base_donnees.Get_liste_global_coord_prism().at(j).Get_id())
                    {
                        coord(ligne,0)=base_donnees.Get_liste_global_coord_prism().at(j).Get_coord_prism_mount_sys().Get_X();
                        coord(ligne,1)=base_donnees.Get_liste_global_coord_prism().at(j).Get_coord_prism_mount_sys().Get_Y();
                        coord(ligne,2)=base_donnees.Get_liste_global_coord_prism().at(j).Get_coord_prism_mount_sys().Get_Z();
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
                mount_coord_prism prism = base_donnees.Get_liste_global_coord_prism().at(i);
                std::string name_bcam_atlas = base_donnees.getName(prism.Get_id().substr(0,14));
                std::string name_prism_atlas = base_donnees.getName(prism.Get_id().substr(15,5));

                //delta selon composantes axiales
                float delta_x=0;
                float delta_y=0;
                float delta_z=0;
                //ajout de la constante de prisme
                for(unsigned int n=0; n<base_donnees.Get_liste_correction_excentrement().size(); n++)
                {
                    if(base_donnees.Get_liste_global_coord_prism().at(i).Get_id().substr(15,5) == base_donnees.Get_liste_correction_excentrement().at(n).Get_id_prism())
                    {
                        delta_x = base_donnees.Get_liste_correction_excentrement().at(n).Get_delta().Get_X();
                        delta_y = base_donnees.Get_liste_correction_excentrement().at(n).Get_delta().Get_Y();
                        delta_z = base_donnees.Get_liste_correction_excentrement().at(n).Get_delta().Get_Z();
                    }
                }
                std::cout<<delta_x<<std::endl;
                std::cout<<delta_y<<std::endl;
                std::cout<<delta_z<<std::endl;
                //enregistrement dans le fichier de resultats
                fichier<<name_bcam_atlas<<"_"<<name_prism_atlas<<" "<<year<<"."<<month<<"."<<day<<"."<<hour<<"."<<min<<"."<<sec<<" "<<result_mean(0,0)+delta_x<<" "<<result_mean(0,1)+delta_y<<" "<<result_mean(0,2)+delta_z<<" "<<result_std(0,0)<<" "<<result_std(0,1)<<" "<<result_std(0,2)<<" "<<"VRAI \n";
            }

        fichier.close();
        return 1;
    }

    else
    {
           return 0;
    }
}

