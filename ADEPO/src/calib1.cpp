#include "header/calib1.h"

<<<<<<< HEAD
calib1::calib1(std::string id_BCAM, std::string tps_calib, Point3f coord_pivot, Point3f coord_axis, float ccd_to_pivot, float ccd_rotation) : m_id_BCAM(id_BCAM), m_tps_calib(tps_calib), m_coord_pivot(coord_pivot), m_coord_axis(coord_axis), m_ccd_to_pivot(ccd_to_pivot), m_ccd_rotation(ccd_rotation)
=======
calib1::calib1(std::string id_BCAM, double tps_calib, Point3f coord_pivot, Point3f coord_axis, double ccd_to_pivot, double ccd_rotation) : m_id_BCAM(id_BCAM), m_tps_calib(tps_calib), m_coord_pivot(coord_pivot), m_coord_axis(coord_axis), m_ccd_to_pivot(ccd_to_pivot), m_ccd_rotation(ccd_rotation)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
{
    //ctor
}

calib1::~calib1()
{
    //dtor
}

void calib1::Affiche()
{
    std::cout<<"*******************************************Infos Calib*******************************************"<<std::endl;
    std::cout<<"Id de la BCAM : "<<this->m_id_BCAM<<std::endl;
    std::cout<<"Date calibration : "<<this->m_tps_calib<<std::endl;
    std::cout<<"Coordonnées du pivot : "<<std::endl;
    this->m_coord_pivot.Affiche();
    std::cout<<"Coordonnées de l'axe : "<<std::endl;
    this->m_coord_axis.Affiche();
    std::cout<<"Distance du CCD au pivot: "<<this->m_ccd_to_pivot<<std::endl;
    std::cout<<"Rotation du CCD : "<<this->m_ccd_rotation<<std::endl;
    std::cout<<"************************************************************************************************"<<std::endl;
}

