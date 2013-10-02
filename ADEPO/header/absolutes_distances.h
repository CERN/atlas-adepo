#ifndef ABSOLUTES_DISTANCES_H
#define ABSOLUTES_DISTANCES_H

#include <iostream>
#include "Point3f.h"

class absolutes_distances
{
public:
    //constructeurs et destructeurs
    absolutes_distances();
    absolutes_distances(std::string id_BCAM_prisme, Point3f distances);
    virtual ~absolutes_distances();

   //setter et getter
    std::string Get_id_BCAM_prisme() const {return m_id_BCAM_prisme;}
    void Set_id_BCAM_prisme(std::string val) {m_id_BCAM_prisme = val;}

    Point3f Get_distances() const {return m_distances;}
    void Set_distances(Point3f val) {m_distances = val;}

    //methodes
    void Affiche();

protected:
private:
    std::string m_id_BCAM_prisme;
    Point3f m_distances;
};

#endif // ABSOLUTES_DISTANCES_H
