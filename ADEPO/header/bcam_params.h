#ifndef BCAM_PARAMS_H
#define BCAM_PARAMS_H

#include "iostream"
#include "Point3f.h"

class BCAM_params
{
public:
    //constructeurs et destructeurs
    BCAM_params();
    BCAM_params(std::string id_bcam, Point3f translation, Point3f rotation);
    virtual ~BCAM_params();

    //setter et getter
    std::string Get_id_bcam() const {return m_id_bcam;}
    void Set_id_bcam(std::string val) {m_id_bcam =val;}

    Point3f Get_translation() const {return m_translation;}
    void Set_translation(Point3f val) {m_translation =val;}

    Point3f Get_rotation() const {return m_rotation;}
    void Set_rotation(Point3f val) {m_rotation =val;}

    //methodes
    void Affiche();

protected:
private:
    std::string m_id_bcam;
    Point3f m_translation;
    Point3f m_rotation;
};

#endif // BCAM_PARAMS_H
