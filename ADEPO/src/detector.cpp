#include "header/detector.h"

<<<<<<< HEAD
detector::detector(int num_id_detector, std::string nom_detector, float airpad_on_add_dist) : m_nom_detector(nom_detector), m_num_id_detector(num_id_detector), m_airpad_on_add_dist(airpad_on_add_dist)
=======
detector::detector(std::string nom_detector, int num_id_detector) : m_nom_detector(nom_detector), m_num_id_detector(num_id_detector)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
{
    //ctor
}


detector::detector()
{
<<<<<<< HEAD
    this->m_num_id_detector = 0;
    this->m_nom_detector = "";
    this->m_airpad_on_add_dist = 0;
=======
    this->m_nom_detector = "";
    this->m_num_id_detector = 0;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
}

detector::~detector()
{
    //dtor
}

void detector::Affiche()
{
<<<<<<< HEAD
    std::cout<<"*******************************************//DETECTORS_DATA*******************************************"<<std::endl;
    std::cout<<"Numéro identifiant detecteur : "<<this->m_num_id_detector<<std::endl;
    std::cout<<"Nom du detecteur : "<<this->m_nom_detector<<std::endl;
    std::cout<<"Constante Airpad on :"<<this->m_airpad_on_add_dist<<std::endl;
=======
    std::cout<<"*******************************************Detector*******************************************"<<std::endl;
    std::cout<<"Nom du detecteur : "<<this->m_nom_detector<<std::endl;
    std::cout<<"Numéro identifiant detecteur : "<<this->m_num_id_detector<<std::endl;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
}
