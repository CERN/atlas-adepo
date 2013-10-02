#ifndef CALIB1_H
#define CALIB1_H

#include "Point3f.h"

#include "iostream"

class calib1
{
public:
    //constructeurs et destructeurs
    calib1();
<<<<<<< HEAD
    calib1(std::string id_BCAM, std::string tps_calib, Point3f coord_pivot, Point3f coord_axis, float ccd_to_pivot, float ccd_rotation);
=======
    calib1(std::string id_BCAM, double tps_calib, Point3f coord_pivot, Point3f coord_axis, double ccd_to_pivot, double ccd_rotation);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    virtual ~calib1();

    //setter et getter
    std::string Get_id_BCAM() const { return m_id_BCAM; }
    void Set_id_BCAM(std::string val) {m_id_BCAM = val; }

<<<<<<< HEAD
    std::string Get_tps_calib() const { return m_tps_calib; }
    void Set_tps_calib(std::string val) {m_tps_calib = val; }
=======
    double Get_tps_calib() const { return m_tps_calib; }
    void Set_tps_calib(double val) {m_tps_calib = val; }
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

    Point3f Get_coord_pivot() const { return m_coord_pivot; }
    void Set_coord_pivot(Point3f val) { m_coord_pivot = val; }

    Point3f Get_coord_axis() const { return m_coord_axis; }
    void Set_coord_axis(Point3f val) { m_coord_axis = val; }

<<<<<<< HEAD
    float Get_ccd_to_pivot() const { return m_ccd_to_pivot; }
    void set_ccd_to_pivot(float val) { m_ccd_to_pivot = val; }

    float Get_ccd_rotation() const { return m_ccd_rotation; }
    void set_ccd_rotation(float val) { m_ccd_rotation = val; }
=======
    double Get_ccd_to_pivot() const { return m_ccd_to_pivot; }
    void set_ccd_to_pivot(double val) { m_ccd_to_pivot = val; }

    double Get_ccd_rotation() const { return m_ccd_rotation; }
    void set_ccd_rotation(double val) { m_ccd_rotation = val; }
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

    //methodes
    void Affiche();

protected:
private:
    std::string m_id_BCAM;
<<<<<<< HEAD
    std::string m_tps_calib;
    Point3f m_coord_pivot;
    Point3f m_coord_axis;
    float m_ccd_to_pivot;
    float m_ccd_rotation;
=======
    double m_tps_calib;
    Point3f m_coord_pivot;
    Point3f m_coord_axis;
    double m_ccd_to_pivot;
    double m_ccd_rotation;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
};

#endif // CALIB1_H
