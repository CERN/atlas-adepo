#include "header/mount_coord_prism.h"

mount_coord_prism::mount_coord_prism(std::string id, Point3f coord_prism_mount_sys): m_id(id), m_coord_prism_mount_sys(coord_prism_mount_sys)
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
    std::cout<<"Objet BCAM-Prisme : "<<this->m_id<<std::endl;
    std::cout<<"Coordonnées du prisme dans le systeme MOUNT : "<<std::endl;
    this->m_coord_prism_mount_sys.Affiche();
}
