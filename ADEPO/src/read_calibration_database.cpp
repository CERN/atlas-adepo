#include "header/read_calibration_database.h"
<<<<<<< HEAD
=======
#include "header/converting_time_calibration.h"
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

int read_calibration_database(std::string nom_fichier, bdd & base_donnees)
{
       std::ifstream fichier((char*)nom_fichier.c_str(), std::ios::in);
       if(fichier)
       {
           std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
           unsigned int etape_calcul = 0;

           while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
           {
<<<<<<< HEAD
               if(!ligne.empty())
                {
                    // pivot + focale + axis + ccd rotation
=======
                //std::cout<<ligne.size()<<std::endl;
                if(!ligne.empty())
                {
                    //detector
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                    if(ligne.size() == 91)
                    {
                        etape_calcul = 1;
                    }

<<<<<<< HEAD
                    // sources
=======
                    //BCAM
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                    if(ligne.size() == 70)
                    {
                        etape_calcul = 2;
                    }

                    if(!ligne.empty())
                    {
                        switch(etape_calcul)
                        {
                        case 1:
                        {
                            char *buffer1 = strdup((char*)ligne.c_str());
                            std::string id_BCAM = strtok(buffer1," ");
                            std::string tps_calib = strtok( NULL, " " );
<<<<<<< HEAD
=======
                            double temps_calib = converting_time_calibration(tps_calib);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                            char *x_pivot = strtok( NULL, " " );
                            char *y_pivot = strtok( NULL, " " );
                            char *z_pivot = strtok( NULL, " " );
                            char *x_axis = strtok( NULL, " " );
                            char *y_axis = strtok( NULL, " " );
                            char *z_axis = strtok( NULL, " " );
                            char *dist_ccd_pivot = strtok( NULL, " " );
                            char *ccd_rotation = strtok( NULL, " " );

                            Point3f pv(atof(x_pivot), atof(y_pivot), atof(z_pivot));
                            Point3f ax(atof(x_axis), atof(y_axis),atof(z_axis));
                            float focale = atof(dist_ccd_pivot);
                            float angle_rotation = atof(ccd_rotation);
<<<<<<< HEAD
                            calib1 cal1(id_BCAM, tps_calib, pv, ax, focale, angle_rotation);
=======
                            calib1 cal1(id_BCAM, temps_calib, pv, ax, focale, angle_rotation);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                            base_donnees.Add_calib1(cal1);
                        }
                        break;

                        case 2:
                        {
                            char *buffer2 = strdup((char*)ligne.c_str());
                            std::string id_BCAM_2 = strtok(buffer2," ");
                            std::string tps_calib_2 = strtok( NULL, " " );
                            char *x1_flash = strtok( NULL, " " );
                            char *y1_flash = strtok( NULL, " " );
                            char *x2_flash = strtok( NULL, " " );
                            char *y2_flash = strtok( NULL, " " );
                            char *z_flash = strtok( NULL, " " );

                            Point3f spt1(atof(x1_flash), atof(y1_flash), atof(z_flash));
                            Point3f spt2(atof(x2_flash), atof(y2_flash), atof(z_flash));
                            calib2 cal2(id_BCAM_2, spt1, spt2);
                            base_donnees.Add_calib2(cal2);
<<<<<<< HEAD
=======


>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
                        }
                        break;

                        }

                    }
                }
<<<<<<< HEAD
          }
           //affichage du contenu de la base de donnees qui contient le fichier de calibration
           /*for(int i=0; i<base_donnees.Get_liste_calib1().size(); i++)
           {
                  base_donnees.Get_liste_calib1().at(i).Affiche();
           }
           for(int j=0; j<base_donnees.Get_liste_calib2().size(); j++)
           {
                  base_donnees.Get_liste_calib2().at(j).Affiche();
           }*/
=======

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
