#include "prism_correction.h"

prism_correction::prism_correction(std::string id_prism, Point3f delta):m_id_prism(id_prism), m_delta(delta)
{
    //ctor
}

prism_correction::prism_correction()
{
    this->m_id_prism = "";
}

prism_correction::~prism_correction()
{
    //dtor
}

void prism_correction::Affiche()
{
    std::cout<<"*******************************************Correction excentrement*******************************************"<<std::endl;
    std::cout<<"Identifiant du prisme : "<<this->m_id_prism<<std::endl;
    std::cout<<"Valeur d'excentrement : "<<std::endl;
    m_delta.Affiche();
}
