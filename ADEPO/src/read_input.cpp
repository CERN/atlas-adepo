#include "read_input.h"
#include <algorithm>

int read_input(std::string fichier_configuration, bdd &base_donnees)
{

    std::ifstream fichier((char*)fichier_configuration.c_str(), std::ios::in);
    if(fichier)
    {
        std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue

        unsigned int etape_calcul = 0;

        while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
        {
            // take ending off the line
            ligne.erase(ligne.find_last_not_of(" \n\r\t")+1);

            // si on a une ligne vide on saute une ligne
            if(!ligne.empty())
            {
                //detector
                if(ligne.substr(0,16).compare("//DETECTORS_DATA")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 1;
                }

                //BCAM
                if(ligne.substr(0,12).compare("//BCAMS_DATA")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 2;
                }

                //driver_ip_adress
                if(ligne.substr(0,18).compare("//DRIVER_IP_ADRESS")==0)
                {
                        getline(fichier, ligne);
                        etape_calcul = 3;
                }

                //adaptateur_bcam_bleu
                if(ligne.substr(0,30).compare("//MODELE_COORDINATES_BLUE_BCAM")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 4;
                }

                //adaptateur_bcam_bleu
                if(ligne.substr(0,31).compare("//MODELE_COORDINATES_BLACK_BCAM")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 5;
                }

                //distances absolues
                if(ligne.substr(0,21).compare("//ABSOLUTE_DISTANCES")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 6;
                }

                //positions des bcams dans ATLAS avec l'adaptateur
                if(ligne.substr(0,19).compare("//ATLAS_COORDINATES")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 7;
                }

                //nomenclature des prismes et des bcams dans atlas
                if(ligne.substr(0,41).compare("//PRISMS_&_BCAM_NAMES_FOR_THE_RESULT_FILE")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 8;
                }

                //corrections d'excentrement par prisme
                if(ligne.substr(0,33).compare("//PRISMS_CORRECTIONS_ATLAS_SYSTEM")==0)
                {
                    getline(fichier, ligne);
                    etape_calcul = 9;
                }

                // take ending off the line
                ligne.erase(ligne.find_last_not_of(" \n\r\t")+1);

                if(!ligne.empty())
                {
                    switch(etape_calcul)
                    {
                        case 1:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            //recuperation du nom du detecteur
                            char *num_id_detector = strtok(buffer, " " );
                            std::string nom_detector = strtok( NULL, " " );
                            char *airpad = strtok( NULL, " " );
                            //ajout dans la base de donnees
                            detector det(atoi(num_id_detector), nom_detector, atof(airpad));
                            //det.Affiche();
                            base_donnees.Add_detector(det);
                        }
                        break;

                        case 4:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            std::string id_cible = strtok(buffer, " " );
                            char *X1 = strtok( NULL, " " );
                            char *Y1 = strtok( NULL, " " );
                            char *Z1 = strtok( NULL, " " );
                            Point3f pt_cible(atof(X1),atof(Y1),atof(Z1));
                            std::string type_bcam = "Blue";
                            bcam_adaptateur blue_model(type_bcam, id_cible, pt_cible);
                            //blue_model.Affiche();
                            base_donnees.Add_bcam_adaptateur(blue_model);

                        }
                        break;

                        case 5:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            std::string id_cible = strtok(buffer, " " );
                            char *X1 = strtok( NULL, " " );
                            char *Y1 = strtok( NULL, " " );
                            char *Z1 = strtok( NULL, " " );
                            Point3f pt_cible(atof(X1),atof(Y1),atof(Z1));
                            std::string type_bcam = "Black";
                            bcam_adaptateur black_model(type_bcam, id_cible, pt_cible);
                            //black_model.Affiche();
                            base_donnees.Add_bcam_adaptateur(black_model);

                        }
                        break;

                        case 3:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            //recuperation de l'adresse ip du driver
                            std::string driver_ip_adress = strtok(buffer," ");
                            base_donnees.Set_driver_ip_adress(driver_ip_adress);
                        }
                        break;

                        case 2:
                        {
                           char *buffer = strdup((char*)ligne.c_str());
                           //recuperation des donnees de la BCAM
                           int nb_string = std::count(ligne.begin(), ligne.end(), ' '); //nombre de colonne dans la ligne
//                           std::cout<<nb_string << ":" << ligne << ":" << std::endl;

                           if(nb_string == 5) //cas ou une BCAM simple ou double vise un prisme
                           {
                               std::string nom_BCAM = strtok(buffer," ");
                               char *id_detector = strtok( NULL, " " );
                               char *num_Port_Driver = strtok( NULL, " " );
                               char *num_Port_Multiplexer = strtok( NULL, " " );
                               std::string id_prisme = strtok( NULL, " " );
                               char *num_chip_bcam_single = strtok( NULL, " " );
                               BCAM bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), atoi(num_chip_bcam_single), id_prisme);
                               //std::cout<<nb_string<<std::endl;
                               //bcam_data.Affiche();
                               base_donnees.Add_BCAM(bcam_data);
                           }

                           if(nb_string == 7) //cas ou une BCAM double vise deux prisme d'un cote et une autre BCAM de l'autre cote
                           {

                               std::string nom_BCAM = strtok(buffer," ");
                               char *id_detector = strtok( NULL, " " );
                               char *num_Port_Driver = strtok( NULL, " " );
                               char *num_Port_Multiplexer = strtok( NULL, " " );
                               std::string id_prisme_1 = strtok( NULL, " " );
                               std::string id_prisme_2 = strtok( NULL, " " );
                               char *num_chip_double_bcam = strtok( NULL, " " );
                               std::string id_bcam_visee = strtok( NULL, " " );
                               BCAM bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), atoi(num_chip_double_bcam), id_prisme_1.append("_").append(id_prisme_2).append("_").append(id_bcam_visee));
                               //bcam_data_.Affiche();
                               base_donnees.Add_BCAM(bcam_data);

                           }

                           if(nb_string == 8) //cas ou une BCAM double vise 3 prismes d'un cote et une bcam de l'autre cote
                           {
                               std::string nom_BCAM = strtok(buffer," ");
                               char *id_detector = strtok( NULL, " " );
                               char *num_Port_Driver = strtok( NULL, " " );
                               char *num_Port_Multiplexer = strtok( NULL, " " );
                               std::string id_prisme_1 = strtok( NULL, " " );
                               std::string id_prisme_2 = strtok( NULL, " " );
                               std::string id_prisme_3 = strtok( NULL, " " );
                               char *num_chip_double_bcam = strtok( NULL, " " );
                               std::string id_bcam_visee = strtok( NULL, " " );

                               BCAM bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), atoi(num_chip_double_bcam), id_prisme_1.append("_").append(id_prisme_2).append("_").append(id_prisme_3).append("_").append(id_bcam_visee));
                               //bcam_data.Affiche();
                               base_donnees.Add_BCAM(bcam_data);
                           }

                           if(nb_string == 6) //cas ou une bcam simple vise deux prismes
                           {
                               std::string nom_BCAM = strtok(buffer," ");
                               char *id_detector = strtok( NULL, " " );
                               char *num_Port_Driver = strtok( NULL, " " );
                               char *num_Port_Multiplexer = strtok( NULL, " " );
                               std::string id_prisme_1 = strtok( NULL, " " );
                               std::string id_prisme_2 = strtok( NULL, " " );
                               char *num_chip_single_bcam = strtok( NULL, " " );
                               BCAM bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), atoi(num_chip_single_bcam), id_prisme_1.append("_").append(id_prisme_2));
                               //bcam_data.Affiche();
                               base_donnees.Add_BCAM(bcam_data);
                           }

                    }
                        break;

                        case 6:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            std::string id_bcam = strtok(buffer, " " );
                            std::string id_prisme = strtok( NULL, " " );
                            char *dist_pivot_prisme = strtok( NULL, " " );
                            char *dist_source1_prisme = strtok( NULL, " " );
                            char *dist_source2_prisme = strtok( NULL, " " );
                            Point3f dist(atof(dist_pivot_prisme), atof(dist_source1_prisme),atof(dist_source2_prisme));
                            absolutes_distances abs_dist(id_bcam.append("_").append(id_prisme), dist);
                            //abs_dist.Affiche();
                            base_donnees.Add_distance_absolue(abs_dist);
                        }
                        break;

                        case 7:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            std::string id_bcam = strtok(buffer, " " );
                            char *B1_x =  strtok( NULL, " " );
                            char *B1_y =  strtok( NULL, " " );
                            char *B1_z =  strtok( NULL, " " );
                            char *B2_x =  strtok( NULL, " " );
                            char *B2_y =  strtok( NULL, " " );
                            char *B2_z =  strtok( NULL, " " );
                            char *B3_x =  strtok( NULL, " " );
                            char *B3_y =  strtok( NULL, " " );
                            char *B3_z =  strtok( NULL, " " );
                            char *B4_x =  strtok( NULL, " " );
                            char *B4_y =  strtok( NULL, " " );
                            char *B4_z =  strtok( NULL, " " );
                            Point3f B1(atof(B1_x), atof(B1_y), atof(B1_z));
                            Point3f B2(atof(B2_x), atof(B2_y), atof(B2_z));
                            Point3f B3(atof(B3_x), atof(B3_y), atof(B3_z));
                            Point3f B4(atof(B4_x), atof(B4_y), atof(B4_z));
                            ATLAS_coordinates pos1_bcam(id_bcam, B1);
                            ATLAS_coordinates pos2_bcam(id_bcam, B2);
                            ATLAS_coordinates pos3_bcam(id_bcam, B3);
                            ATLAS_coordinates pos4_bcam(id_bcam, B4);
                            //pos1_bcam.Affiche();
                            //pos2_bcam.Affiche();
                            //pos3_bcam.Affiche();
                            //pos4_bcam.Affiche();
                            base_donnees.Add_ATLAS_coordinates(pos1_bcam);
                            base_donnees.Add_ATLAS_coordinates(pos2_bcam);
                            base_donnees.Add_ATLAS_coordinates(pos3_bcam);
                            base_donnees.Add_ATLAS_coordinates(pos4_bcam);
                        }
                        break;

                        case 8:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            std::string name = strtok(buffer, " " );
                            std::string id = strtok( NULL, " " );
                            base_donnees.addName(id, name);
                        }
                        break;

                        case 9:
                        {
                            char *buffer = strdup((char*)ligne.c_str());
                            std::string id_prisme = strtok(buffer, " " );
                            char *delta_x = strtok( NULL, " " );
                            char *delta_y = strtok( NULL, " " );
                            char *delta_z = strtok( NULL, " " );
                            Point3f delta(atof(delta_x),atof(delta_y),atof(delta_z));
                            prism_correction pr_corr(id_prisme, delta);
                            //pr_corr.Affiche();
                            base_donnees.Add_correction_excentrement(pr_corr);
                        }
                        break;
                    }

                 }

            }

        }

        //std::cout<<base_donnees.Get_liste_ATLAS_coordinates().size()<<std::endl;
        /*for(int i=0; i<base_donnees.Get_liste_ATLAS_coordinates().size(); i++)
        {
            base_donnees.Get_liste_ATLAS_coordinates().at(i).Get_cible().Affiche();
        }*/

        fichier.close();
        return 1;

    }
    else
    {
        return 0;
    }
}
