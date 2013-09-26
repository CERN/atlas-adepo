#include "header/calcul_coord_bcam_system.h"

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
}
