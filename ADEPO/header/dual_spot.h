#ifndef DUAL_SPOT_H
#define DUAL_SPOT_H

#include "iostream"
#include "bcam.h"

class DualSpot
{
public:
    DualSpot(BCAM* bcam, double i1CCD, double j1CCD, double i2CCD, double j2CCD) :
        mBCAM(bcam), mI1CCD(i1CCD), mJ1CCD(j1CCD), mI2CCD(i2CCD), mJ2CCD(j2CCD) {};
    virtual ~DualSpot() {};

    //setter et getter
    BCAM* getBCAM() const { return mBCAM; }
    Prism getPrism() const { return mBCAM->getPrism(); }
    double getI1CCD() const { return mI1CCD; }
    double getJ1CCD() const { return mJ1CCD; }
    double getI2CCD() const { return mI2CCD; }
    double getJ2CCD() const { return mJ2CCD; }

    std::string getName() const { return getBCAM()->getName()+"_"+getPrism().getName(); }

    //methodes
    void print() {
        std::cout<<"*******************************************Coord Spots*******************************************"<<std::endl;
        std::cout<<"Nom de la BCAM : "<<getBCAM()->getName()<<std::endl;
        std::cout<<"Nom de la Prism : "<<getPrism().getName()<<std::endl;
        std::cout<<"Coord i1 : "<<getI1CCD()<<std::endl;
        std::cout<<"Coord j1 : "<<getJ1CCD()<<std::endl;
        std::cout<<"Coord i2 : "<<getI2CCD()<<std::endl;
        std::cout<<"Coord j2 : "<<getJ2CCD()<<std::endl;
    }

protected:
private:
    BCAM* mBCAM;
    double mI1CCD;
    double mJ1CCD;
    double mI2CCD;
    double mJ2CCD;
};

#endif // DUAL_SPOT_H
