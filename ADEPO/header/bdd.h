#ifndef BDD_H
#define BDD_H
//////////////////////////////////////////
#include <vector>
#include <map>
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
#include "header/bcam_adaptateur.h"
#include "header/absolutes_distances.h"
#include "header/atlas_coordinates.h"
#include "header/bcam_params.h"
#include "header/prism_correction.h"
/////////////////////////////////////////////

class bdd
{
public:
    //constructeurs et destructeur
    bdd();
    bdd(const bdd& copie);
    virtual ~bdd();

    //getter
    //gestion des bcams dans le terrain a partir du fichier de configuration
    std::vector<BCAM> Get_liste_BCAM() const {return m_liste_BCAM;}
    //gestion des detecteurs dans le fichier de configuration
    std::vector<detector> Get_liste_detector() const {return m_liste_detector;}
    std::vector<calib1> Get_liste_calib1() const {return m_liste_calib1;}
    std::vector<calib1> Get_liste_calib1_clean() const {return m_liste_calib1_clean;}
    std::vector<calib2> Get_liste_calib2() const {return m_liste_calib2;}
    std::vector<calib2> Get_liste_calib2_clean() const {return m_liste_calib2_clean;}
    std::vector<spot> Get_liste_spots() const {return m_liste_spots;}
    std::vector<mount_coord_spots> Get_liste_mount_coord_spots() const {return m_liste_mount_coord_spots;}
    std::vector<mount_coord_prism> Get_liste_mount_coord_prism() const {return m_liste_mount_coord_prism;}
    //gestion de l'adresse IP
    std::string Get_driver_ip_adress() const {return m_driver_ip_adress;}
    //gestion des coordonnees mount de l'adaptateur
    std::vector<bcam_adaptateur> Get_liste_bcam_adatateur() const {return m_liste_bcam_adaptateur;}
    //gestion des distances absolues
    std::vector<absolutes_distances> Get_liste_absolutes_distances() const {return m_liste_absolutes_distances;}
    //gestion des coordonnees de l'adaptateur <==> de la bcam, dans le repere ATLAS
    std::vector<ATLAS_coordinates> Get_liste_ATLAS_coordinates() const {return m_liste_ATLAS_coordinates;}
    //gestion des parametres de translation et de rotation par BCAM
    std::vector<BCAM_params> Get_liste_BCAM_params() const {return m_liste_bcam_params;}
    //gestion de la liste des coordonnees du prisme dans le repre global
    std::vector<mount_coord_prism> Get_liste_global_coord_prism() const {return m_liste_global_coord_prism;}
    //gestion des corrections d'excentrement
    std::vector<prism_correction> Get_liste_correction_excentrement() const {return m_liste_correction_excentrement;}

    std::string getName(std::string id) {
        return names[id];
    }

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
    //gestion de l'adresse IP
    void Set_driver_ip_adress(std::string val) {m_driver_ip_adress = val;}
    //gestion de l'adaptateur
    void Add_bcam_adaptateur(bcam_adaptateur val) {m_liste_bcam_adaptateur.push_back(val);}
    //gestion des distances absolues
    void Add_distance_absolue(absolutes_distances val) {m_liste_absolutes_distances.push_back(val);}
    //gestion des coordonnees de l'adaptatuer <==> de la bcam, dans le repere ATLAS
    void Add_ATLAS_coordinates(ATLAS_coordinates val) {m_liste_ATLAS_coordinates.push_back(val);}
    //gestion des parametres de translation et de rotation par BCAM
    void Add_BCAM_params(BCAM_params val) {m_liste_bcam_params.push_back(val);}
    //gestion de la liste des coordonnees du prisme dans le repre global
    void Add_global_coord_prism(mount_coord_prism val) {m_liste_global_coord_prism.push_back(val);}
    //gestion des nomenclatures
    void addName(std::string id, std::string name) {
        names[id] = name;
    }
    //gestion des correctiosn d'excentrement
    void Add_correction_excentrement(prism_correction val) {m_liste_correction_excentrement.push_back(val);}

    //vidage partiel de la bdd
    void vidage();
    //vidage complet de la bdd si on charge un second fichier
    void vidage_complet();

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
    std::string m_driver_ip_adress;
    std::vector<bcam_adaptateur> m_liste_bcam_adaptateur;
    std::vector<absolutes_distances> m_liste_absolutes_distances;
    std::vector<ATLAS_coordinates> m_liste_ATLAS_coordinates;
    std::vector<BCAM_params> m_liste_bcam_params;
    std::vector<mount_coord_prism> m_liste_global_coord_prism;
    std::vector<prism_correction> m_liste_correction_excentrement;

    std::map<std::string, std::string> names;
};

#endif // BDD_H
