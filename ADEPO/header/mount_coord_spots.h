#ifndef MOUNT_COORD_SPOTS_H
#define MOUNT_COORD_SPOTS_H

#include <iostream>
#include "Point3f.h"
#include "bcam.h"

class mount_coord_spots
{
public:
    mount_coord_spots(BCAM bcam, Point3f coord1, Point3f coord2) :
        mBCAM(bcam), mCoord1(coord1), mCoord2(coord2) {};
    virtual ~mount_coord_spots() {};

    BCAM getBCAM() const { return mBCAM; }
    Prism getPrism() const { return mBCAM.getPrism(); }
    std::string getName() const { return getBCAM().getName()+"_"+getPrism().getName(); }

    Point3f getCoord1() const {return mCoord1; }
    Point3f getCoord2() const {return mCoord2; }

    //methodes
    void print() {
        std::cout<<"*******************************************Mount coordinates*******************************************"<<std::endl;
        std::cout<<"BCAM : "<<getBCAM().getName()<<std::endl;
        std::cout<<"Prism : "<<getPrism().getName()<<std::endl;
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 1) : "<<std::endl;
        this->getCoord1().print();
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 2) : "<<std::endl;
        this->getCoord2().print();
    }

protected:
private:
    BCAM mBCAM;
    Point3f mCoord1;
    Point3f mCoord2;
};

#endif // MOUNT_COORD_SPOTS_H
