#include "header/table_names.h"

table_names::table_names(std::string name_cta, std::string name_su): m_name_cta(name_cta), m_name_su(name_su)
{
    //ctor
}

table_names::table_names()
{
    this->m_name_cta="";
    this->m_name_su="";
}

table_names::~table_names()
{
    //dtor
}

void table_names::Affiche()
{
    std::cout<<"*******************************************Table nomenclature*******************************************"<<std::endl;
    std::cout<<"Nom objet ATLAS : "<<this->m_name_cta<<std::endl;
    std::cout<<"Nom objet SU : "<<this->m_name_su<<std::endl;
}
