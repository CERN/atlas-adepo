#include "adepo.h"
#include "calcul_coord_bcam_system.h"

#define mm2m 0.001

void calcul_coord_bcam_system(bdd & base_donnees)
{
    bool found = false;
    for (unsigned int i=0; i<base_donnees.getMountCoordSpots().size(); i++) // je parcours la database qui contient les coord des observation dans le system MOUNT
    {
        mount_coord_spots spot = base_donnees.getMountCoordSpots().at(i);

        for (unsigned int j=0; j<base_donnees.getCalibs1().size(); j++) //je parcours la base de donnee de calibration 1
        {
            calib1 calib1 = base_donnees.getCalibs1().at(j);

            // NumChip == 2 is Z+ direction (check?)
            int num_chip = base_donnees.getBCAM(spot.getBCAM())->getNumChip();
            bool directionOk1 = ((num_chip == 2) && (calib1.getDirection() == 1)) || ((num_chip == 1) && (calib1.getDirection() == -1));

            for(unsigned int k=0; k<base_donnees.getCalibs2().size(); k++) //je parcours la base de donnee de calibration 2
            {
                calib2 calib2k = base_donnees.getCalibs2().at(k);
                calib2 calib2j = base_donnees.getCalibs2().at(j);

                bool directionOk2 = ((num_chip == 2) && (calib2k.getDirection() == 1)) || ((num_chip == 1) && (calib2k.getDirection() == -1));

                for(unsigned int l=0; l<base_donnees.getAbsoluteDistances().size(); l++) //je parcours la base de donnee des distances absolues
                {
                    absolutes_distances absolutes_distances = base_donnees.getAbsoluteDistances().at(l);

                    if(spot.getBCAM() == calib1.getBCAM() && directionOk1 &&
                            spot.getBCAM() == calib2k.getBCAM() && directionOk2 &&
                            spot.getName() == absolutes_distances.getName())
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
                            float dist_sources = sqrt(pow(calib2j.getCoordFlash1().x() - calib2j.getCoordFlash2().x(),2) +
                                                      pow(calib2j.getCoordFlash1().y() - calib2j.getCoordFlash2().y(),2) +
                                                      pow(calib2j.getCoordFlash1().z() - calib2j.getCoordFlash2().z(),2));
                            float dist_cheep = sqrt(pow(spot.getCoord1().x() - spot.getCoord2().x(),2) +
                                                    pow(spot.getCoord1().y() - spot.getCoord2().y(),2) +
                                                    pow(spot.getCoord1().z() - spot.getCoord2().z(),2));
                            D1 = (dist_sources*mm2m*focale)/(dist_cheep);
                            D2 = D1;
                        }

                        //composante X
                        float a1_x = calib2k.getCoordFlash1().x()*mm2m + calib1.getCoordPivot().x()*mm2m;
                        float b1_x = spot.getCoord1().x() - calib1.getCoordPivot().x()*mm2m;
                        float c1_x = D1/focale;
                        float prisme_x1 = a1_x-b1_x*c1_x;

                        float a2_x = calib2k.getCoordFlash2().x()*mm2m + calib1.getCoordPivot().x()*mm2m;
                        float b2_x = spot.getCoord2().x() - calib1.getCoordPivot().x()*mm2m;
                        float c2_x = D2/focale;
                        float prisme_x2 = a2_x-b2_x*c2_x;

                        //composante Y
                        float a1_y = calib2k.getCoordFlash1().y()*mm2m + calib1.getCoordPivot().y()*mm2m;
                        float b1_y = spot.getCoord1().y() - calib1.getCoordPivot().y()*mm2m;
                        float c1_y = D1/focale;
                        float prisme_y1 = a1_y-b1_y*c1_y;

                        float a2_y = calib2k.getCoordFlash2().y()*mm2m + calib1.getCoordPivot().y()*mm2m;
                        float b2_y = spot.getCoord2().y() - calib1.getCoordPivot().y()*mm2m;
                        float c2_y = D2/focale;
                        float prisme_y2 = a2_y-b2_y*c2_y;

                        //composante Z
                        float a1_z = calib2k.getCoordFlash1().z()*mm2m + calib1.getCoordPivot().z()*mm2m;
                        float b1_z = spot.getCoord1().z() - calib1.getCoordPivot().z()*mm2m;
                        float c1_z = D1/focale;
                        float prisme_z1 = a1_z-b1_z*c1_z;

                        float a2_z = calib2k.getCoordFlash2().z()*mm2m + calib1.getCoordPivot().z()*mm2m;
                        float b2_z = spot.getCoord2().z() - calib1.getCoordPivot().z()*mm2m;
                        float c2_z = D2/focale;
                        float prisme_z2 = a2_z-b2_z*c2_z;

                        float coordPrisme_x = (prisme_x1+prisme_x2)/4;
                        float coordPrisme_y = (prisme_y1+prisme_y2)/4;
                        float coordPrisme_z = (prisme_z1+prisme_z2)/4;

                        //ajout dans la base de donnees
                        Point3f xyz(coordPrisme_x, coordPrisme_y, coordPrisme_z);
                        mount_coord_prism xyz_prism(spot.getBCAM(), spot.getPrism(), xyz);
                        base_donnees.add(xyz_prism);
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
    for(unsigned int i=0; i<base_donnees.getMountCoordPrisms().size(); i++)
    {
        base_donnees.getMountCoordPrisms().at(i).print();
    }
#endif
}
