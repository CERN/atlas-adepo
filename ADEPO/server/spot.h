#ifndef SPOT_H
#define SPOT_H

#include "iostream"
#include "bcam.h"

class Spot
{
public:
    Spot(BCAM bcam, double i, double j) : mBCAM(bcam), mI(i), mJ(j) {};
    virtual ~Spot() {};

    BCAM getBCAM() const { return mBCAM; }
    double i() const { return mI; }
    double j() const { return mJ; }
    std::string toString() const { return "tbd"; }

private:
    BCAM mBCAM;
    double mI, mJ;
};

#endif // SPOT_H

