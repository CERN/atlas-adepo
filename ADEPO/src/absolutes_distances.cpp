#include "header/absolutes_distances.h"

absolutes_distances::absolutes_distances(std::string id_BCAM_prisme, Point3f distances) : m_id_BCAM_prisme(id_BCAM_prisme), m_distances(distances)
{
    //ctor
}

absolutes_distances::absolutes_distances()
{
    this->m_id_BCAM_prisme="";
}

absolutes_distances::~absolutes_distances()
{
    //dtor
}

void absolutes_distances::Affiche()
{
    std::cout<<"*******************************************//ABSOLUTES_DISTANCES*******************************************"<<std::endl;
    std::cout<<"La distance est entre  : "<<this->m_id_BCAM_prisme<<std::endl;
    std::cout<<"Les valeurs des distances : \n"<<std::endl;
    m_distances.Affiche();
}
