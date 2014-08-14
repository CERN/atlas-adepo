#ifndef SPOT_H
#define SPOT_H

#include "iostream"
#include "bcam.h"

class spot
{
public:
    spot(std::string id, double i1CCD, double j1CCD, double i2CCD, double j2CCD) : mId(id), mI1CCD(i1CCD), mJ1CCD(j1CCD), mI2CCD(i2CCD), mJ2CCD(j2CCD) {};
    virtual ~spot() {};

    //setter et getter
    std::string getId() const { return mId; }
    double getI1CCD() const { return mI1CCD; }
    double getJ1CCD() const { return mJ1CCD; }
    double getI2CCD() const { return mI2CCD; }
    double getJ2CCD() const { return mJ2CCD; }

    //methodes
    void print() {
        std::cout<<"*******************************************Coord Spots*******************************************"<<std::endl;
        std::cout<<"Nom de la BCAM : "<<getId()<<std::endl;
        std::cout<<"Coord i1 : "<<getI1CCD()<<std::endl;
        std::cout<<"Coord j1 : "<<getJ1CCD()<<std::endl;
        std::cout<<"Coord i2 : "<<getI2CCD()<<std::endl;
        std::cout<<"Coord j2 : "<<getJ2CCD()<<std::endl;
    }

protected:
private:
    std::string mId;
    double mI1CCD;
    double mJ1CCD;
    double mI2CCD;
    double mJ2CCD;
};

#endif // SPOT_H
