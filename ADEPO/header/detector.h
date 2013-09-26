#ifndef DETECTOR_H
#define DETECTOR_H

#include <iostream>

class detector
{
public:
    //constructeurs et destructeurs
    detector();
    detector(std::string nom_detector, int num_id_detector);
    virtual ~detector();

    //setter et getter
    std::string Get_nom_detector() const {return m_nom_detector; }
    void Set_nom_detector(std::string val) {m_nom_detector =val; }

    int Get_num_id_detector() const {return m_num_id_detector; }
    void Set_num_id_detector(int val) {m_num_id_detector = val; }

    //methodes
    void Affiche();
protected:
private:
    std::string m_nom_detector;
    int m_num_id_detector;
};

#endif // DETECTOR_H
