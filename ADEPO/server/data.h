#ifndef DATA_H
#define DATA_H

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
#include <QHash>
#include <QList>

#include "configuration.h"
#include "bcam.h"
#include "dual_spot.h"
#include "mount_coord_spots.h"
#include "mount_coord_prism.h"
#include "global_coord_prism.h"
#include "bcam_params.h"



class Data
{
public:
    //constructeurs et destructeur
    Data() {};
    Data(const Data& /* copie */) {};
    virtual ~Data() {};

    //getter
    QList<DualSpot> getDualSpots() const {return mDualSpots;}
    QList<MountCoordSpots> getMountCoordSpots() const {return mMountCoordSpots;}
    QList<MountCoordPrism> getMountCoordPrisms() const {return mMountCoordPrisms;}
    //gestion des parametres de translation et de rotation par BCAM
    QList<BCAMParams> getBCAMParams() const {return mBcamParams;}
    //gestion de la liste des coordonnees du prisme dans le repre global
    QList<GlobalCoordPrism> getGlobalCoordPrisms() const {return mGlobalCoordPrisms;}

   //methodes d'ajout
    void add(DualSpot val) {mDualSpots.push_back(val);}
    void add(MountCoordSpots val) {mMountCoordSpots.push_back(val);}
    void add(MountCoordPrism val) {mMountCoordPrisms.push_back(val);}
    //gestion des parametres de translation et de rotation par BCAM
    void add(BCAMParams val) {mBcamParams.push_back(val);}
    //gestion de la liste des coordonnees du prisme dans le repre global
    void add(GlobalCoordPrism val) {mGlobalCoordPrisms.push_back(val);}

    void clear() {
        mDualSpots.clear();
        mMountCoordSpots.clear();
        mMountCoordPrisms.clear();
        mGlobalCoordPrisms.clear();
    }

private:
    QList<DualSpot> mDualSpots;
    QList<MountCoordSpots> mMountCoordSpots;
    QList<MountCoordPrism> mMountCoordPrisms;
    QList<BCAMParams> mBcamParams;
    QList<GlobalCoordPrism> mGlobalCoordPrisms;

};

#endif // DATA_H
