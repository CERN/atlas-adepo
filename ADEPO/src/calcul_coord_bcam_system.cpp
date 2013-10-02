#include "header/calcul_coord_bcam_system.h"

<<<<<<< HEAD
#define mm2m 0.001

int calcul_coord_bcam_system(bdd & base_donnees)
{
    for (int i=0; i<base_donnees.Get_liste_mount_coord_spots().size(); i++) // je parcours la database qui contient les coord des observation dans le system MOUNT
    {
        for (int j=0; j<base_donnees.Get_liste_calib1().size(); j++) //je parcours la base de donnee de calibration 1
        {
            for(int k=0; k<base_donnees.Get_liste_calib2().size(); k++) //je parcours la base de donnee de calibration 2
            {
                for(int l=0; l<base_donnees.Get_liste_absolutes_distances().size(); l++) //je parcours la base de donnee des distances absolues
                {
                    if(base_donnees.Get_liste_mount_coord_spots().at(i).Get_id().substr(0,14) == base_donnees.Get_liste_calib1().at(j).Get_id_BCAM() && base_donnees.Get_liste_mount_coord_spots().at(i).Get_id().substr(0,14) == base_donnees.Get_liste_calib2().at(k).Get_id_BCAM() && base_donnees.Get_liste_mount_coord_spots().at(i).Get_id() == base_donnees.Get_liste_absolutes_distances().at(l).Get_id_BCAM_prisme())
                    {

                        //calcul du mileu de la distance entre les 2 spots sur le ccd
                        float milieu_x = (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_X() + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_X())/2;
                        float milieu_y = (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Y() + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Y())/2;
                        float milieu_z = (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Z() + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Z())/2;

                        //focale 3D = distance entre point milieu et pivot
                        float focale = sqrt(pow(milieu_x - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X()*mm2m,2) + pow(milieu_y - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y()*mm2m, 2) + pow(milieu_z - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z()*mm2m,2));

                        //distances absolues
                        float D1 = (base_donnees.Get_liste_absolutes_distances().at(l).Get_distances().Get_X() + base_donnees.Get_liste_absolutes_distances().at(l).Get_distances().Get_Y());   //deja en metre
                        float D2 = (base_donnees.Get_liste_absolutes_distances().at(l).Get_distances().Get_X() + base_donnees.Get_liste_absolutes_distances().at(l).Get_distances().Get_Z()); //deja en metre

                        //si la distance est nulle ==> distance BCAM pour le calcul des coordonnees du prisme
                        if(D1 == 0 || D2 == 0)
                        {
                            float dist_sources = sqrt(pow(base_donnees.Get_liste_calib2().at(j).Get_coord_flash_1().Get_X() - base_donnees.Get_liste_calib2().at(j).Get_coord_flash_2().Get_X(),2) + pow(base_donnees.Get_liste_calib2().at(j).Get_coord_flash_1().Get_Y() - base_donnees.Get_liste_calib2().at(j).Get_coord_flash_2().Get_Y(),2) + pow(base_donnees.Get_liste_calib2().at(j).Get_coord_flash_1().Get_Z() - base_donnees.Get_liste_calib2().at(j).Get_coord_flash_2().Get_Z(),2));
                            float dist_cheep = sqrt(pow(base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_X() - base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_X(),2) + pow(base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Y() - base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Y(),2) + pow(base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Z() - base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Z(),2));
                            D1 = (dist_sources*mm2m*focale)/(dist_cheep);
                            D2 = D1;
                        }

                        //composante X
                        float a1_x = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_1().Get_X()*mm2m + base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X()*mm2m;
                        float b1_x = base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_X() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X()*mm2m;
                        float c1_x = D1/focale;
                        float prisme_x1 = a1_x-b1_x*c1_x;

                        float a2_x = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_2().Get_X()*mm2m + base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X()*mm2m;
                        float b2_x = base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_X() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X()*mm2m;
                        float c2_x = D2/focale;
                        float prisme_x2 = a2_x-b2_x*c2_x;

                        //composante Y
                        float a1_y = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_1().Get_Y()*mm2m + base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y()*mm2m;
                        float b1_y = base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Y() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y()*mm2m;
                        float c1_y = D1/focale;
                        float prisme_y1 = a1_y-b1_y*c1_y;

                        float a2_y = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_2().Get_Y()*mm2m + base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y()*mm2m;
                        float b2_y = base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Y() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y()*mm2m;
                        float c2_y = D2/focale;
                        float prisme_y2 = a2_y-b2_y*c2_y;

                        //composante Z
                        float a1_z = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_1().Get_Z()*mm2m + base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z()*mm2m;
                        float b1_z = base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Z() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z()*mm2m;
                        float c1_z = D1/focale;
                        float prisme_z1 = a1_z-b1_z*c1_z;

                        float a2_z = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_2().Get_Z()*mm2m + base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z()*mm2m;
                        float b2_z = base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Z() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z()*mm2m;
                        float c2_z = D2/focale;
                        float prisme_z2 = a2_z-b2_z*c2_z;

                        float coordPrisme_x = (prisme_x1+prisme_x2)/4;
                        float coordPrisme_y = (prisme_y1+prisme_y2)/4;
                        float coordPrisme_z = (prisme_z1+prisme_z2)/4;

                        //ajout dans la base de donnees
                        Point3f xyz(coordPrisme_x, coordPrisme_y, coordPrisme_z);
                        mount_coord_prism xyz_prism(base_donnees.Get_liste_mount_coord_spots().at(i).Get_id(), xyz);
                        base_donnees.Add_mount_coord_prism(xyz_prism);

                    }
                }

            }

        }
    }

    //affichage base donnee des coordonnees des prismes dans le systeme MOUNT
    /*for(int i=0; i<base_donnees.Get_liste_mount_coord_prism().size(); i++)
    {
        base_donnees.Get_liste_mount_coord_prism().at(i).Affiche();
    }*/
=======
int calcul_coord_bcam_system(double distance, bdd & base_donnees)
{
    // je parcours la database qui contient les coord des observation dans le system MOUNT
    for (int i=0; i<base_donnees.Get_liste_mount_coord_spots().size(); i++)
    {
        for (int j=0; j<base_donnees.Get_liste_calib1().size(); j++)
        {
            if(base_donnees.Get_liste_mount_coord_spots().at(i).Get_id().substr(0,14) == base_donnees.Get_liste_calib1().at(j).Get_id_BCAM())
            {
                // distance = fonction (objet1, objet2)
                double R = distance/base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot();
                double ptPrisme_x_S1 = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X() - (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_X() - base_donnees.Get_liste_calib1().at(j). Get_coord_pivot().Get_X())*R;
                double ptPrisme_y_S1 = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y() - (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Y() - base_donnees.Get_liste_calib1().at(j). Get_coord_pivot().Get_Y())*R;

                double ptPrisme_x_S2 = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X() - (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_X() - base_donnees.Get_liste_calib1().at(j). Get_coord_pivot().Get_X())*R;
                double ptPrisme_y_S2 = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y() - (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Y() - base_donnees.Get_liste_calib1().at(j). Get_coord_pivot().Get_Y())*R;

                double ptPrisme_z = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z() - (base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Z() - base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z())*R;

                double Px_S1 = (ptPrisme_x_S1 + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_X())/2;
                double Py_S1 = (ptPrisme_y_S1 + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Y())/2;
                double Pz_S1 = (ptPrisme_z + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord1().Get_Z())/2;

                double Px_S2 = (ptPrisme_x_S2 + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_X())/2;
                double Py_S2 = (ptPrisme_y_S2 + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Y())/2;
                double Pz_S2 = (ptPrisme_z + base_donnees.Get_liste_mount_coord_spots().at(i).Get_coord2().Get_Z())/2;

                double coordPrisme_x = (Px_S1 + Px_S2)/2;
                double coordPrisme_y = (Py_S1 + Py_S2)/2;
                double coordPrisme_z = (Pz_S1 + Pz_S2)/2;

                //ajout dans la base de donnees
                Point3f xyz(coordPrisme_x, coordPrisme_y, coordPrisme_z);
                mount_coord_prism xyz_prism(base_donnees.Get_liste_mount_coord_spots().at(i).Get_id().substr(15,23), base_donnees.Get_liste_mount_coord_spots().at(i).Get_id().substr(0,14), xyz);
                base_donnees.Add_mount_coord_prism(xyz_prism);
            }
        }
    }
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
}
