#ifndef ABSOLUTES_DISTANCES_H
#define ABSOLUTES_DISTANCES_H

#include <iostream>
#include "Point3f.h"

class absolutes_distances
{
public:
    absolutes_distances(std::string Id, Point3f distances) : mId(Id), mDistances(distances) {};
    virtual ~absolutes_distances() {};

   //setter et getter
    std::string getId() const {return mId;}

    Point3f getDistances() const {return mDistances;}

    //methodes
    void print() {
        std::cout<<"*******************************************//ABSOLUTES_DISTANCES*******************************************"<<std::endl;
        std::cout<<"La distance est entre  : "<<getId()<<std::endl;
        std::cout<<"Les valeurs des distances : \n"<<std::endl;
        getDistances().print();
    }

protected:
private:
    std::string mId;
    Point3f mDistances;
};

#endif // ABSOLUTES_DISTANCES_H
