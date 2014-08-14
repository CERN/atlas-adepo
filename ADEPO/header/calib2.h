#ifndef CALIB2_H
#define CALIB2_H

#include "Point3f.h"

#include "iostream"

class calib2
{
public:
    calib2(std::string bcam, Point3f coordFlash1, Point3f coordFlash2) : mBCAM(bcam), mCoordFlash1(coordFlash1), mCoordFlash2(coordFlash2) {};
    virtual ~calib2() {};

    //setter et getter
    std::string getBCAM() const { return mBCAM; }

    Point3f getCoordFlash1() const {return mCoordFlash1; }

    Point3f getCoordFlash2() const {return mCoordFlash2; }

    //methodes
    void print() {
        std::cout<<"*******************************************Infos Calib*******************************************"<<std::endl;
        std::cout<<"Id de la BCAM : "<<getBCAM()<<std::endl;
        std::cout<<"Affichage des cordonnées du premier flash : "<<std::endl;
        this->getCoordFlash1().print();
        std::cout<<"Affichage des cordonnées du second flash : "<<std::endl;
        this->getCoordFlash2().print();
        std::cout<<"************************************************************************************************"<<std::endl;
    }

protected:
private:
    std::string mBCAM;
    Point3f mCoordFlash1;
    Point3f mCoordFlash2;
};

#endif // CALIB2_H
