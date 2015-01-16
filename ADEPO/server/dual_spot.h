#ifndef DUAL_SPOT_H
#define DUAL_SPOT_H

#include "iostream"
#include "bcam.h"
#include "spot.h"

class DualSpot
{
public:
    DualSpot(BCAM bcam, double i1, double j1, double i2, double j2) :
        mBCAM(bcam), mSpot1(Spot(bcam, i1, j1)), mSpot2(Spot(bcam, i2, j2)) {};
    virtual ~DualSpot() {};

    //setter et getter
    BCAM getBCAM() const { return mBCAM; }
    Prism getPrism() const { return mBCAM.getPrism(); }
    Spot getSpot1() const { return mSpot1; }
    Spot getSpot2() const { return mSpot2; }

    QString getName() const { return getBCAM().getName()+"_"+getPrism().getName(); }

    //methodes
    void print() {
        std::cout<<"*******************************************Coord Spots*******************************************"<<std::endl;
        std::cout<<"Nom de la BCAM : "<<getBCAM().getName().toStdString()<<std::endl;
        std::cout<<"Nom de la Prism : "<<getPrism().getName().toStdString()<<std::endl;
        std::cout<<"Coord spot 1 : "<<getSpot1().toString()<<std::endl;
        std::cout<<"Coord spot 2 : "<<getSpot2().toString()<<std::endl;
    }

protected:
private:
    BCAM mBCAM;
    Spot mSpot1;
    Spot mSpot2;
};

#endif // DUAL_SPOT_H
