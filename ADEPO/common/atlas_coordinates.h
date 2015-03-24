#ifndef ATLAS_COORDINATES_H
#define ATLAS_COORDINATES_H

#include "iostream"
#include "point3d.h"

#include <QString>

class ATLASCoordinates
{
public:
    ATLASCoordinates(QString bcam, Point3d target) : mBCAM(bcam), mTarget(target) {};
    virtual ~ATLASCoordinates() {};

    //setter et getter
    QString getBCAM() const {return mBCAM; }

    Point3d getTarget() const {return mTarget;}

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
    Point3d mTarget;
};

#endif // ATLAS_COORDINATES_H
