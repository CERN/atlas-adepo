#include "read_lwdaq_output.h"
#include "algorithm"

int read_lwdaq_output(QFile &file, bdd & base_donnees)
{
    std::ifstream fichier((char*)file.fileName().toStdString().c_str(), std::ios::in);
    if(fichier)
    {
        std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
        unsigned int etape_calcul=0;

        while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
        {
            // take ending off the line
            ligne.erase(ligne.find_last_not_of(" \n\r\t")+1);

            if(!ligne.empty())
            {
                int nb_colonnes = std::count(ligne.begin(), ligne.end(), ' '); //je compte le nombre de colonnes dans le fichier

                //2 spots
                if(nb_colonnes == 12)
                {
                    etape_calcul = 1;
                }

                //4 spots
                if(nb_colonnes == 24)
                {
                    etape_calcul = 2;
                }

                //6 spots
                if(nb_colonnes == 36)
                {
                    etape_calcul = 3;
                }

                //message d'erreur
                if(nb_colonnes == 8)
                {
                    etape_calcul = 4;
                }

                if(!ligne.empty())
                {
                    switch(etape_calcul)
                    {
                    case 1:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom de la BCAM_Objet + coordonnées images du premier spot
                        std::string nom_BCAM_Objets = strtok(buffer," ");
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
                        spot sp(nom_BCAM_Objets.substr(0,14), nom_BCAM_Objets.substr(15,5),
                                atof(coord1_i_ccd), atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                        base_donnees.add(sp);
                        break;
                    }

                    case 2:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                        std::string nom_BCAM_Objets = strtok(buffer," ");
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
                        spot sp1(nom_BCAM_Objets.substr(0,14), nom_BCAM_Objets.substr(15,5),
                                 atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                        base_donnees.add(sp1);
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
                        spot sp2(nom_BCAM_Objets.substr(0,14), nom_BCAM_Objets.substr(21,5),
                                 atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                        base_donnees.add(sp2);
                        break;
                    }

                    case 3:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                        std::string nom_BCAM_Objets = strtok(buffer," ");
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
                        spot sp1(nom_BCAM_Objets.substr(0,14), nom_BCAM_Objets.substr(15,5),
                                 atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                        base_donnees.add(sp1);
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
                        spot sp2(nom_BCAM_Objets.substr(0,14), nom_BCAM_Objets.substr(21,5),
                                 atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                        base_donnees.add(sp2);
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
                        spot sp3(nom_BCAM_Objets.substr(0,14), nom_BCAM_Objets.substr(27,5),
                                 atof(coord5_i_ccd), atof(coord5_j_ccd), atof(coord6_i_ccd), atof(coord6_j_ccd));
                        base_donnees.add(sp3);
                        break;
                    }

                    case 4:
                    {
                       return 0;
                    }
                    } // switch
                }
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
