#ifndef CALIB1_H
#define CALIB1_H

#include "point3d.h"
#include "iostream"

#include <QString>

class Calib1
{
public:
    Calib1(QString bcam, QString tpsCalib, Point3d coordPivot, Point3d coordAxis, float ccdToPivot, float ccdRotation) :
        mBCAM(bcam), mTpsCalib(tpsCalib), mCoordPivot(coordPivot), mCoordAxis(coordAxis), mCcdToPivot(ccdToPivot), mCcdRotation(ccdRotation) {};
    virtual ~Calib1() {};

    //setter et getter
    QString getBCAM() const { return mBCAM; }
    QString getTpsCalib() const { return mTpsCalib; }
    Point3d getCoordPivot() const { return mCoordPivot; }
    Point3d getCoordAxis() const { return mCoordAxis; }
    int getDirection() const { return mCoordAxis.z() > 0 ? 1 : -1; }
    float getCcdToPivot() const { return mCcdToPivot; }
    float getCcdRotation() const { return mCcdRotation; }

    //methodes
    void print() {
        std::cout<<"*******************************************Infos Calib*******************************************"<<std::endl;
        std::cout<<"Id de la BCAM : "<<getBCAM().toStdString()<<std::endl;
        std::cout<<"Date calibration : "<<getTpsCalib().toStdString()<<std::endl;
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
    QString mBCAM;
    QString mTpsCalib;
    Point3d mCoordPivot;
    Point3d mCoordAxis;
    float mCcdToPivot;
    float mCcdRotation;
};

#endif // CALIB1_H
