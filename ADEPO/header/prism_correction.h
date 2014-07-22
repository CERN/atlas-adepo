#ifndef PRISM_CORRECTION_H
#define PRISM_CORRECTION_H

#include "iostream"
#include "Point3f.h"

class prism_correction
{
public:
    //constructeurs et destructeurs
    prism_correction();
    prism_correction(std::string id_prism, Point3f delta);
    virtual ~prism_correction();

    //setter et getter
    std::string Get_id_prism() const {return m_id_prism;}
    void Set_id_prism(std::string val) {m_id_prism=val;}

    Point3f Get_delta() const {return m_delta;}
    void Set_delta(Point3f val) {m_delta=val;}

    //methodes
    void Affiche();

protected:
private:
    std::string m_id_prism;
    Point3f m_delta;
};

#endif // PRISM_CORRECTION_H
