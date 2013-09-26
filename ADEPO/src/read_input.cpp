#include "header/read_input.h"

int read_input(std::string fichier_configuration, bdd &base_donnees)
{

    std::ifstream fichier((char*)fichier_configuration.c_str(), std::ios::in);
    if(fichier)
    {
        std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
        int num_bcam=0;
        int num_detector=0;
        int num_chip=2;

        unsigned int etape_calcul = 0;

        while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
        {

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

                if(!ligne.empty())
                {
                    switch(etape_calcul)
                    {
                    case 1:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom du detecteur
                        std::string nom_detector = strtok(buffer," ");
                        char *num_id_detector = strtok( NULL, " " );
                        //ajout dans la base de donnees
                        detector det(nom_detector, atof(num_id_detector));
                        base_donnees.Add_detector(det);

                        //passage au detecteur suivant
                        num_detector++;
                    }
                    break;

                    case 2:
                    {
                       char *buffer = strdup((char*)ligne.c_str());
                       //recuperation des donnees de la BCAM
                       std::string nom_BCAM = strtok(buffer," ");
                       char *id_detector = strtok( NULL, " " );
                       char *num_Port_Driver = strtok( NULL, " " );
                       char *num_Port_Multiplexer = strtok( NULL, " " );
                       std::string type_bool_BCAM = strtok( NULL, " " );

                       if(type_bool_BCAM == "S")
                       {
                           std::string id_prisme = strtok( NULL, " " );
                           BCAM bcam_data(nom_BCAM, atof(id_detector), atof(num_Port_Driver), atof(num_Port_Multiplexer), type_bool_BCAM, num_chip, id_prisme);
                           base_donnees.Add_BCAM(bcam_data);
                       }

                       if(type_bool_BCAM == "D" && ligne.length() == 33)
                       {
                           std::string id_prisme = strtok( NULL, " ");
                           char *num_ccd = strtok( NULL, " " );

                           BCAM bcam_data(nom_BCAM, atof(id_detector), atof(num_Port_Driver), atof(num_Port_Multiplexer), type_bool_BCAM, atof(num_ccd), id_prisme);
                           base_donnees.Add_BCAM(bcam_data);
                       }

                       if(type_bool_BCAM == "D" && (ligne.length() == 57 || ligne.length() == 58))
                       {
                           std::string id_prisme_1 = strtok( NULL, " ");
                           std::string id_prisme_2 = strtok( NULL, " ");
                           char *num_ccd = strtok( NULL, " " );
                           std::string id_BCAM_visee = strtok( NULL, " " );

                           int opposite_ccd=0;

                           if(atof(num_ccd) == 2)
                           {
                                opposite_ccd = 1;
                           }
                           else
                           {
                                opposite_ccd = 2;
                           }

                           BCAM bcam_data1(nom_BCAM, atof(id_detector), atof(num_Port_Driver), atof(num_Port_Multiplexer), type_bool_BCAM, atof(num_ccd), id_prisme_1.append("_").append(id_prisme_2));
                           BCAM bcam_data2(nom_BCAM, atof(id_detector), atof(num_Port_Driver), atof(num_Port_Multiplexer), type_bool_BCAM, opposite_ccd, id_BCAM_visee);
                           base_donnees.Add_BCAM(bcam_data1);
                           base_donnees.Add_BCAM(bcam_data2);
                       }

                        //passage a la bcam suivante
                        num_bcam++;

                }
                        break;

                    }

                    }

                }

            }
        for(int i=0; i<base_donnees.Get_liste_BCAM().size();i++)
        {
            std::cout<<base_donnees.Get_liste_BCAM().at(i). Get_objet_vise()<<std::endl;
        }


        fichier.close();
        return 1;

    }
    else
    {
        return 0;
    }
}
