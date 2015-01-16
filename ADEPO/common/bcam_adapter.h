#ifndef BCAM_ADAPTER_H
#define BCAM_ADAPTER_H

#include "iostream"
#include "point3f.h"

#include <QString>

class BCAMAdapter
{
public:
    BCAMAdapter(QString typeBCAM, QString target, Point3f targetCoord) : mTypeBCAM(typeBCAM), mTarget(target), mTargetCoord(targetCoord) {};
    virtual ~BCAMAdapter() {};

    //setter et getter
    QString getTypeBCAM() const {return mTypeBCAM;}

    QString getTarget() const {return mTarget;}

    Point3f getTargetCoord() const {return mTargetCoord;}

    //methodes
    void print() {
        std::cout<<"*******************************************//BCAM_ADAPTATEUR*******************************************"<<std::endl;
        std::cout<<"Type de la BCAM : "<<getTypeBCAM().toStdString()<<std::endl;
        std::cout<<"Id de la cible : "<<getTarget().toStdString()<<std::endl;
        std::cout<<"Coordonnees : "<<std::endl;
        this->getTargetCoord().print();
    }

protected:
private:
    QString mTypeBCAM;
    QString mTarget;
    Point3f mTargetCoord;
};

#endif // BCAM_ADAPTER_H
