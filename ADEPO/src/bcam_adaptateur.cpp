#include "header/bcam_adaptateur.h"

bcam_adaptateur::bcam_adaptateur(std::string type_bcam, std::string id_cible, Point3f coord_cible) : m_type_bcam(type_bcam), m_id_cible(id_cible), m_coord_cible(coord_cible)
{
    //ctor
}

bcam_adaptateur::~bcam_adaptateur()
{
    //dtor
}

bcam_adaptateur::bcam_adaptateur()
{
    this->m_type_bcam="";
    this->m_id_cible="";
}

void bcam_adaptateur::Affiche()
{
    std::cout<<"*******************************************//BCAM_ADAPTATEUR*******************************************"<<std::endl;
    std::cout<<"Type de la BCAM : "<<this->m_type_bcam<<std::endl;
    std::cout<<"Id de la cible : "<<this->m_id_cible<<std::endl;
    std::cout<<"Coordonnees : "<<std::endl;
    this->m_coord_cible.Affiche();


}
