#ifndef BCAM_PARAMS_H
#define BCAM_PARAMS_H

#include "iostream"
#include "point3f.h"

class BCAMParams
{
public:
    BCAMParams(std::string bcam, Point3f translation, Point3f rotation) : mBCAM(bcam), mTranslation(translation), mRotation(rotation) {};

    virtual ~BCAMParams() {};

    //setter et getter
    std::string getBCAM() const {return mBCAM;}

    Point3f getTranslation() const {return mTranslation;}

    Point3f getRotation() const {return mRotation;}

    //methodes
    void print() {
        std::cout<<"*******************************************//BCAM_parametres*******************************************"<<std::endl;
        std::cout<<"Identifiant de la BCAM : "<<getBCAM()<<std::endl;
        std::cout<<"Translation : "<<std::endl;
        getTranslation().print();
        std::cout<<"Angles de rotation : "<<std::endl;
        getRotation().print();
    }

protected:
private:
    std::string mBCAM;
    Point3f mTranslation;
    Point3f mRotation;
};

#endif // BCAM_PARAMS_H
