#ifndef PRISM_CORRECTION_H
#define PRISM_CORRECTION_H

#include "iostream"
#include "point3f.h"

class PrismCorrection
{
public:
    PrismCorrection(std::string prism, Point3f delta) : mPrism(prism), mDelta(delta) {};
    virtual ~PrismCorrection() {};

    //setter et getter
    std::string getPrism() const {return mPrism;}

    Point3f getDelta() const {return mDelta;}

    //methodes
    void print() {
        std::cout<<"*******************************************Correction excentrement*******************************************"<<std::endl;
        std::cout<<"Identifiant du prisme : "<<getPrism()<<std::endl;
        std::cout<<"Valeur d'excentrement : "<<std::endl;
        getDelta().print();
    }

protected:
private:
    std::string mPrism;
    Point3f mDelta;
};

#endif // PRISM_CORRECTION_H
