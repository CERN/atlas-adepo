#ifndef BDD_H
#define BDD_H

#include <vector>
#include <map>
#include <string>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdexcept>
#include <cstring>
#include <stdlib.h>
#include <unistd.h>
#include <cstdlib>
#include <cmath>

#include <QString>
#include <QStringList>

#include "configuration.h"
#include "bcam.h"
#include "dual_spot.h"
#include "mount_coord_spots.h"
#include "mount_coord_prism.h"
#include "global_coord_prism.h"
#include "bcam_params.h"



class BDD
{
public:
    //constructeurs et destructeur
    BDD() {};
    BDD(const BDD& /* copie */) {};
    virtual ~BDD() {};

    //getter
    std::vector<BCAM> getBCAMs(int id_detector, Configuration& config);
    std::vector<DualSpot> getDualSpots() const {return mDualSpots;}
    std::vector<MountCoordSpots> getMountCoordSpots() const {return mMountCoordSpots;}
    std::vector<MountCoordPrism> getMountCoordPrisms() const {return mMountCoordPrisms;}
    //gestion des parametres de translation et de rotation par BCAM
    std::vector<BCAMParams> getBCAMParams() const {return mBcamParams;}
    //gestion de la liste des coordonnees du prisme dans le repre global
    std::vector<GlobalCoordPrism> getGlobalCoordPrisms() const {return mGlobalCoordPrisms;}

    BCAM getBCAM(std::string bcam_prism) {
        for(unsigned int i=0; i < mBCAMs.size(); i++) {
           if (bcam_prism == mBCAMs[i].getName() + "_" + mBCAMs[i].getPrism().getName()) {
               return mBCAMs[i];
           }
        }
        std::cout << "WARNING BCAM with name " << bcam_prism << " not defined in current selection." << std::endl;
        throw std::invalid_argument(bcam_prism);
    }

   //methodes d'ajout
    void add(DualSpot val) {mDualSpots.push_back(val);}
    void add(MountCoordSpots val) {mMountCoordSpots.push_back(val);}
    void add(MountCoordPrism val) {mMountCoordPrisms.push_back(val);}
    //gestion des parametres de translation et de rotation par BCAM
    void add(BCAMParams val) {mBcamParams.push_back(val);}
    //gestion de la liste des coordonnees du prisme dans le repre global
    void add(GlobalCoordPrism val) {mGlobalCoordPrisms.push_back(val);}


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
        mBCAMs.clear();
        mDualSpots.clear();
        mMountCoordSpots.clear();
        mMountCoordPrisms.clear();
        mGlobalCoordPrisms.clear();
    }

protected:
private:
    std::vector<BCAM> mBCAMs;
    std::vector<DualSpot> mDualSpots;
    std::vector<MountCoordSpots> mMountCoordSpots;
    std::vector<MountCoordPrism> mMountCoordPrisms;
    std::vector<BCAMParams> mBcamParams;
    std::vector<GlobalCoordPrism> mGlobalCoordPrisms;

};

#endif // BDD_H
