#ifndef MOUNT_COORD_PRISM_H
#define MOUNT_COORD_PRISM_H

#include <iostream>
#include "vector"
#include "Point3f.h"


class mount_coord_prism
{
public:
    mount_coord_prism(std::string bcam, std::string prism, Point3f coordPrismMountSys, float airpad) :
        mBCAM(bcam), mPrism(prism), mCoordPrismMountSys(coordPrismMountSys), mAirpad(airpad) {};
    virtual ~mount_coord_prism() {};

    //getter setter
    std::string getBCAM() const {return mBCAM; }
    std::string getPrism() const {return mPrism; }
    std::string getName() const { return getBCAM()+"_"+getPrism(); }
    Point3f getCoordPrismMountSys() const {return mCoordPrismMountSys; }

    float getAirpad() { return mAirpad; }

    //methodes
    void print() {
        std::cout<<"*******************************************Mount coordinates of prism*******************************************"<<std::endl;
        std::cout<<"Objet BCAM : "<<getBCAM()<<std::endl;
        std::cout<<"Objet Prism : "<<getPrism()<<std::endl;
        std::cout<<"Coordonnées du prisme dans le systeme MOUNT : "<<std::endl;
        getCoordPrismMountSys().print();
    }

protected:
private:
    std::string mBCAM;
    std::string mPrism;
    Point3f mCoordPrismMountSys;
    float mAirpad;
};

#endif // MOUNT_COORD_PRISM_H
