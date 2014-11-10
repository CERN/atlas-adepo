#ifndef BDD_H
#define BDD_H
//////////////////////////////////////////
#include <vector>
#include <map>
#include <string>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdexcept>
#include <detector.h>
#include <cstring>
#include <stdlib.h>
#include <QString>
#include <QStringList>
#include "unistd.h"
#include "cstdlib"
#include "math.h"
////////////////////////////////////////////
#include "bcam.h"
#include "bcam_config.h"
#include "detector.h"
#include "dual_spot.h"
#include "calib1.h"
#include "calib2.h"
#include "mount_coord_spots.h"
#include "mount_coord_prism.h"
#include "global_coord_prism.h"
#include "bcam_adaptateur.h"
#include "absolutes_distances.h"
#include "atlas_coordinates.h"
#include "bcam_params.h"
#include "prism_correction.h"
/////////////////////////////////////////////

class bdd
{
public:
    //constructeurs et destructeur
    bdd() {};
    bdd(const bdd& /* copie */) {};
    virtual ~bdd() {};

    //getter
    //gestion des bcams dans le terrain a partir du fichier de configuration
    std::vector<BCAMConfig> getBCAMConfigs() const {return mBCAMConfigs;}
    std::vector<BCAM> getBCAMs(int id_detector);
    //gestion des detecteurs dans le fichier de configuration
    std::vector<detector> getDetectors() const {return mDetectors;}
    std::vector<calib1> getCalibs1() const {return mCalibs1;}
//    std::vector<calib1> getCalibs1Clean() const {return m_liste_calib1_clean;}
    std::vector<calib2> getCalibs2() const {return mCalibs2;}
//    std::vector<calib2> Get_liste_calib2_clean() const {return m_liste_calib2_clean;}
    std::vector<DualSpot> getDualSpots() const {return mDualSpots;}
    std::vector<mount_coord_spots> getMountCoordSpots() const {return mMountCoordSpots;}
    std::vector<mount_coord_prism> getMountCoordPrisms() const {return mMountCoordPrisms;}
    //gestion de l'adresse IP
    std::string getDriverIpAddress() const {return mDriverIpAddress;}
    //gestion des coordonnees mount de l'adaptateur
    std::vector<bcam_adaptateur> getBCAMAdapters() const {return mBCAMAdapters;}
    //gestion des distances absolues
    std::vector<absolutes_distances> getAbsoluteDistances() const {return mAbsoluteDistances;}
    //gestion des coordonnees de l'adaptateur <==> de la bcam, dans le repere ATLAS
    std::vector<ATLAS_coordinates> getATLASCoordinates() const {return mATLASCoordinates;}
    //gestion des parametres de translation et de rotation par BCAM
    std::vector<BCAM_params> getBCAMParams() const {return mBcamParams;}
    //gestion de la liste des coordonnees du prisme dans le repre global
    std::vector<global_coord_prism> getGlobalCoordPrisms() const {return mGlobalCoordPrisms;}
    //gestion des corrections d'excentrement
    std::vector<prism_correction> getPrismCorrections() const {return mPrismCorrections;}

    std::string getName(std::string id) { return names.at(id); }

    BCAM getBCAM(std::string bcam_prism) {
        for(unsigned int i=0; i < mBCAMs.size(); i++) {
           if (bcam_prism == mBCAMs[i].getName() + "_" + mBCAMs[i].getPrism().getName()) {
               return mBCAMs[i];
           }
        }
        std::cout << "WARNING BCAM with name " << bcam_prism << " not defined in current selection." << std::endl;
        throw std::invalid_argument(bcam_prism);
    }


    BCAMConfig getBCAMConfig(std::string name) {
        for(unsigned int i=0; i < mBCAMConfigs.size(); i++) {
            if (name == mBCAMConfigs[i].getName()) {
                return mBCAMConfigs[i];
            }
        }
        std::cout << "WARNING BCAMConfig with name " << name << " not defined in configuration." << std::endl;
        throw std::invalid_argument(name);
    }

    detector getDetector(std::string bcamName) {
        BCAMConfig bcam = getBCAMConfig(bcamName);
        for(unsigned int j=0; j < mDetectors.size(); j++) {
            if (bcam.getDetectorId() == mDetectors[j].getId()) {
                return mDetectors[j];
            }
        }
        std::cout << "WARNING detector with id " << bcam.getDetectorId() << " not defined in configuration." << std::endl;
        throw std::invalid_argument(bcamName);
    }


   //methodes d'ajout
    void add(BCAMConfig val) { mBCAMConfigs.push_back(val); }
    void add(detector val) {mDetectors.push_back(val);}
    void add(calib1 val) { mCalibs1.push_back(val); }
//    void addClean(calib1 val) {mCalibs1Clean.push_back(val);}
    void add(calib2 val) {mCalibs2.push_back(val);}
//    void Add_calib2_clean(calib2 val) {m_liste_calib2_clean.push_back(val);}
    void add(DualSpot val) {mDualSpots.push_back(val);}
    void add(mount_coord_spots val) {mMountCoordSpots.push_back(val);}
    void add(mount_coord_prism val) {mMountCoordPrisms.push_back(val);}
    //gestion de l'adresse IP
    void setDriverIpAddress(std::string val) {mDriverIpAddress = val;}
    //gestion de l'adaptateur
    void add(bcam_adaptateur val) {mBCAMAdapters.push_back(val);}
    //gestion des distances absolues
    void add(absolutes_distances val) {mAbsoluteDistances.push_back(val);}
    //gestion des coordonnees de l'adaptatuer <==> de la bcam, dans le repere ATLAS
    void add(ATLAS_coordinates val) {mATLASCoordinates.push_back(val);}
    //gestion des parametres de translation et de rotation par BCAM
    void add(BCAM_params val) {mBcamParams.push_back(val);}
    //gestion de la liste des coordonnees du prisme dans le repre global
    void add(global_coord_prism val) {mGlobalCoordPrisms.push_back(val);}
    //gestion des nomenclatures
    void addName(std::string id, std::string name) { names[id] = name; }

    //gestion des correctiosn d'excentrement
    void add(prism_correction val) {mPrismCorrections.push_back(val);}

    std::vector<BCAM>& getBCAMs() { return mBCAMs; }

    //vidage partiel de la bdd
    void vidage() {
        mDualSpots.clear();
        mMountCoordSpots.clear();
        mMountCoordPrisms.clear();
        mGlobalCoordPrisms.clear();
    }

    //vidage complet de la bdd si on charge un second fichier
    void vidage_complet() {
        mBCAMConfigs.clear();
        mBCAMs.clear();
        mDetectors.clear();
        mCalibs1.clear();
//        mCalibs1Clean.clear();
        mCalibs2.clear();
//        m_liste_calib2_clean.clear();
        mDualSpots.clear();
        mMountCoordSpots.clear();
        mMountCoordPrisms.clear();
        mGlobalCoordPrisms.clear();
        mDriverIpAddress.clear();
        mBCAMAdapters.clear();
        mAbsoluteDistances.clear();
        mATLASCoordinates.clear();
    }

protected:
private:
    std::vector<BCAMConfig> mBCAMConfigs;
    std::vector<BCAM> mBCAMs;
    std::vector<detector> mDetectors;
    std::vector<calib1> mCalibs1;
//    std::vector<calib1> mCalibs1Clean;
    std::vector<calib2> mCalibs2;
//    std::vector<calib2> m_liste_calib2_clean;
    std::vector<DualSpot> mDualSpots;
    std::vector<mount_coord_spots> mMountCoordSpots;
    std::vector<mount_coord_prism> mMountCoordPrisms;
    std::string mDriverIpAddress;
    std::vector<bcam_adaptateur> mBCAMAdapters;
    std::vector<absolutes_distances> mAbsoluteDistances;
    std::vector<ATLAS_coordinates> mATLASCoordinates;
    std::vector<BCAM_params> mBcamParams;
    std::vector<global_coord_prism> mGlobalCoordPrisms;
    std::vector<prism_correction> mPrismCorrections;

    std::map<std::string, std::string> names;
};

#endif // BDD_H
