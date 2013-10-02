#ifndef ATLAS_COORDINATES_H
#define ATLAS_COORDINATES_H

#include "iostream"
#include "vector"
#include "Point3f.h"

class ATLAS_coordinates
{
public:
    //constructeurs et destructeurs
    ATLAS_coordinates();
    ATLAS_coordinates(std::string id_BCAM, Point3f cible);
    virtual ~ATLAS_coordinates();

    //setter et getter
    std::string Get_id_BCAM() const {return m_id_BCAM; }
    void Set_id_BCAM(std::string val) {m_id_BCAM = val;}

    Point3f Get_cible() const {return m_cible;}
    void Set_cible(Point3f val) {m_cible = val;}

    //methodes
    void Affiche();

protected:
private:
    std::string m_id_BCAM;
    Point3f m_cible;
};

#endif // ATLAS_COORDINATES_H
