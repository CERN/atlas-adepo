#ifndef MOUNT_COORD_SPOTS_H
#define MOUNT_COORD_SPOTS_H

#include <iostream>
#include "Point3f.h"

class mount_coord_spots
{
public:
    mount_coord_spots(std::string id,  Point3f coord1, Point3f coord2) : mId(id), mCoord1(coord1), mCoord2(coord2) {};
    virtual ~mount_coord_spots() {};

    std::string getId() const { return mId; }

    Point3f getCoord1() const {return mCoord1; }
    Point3f getCoord2() const {return mCoord2; }

    //methodes
    void print() {
        std::cout<<"*******************************************Mount coordinates*******************************************"<<std::endl;
        std::cout<<"Id : "<<getId()<<std::endl;
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 1) : "<<std::endl;
        this->getCoord1().print();
        std::cout<<"Coordonnées dans le systeme MOUNT (spot 2) : "<<std::endl;
        this->getCoord2().print();
    }

protected:
private:
    std::string mId;
    Point3f mCoord1;
    Point3f mCoord2;
};

#endif // MOUNT_COORD_SPOTS_H
