#ifndef ABSOLUTE_DISTANCES_H
#define ABSOLUTE_DISTANCES_H

#include <iostream>

#include <QString>

#include "point3d.h"

class AbsoluteDistances
{
public:
    AbsoluteDistances(QString bcam, QString prism, Point3d distances) : mBCAM(bcam), mPrism(prism), mDistances(distances) {};
    virtual ~AbsoluteDistances() {};

   //setter et getter
    QString getBCAM() const {return mBCAM;}
    QString getPrism() const {return mPrism;}
    QString getName() const { return getBCAM()+"_"+getPrism(); }

    Point3d getDistances() const {return mDistances;}

    //methodes
    void print() {
        std::cout<<"*******************************************//ABSOLUTES_DISTANCES*******************************************"<<std::endl;
        std::cout<<"La distance est entre  : "<<getBCAM().toStdString()<<" "<<getPrism().toStdString()<<std::endl;
        std::cout<<"Les valeurs des distances : \n"<<std::endl;
        getDistances().print();
    }

protected:
private:
    QString mBCAM;
    QString mPrism;
    Point3d mDistances;
};

#endif // ABSOLUTE_DISTANCES_H
