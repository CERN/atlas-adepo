#ifndef ATLAS_COORDINATES_H
#define ATLAS_COORDINATES_H

#include "iostream"
#include "vector"
#include "Point3f.h"

class ATLAS_coordinates
{
public:
    ATLAS_coordinates(std::string id, Point3f target) : mId(id), mTarget(target) {};
    virtual ~ATLAS_coordinates() {};

    //setter et getter
    std::string getId() const {return mId; }

    Point3f getTarget() const {return mTarget;}

    //methodes
    void print() {
        std::cout<<"*******************************************//ATLAS_COORDINATES*******************************************"<<std::endl;
        std::cout<<"Objet BCAM : "<<getId()<<std::endl;
        std::cout<<"Coordonnees de l'adaptateur : "<<std::endl;
        std::cout<<"Coordonnees de la cible : "<<std::endl;
        getTarget().print();
    }

protected:
private:
    std::string mId;
    Point3f mTarget;
};

#endif // ATLAS_COORDINATES_H
