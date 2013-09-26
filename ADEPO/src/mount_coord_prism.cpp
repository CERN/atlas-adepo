#include "header/mount_coord_prism.h"

mount_coord_prism::mount_coord_prism(std::string id_prism, std::string id_BCAM, Point3f coord_prism_mount_sys): m_id_prism(id_prism), m_id_BCAM(id_BCAM), m_coord_prism_mount_sys(coord_prism_mount_sys)
{
    //ctor
}

mount_coord_prism::~mount_coord_prism()
{
    //dtor
}

void mount_coord_prism::Affiche()
{
    std::cout<<"*******************************************Mount coordinates of prism*******************************************"<<std::endl;
    std::cout<<"Id prism : "<<this->m_id_prism<<std::endl;
    std::cout<<"Id BCAM : "<<this->m_id_BCAM;
    std::cout<<"Coordonnées du prisme dans le systeme MOUNT : "<<std::endl;
    this->m_coord_prism_mount_sys.Affiche();
}
