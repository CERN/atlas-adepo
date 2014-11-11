#include "read_lwdaq_output.h"
#include "algorithm"

#include <QString>
#include <QStringList>

int read_lwdaq_output(QFile &file, bdd & base_donnees)
{
    std::ifstream fichier((char*)file.fileName().toStdString().c_str(), std::ios::in);
    if(fichier)
    {
        std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
        double savedSpotI = 0;
        double savedSpotJ = 0;
        bool savedSpotReady = false;

        while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
        {
            // take ending off the line
            ligne.erase(ligne.find_last_not_of(" \n\r\t")+1);

            if(!ligne.empty())
            {
                int nb_colonnes = std::count(ligne.begin(), ligne.end(), ' '); //je compte le nombre de colonnes dans le fichier

                switch(nb_colonnes)
                {
                case 6: // 1 spot, wait for second one...
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet + coordonnées images du spot
                    std::string name = strtok(buffer," ");
                    BCAM bcam = base_donnees.getBCAM(name);
                    char *coord_i_ccd = strtok( NULL, " " );
                    char *coord_j_ccd = strtok( NULL, " " );
                    //sauter les 4 prochaines valeurs
                    for(int i=0; i<4; i++)
                    {
                        strtok( NULL, " " );
                    }

                    if (savedSpotReady) {
                        DualSpot dsp(bcam, savedSpotI, savedSpotJ, atof(coord_i_ccd), atof(coord_j_ccd));
                        base_donnees.add(dsp);
                        savedSpotReady = false;
                    } else {
                        savedSpotI = atof(coord_i_ccd);
                        savedSpotJ = atof(coord_j_ccd);
                        savedSpotReady = true;
                    }
                }

                case 12: // 2 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet + coordonnées images du premier spot
                    std::string name = strtok(buffer," ");
                    BCAM bcam = base_donnees.getBCAM(name);
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
                    DualSpot dsp(bcam,
                            atof(coord1_i_ccd), atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                    base_donnees.add(dsp);
//                    sp.print();
                    break;
                }

                case 24: // 4 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                    std::string name = strtok(buffer," ");
                    BCAM bcam = base_donnees.getBCAM(name);
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
                    DualSpot dsp1(bcam,
                             atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                    base_donnees.add(dsp1);
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
                    DualSpot dsp2(bcam,
                             atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                    base_donnees.add(dsp2);
//                    sp1.print();
//                    sp2.print();
                    break;
                }

                case 36: // 6 spots
                {
                    char *buffer = strdup((char*)ligne.c_str());
                    //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                    std::string name = strtok(buffer," ");
                    BCAM bcam = base_donnees.getBCAM(name);
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
                    DualSpot dsp1(bcam,
                             atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                    base_donnees.add(dsp1);
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
                    DualSpot dsp2(bcam,
                             atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                    base_donnees.add(dsp2);
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
                    DualSpot dsp3(bcam,
                             atof(coord5_i_ccd), atof(coord5_j_ccd), atof(coord6_i_ccd), atof(coord6_j_ccd));
                    base_donnees.add(dsp3);
                    break;
                }

                default: // error
                {
                   return 0;
                }
                } // switch
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
