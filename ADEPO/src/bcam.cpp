#include "header/bcam.h"

<<<<<<< HEAD
BCAM::BCAM(std::string nom_BCAM, int id_detector, int num_Port_Driver, int num_Port_Mux, int num_chip, std::string objet_vise):m_nom_BCAM(nom_BCAM), m_id_detector(id_detector), m_num_Port_Driver(num_Port_Driver), m_num_Port_Mux(num_Port_Mux), m_num_chip(num_chip), m_objet_vise(objet_vise)
=======
BCAM::BCAM(std::string nom_BCAM, int id_detector, int num_Port_Driver, int num_Port_Mux, std::string type_bool_BCAM, int num_chip, std::string objet_vise):m_nom_BCAM(nom_BCAM), m_id_detector(id_detector), m_num_Port_Driver(num_Port_Driver), m_num_Port_Mux(num_Port_Mux), m_type_bool_BCAM(type_bool_BCAM), m_num_chip(num_chip), m_objet_vise(objet_vise)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
{
    //ctor
}

BCAM::BCAM()
{
    this->m_nom_BCAM = "";
<<<<<<< HEAD
    this->m_id_detector = 0;
=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    this->m_num_Port_Driver = 0;
    this->m_num_Port_Mux = 0;
    this->m_num_chip = 0;
    this->m_objet_vise = "";
<<<<<<< HEAD
=======
    this->m_type_bool_BCAM="";
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
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
<<<<<<< HEAD
    std::cout<<"Objet visee : "<<this->m_objet_vise<<std::endl;
=======
    std::cout<<"BCAM visee : "<<this->m_objet_vise<<std::endl;
    std::cout<<"Single ou double ? : "<<this->m_type_bool_BCAM<<std::endl;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    std::cout<<"Numero du chip : "<<this->m_num_chip<<std::endl;
    std::cout<<"************************************************************************************************"<<std::endl;
}

