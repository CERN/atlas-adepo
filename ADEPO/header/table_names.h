#ifndef TABLE_NAMES_H
#define TABLE_NAMES_H

#include "iostream"

class table_names
{
public:
    //constructeurs et destructeurs
    table_names();
    table_names(std::string name_cta, std::string name_su);
    virtual ~table_names();

    //setter et getter
    std::string Get_name_cta() const {return m_name_cta;}
    void Set_name_cta(std::string val) {m_name_cta=val;}

    std::string Get_name_su() const {return m_name_su;}
    void Set_name_su(std::string val) {m_name_su=val;}

    //methodes
    void Affiche();

protected:
private:
    std::string m_name_cta;
    std::string m_name_su;



};

#endif // TABLE_NAMES_H
