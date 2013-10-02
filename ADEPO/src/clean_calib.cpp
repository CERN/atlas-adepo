#include "header/clean_calib.h"

<<<<<<< HEAD
/*void clean_calib(bdd & base_donnees)
{
    for(int i=0; i<base_donnees.Get_liste_BCAM().size(); i++)
    {
        std::string tps_calib="";
        float X_pivot=0;
        float Y_pivot=0;
        float Z_pivot=0;
        float X_axis=0;
        float Y_axis=0;
        float Z_axis=0;
        float focale=0;
        float angle_rotation=0;

        float X_flash_1=0;
        float Y_flash_1=0;
        float Z_flash_1=0;
        float X_flash_2=0;
        float Y_flash_2=0;
        float Z_flash_2=0;
=======

void clean_calib(bdd & base_donnees)
{


    for(int i=0; i<base_donnees.Get_liste_BCAM().size(); i++)
    {
        double tps_calib=0;
        double X_pivot=0;
        double Y_pivot=0;
        double Z_pivot=0;
        double X_axis=0;
        double Y_axis=0;
        double Z_axis=0;
        double focale=0;
        double angle_rotation=0;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

        for(int j=0; j<base_donnees.Get_liste_calib1().size(); j++)
        {

            if(base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM() == base_donnees.Get_liste_calib1().at(j).Get_id_BCAM())
            {
                tps_calib = base_donnees.Get_liste_calib1().at(j).Get_tps_calib();
                X_pivot = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X();
                Y_pivot = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y();
                Z_pivot = base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z();

                X_axis = base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_X();
                Y_axis = base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Y();
                Z_axis = base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Z();

                focale = base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot();
                angle_rotation = base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation();
            }
        }
        Point3f coord_pivot(X_pivot, Y_pivot, Z_pivot);
        Point3f coord_axis(X_axis, Y_axis, Z_axis);
        calib1 cal1(base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM(), tps_calib, coord_pivot, coord_axis, focale, angle_rotation);
        base_donnees.Add_calib1_clean(cal1);

        for(int k=0; k<base_donnees.Get_liste_calib2().size(); k++)
        {
<<<<<<< HEAD
=======
            double X_flash_1=0;
            double Y_flash_1=0;
            double Z_flash_1=0;
            double X_flash_2=0;
            double Y_flash_2=0;
            double Z_flash_2=0;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

            if(base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM() == base_donnees.Get_liste_calib2().at(k).Get_id_BCAM())
            {
                X_flash_1 = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_1().Get_X();
                Y_flash_1 = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_1().Get_Y();
                Z_flash_1 = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_1().Get_Z();
                X_flash_2 = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_2().Get_X();
                Y_flash_2 = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_2().Get_Y();
                Z_flash_2 = base_donnees.Get_liste_calib2().at(k).Get_coord_flash_2().Get_Z();
            }
<<<<<<< HEAD
        }
        Point3f flash_1(X_flash_1, Y_flash_1, Z_flash_1);
        Point3f flash_2(X_flash_2, Y_flash_2, Z_flash_2);
        calib2 cal2(base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM(), flash_1, flash_2);
        base_donnees.Add_calib2_clean(cal2);
    }

    //affichage du contenu de la base de donnee qui contient que les donnees de calibration qui nous interessent
    for(int i=0; i<base_donnees.Get_liste_calib1_clean().size(); i++)
    {
        base_donnees.Get_liste_calib1_clean().at(i).Affiche();
    }
    for(int j=0; j<base_donnees.Get_liste_calib2_clean().size(); j++)
    {
        base_donnees.Get_liste_calib2_clean().at(j).Affiche();
    }

}*/
=======

            Point3f flash_1(X_flash_1, Y_flash_1, Z_flash_1);
            Point3f flash_2(X_flash_2, Y_flash_2, Z_flash_2);
            calib2 cal2(base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM(), flash_1, flash_2);
            base_donnees.Add_calib2_clean(cal2);
        }
    }


}
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518


