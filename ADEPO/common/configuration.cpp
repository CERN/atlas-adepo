
#include <algorithm>
#include <iosfwd>
#include <fstream>
#include <iostream>

#include <QDebug>

#include "configuration.h"

#define NBR_DETECTORS 8
#define ID_LENGTH_BCAM 14

int Configuration::read(QString filename)
{

    std::ifstream file((char*)filename.toStdString().c_str(), std::ios::in);
    if(!file) {
        qWarning() << "Cannot read configuration file " << filename;
        return 0;
    }

    clear();

    std::string line;

    unsigned int etape_calcul = 0;

    while(std::getline(file,line)) // tant que l'on arrive pas a la fin du file
    {
        // take ending off the line
        line.erase(line.find_last_not_of(" \n\r\t")+1);

        // si on a une line vide on saute une line
        if(!line.empty())
        {
            //detector
            if(line.substr(0,16).compare("//DETECTORS_DATA")==0)
            {
                getline(file, line);
                etape_calcul = 1;
            }

            //BCAM
            if(line.substr(0,12).compare("//BCAMS_DATA")==0)
            {
                getline(file, line);
                etape_calcul = 2;
            }

            //driver_ip_adress
            if(line.substr(0,18).compare("//DRIVER_IP_ADRESS")==0)
            {
                    getline(file, line);
                    etape_calcul = 3;
            }

            //adaptateur_bcam_bleu
            if(line.substr(0,30).compare("//MODELE_COORDINATES_BLUE_BCAM")==0)
            {
                getline(file, line);
                etape_calcul = 4;
            }

            //adaptateur_bcam_bleu
            if(line.substr(0,31).compare("//MODELE_COORDINATES_BLACK_BCAM")==0)
            {
                getline(file, line);
                etape_calcul = 5;
            }

            //distances absolues
            if(line.substr(0,21).compare("//ABSOLUTE_DISTANCES")==0)
            {
                getline(file, line);
                etape_calcul = 6;
            }

            //positions des bcams dans ATLAS avec l'adaptateur
            if(line.substr(0,19).compare("//ATLAS_COORDINATES")==0)
            {
                getline(file, line);
                etape_calcul = 7;
            }

            //nomenclature des prismes et des bcams dans atlas
            if(line.substr(0,41).compare("//PRISMS_&_BCAM_NAMES_FOR_THE_RESULT_FILE")==0)
            {
                getline(file, line);
                etape_calcul = 8;
            }

            //corrections d'excentrement par prisme
            if(line.substr(0,33).compare("//PRISMS_CORRECTIONS_ATLAS_SYSTEM")==0)
            {
                getline(file, line);
                etape_calcul = 9;
            }

            // take ending off the line
            line.erase(line.find_last_not_of(" \n\r\t")+1);

            if(!line.empty())
            {
                switch(etape_calcul)
                {
                    case 1:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        //recuperation du nom du detecteur
                        char *num_id_detector = strtok(buffer, " " );
                        QString nom_detector = QString::fromStdString(strtok( NULL, " " ));
                        char *airpad = strtok( NULL, " " );
                        //ajout dans la base de donnees
                        Detector det(atoi(num_id_detector), nom_detector, atof(airpad));
                        //det.Affiche();
                        add(det);
                    }
                    break;

                    case 4:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        QString id_cible = QString::fromStdString(strtok(buffer, " " ));
                        char *X1 = strtok( NULL, " " );
                        char *Y1 = strtok( NULL, " " );
                        char *Z1 = strtok( NULL, " " );
                        Point3d pt_cible(atof(X1),atof(Y1),atof(Z1));
                        QString type_bcam = "Blue";
                        BCAMAdapter blue_model(type_bcam, id_cible, pt_cible);
                        //blue_model.Affiche();
                        add(blue_model);

                    }
                    break;

                    case 5:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        QString id_cible = QString::fromStdString(strtok(buffer, " " ));
                        char *X1 = strtok( NULL, " " );
                        char *Y1 = strtok( NULL, " " );
                        char *Z1 = strtok( NULL, " " );
                        Point3d pt_cible(atof(X1),atof(Y1),atof(Z1));
                        QString type_bcam = "Black";
                        BCAMAdapter black_model(type_bcam, id_cible, pt_cible);
                        //black_model.Affiche();
                        add(black_model);

                    }
                    break;

                    case 3:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        //recuperation de l'adresse ip du driver
                        QString driver_ip_adress = QString::fromStdString(strtok(buffer," "));
                        setDriverIpAddress(driver_ip_adress);
                    }
                    break;

                    case 2:
                    {
                       char *buffer = strdup((char*)line.c_str());
                       //recuperation des donnees de la BCAM
                       int nb_string = std::count(line.begin(), line.end(), ' '); //nombre de colonne dans la line

                       if (nb_string < 5) {
                            qCritical() << "Error in config: " << nb_string << ":" << QString::fromStdString(line);
                       } else {
                           // 20MABNDA000318 3 2 1 PR004 ...
                           QString nom_BCAM = QString::fromStdString(strtok(buffer," "));
                           char *id_detector = strtok( NULL, " " );
                           char *num_Port_Driver = strtok( NULL, " " );
                           char *num_Port_Multiplexer = strtok( NULL, " " );
                           std::vector<Prism> prisms;
                           QString prism1 = QString::fromStdString(strtok( NULL, " " ));

                           switch(nb_string)
                           {
                               default:
                                   qCritical() << "Error in config: " << nb_string << ":" << QString::fromStdString(line);
                                   break;
                               case 5: //cas ou une BCAM simple ou double vise un prisme
                               {    // 20MABNDA000318 3 2 1 PR004 2
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
                                   //std::cout<<nb_string<<std::endl;
                                   // bcam_data.print();
                                   add(bcam_data);
                               }
                               break;

                               case 7: //cas ou une BCAM double vise deux prisme d'un cote et une autre BCAM de l'autre cote
                               {    // 20MABNDL000077 1 2 7 PR002 PR003 1 20MABNDM000168
                                   QString prism2 = QString::fromStdString(strtok( NULL, " " ));
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   prisms.push_back(Prism(prism2, atoi(num_chip)));
                                   prisms.push_back(Prism(strtok( NULL, " " ), atoi(num_chip) == 1 ? 2 : 1));
                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
                                   // bcam_data.print();
                                   add(bcam_data);
                               }
                               break;

                               case 8: //cas ou une BCAM double vise 2 prismes d'un cote et une bcam de l'autre cote avec prisme
                               {    // 20MABNDL000077 1 2 7 PR002 PR003 1 20MABNDM000168 PR024
                                   QString prism2 = QString::fromStdString(strtok( NULL, " " ));
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   prisms.push_back(Prism(prism2, atoi(num_chip)));
                                   prisms.push_back(Prism(strtok( NULL, " " ), atoi(num_chip) == 1 ? 2 : 1));
                                   prisms.push_back(Prism(strtok( NULL, " " ), atoi(num_chip) == 1 ? 2 : 1));

                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
    //                               bcam_data.print();
                                   add(bcam_data);
                               }
                               break;

                               case 6: //cas ou une bcam simple vise deux prismes
                               {    // 20MABNDA000035 8 3 6 PR044 PR047 2
                                   QString prism2 = QString::fromStdString(strtok( NULL, " " ));
                                   char *num_chip = strtok( NULL, " " );
                                   prisms.push_back(Prism(prism1, atoi(num_chip)));
                                   prisms.push_back(Prism(prism2, atoi(num_chip)));
                                   BCAMConfig bcam_data(nom_BCAM, atoi(id_detector), atoi(num_Port_Driver), atoi(num_Port_Multiplexer), prisms);
                                   // bcam_data.print();
                                   add(bcam_data);
                               }
                               break;
                            }
                        }
                    }
                    break;

                    case 6:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        QString id_bcam = QString::fromStdString(strtok(buffer, " " ));
                        QString id_prisme = QString::fromStdString(strtok( NULL, " " ));
                        char *dist_pivot_prisme = strtok( NULL, " " );
                        char *dist_source1_prisme = strtok( NULL, " " );
                        char *dist_source2_prisme = strtok( NULL, " " );
                        Point3d dist(atof(dist_pivot_prisme), atof(dist_source1_prisme),atof(dist_source2_prisme));
                        AbsoluteDistances abs_dist(id_bcam, id_prisme, dist);
                        //abs_dist.Affiche();
                        add(abs_dist);
                    }
                    break;

                    case 7:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        QString id_bcam = QString::fromStdString(strtok(buffer, " " ));
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
                        Point3d B1(atof(B1_x), atof(B1_y), atof(B1_z));
                        Point3d B2(atof(B2_x), atof(B2_y), atof(B2_z));
                        Point3d B3(atof(B3_x), atof(B3_y), atof(B3_z));
                        Point3d B4(atof(B4_x), atof(B4_y), atof(B4_z));
                        ATLASCoordinates pos1_bcam(id_bcam, B1);
                        ATLASCoordinates pos2_bcam(id_bcam, B2);
                        ATLASCoordinates pos3_bcam(id_bcam, B3);
                        ATLASCoordinates pos4_bcam(id_bcam, B4);
                        //pos1_bcam.print();
                        //pos2_bcam.print();
                        //pos3_bcam.print();
                        //pos4_bcam.print();
                        add(pos1_bcam);
                        add(pos2_bcam);
                        add(pos3_bcam);
                        add(pos4_bcam);
                    }
                    break;

                    case 8:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        QString name = QString::fromStdString(strtok(buffer, " " ));
                        QString id = QString::fromStdString(strtok( NULL, " " ));
                        addName(id, name);
                    }
                    break;

                    case 9:
                    {
                        char *buffer = strdup((char*)line.c_str());
                        QString id_prisme = QString::fromStdString(strtok(buffer, " " ));
                        char *delta_x = strtok( NULL, " " );
                        char *delta_y = strtok( NULL, " " );
                        char *delta_z = strtok( NULL, " " );
                        Point3d delta(atof(delta_x),atof(delta_y),atof(delta_z));
                        PrismCorrection pr_corr(id_prisme, delta);
                        //pr_corr.Affiche();
                        add(pr_corr);
                    }
                    break;
                }

             }

        }

    }

    file.close();

    this->filename = filename;

    return 1;
}


QString Configuration::check() const
{
    //test des numéros des ports driver : sur les driver les numéros de ports possibles sont compris entre 1 et 8
    for (unsigned int i=0; i<getBCAMConfigs().size(); i++)
    {
        if(getBCAMConfigs().at(i).getDriverSocket()>8 || getBCAMConfigs().at(i).getDriverSocket()<1)
        {
            return "Attention les numéros des ports driver sont impérativement compris entre 1 et 8";
        }
    }

    //test des numéros des ports multiplexer : sur les multiplexer les numéros des ports possibles sont compris entre 1 et 10
    for (unsigned int i=0; i<getBCAMConfigs().size(); i++)
    {
        if(getBCAMConfigs().at(i).getMuxSocket()>10 || getBCAMConfigs().at(i).getMuxSocket()<1)
        {
            return "Attention les numéros des ports multiplexer sont impérativement compris entre 1 et 10";
        }
    }

    //test sur le nombre de détecteurs (ce nombre == 8 )
//    if (getDetectors().size() != NBR_DETECTORS)
//    {
//        return "Information Le nombre de detecteurs est different de 8";
//    }

    //test pour vérifier si dans le file d'entrée, il y a un seul et unique détecteur avec un seul et unique identifiant
    for (unsigned int i=0; i<getDetectors().size(); i++)
    {

         for (unsigned int j=0; j<getDetectors().size(); j++)
        {
             if( j != i && getDetectors().at(i).getName() == getDetectors().at(j).getName())
             {
                 return "Attention Vous avez entre 2 fois le meme nom de detecteur !";
             }
             if(j != i && getDetectors().at(i).getId() == getDetectors().at(j).getId())
             {
                 return "Attention Vous avez entre 2 fois le meme numero d'identifiant pour un detectuer !";
             }
        }
    }

    //test sur la longueur des chaînes de caractères (identifiant des BCAMs)
    for (unsigned int i=0; i<getBCAMConfigs().size(); i++)
    {
        if(getBCAMConfigs().at(i).getName().size() != ID_LENGTH_BCAM)
        {
            return "Attention Au moins 1 BCAM comporte un identifiant de longueur inapropriee !";
        }
    }


    //test pour vérifier si dans le file d'entrée, il y a une seule et unique BCAM (vu la structure du file elle appartient à un unique detecteur)
    for (unsigned int i=0; i<getBCAMConfigs().size(); i++)
    {
        for (unsigned int j=0; j<getBCAMConfigs().size(); j++)
        {
            if(j != i && getBCAMConfigs().at(i).getName() == getBCAMConfigs().at(j).getName())
            {
                return "Attention Vous avez entre 2 fois le meme numero d'identifiant de BCAM !";
            }
        }
    }

    //test pour éviter que 2 BCAMs ne soient branchées sur le même port multiplexer et même port driver à la fois
    for (unsigned int i=0; i<getBCAMConfigs().size(); i++)
    {
        for (unsigned int j=0; j<getBCAMConfigs().size(); j++)
        {
            if((i != j) && (getBCAMConfigs().at(i).getDriverSocket() == getBCAMConfigs().at(j).getDriverSocket()) &&
                    (getBCAMConfigs().at(i).getMuxSocket() == getBCAMConfigs().at(j).getMuxSocket()))
            {
                return "Attention 2 BCAMs ne peut pas être branchée sur le même port driver et multiplexer à la fois !";
            }
        }
    }

    return "";
}

