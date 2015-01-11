#include "read_input.h"

#include <algorithm>
#include <iosfwd>
#include <fstream>
#include <iostream>

int read_input(std::string fichier_configuration, Configuration &config)
{

    std::ifstream fichier((char*)fichier_configuration.c_str(), std::ios::in);
    if(!fichier) {
        std::cout << "WARNING Cannot read input file " << fichier_configuration << std::endl;
        return 0;
    }

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
                        Detector det(atoi(num_id_detector), nom_detector, atof(airpad));
                        //det.Affiche();
                        config.add(det);
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
                        BCAMAdapter blue_model(type_bcam, id_cible, pt_cible);
                        //blue_model.Affiche();
                        config.add(blue_model);

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
                        BCAMAdapter black_model(type_bcam, id_cible, pt_cible);
                        //black_model.Affiche();
                        config.add(black_model);

                    }
                    break;

                    case 3:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation de l'adresse ip du driver
                        std::string driver_ip_adress = strtok(buffer," ");
                        config.setDriverIpAddress(driver_ip_adress);
                    }
                    break;

                    case 2:
                    {
                       char *buffer = strdup((char*)ligne.c_str());
                       //recuperation des donnees de la BCAM
                       int nb_string = std::count(ligne.begin(), ligne.end(), ' '); //nombre de colonne dans la ligne

                       if (nb_string < 5) {
                            std::cout << "Error in config: " << nb_string << ":" << ligne << ":" << std::endl;
                       } else {
                           // 20MABNDA000318 3 2 1 PR004 ...
                           std::string nom_BCAM = strtok(buffer," ");
                           char *id_detector = strtok( NULL, " " );
                           char *num_Port_Driver = strtok( NULL, " " );
                           char *num_Port_Multiplexer = strtok( NULL, " " );
                           std::vector<Prism> prisms;
                           std::string prism1 = strtok( NULL, " " );

                           switch(nb_string)
                           {
                               default:
                                   std::cout << "Error in config: " << nb_string << ":" << ligne << ":" << std::endl;
                                   break;
                               case 5: //cas ou une BCAM simple ou double vise un prisme
                               {    // 20MABNDA000318 3 2 1 PR004 2
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
                                   //std::cout<<nb_string<<std::endl;
                                   // bcam_data.print();
                                   config.add(bcam_data);
                               }
                               break;

                               case 7: //cas ou une BCAM double vise deux prisme d'un cote et une autre BCAM de l'autre cote
                               {    // 20MABNDL000077 1 2 7 PR002 PR003 1 20MABNDM000168
                                   std::string prism2 = strtok( NULL, " " );
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   prisms.push_back(Prism(prism2, atoi(num_chip)));
                                   prisms.push_back(Prism(strtok( NULL, " " ), atoi(num_chip) == 1 ? 2 : 1));
                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
                                   // bcam_data.print();
                                   config.add(bcam_data);
                               }
                               break;

                               case 8: //cas ou une BCAM double vise 2 prismes d'un cote et une bcam de l'autre cote avec prisme
                               {    // 20MABNDL000077 1 2 7 PR002 PR003 1 20MABNDM000168 PR024
                                   std::string prism2 = strtok( NULL, " " );
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   prisms.push_back(Prism(prism2, atoi(num_chip)));
                                   prisms.push_back(Prism(strtok( NULL, " " ), atoi(num_chip) == 1 ? 2 : 1));
                                   prisms.push_back(Prism(strtok( NULL, " " ), atoi(num_chip) == 1 ? 2 : 1));

                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
    //                               bcam_data.print();
                                   config.add(bcam_data);
                               }
                               break;

                               case 6: //cas ou une bcam simple vise deux prismes
                               {    // 20MABNDA000035 8 3 6 PR044 PR047 2
                                   std::string prism2 = strtok( NULL, " " );
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   prisms.push_back(Prism(prism2, atoi(num_chip)));
                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
                                   // bcam_data.print();
                                   config.add(bcam_data);
                               }
                               break;
                            }
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
                        AbsoluteDistances abs_dist(id_bcam, id_prisme, dist);
                        //abs_dist.Affiche();
                        config.add(abs_dist);
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
                        ATLASCoordinates pos1_bcam(id_bcam, B1);
                        ATLASCoordinates pos2_bcam(id_bcam, B2);
                        ATLASCoordinates pos3_bcam(id_bcam, B3);
                        ATLASCoordinates pos4_bcam(id_bcam, B4);
                        //pos1_bcam.print();
                        //pos2_bcam.print();
                        //pos3_bcam.print();
                        //pos4_bcam.print();
                        config.add(pos1_bcam);
                        config.add(pos2_bcam);
                        config.add(pos3_bcam);
                        config.add(pos4_bcam);
                    }
                    break;

                    case 8:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        std::string name = strtok(buffer, " " );
                        std::string id = strtok( NULL, " " );
                        config.addName(id, name);
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
                        PrismCorrection pr_corr(id_prisme, delta);
                        //pr_corr.Affiche();
                        config.add(pr_corr);
                    }
                    break;
                }

             }

        }

    }

    fichier.close();
    return 1;
}
