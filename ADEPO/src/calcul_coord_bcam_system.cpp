#include "adepo.h"
#include "calcul_coord_bcam_system.h"

#define mm2m 0.001

void calcul_coord_bcam_system(bdd & base_donnees, bool airpads)
{
    bool found = false;
    for (unsigned int i=0; i<base_donnees.Get_liste_mount_coord_spots().size(); i++) // je parcours la database qui contient les coord des observation dans le system MOUNT
    {
        mount_coord_spots spot = base_donnees.Get_liste_mount_coord_spots().at(i);

        for (unsigned int j=0; j<base_donnees.Get_liste_calib1().size(); j++) //je parcours la base de donnee de calibration 1
        {
            calib1 calib1 = base_donnees.Get_liste_calib1().at(j);

            for(unsigned int k=0; k<base_donnees.Get_liste_calib2().size(); k++) //je parcours la base de donnee de calibration 2
            {
                calib2 calib2 = base_donnees.Get_liste_calib2().at(k);

                for(unsigned int l=0; l<base_donnees.Get_liste_absolutes_distances().size(); l++) //je parcours la base de donnee des distances absolues
                {
                    absolutes_distances absolutes_distances = base_donnees.Get_liste_absolutes_distances().at(l);

                    if(spot.getId().substr(0,14) == calib1.getId() &&
                            spot.getId().substr(0,14) == calib2.getId() &&
                            spot.getId() == absolutes_distances.getId())
                    {
                        //calcul du mileu de la distance entre les 2 spots sur le ccd
                        float milieu_x = (spot.getCoord1().x() + spot.getCoord2().x())/2;
                        float milieu_y = (spot.getCoord1().y() + spot.getCoord2().y())/2;
                        float milieu_z = (spot.getCoord1().z() + spot.getCoord2().z())/2;

                        //focale 3D = distance entre point milieu et pivot
                        float focale = sqrt(pow(milieu_x - calib1.getCoordPivot().x()*mm2m,2) +
                                            pow(milieu_y - calib1.getCoordPivot().y()*mm2m,2) +
                                            pow(milieu_z - calib1.getCoordPivot().z()*mm2m,2));

                        //distances absolues
                        float D1 = (absolutes_distances.getDistances().x() + absolutes_distances.getDistances().y());   //deja en metre
                        float D2 = (absolutes_distances.getDistances().x() + absolutes_distances.getDistances().z()); //deja en metre

                        //si la distance est nulle ==> distance BCAM pour le calcul des coordonnees du prisme
                        if(D1 == 0 || D2 == 0)
                        {
                            float dist_sources = sqrt(pow(base_donnees.Get_liste_calib2().at(j).getCoordFlash1().x() - base_donnees.Get_liste_calib2().at(j).getCoordFlash2().x(),2) +
                                                      pow(base_donnees.Get_liste_calib2().at(j).getCoordFlash1().y() - base_donnees.Get_liste_calib2().at(j).getCoordFlash2().y(),2) +
                                                      pow(base_donnees.Get_liste_calib2().at(j).getCoordFlash1().z() - base_donnees.Get_liste_calib2().at(j).getCoordFlash2().z(),2));
                            float dist_cheep = sqrt(pow(spot.getCoord1().x() - spot.getCoord2().x(),2) +
                                                    pow(spot.getCoord1().y() - spot.getCoord2().y(),2) +
                                                    pow(spot.getCoord1().z() - spot.getCoord2().z(),2));
                            D1 = (dist_sources*mm2m*focale)/(dist_cheep);
                            D2 = D1;
                        }

                        //composante X
                        float a1_x = calib2.getCoordFlash1().x()*mm2m + calib1.getCoordPivot().x()*mm2m;
                        float b1_x = spot.getCoord1().x() - calib1.getCoordPivot().x()*mm2m;
                        float c1_x = D1/focale;
                        float prisme_x1 = a1_x-b1_x*c1_x;

                        float a2_x = calib2.getCoordFlash2().x()*mm2m + calib1.getCoordPivot().x()*mm2m;
                        float b2_x = spot.getCoord2().x() - calib1.getCoordPivot().x()*mm2m;
                        float c2_x = D2/focale;
                        float prisme_x2 = a2_x-b2_x*c2_x;

                        //composante Y
                        float a1_y = calib2.getCoordFlash1().y()*mm2m + calib1.getCoordPivot().y()*mm2m;
                        float b1_y = spot.getCoord1().y() - calib1.getCoordPivot().y()*mm2m;
                        float c1_y = D1/focale;
                        float prisme_y1 = a1_y-b1_y*c1_y;

                        float a2_y = calib2.getCoordFlash2().y()*mm2m + calib1.getCoordPivot().y()*mm2m;
                        float b2_y = spot.getCoord2().y() - calib1.getCoordPivot().y()*mm2m;
                        float c2_y = D2/focale;
                        float prisme_y2 = a2_y-b2_y*c2_y;

                        //composante Z
                        float a1_z = calib2.getCoordFlash1().z()*mm2m + calib1.getCoordPivot().z()*mm2m;
                        float b1_z = spot.getCoord1().z() - calib1.getCoordPivot().z()*mm2m;
                        float c1_z = D1/focale;
                        float prisme_z1 = a1_z-b1_z*c1_z;

                        float a2_z = calib2.getCoordFlash2().z()*mm2m + calib1.getCoordPivot().z()*mm2m;
                        float b2_z = spot.getCoord2().z() - calib1.getCoordPivot().z()*mm2m;
                        float c2_z = D2/focale;
                        float prisme_z2 = a2_z-b2_z*c2_z;

                        float coordPrisme_x = (prisme_x1+prisme_x2)/4;
                        float coordPrisme_y = (prisme_y1+prisme_y2)/4;
                        float coordPrisme_z = (prisme_z1+prisme_z2)/4;

                        float airpad = airpads ? base_donnees.getDetector(spot.getId().substr(0,14))->getAirpad() : 0.0f;

                        //ajout dans la base de donnees
                        Point3f xyz(coordPrisme_x, coordPrisme_y, coordPrisme_z+airpad);
                        mount_coord_prism xyz_prism(spot.getId(), xyz, airpad);
                        base_donnees.Add_mount_coord_prism(xyz_prism);
                        found = true;
                    }
                }

            }

        }
    }

    if (!found) {
        std::cout << "WARNING: No calcul_coord_bcam_system found, some setup file may be missing." << std::endl;
    }

    //affichage base donnee des coordonnees des prismes dans le systeme MOUNT
#ifdef ADEPO_DEBUG
    for(unsigned int i=0; i<base_donnees.Get_liste_mount_coord_prism().size(); i++)
    {
        base_donnees.Get_liste_mount_coord_prism().at(i).print();
    }
#endif
}
