#include "header/atlas_coordinates.h"

ATLAS_coordinates::ATLAS_coordinates(std::string id_BCAM, Point3f cible) : m_id_BCAM(id_BCAM), m_cible(cible)
{
    //ctor
}

ATLAS_coordinates::ATLAS_coordinates()
{
    this->m_id_BCAM = "";
}

ATLAS_coordinates::~ATLAS_coordinates()
{
    //dtor
}

void ATLAS_coordinates::Affiche()
{
    std::cout<<"*******************************************//ATLAS_COORDINATES*******************************************"<<std::endl;
    std::cout<<"Objet BCAM : "<<this->m_id_BCAM<<std::endl;
    std::cout<<"Coordonnees de l'adaptateur : "<<std::endl;
    std::cout<<"Coordonnees de la cible : "<<std::endl;
    this->m_cible.Affiche();
}
