#ifndef BCAM_PARAMS_H
#define BCAM_PARAMS_H

#include "iostream"
#include "Point3f.h"

class BCAM_params
{
public:
    BCAM_params(std::string id, Point3f translation, Point3f rotation) : mId(id), mTranslation(translation), mRotation(rotation) {};

    virtual ~BCAM_params() {};

    //setter et getter
    std::string getId() const {return mId;}

    Point3f getTranslation() const {return mTranslation;}

    Point3f getRotation() const {return mRotation;}

    //methodes
    void print() {
        std::cout<<"*******************************************//BCAM_parametres*******************************************"<<std::endl;
        std::cout<<"Identifiant de la BCAM : "<<getId()<<std::endl;
        std::cout<<"Translation : "<<std::endl;
        getTranslation().print();
        std::cout<<"Angles de rotation : "<<std::endl;
        getRotation().print();
    }

protected:
private:
    std::string mId;
    Point3f mTranslation;
    Point3f mRotation;
};

#endif // BCAM_PARAMS_H
