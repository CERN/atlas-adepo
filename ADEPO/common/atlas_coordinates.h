#ifndef ATLAS_COORDINATES_H
#define ATLAS_COORDINATES_H

#include "iostream"
#include "vector"
#include "point3f.h"

#include <QString>

class ATLASCoordinates
{
public:
    ATLASCoordinates(QString bcam, Point3f target) : mBCAM(bcam), mTarget(target) {};
    virtual ~ATLASCoordinates() {};

    //setter et getter
    QString getBCAM() const {return mBCAM; }

    Point3f getTarget() const {return mTarget;}

    //methodes
    void print() {
        std::cout<<"*******************************************//ATLAS_COORDINATES*******************************************"<<std::endl;
        std::cout<<"Objet BCAM : "<<getBCAM().toStdString()<<std::endl;
        std::cout<<"Coordonnees de l'adaptateur : "<<std::endl;
        std::cout<<"Coordonnees de la cible : "<<std::endl;
        getTarget().print();
    }

protected:
private:
    QString mBCAM;
    Point3f mTarget;
};

#endif // ATLAS_COORDINATES_H
