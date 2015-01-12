#ifndef CALIB1_H
#define CALIB1_H

#include "point3f.h"

#include "iostream"

class Calib1
{
public:
    Calib1(std::string bcam, std::string tpsCalib, Point3f coordPivot, Point3f coordAxis, float ccdToPivot, float ccdRotation) :
        mBCAM(bcam), mTpsCalib(tpsCalib), mCoordPivot(coordPivot), mCoordAxis(coordAxis), mCcdToPivot(ccdToPivot), mCcdRotation(ccdRotation) {};
    virtual ~Calib1() {};

    //setter et getter
    std::string getBCAM() const { return mBCAM; }
    std::string getTpsCalib() const { return mTpsCalib; }
    Point3f getCoordPivot() const { return mCoordPivot; }
    Point3f getCoordAxis() const { return mCoordAxis; }
    int getDirection() const { return mCoordAxis.z() > 0 ? 1 : -1; }
    float getCcdToPivot() const { return mCcdToPivot; }
    float getCcdRotation() const { return mCcdRotation; }

    //methodes
    void print() {
        std::cout<<"*******************************************Infos Calib*******************************************"<<std::endl;
        std::cout<<"Id de la BCAM : "<<getBCAM()<<std::endl;
        std::cout<<"Date calibration : "<<getTpsCalib()<<std::endl;
        std::cout<<"Coordonnées du pivot : "<<std::endl;
        this->getCoordPivot().print();
        std::cout<<"Coordonnées de l'axe : "<<std::endl;
        this->getCoordAxis().print();
        std::cout<<"Distance du CCD au pivot: "<<getCcdToPivot()<<std::endl;
        std::cout<<"Rotation du CCD : "<<this->getCcdRotation()<<std::endl;
        std::cout<<"************************************************************************************************"<<std::endl;
    }

protected:
private:
    std::string mBCAM;
    std::string mTpsCalib;
    Point3f mCoordPivot;
    Point3f mCoordAxis;
    float mCcdToPivot;
    float mCcdRotation;
};

#endif // CALIB1_H
