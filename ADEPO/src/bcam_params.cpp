#include "bcam_params.h"

BCAM_params::BCAM_params(std::string id_bcam, Point3f translation, Point3f rotation) : m_id_bcam(id_bcam), m_translation(translation), m_rotation(rotation)
{
    //ctor
}

BCAM_params::~BCAM_params()
{
    //dtor
}

BCAM_params::BCAM_params()
{
    this->m_id_bcam = "";
}

void BCAM_params::Affiche()
{
    std::cout<<"*******************************************//BCAM_parametres*******************************************"<<std::endl;
    std::cout<<"Identifiant de la BCAM : "<<this->m_id_bcam<<std::endl;
    std::cout<<"Translation : "<<std::endl;
    this->m_translation.Affiche();
    std::cout<<"Angles de rotation : "<<std::endl;
    this->m_rotation.Affiche();
}
