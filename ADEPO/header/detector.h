#ifndef DETECTOR_H
#define DETECTOR_H

#include <iostream>

class detector
{
public:
    //constructeurs et destructeurs
    detector();
<<<<<<< HEAD
    detector(int num_id_detector, std::string nom_detector, float airpad_on_add_dist);
    virtual ~detector();

    //setter et getter
    int Get_num_id_detector() const {return m_num_id_detector; }
    void Set_num_id_detector(int val) {m_num_id_detector = val; }

    std::string Get_nom_detector() const {return m_nom_detector; }
    void Set_nom_detector(std::string val) {m_nom_detector = val; }

    float Get_airpad_on_add_dist() const {return m_airpad_on_add_dist;}
    void Set_airpad_on_add_dist(float val) {m_airpad_on_add_dist = val;}

    //methodes
    void Affiche();

protected:
private:
    int m_num_id_detector;
    std::string m_nom_detector;
    float m_airpad_on_add_dist;

=======
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
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
};

#endif // DETECTOR_H
