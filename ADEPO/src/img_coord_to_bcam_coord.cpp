#include "adepo.h"
#include "img_coord_to_bcam_coord.h"
#include "Eigen/Core"

#define bcam_tc255_center_x 1.720
#define bcam_tc255_center_y 1.220

#define mm2m 0.001
#define um2m 0.000001


//fonction de transformation du repere ccd au repere BCAM (MOUNT)
void img_coord_to_bcam_coord(bdd & base_donnees)
{
    bool found = false;
    for(unsigned int i=0; i<base_donnees.getSpots().size(); i++) //je parcours la base de donnees des coordonnees images
    {
        for (unsigned int j=0; j<base_donnees.getCalibs1().size(); j++) //je parcours la base de donnees qui contient les informations de calibration
        {
            spot spot = base_donnees.getSpots().at(i);
            calib1 calib1 = base_donnees.getCalibs1().at(j);
            // NumChip == 2 is Z+ direction (check?)
            int num_chip = base_donnees.getBCAM(spot.getBCAM())->getNumChip();
            bool directionOk = ((num_chip == 2) && (calib1.getCoordAxis().z() > 0)) || ((num_chip == 1) && (calib1.getCoordAxis().z() < 0));
            std::cout << spot.getBCAM() << " " calib1.getBCAM() << directionOk << " " <<  num_chip << " " << calib1.getCoordAxis().z() << std::endl;

            // check for name and direction.
            if (spot.getBCAM() == calib1.getBCAM() && directionOk)
            {
                //transformation des coordonnees IMAGE vers le repere MOUNT

                Eigen::MatrixXd ccd1(1,3);       //vecteur des coordonnees images1
                ccd1(0,0)=spot.getI1CCD()*um2m;
                ccd1(0,1)=spot.getJ1CCD()*um2m;
                ccd1(0,2)=0;
                //std::cout<<ccd<<std::endl;

                Eigen::MatrixXd ccd2(1,3);       //vecteur des coordonnees images2
                ccd2(0,0)=spot.getI2CCD()*um2m;
                ccd2(0,1)=spot.getJ2CCD()*um2m;
                ccd2(0,2)=0;
                //std::cout<<ccd<<std::endl;

                Eigen::MatrixXd centre(1,3);    //vecteur du centre du ccd dans le systeme MOUNT
                centre(0,0)=bcam_tc255_center_x*mm2m;
                centre(0,1)=bcam_tc255_center_y*mm2m;
                centre(0,2)=0;
                //std::cout<<centre<<std::endl;

                Eigen::MatrixXd pivot(1,3);     //vecteur pivot
                pivot(0,0)=calib1.getCoordPivot().x()*mm2m;
                pivot(0,1)=calib1.getCoordPivot().y()*mm2m;
                pivot(0,2)=calib1.getCoordPivot().z()*mm2m;
                //std::cout<<pivot<<std::endl;

                Eigen::MatrixXd axis(1,3);      //vecteur axis
                axis(0.0)=calib1.getCoordAxis().x()*mm2m;
                axis(0,1)=calib1.getCoordAxis().y()*mm2m;
                axis(0,2)=calib1.getCoordAxis().z(); // NOTE, unit-less just gives direction of the bcam as 1 and -1
                //std::cout<<axis<<std::endl;

                Eigen::MatrixXd rotation(3,3);  //matrice rotation en fonction du signe de axis.z
                if(axis(0,2) > 0)
                {
                    rotation(0,0)=cos(-calib1.getCcdRotation()*mm2m);
                    rotation(1,0)=sin(-calib1.getCcdRotation()*mm2m);
                    rotation(2,0)=0;
                    rotation(0,1)=-sin(-calib1.getCcdRotation()*mm2m);
                    rotation(1,1)=cos(-calib1.getCcdRotation()*mm2m);
                    rotation(2,1)=0;
                    rotation(0,2)=0;
                    rotation(1,2)=0;
                    rotation(2,2)=1;
                }
                else
                {
                    rotation(0,0)=-cos(-calib1.getCcdRotation()*mm2m);
                    rotation(1,0)=sin(-calib1.getCcdRotation()*mm2m);
                    rotation(2,0)=0;
                    rotation(0,1)=sin(-calib1.getCcdRotation()*mm2m);
                    rotation(1,1)=cos(-calib1.getCcdRotation()*mm2m);
                    rotation(2,1)=0;
                    rotation(0,2)=0;
                    rotation(1,2)=0;
                    rotation(2,2)=1;
                }
                //std::cout<<rotation<<std::endl;

                //transformation1           //vecteur mount 1
                Eigen::MatrixXd coord_mount1(3,1);
                coord_mount1=(ccd1-centre)*rotation + pivot - calib1.getCcdToPivot()*mm2m*axis;
                //std::cout<<coord_mount<<std::endl;

                //transformation2           //vecteur mount 2
                Eigen::MatrixXd coord_mount2(3,1);
                coord_mount2=(ccd2-centre)*rotation + pivot - calib1.getCcdToPivot()*mm2m*axis;
                //std::cout<<coord_mount<<std::endl;

                //sauvegarde dans la base de donnee
                Point3f mount_sp1(coord_mount1(0,0), coord_mount1(0,1), coord_mount1(0,2));
                Point3f mount_sp2(coord_mount2(0,0), coord_mount2(0,1), coord_mount2(0,2));
                mount_coord_spots mount_couple_spots(spot.getBCAM(), spot.getPrism(), mount_sp1, mount_sp2);
                base_donnees.add(mount_couple_spots);

                found = true;
            }
        }
    }

    //affichage de la base de donnees qui contient les observations transformees dans le repere MOUNT
#ifdef ADEPO_DEBUG
    for(unsigned int i=0; i<base_donnees.getMountCoordSpots().size(); i++)
    {
        base_donnees.getMountCoordSpots().at(i).print();
    }
#endif

    if (!found) {
        std::cout << "WARNING: no img_coord_to_bcam_coord found, some setup file may be missing..." << std::endl;
    }
}
