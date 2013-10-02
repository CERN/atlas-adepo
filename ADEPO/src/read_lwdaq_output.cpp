#include "header/read_lwdaq_output.h"
<<<<<<< HEAD
#include "algorithm"
=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

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
<<<<<<< HEAD
                int nb_colonnes = std::count(ligne.begin(), ligne.end(), ' '); //je compte le nombre de colonnes dans le fichier
                std::cout<<nb_colonnes<<std::endl;
                std::cout<<ligne<<std::endl;
                //2 spots
                if(nb_colonnes == 12)
=======
                //2 spots
                if(ligne.size() == 86)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                {
                    etape_calcul = 1;
                }

                //4 spots
<<<<<<< HEAD
                if(nb_colonnes == 24)
=======
                if(ligne.size() == 157)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                {
                    etape_calcul = 2;
                }

<<<<<<< HEAD
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

=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
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
<<<<<<< HEAD
                        std::string nom_BCAM_Objet1 = nom_BCAM_Objets.substr(0,14).append("_").append(nom_BCAM_Objets.substr(15,5));
                        std::string nom_BCAM_Objet2 = nom_BCAM_Objets.substr(0,14).append("_").append(nom_BCAM_Objets.substr(21,5));
=======
                        std::string nom_BCAM_Objet1 = nom_BCAM_Objets.substr(0,23);
                        std::string nom_BCAM_Objet2 = nom_BCAM_Objets.substr(0,14).append(nom_BCAM_Objets.substr(23,32));
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
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

<<<<<<< HEAD
                    case 3:
                    {
                        char *buffer = strdup((char*)ligne.c_str());
                        //recuperation du nom de la BCAM_Objet(S) + coordonnées images du premier spot
                        std::string nom_BCAM_Objets = strtok(buffer," ");
                        std::string nom_BCAM_Objet1 = nom_BCAM_Objets.substr(0,14).append("_").append(nom_BCAM_Objets.substr(15,5));
                        std::string nom_BCAM_Objet2 = nom_BCAM_Objets.substr(0,14).append("_").append(nom_BCAM_Objets.substr(21,5));
                        std::string nom_BCAM_Objet3 = nom_BCAM_Objets.substr(0,14).append("_").append(nom_BCAM_Objets.substr(27,5));
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
                        spot sp3(nom_BCAM_Objet3, atof(coord5_i_ccd), atof(coord5_j_ccd), atof(coord6_i_ccd), atof(coord6_j_ccd));
                        base_donnees.Add_spots(sp3);
                    }

                    case 4:
                    {
                       return 0;
                    }
                    break;
=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                    }

                }
            }
        }

<<<<<<< HEAD
        //affichage de la base de donnees qui contient les coordonnees image
        /*for(int i=0; i<base_donnees.Get_liste_spots().size(); i++)
        {
            base_donnees.Get_liste_spots().at(i).Affiche();
        }*/
=======
        for(int i=0; i<base_donnees.Get_liste_spots().size(); i++)
        {
            base_donnees.Get_liste_spots().at(i).Affiche();
        }
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

        fichier.close();
        return 1;
    }
    else
    {
        return 0;
    }
}
