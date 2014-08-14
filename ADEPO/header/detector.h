#ifndef DETECTOR_H
#define DETECTOR_H

#include <iostream>

class detector
{
public:
    //constructeurs et destructeurs
    detector();
    detector(int num_id_detector, std::string nom_detector, float airpad);
    virtual ~detector();

    //setter et getter
    int Get_num_id_detector() const {return m_num_id_detector; }

    std::string Get_nom_detector() const {return m_nom_detector; }

    float getAirpad() const {return m_airpad;}

    //methodes
    void Affiche();

protected:
private:
    int m_num_id_detector;
    std::string m_nom_detector;
    float m_airpad;

};

#endif // DETECTOR_H
