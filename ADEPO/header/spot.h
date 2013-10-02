#ifndef SPOT_H
#define SPOT_H

#include "iostream"
#include "bcam.h"

class spot
{
public:
    //constructeurs et destructeurs
    spot();
    spot(std::string nom_BCAM, double i1_CCD, double j1_CCD, double i2_CCD, double j2_CCD);
    virtual ~spot();

    //setter et getter
    std::string Get_nom_BCAM_Objet() const { return m_nom_BCAM; }
    void Set_nom_BCAM_Objet(std::string val) {m_nom_BCAM = val; }

    double Get_i1_CCD() const { return m_i1_CCD; }
    void Set_i1_CCD(double val) {m_i1_CCD = val; }

    double Get_j1_CCD() const { return m_j1_CCD; }
    void Set_j1_CCD(double val) {m_j1_CCD = val; }

    double Get_i2_CCD() const { return m_i2_CCD; }
    void Set_i2_CCD(double val) {m_i2_CCD = val; }

    double Get_j2_CCD() const { return m_j2_CCD; }
    void Set_j2_CCD(double val) {m_j2_CCD = val; }

    //methodes
    void Affiche();

protected:
private:
    std::string m_nom_BCAM;
    double m_i1_CCD;
    double m_j1_CCD;
    double m_i2_CCD;
    double m_j2_CCD;
};

#endif // SPOT_H
