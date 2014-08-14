#ifndef MOUNT_COORD_SPOTS_H
#define MOUNT_COORD_SPOTS_H

#include <iostream>
#include "Point3f.h"

class mount_coord_spots
{
public:
    mount_coord_spots(std::string bcam, std::string prism,  Point3f coord1, Point3f coord2) : mBCAM(bcam), mPrism(prism), mCoord1(coord1), mCoord2(coord2) {};
    virtual ~mount_coord_spots() {};

    std::string getBCAM() const { return mBCAM; }
    std::string getPrism() const { return mPrism; }
    std::string getName() const { return getBCAM()+"_"+getPrism(); }

    Point3f getCoord1() const {return mCoord1; }
    Point3f getCoord2() const {return mCoord2; }

    //methodes
    void print() {
        std::cout<<"*******************************************Mount coordinates*******************************************"<<std::endl;
        std::cout<<"BCAM : "<<getBCAM()<<std::endl;
        std::cout<<"Prism : "<<getPrism()<<std::endl;
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 1) : "<<std::endl;
        this->getCoord1().print();
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 2) : "<<std::endl;
        this->getCoord2().print();
    }

protected:
private:
    std::string mBCAM;
    std::string mPrism;
    Point3f mCoord1;
    Point3f mCoord2;
};

#endif // MOUNT_COORD_SPOTS_H
