#ifndef BCAM_ADAPTER_H
#define BCAM_ADAPTER_H

#include "iostream"
#include "point3f.h"

class BCAMAdapter
{
public:
    BCAMAdapter(std::string typeBCAM, std::string target, Point3f targetCoord) : mTypeBCAM(typeBCAM), mTarget(target), mTargetCoord(targetCoord) {};
    virtual ~BCAMAdapter() {};

    //setter et getter
    std::string getTypeBCAM() const {return mTypeBCAM;}

    std::string getTarget() const {return mTarget;}

    Point3f getTargetCoord() const {return mTargetCoord;}

    //methodes
    void print() {
        std::cout<<"*******************************************//BCAM_ADAPTATEUR*******************************************"<<std::endl;
        std::cout<<"Type de la BCAM : "<<getTypeBCAM()<<std::endl;
        std::cout<<"Id de la cible : "<<getTarget()<<std::endl;
        std::cout<<"Coordonnees : "<<std::endl;
        this->getTargetCoord().print();
    }

protected:
private:
    std::string mTypeBCAM;
    std::string mTarget;
    Point3f mTargetCoord;
};

#endif // BCAM_ADAPTER_H
