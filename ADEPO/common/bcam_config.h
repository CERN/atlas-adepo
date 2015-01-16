#ifndef BCAM_CONFIG_H
#define BCAM_CONFIG_H

#include <iostream>

#include "prism.h"

#include <QString>

class BCAMConfig
{
public:
    //constructeurs et destructeurs
    BCAMConfig(QString name, int detectorId, int driverSocket, int muxSocket, std::vector<Prism> prisms) :
           mName(name), mDetectorId(detectorId), mDriverSocket(driverSocket), mMuxSocket(muxSocket), mPrisms(prisms) {};
    virtual ~BCAMConfig() {};

    //setter et getter
    QString getName() const { return mName; }

    int getDetectorId() const { return mDetectorId; }

    int getDriverSocket() const { return mDriverSocket; }

    int getMuxSocket() const { return mMuxSocket; }

    std::vector<Prism> getPrisms() const { return mPrisms; }

    QString getPrismsAsString() {
        QString s;
        for (unsigned int i = 0; i < mPrisms.size(); i++) {
            if (i > 0) {
                s.append("_");
            }
            s.append(mPrisms[i].getName());
        }
        return s;
    }

    //methodes
    void print() {
        std::cout<<"*******************************************Infos BCAM*******************************************"<<std::endl;
        std::cout<<"Nom de la BCAM : "<<getName().toStdString()<<std::endl;
        std::cout<<"Identifiant du detecteur auquel la BCAM appartient : "<<getDetectorId()<<std::endl;
        std::cout<<"Numéro du port Driver : "<<getDriverSocket()<<std::endl;
        std::cout<<"Numéro du port Multiplexer : "<<getMuxSocket()<<std::endl;
//        std::cout<<"Objet visee : "<<getPrisms()<<std::endl;
        std::cout<<"************************************************************************************************"<<std::endl;
    }

protected:
private:
    QString mName;
    int mDetectorId;
    int mDriverSocket;
    int mMuxSocket;
    std::vector<Prism> mPrisms;
};

#endif // BCAM_CONFIG_H
