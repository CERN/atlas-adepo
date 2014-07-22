#include "detector.h"

detector::detector(int num_id_detector, std::string nom_detector, float airpad_on_add_dist) : m_num_id_detector(num_id_detector), m_nom_detector(nom_detector), m_airpad_on_add_dist(airpad_on_add_dist)
{
    //ctor
}


detector::detector()
{
    this->m_num_id_detector = 0;
    this->m_nom_detector = "";
    this->m_airpad_on_add_dist = 0;
}

detector::~detector()
{
    //dtor
}

void detector::Affiche()
{
    std::cout<<"*******************************************//DETECTORS_DATA*******************************************"<<std::endl;
    std::cout<<"Numéro identifiant detecteur : "<<this->m_num_id_detector<<std::endl;
    std::cout<<"Nom du detecteur : "<<this->m_nom_detector<<std::endl;
    std::cout<<"Constante Airpad on :"<<this->m_airpad_on_add_dist<<std::endl;
}
