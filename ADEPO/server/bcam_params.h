#ifndef BCAM_PARAMS_H
#define BCAM_PARAMS_H

#include "iostream"
#include "point3d.h"

#include <QString>

class BCAMParams
{
public:
    BCAMParams(QString bcam, Point3d translation, Point3d rotation) : mBCAM(bcam), mTranslation(translation), mRotation(rotation) {};

    virtual ~BCAMParams() {};

    //setter et getter
    QString getBCAM() const {return mBCAM;}

    Point3d getTranslation() const {return mTranslation;}

    Point3d getRotation() const {return mRotation;}

    //methodes
    void print() {
        std::cout<<"*******************************************//BCAM_parametres*******************************************"<<std::endl;
        std::cout<<"Identifiant de la BCAM : "<<getBCAM().toStdString()<<std::endl;
        std::cout<<"Translation : "<<std::endl;
        getTranslation().print();
        std::cout<<"Angles de rotation : "<<std::endl;
        getRotation().print();
    }

protected:
private:
    QString mBCAM;
    Point3d mTranslation;
    Point3d mRotation;
};

#endif // BCAM_PARAMS_H
