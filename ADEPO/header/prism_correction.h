#ifndef PRISM_CORRECTION_H
#define PRISM_CORRECTION_H

#include "iostream"
#include "Point3f.h"

class prism_correction
{
public:
    prism_correction(std::string id, Point3f delta) : mId(id), mDelta(delta) {};
    virtual ~prism_correction() {};

    //setter et getter
    std::string getId() const {return mId;}

    Point3f getDelta() const {return mDelta;}

    //methodes
    void print() {
        std::cout<<"*******************************************Correction excentrement*******************************************"<<std::endl;
        std::cout<<"Identifiant du prisme : "<<getId()<<std::endl;
        std::cout<<"Valeur d'excentrement : "<<std::endl;
        getDelta().print();
    }

protected:
private:
    std::string mId;
    Point3f mDelta;
};

#endif // PRISM_CORRECTION_H
