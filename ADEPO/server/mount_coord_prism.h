#ifndef MOUNT_COORD_PRISM_H
#define MOUNT_COORD_PRISM_H

#include <iostream>
#include "vector"
#include "Point3f.h"
#include "bcam.h"


class MountCoordPrism
{
public:
    MountCoordPrism(BCAM bcam, Point3f coordPrismMountSys) :
        mBCAM(bcam), mCoordPrismMountSys(coordPrismMountSys) {};
    virtual ~MountCoordPrism() {};

    //getter setter
    BCAM getBCAM() const {return mBCAM; }
    Prism getPrism() const {return mBCAM.getPrism(); }
    std::string getName() const { return getBCAM().getName()+"_"+getPrism().getName(); }
    Point3f getCoordPrismMountSys() const {return mCoordPrismMountSys; }


    //methodes
    void print() {
        std::cout<<"*******************************************Mount coordinates of prism*******************************************"<<std::endl;
        std::cout<<"Objet BCAM : "<<getBCAM().getName()<<std::endl;
        std::cout<<"Objet Prism : "<<getPrism().getName()<<std::endl;
        std::cout<<"Coordonnées du prisme dans le systeme MOUNT : "<<std::endl;
        getCoordPrismMountSys().print();
    }

protected:
private:
    BCAM mBCAM;
    Point3f mCoordPrismMountSys;
};

#endif // MOUNT_COORD_PRISM_H
