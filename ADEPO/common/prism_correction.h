#ifndef PRISM_CORRECTION_H
#define PRISM_CORRECTION_H

#include "iostream"
#include "point3d.h"

#include <QString>

class PrismCorrection
{
public:
    PrismCorrection(QString prism, Point3d delta) : mPrism(prism), mDelta(delta) {};
    virtual ~PrismCorrection() {};

    //setter et getter
    QString getPrism() const {return mPrism;}

    Point3d getDelta() const {return mDelta;}

    //methodes
    void print() {
        std::cout<<"*******************************************Correction excentrement*******************************************"<<std::endl;
        std::cout<<"Identifiant du prisme : "<<getPrism().toStdString()<<std::endl;
        std::cout<<"Valeur d'excentrement : "<<std::endl;
        getDelta().print();
    }

protected:
private:
    QString mPrism;
    Point3d mDelta;
};

#endif // PRISM_CORRECTION_H
