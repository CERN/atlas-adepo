#include "calib2.h"

calib2::calib2(std::string id_BCAM, Point3f coord_flash_1, Point3f coord_flash_2) : m_id_BCAM(id_BCAM), m_coord_flash_1(coord_flash_1), m_coord_flash_2(coord_flash_2)
{
    //ctor
}

calib2::~calib2()
{
    //dtor
}

void calib2::Affiche()
{
    std::cout<<"*******************************************Infos Calib*******************************************"<<std::endl;
    std::cout<<"Id de la BCAM : "<<this->m_id_BCAM<<std::endl;
    std::cout<<"Affichage des cordonnées du premier flash : "<<std::endl;
    this->m_coord_flash_1.Affiche();
    std::cout<<"Affichage des cordonnées du second flash : "<<std::endl;
    this->m_coord_flash_2.Affiche();
    std::cout<<"************************************************************************************************"<<std::endl;
}
