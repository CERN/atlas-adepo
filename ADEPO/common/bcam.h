#ifndef BCAM_H
#define BCAM_H

#include <iostream>

#include "prism.h"

class BCAM
{
public:
    //constructeurs et destructeurs
    BCAM(std::string name, int detectorId, int driverSocket, int muxSocket, Prism prism) :
           mName(name), mDetectorId(detectorId), mDriverSocket(driverSocket), mMuxSocket(muxSocket), mPrism(prism) {};
    virtual ~BCAM() {};

    //setter et getter
    std::string getName() const { return mName; }

    int getDetectorId() const { return mDetectorId; }

    int getDriverSocket() const { return mDriverSocket; }

    int getMuxSocket() const { return mMuxSocket; }

    Prism getPrism() const { return mPrism; }

    //methodes
    void print() {
        std::cout<<"*******************************************BCAM*******************************************"<<std::endl;
        std::cout<<"Nom de la BCAM : "<<getName()<<std::endl;
        std::cout<<"Identifiant du detecteur auquel la BCAM appartient : "<<getDetectorId()<<std::endl;
        std::cout<<"Numéro du port Driver : "<<getDriverSocket()<<std::endl;
        std::cout<<"Numéro du port Multiplexer : "<<getMuxSocket()<<std::endl;
        std::cout<<"Objet visee : "<<getPrism().getName()<<std::endl;
        std::cout<<"************************************************************************************************"<<std::endl;
    }

protected:
private:
    std::string mName;
    int mDetectorId;
    int mDriverSocket;
    int mMuxSocket;
    Prism mPrism;
};

#endif // BCAM_H
