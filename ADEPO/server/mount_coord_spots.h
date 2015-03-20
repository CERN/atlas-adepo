#ifndef MOUNT_COORD_SPOTS_H
#define MOUNT_COORD_SPOTS_H

#include <iostream>
#include "point3d.h"
#include "bcam.h"

class MountCoordSpots
{
public:
    MountCoordSpots(BCAM bcam, Point3d coord1, Point3d coord2) :
        mBCAM(bcam), mCoord1(coord1), mCoord2(coord2) {};
    virtual ~MountCoordSpots() {};

    BCAM getBCAM() const { return mBCAM; }
    Prism getPrism() const { return mBCAM.getPrism(); }
    QString getName() const { return getBCAM().getName()+"_"+getPrism().getName(); }

    Point3d getCoord1() const {return mCoord1; }
    Point3d getCoord2() const {return mCoord2; }

    //methodes
    void print() {
        std::cout<<"*******************************************Mount coordinates*******************************************"<<std::endl;
        std::cout<<"BCAM : "<<getBCAM().getName().toStdString()<<std::endl;
        std::cout<<"Prism : "<<getPrism().getName().toStdString()<<std::endl;
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 1) : "<<std::endl;
        this->getCoord1().print();
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 2) : "<<std::endl;
        this->getCoord2().print();
    }

protected:
private:
    BCAM mBCAM;
    Point3d mCoord1;
    Point3d mCoord2;
};

#endif // MOUNT_COORD_SPOTS_H
