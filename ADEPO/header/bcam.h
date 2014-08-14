#ifndef BCAM_H
#define BCAM_H

#include <iostream>

class BCAM
{
public:
    //constructeurs et destructeurs
    BCAM(std::string name, int detectorId, int driverSocket, int muxSocket, int numChip, std::string prisms) :
           mName(name), mDetectorId(detectorId), mDriverSocket(driverSocket), mMuxSocket(muxSocket), mNumChip(numChip), mPrisms(prisms) {};
    virtual ~BCAM() {};

    //setter et getter
    std::string getName() const { return mName; }

    int getDetectorId() const { return mDetectorId; }

    int getDriverSocket() const { return mDriverSocket; }

    int getMuxSocket() const { return mMuxSocket; }

    int getNumChip() const { return mNumChip; }

    std::string getPrisms() const { return mPrisms; }

    //methodes
    void print() {
        std::cout<<"*******************************************Infos BCAM*******************************************"<<std::endl;
        std::cout<<"Nom de la BCAM : "<<getName()<<std::endl;
        std::cout<<"Identifiant du detecteur auquel la BCAM appartient : "<<getDetectorId()<<std::endl;
        std::cout<<"Numéro du port Driver : "<<getDriverSocket()<<std::endl;
        std::cout<<"Numéro du port Multiplexer : "<<getMuxSocket()<<std::endl;
        std::cout<<"Objet visee : "<<getPrisms()<<std::endl;
        std::cout<<"Numero du chip : "<<getNumChip()<<std::endl;
        std::cout<<"************************************************************************************************"<<std::endl;
    }

protected:
private:
    std::string mName;
    int mDetectorId;
    int mDriverSocket;
    int mMuxSocket;
    int mNumChip;
    std::string mPrisms;
};

#endif // BCAM_H
