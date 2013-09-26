#include "header/read_lwdaq_output.h"

int read_lwdaq_output(std::string nom_fichier, bdd & base_donnees)
{
    std::ifstream fichier((char*)nom_fichier.c_str(), std::ios::in);
    if(fichier)
    {
        std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
        unsigned int etape_calcul=0;

        while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
        {
            if(!ligne.empty())
            {
                //2 spots
                if(ligne.size() == 86)
                {
                    etape_calcul = 1;
                }

                //4 spots
                if(ligne.size() == 157)
                {
                    etape_calcul = 2;
                }

                if(!ligne.empty())
                {
                    switch(etape_calcul)
                    {
                    case 1:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom de la BCAM_Objet + coordonnées images du premier spot
                        std::string nom_BCAM_Objet = strtok(buffer," ");
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
                        spot sp(nom_BCAM_Objet, atof(coord1_i_ccd), atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                        base_donnees.Add_spots(sp);
                    }
                    break;

                    case 2:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                        std::string nom_BCAM_Objets = strtok(buffer," ");
                        std::string nom_BCAM_Objet1 = nom_BCAM_Objets.substr(0,23);
                        std::string nom_BCAM_Objet2 = nom_BCAM_Objets.substr(0,14).append(nom_BCAM_Objets.substr(23,32));
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
                        spot sp1(nom_BCAM_Objet1, atof(coord1_i_ccd),atof(coord1_j_ccd), atof(coord2_i_ccd), atof(coord2_j_ccd));
                        base_donnees.Add_spots(sp1);
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
                        spot sp2(nom_BCAM_Objet2, atof(coord3_i_ccd), atof(coord3_j_ccd), atof(coord4_i_ccd), atof(coord4_j_ccd));
                        base_donnees.Add_spots(sp2);
                    }
                    break;

                    }

                }
            }
        }

        for(int i=0; i<base_donnees.Get_liste_spots().size(); i++)
        {
            base_donnees.Get_liste_spots().at(i).Affiche();
        }

        fichier.close();
        return 1;
    }
    else
    {
        return 0;
    }
}
