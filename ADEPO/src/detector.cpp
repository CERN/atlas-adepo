#include "header/detector.h"

detector::detector(std::string nom_detector, int num_id_detector) : m_nom_detector(nom_detector), m_num_id_detector(num_id_detector)
{
    //ctor
}


detector::detector()
{
    this->m_nom_detector = "";
    this->m_num_id_detector = 0;
}

detector::~detector()
{
    //dtor
}

void detector::Affiche()
{
    std::cout<<"*******************************************Detector*******************************************"<<std::endl;
    std::cout<<"Nom du detecteur : "<<this->m_nom_detector<<std::endl;
    std::cout<<"Numéro identifiant detecteur : "<<this->m_num_id_detector<<std::endl;
}
