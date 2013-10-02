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
<<<<<<< HEAD
    mount_coord_prism(std::string id, Point3f coord_prism_mount_sys);
    virtual ~mount_coord_prism();

    //getter setter
    std::string Get_id() const {return m_id; }
    void Set_id_prism(std::string val) {m_id = val ;}
=======
    mount_coord_prism(std::string id_prism, std::string id_BCAM, Point3f coord_prism_mount_sys);
    virtual ~mount_coord_prism();

    //getter setter
    std::string Get_id_prism() const {return m_id_prism; }
    void Set_id_prism(std::string val) {m_id_prism = val ;}

    std::string Get_id_BCAM() const {return m_id_BCAM; }
    void Set_id_BCAM(std::string val) {m_id_BCAM = val ;}
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

    Point3f Get_coord_prism_mount_sys() const {return m_coord_prism_mount_sys; }
    void Set_coord_prism_mount_sys(Point3f val) {m_coord_prism_mount_sys = val; }

    //methodes
    void Affiche();

protected:
private:
<<<<<<< HEAD
    std::string m_id;
=======
    std::string m_id_prism;
    std::string m_id_BCAM;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    Point3f m_coord_prism_mount_sys;

};

#endif // MOUNT_COORD_PRISM_H
