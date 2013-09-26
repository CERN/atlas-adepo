#include "header/img_coord_to_bcam_coord.h"

#define bcam_tc255_center_x 1.720
#define bcam_tc255_center_y 1.220

#define mm2m 0.001
#define um2m 0.000001


//fonction de transformation du repere ccd au repere BCAM (MOUNT)
int img_coord_to_bcam_coord(bdd & base_donnees)
{

    for(int i=0; i<base_donnees.Get_liste_spots().size(); i++)
    {
        for (int j=0; j<base_donnees.Get_liste_calib1().size(); j++)
        {
            if(base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet().substr(0,14) == base_donnees.Get_liste_calib1().at(j).Get_id_BCAM())
            {
                //calcul du centre du ccd dans le repere BCAM (MOUNT)
                double ccd_centre_x = (base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_X()/1000)*(-base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot()/1000);
                double ccd_centre_y = (base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Y()/1000)*(-base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot()/1000);
                double ccd_centre_z = (base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Z())*(-base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot()/1000);

                double rx_S1;
                double ry_S1;

                double rx_S2;
                double ry_S2;

                double rz;

                double qx_S1 = base_donnees.Get_liste_spots().at(i).Get_i1_CCD()/1000000 - bcam_tc255_center_x/1000;
                double qy_S1 = base_donnees.Get_liste_spots().at(i).Get_j1_CCD()/1000000 - bcam_tc255_center_y/1000;

                double qx_S2 = base_donnees.Get_liste_spots().at(i).Get_i2_CCD()/1000000 - bcam_tc255_center_x/1000;
                double qy_S2 = base_donnees.Get_liste_spots().at(i).Get_j2_CCD()/1000000 - bcam_tc255_center_y/1000;

                if(base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Z() > 0)
                {
                    rx_S1 = ccd_centre_x + qx_S1*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) - qy_S1*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);
                    ry_S1 = ccd_centre_y + qy_S1*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) + qx_S1*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);

                    rx_S2 = ccd_centre_x + qx_S2*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) - qy_S2*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);
                    ry_S2 = ccd_centre_y + qy_S2*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) + qx_S2*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);

                    rz = ccd_centre_z;
                }
                else
                {
                    rx_S1 = ccd_centre_x - qx_S1*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) + qy_S1*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);
                    ry_S1 = ccd_centre_y + qy_S1*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) + qx_S1*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);

                    rx_S2 = ccd_centre_x - qx_S2*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) + qy_S2*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);
                    ry_S2 = ccd_centre_y + qy_S2*cos(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000) + qx_S2*sin(base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()/1000);

                    rz = ccd_centre_z;
                }

                Point3f mount_sp1(rx_S1,ry_S1,rz);
                Point3f mount_sp2(rx_S2, ry_S2, rz);
                mount_coord_spots mount_couple_spots(base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet(), mount_sp1, mount_sp2);
                base_donnees.Add_mount_coord_spots(mount_couple_spots);
            }
        }
    }

}

