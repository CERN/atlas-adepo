#ifndef BDD_H
#define BDD_H
//////////////////////////////////////////
#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <header/detector.h>
#include <cstring>
#include <stdlib.h>
#include "unistd.h"
#include "cstdlib"
#include "math.h"
////////////////////////////////////////////
#include "header/bcam.h"
#include "header/detector.h"
#include "header/spot.h"
#include "header/calib1.h"
#include "header/calib2.h"
#include "header/mount_coord_spots.h"
#include "header/mount_coord_prism.h"
/////////////////////////////////////////////

class bdd
{
public:
    //constructeurs et destructeur
    bdd();
    bdd(const bdd& copie);
    virtual ~bdd();

    //getter
    std::vector<BCAM> Get_liste_BCAM() const {return m_liste_BCAM;}
    std::vector<detector> Get_liste_detector() const {return m_liste_detector;}
    std::vector<calib1> Get_liste_calib1() const {return m_liste_calib1;}
    std::vector<calib1> Get_liste_calib1_clean() const {return m_liste_calib1_clean;}
    std::vector<calib2> Get_liste_calib2() const {return m_liste_calib2;}
    std::vector<calib2> Get_liste_calib2_clean() const {return m_liste_calib2_clean;}
    std::vector<spot> Get_liste_spots() const {return m_liste_spots;}
    std::vector<mount_coord_spots> Get_liste_mount_coord_spots() const {return m_liste_mount_coord_spots;}
    std::vector<mount_coord_prism> Get_liste_mount_coord_prism() const {return m_liste_mount_coord_prism;}



   //methodes d'ajout
    void Add_BCAM(BCAM val) {m_liste_BCAM.push_back(val);}
    void Add_detector(detector val) {m_liste_detector.push_back(val);}
    void Add_calib1(calib1 val) {m_liste_calib1.push_back(val);}
    void Add_calib1_clean(calib1 val) {m_liste_calib1_clean.push_back(val);}
    void Add_calib2(calib2 val) {m_liste_calib2.push_back(val);}
    void Add_calib2_clean(calib2 val) {m_liste_calib2_clean.push_back(val);}
    void Add_spots(spot val) {m_liste_spots.push_back(val);}
    void Add_mount_coord_spots(mount_coord_spots val) {m_liste_mount_coord_spots.push_back(val);}
    void Add_mount_coord_prism(mount_coord_prism val) {m_liste_mount_coord_prism.push_back(val);}

protected:
private:
    std::vector<BCAM> m_liste_BCAM;
    std::vector<detector> m_liste_detector;
    std::vector<calib1> m_liste_calib1;
    std::vector<calib1> m_liste_calib1_clean;
    std::vector<calib2> m_liste_calib2;
    std::vector<calib2> m_liste_calib2_clean;
    std::vector<spot> m_liste_spots;
    std::vector<mount_coord_spots> m_liste_mount_coord_spots;
    std::vector<mount_coord_prism> m_liste_mount_coord_prism;

};

#endif // BDD_H
