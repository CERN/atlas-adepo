#ifndef CALIB2_H
#define CALIB2_H

#include "Point3f.h"

#include "iostream"

class calib2
{
public:
    //constructeurs et destructeurs
    calib2();
    calib2(std::string id_BCAM, Point3f coord_flash_1, Point3f coord_flash_2);
    virtual ~calib2();

    //setter et getter
    std::string Get_id_BCAM() const { return m_id_BCAM; }
    void Set_id_BCAM(std::string val) {m_id_BCAM = val; }

    Point3f Get_coord_flash_1() const {return m_coord_flash_1; }
    void Set_coord_flash_1(Point3f val) { m_coord_flash_1 = val; }

    Point3f Get_coord_flash_2() const {return m_coord_flash_2; }
    void Set_coord_flash_2(Point3f val) { m_coord_flash_2 = val; }



    //methodes
    void Affiche();

protected:
private:
    std::string m_id_BCAM;
    Point3f m_coord_flash_1;
    Point3f m_coord_flash_2;
};

#endif // CALIB2_H
