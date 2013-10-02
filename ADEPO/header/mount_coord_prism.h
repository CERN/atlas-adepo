#ifndef MOUNT_COORD_PRISM_H
#define MOUNT_COORD_PRISM_H

#include <iostream>
#include "vector"
#include "Point3f.h"


class mount_coord_prism
{
public:
    //constructeurs et destructeurs
    mount_coord_prism();
    mount_coord_prism(std::string id, Point3f coord_prism_mount_sys);
    virtual ~mount_coord_prism();

    //getter setter
    std::string Get_id() const {return m_id; }
    void Set_id_prism(std::string val) {m_id = val ;}

    Point3f Get_coord_prism_mount_sys() const {return m_coord_prism_mount_sys; }
    void Set_coord_prism_mount_sys(Point3f val) {m_coord_prism_mount_sys = val; }

    //methodes
    void Affiche();

protected:
private:
    std::string m_id;
    Point3f m_coord_prism_mount_sys;

};

#endif // MOUNT_COORD_PRISM_H
