#include "header/spot.h"

spot::spot(std::string nom_BCAM, double i1_CCD, double j1_CCD, double i2_CCD, double j2_CCD): m_nom_BCAM(nom_BCAM), m_i1_CCD(i1_CCD), m_j1_CCD(j1_CCD), m_i2_CCD(i2_CCD), m_j2_CCD(j2_CCD)
{
    //ctor
}

spot::spot()
{
    this->m_nom_BCAM = "";
    this->m_i1_CCD = 0;
    this->m_j1_CCD = 0;
    this->m_i2_CCD = 0;
    this->m_j2_CCD = 0;
}

spot::~spot()
{
    //dtor
}

void spot::Affiche()
{
    std::cout<<"*******************************************Coord Spots*******************************************"<<std::endl;
    std::cout<<"Nom de la BCAM : "<<this->m_nom_BCAM<<std::endl;
    std::cout<<"Coord i1 : "<<this->m_i1_CCD<<std::endl;
    std::cout<<"Coord j1 : "<<this->m_j1_CCD<<std::endl;
    std::cout<<"Coord i2 : "<<this->m_i2_CCD<<std::endl;
    std::cout<<"Coord j2 : "<<this->m_j2_CCD<<std::endl;
}
