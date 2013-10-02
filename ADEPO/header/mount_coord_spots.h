#ifndef MOUNT_COORD_SPOTS_H
#define MOUNT_COORD_SPOTS_H

#include <iostream>
#include "Point3f.h"

class mount_coord_spots
{
public:
    //constructeurs et destructeurs
    mount_coord_spots();
    mount_coord_spots(std::string id,  Point3f coord1, Point3f coord2);
    virtual ~mount_coord_spots();

     //setter et getter
    std::string Get_id() const { return m_id; }
    void Set_id(std::string val) {m_id = val; }

    Point3f Get_coord1() const {return m_coord1; }
    void Set_coord1(Point3f val) { m_coord1 = val; }

    Point3f Get_coord2() const {return m_coord2; }
    void Set_coord2(Point3f val) { m_coord2 = val; }

    //methodes
    void Affiche();


protected:
private:
    std::string m_id;
    Point3f m_coord1;
    Point3f m_coord2;


};

#endif // MOUNT_COORD_SPOTS_H
