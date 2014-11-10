#ifndef SPOT_H
#define SPOT_H

#include "iostream"
#include "bcam.h"

class Spot
{
public:
    Spot(std::string bcam, std::string prism, double i1CCD, double j1CCD, double i2CCD, double j2CCD) : mBCAM(bcam), mPrism(prism), mI1CCD(i1CCD), mJ1CCD(j1CCD), mI2CCD(i2CCD), mJ2CCD(j2CCD) {};
    virtual ~Spot() {};
};

#endif // SPOT_H

