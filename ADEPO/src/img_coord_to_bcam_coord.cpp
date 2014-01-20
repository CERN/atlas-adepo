#include "header/img_coord_to_bcam_coord.h"
#include "eigen-eigen-ffa86ffb5570/Eigen/Core"

#define bcam_tc255_center_x 1.720
#define bcam_tc255_center_y 1.220

#define mm2m 0.001
#define um2m 0.000001


//fonction de transformation du repere ccd au repere BCAM (MOUNT)
void img_coord_to_bcam_coord(bdd & base_donnees)
{

    for(unsigned int i=0; i<base_donnees.Get_liste_spots().size(); i++) //je parcours la base de donnees des coordonnees images
    {
        for (unsigned int j=0; j<base_donnees.Get_liste_calib1().size(); j++) //je parcours la base de donnees qui contient les informations de calibration
        {
            if(base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet().substr(0,14) == base_donnees.Get_liste_calib1().at(j).Get_id_BCAM())
            {
                //transformation des coordonnees IMAGE vers le repere MOUNT

                Eigen::MatrixXd ccd1(1,3);       //vecteur des coordonnees images1
                ccd1(0,0)=base_donnees.Get_liste_spots().at(i).Get_i1_CCD()*um2m;
                ccd1(0,1)=base_donnees.Get_liste_spots().at(i).Get_j1_CCD()*um2m;
                ccd1(0,2)=0;
                //std::cout<<ccd<<std::endl;

                Eigen::MatrixXd ccd2(1,3);       //vecteur des coordonnees images2
                ccd2(0,0)=base_donnees.Get_liste_spots().at(i).Get_i2_CCD()*um2m;
                ccd2(0,1)=base_donnees.Get_liste_spots().at(i).Get_j2_CCD()*um2m;
                ccd2(0,2)=0;
                //std::cout<<ccd<<std::endl;

                Eigen::MatrixXd centre(1,3);    //vecteur du centre du ccd dans le systeme MOUNT
                centre(0,0)=bcam_tc255_center_x*mm2m;
                centre(0,1)=bcam_tc255_center_y*mm2m;
                centre(0,2)=0;
                //std::cout<<centre<<std::endl;

                Eigen::MatrixXd pivot(1,3);     //vecteur pivot
                pivot(0,0)=base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_X()*mm2m;
                pivot(0,1)=base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Y()*mm2m;
                pivot(0,2)=base_donnees.Get_liste_calib1().at(j).Get_coord_pivot().Get_Z()*mm2m;
                //std::cout<<pivot<<std::endl;

                Eigen::MatrixXd axis(1,3);      //vecteur axis
                axis(0.0)=base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_X()*mm2m;
                axis(0,1)=base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Y()*mm2m;
                axis(0,2)=base_donnees.Get_liste_calib1().at(j).Get_coord_axis().Get_Z();
                //std::cout<<axis<<std::endl;

                Eigen::MatrixXd rotation(3,3);  //matrice rotation en fonction du signe de axis.z
                if(axis(0,2) > 0)
                {
                    rotation(0,0)=cos(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(1,0)=sin(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(2,0)=0;
                    rotation(0,1)=-sin(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(1,1)=cos(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(2,1)=0;
                    rotation(0,2)=0;
                    rotation(1,2)=0;
                    rotation(2,2)=1;
                }
                else
                {
                    rotation(0,0)=-cos(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(1,0)=sin(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(2,0)=0;
                    rotation(0,1)=sin(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(1,1)=cos(-base_donnees.Get_liste_calib1().at(j).Get_ccd_rotation()*mm2m);
                    rotation(2,1)=0;
                    rotation(0,2)=0;
                    rotation(1,2)=0;
                    rotation(2,2)=1;
                }
                //std::cout<<rotation<<std::endl;

                //transformation1           //vecteur mount 1
                Eigen::MatrixXd coord_mount1(3,1);
                coord_mount1=(ccd1-centre)*rotation + pivot - base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot()*mm2m*axis;
                //std::cout<<coord_mount<<std::endl;

                //transformation2           //vecteur mount 2
                Eigen::MatrixXd coord_mount2(3,1);
                coord_mount2=(ccd2-centre)*rotation + pivot - base_donnees.Get_liste_calib1().at(j).Get_ccd_to_pivot()*mm2m*axis;
                //std::cout<<coord_mount<<std::endl;

                //sauvegarde dans la base de donnee
                Point3f mount_sp1(coord_mount1(0,0), coord_mount1(0,1), coord_mount1(0,2));
                Point3f mount_sp2(coord_mount2(0,0), coord_mount2(0,1), coord_mount2(0,2));
                mount_coord_spots mount_couple_spots(base_donnees.Get_liste_spots().at(i).Get_nom_BCAM_Objet(), mount_sp1, mount_sp2);
                base_donnees.Add_mount_coord_spots(mount_couple_spots);
            }
        }
    }

    //affichage de la base de donnees qui contient les observations transformees dans le repere MOUNT
    /*for(int i=0; i<base_donnees.Get_liste_mount_coord_spots().size(); i++)
    {
        base_donnees.Get_liste_mount_coord_spots().at(i).Affiche();
    }*/
}
