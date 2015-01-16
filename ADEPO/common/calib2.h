#ifndef CALIB2_H
#define CALIB2_H

#include "point3f.h"
#include "iostream"

#include <QString>

class Calib2
{
public:
    Calib2(QString bcam, Point3f coordFlash1, Point3f coordFlash2) : mBCAM(bcam), mCoordFlash1(coordFlash1), mCoordFlash2(coordFlash2) {};
    virtual ~Calib2() {};

    //setter et getter
    QString getBCAM() const { return mBCAM; }

    Point3f getCoordFlash1() const {return mCoordFlash1; }

    Point3f getCoordFlash2() const {return mCoordFlash2; }

    int getDirection() const { return mCoordFlash1.z() > 0 ? 1 : -1; }

    //methodes
    void print() {
        std::cout<<"*******************************************Infos Calib*******************************************"<<std::endl;
        std::cout<<"Id de la BCAM : "<<getBCAM().toStdString()<<std::endl;
        std::cout<<"Affichage des cordonnées du premier flash : "<<std::endl;
        this->getCoordFlash1().print();
        std::cout<<"Affichage des cordonnées du second flash : "<<std::endl;
        this->getCoordFlash2().print();
        std::cout<<"************************************************************************************************"<<std::endl;
    }

protected:
private:
    QString mBCAM;
    Point3f mCoordFlash1;
    Point3f mCoordFlash2;
};

#endif // CALIB2_H
