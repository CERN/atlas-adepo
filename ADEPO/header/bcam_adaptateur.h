#ifndef BCAM_ADAPTATEUR_H
#define BCAM_ADAPTATEUR_H

#include "iostream"
#include "Point3f.h"

class bcam_adaptateur
{
public:
    //constructeurs et destructeurs
    bcam_adaptateur();
    bcam_adaptateur(std::string type_bcam, std::string id_cible, Point3f coord_cible);
    virtual ~bcam_adaptateur();

    //setter et getter
    std::string Get_type_bcam() const {return m_type_bcam;}
    void Set_type_bcam(std::string val) {m_type_bcam =val;}

    std::string Get_id_cible() const {return m_id_cible;}
    void Set_id_cible(std::string val) {m_id_cible =val;}

    Point3f Get_coord_cible() const {return m_coord_cible;}
    void Set_coord_cible(Point3f val) {m_coord_cible =val;}

    //methodes
    void Affiche();

protected:
private:
    std::string m_type_bcam;
    std::string m_id_cible;
    Point3f m_coord_cible;
};

#endif // BCAM_ADAPTATEUR_H
