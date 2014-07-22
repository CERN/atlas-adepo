#include "bcam.h"

BCAM::BCAM(std::string nom_BCAM, int id_detector, int num_Port_Driver, int num_Port_Mux, int num_chip, std::string objet_vise):m_nom_BCAM(nom_BCAM), m_id_detector(id_detector), m_num_Port_Driver(num_Port_Driver), m_num_Port_Mux(num_Port_Mux), m_num_chip(num_chip), m_objet_vise(objet_vise)
{
    //ctor
}

BCAM::BCAM()
{
    this->m_nom_BCAM = "";
    this->m_id_detector = 0;
    this->m_num_Port_Driver = 0;
    this->m_num_Port_Mux = 0;
    this->m_num_chip = 0;
    this->m_objet_vise = "";
}

BCAM::~BCAM()
{
    //dtor
}

void BCAM::Affiche()
{
    std::cout<<"*******************************************Infos BCAM*******************************************"<<std::endl;
    std::cout<<"Nom de la BCAM : "<<this->m_nom_BCAM<<std::endl;
    std::cout<<"Identifiant du detecteur auquel la BCAM appartient : "<<this->m_id_detector<<std::endl;
    std::cout<<"Numéro du port Driver : "<<this->m_num_Port_Driver<<std::endl;
    std::cout<<"Numéro du port Multiplexer : "<<this->m_num_Port_Mux<<std::endl;
    std::cout<<"Objet visee : "<<this->m_objet_vise<<std::endl;
    std::cout<<"Numero du chip : "<<this->m_num_chip<<std::endl;
    std::cout<<"************************************************************************************************"<<std::endl;
}

