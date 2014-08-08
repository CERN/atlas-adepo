#include "mount_coord_spots.h"

mount_coord_spots::mount_coord_spots(std::string id,  Point3f coord1, Point3f coord2): m_id(id), m_coord1(coord1), m_coord2(coord2)
{
    //ctor
}

mount_coord_spots::~mount_coord_spots()
{
    //dtor
}

void mount_coord_spots::Affiche()
{
    std::cout<<"*******************************************Mount coordinates*******************************************"<<std::endl;
    std::cout<<"Id : "<<this->m_id<<std::endl;
    std::cout<<"Coordonnées dans le systeme MOUNT (spot 1) : "<<std::endl;
    this->m_coord1.Affiche();
    std::cout<<"Coordonnées dans le systeme MOUNT (spot 2) : "<<std::endl;
    this->m_coord2.Affiche();
}
