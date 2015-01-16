#ifndef DETECTOR_H
#define DETECTOR_H

#include <iostream>

#include <QString>

class Detector {
public:
    Detector(int id, QString name, float airpad) : mId(id), mName(name), mAirpad(airpad) {}

    virtual ~Detector() {};

    int getId() const { return mId; }
    QString getName() const { return mName; }
    float getAirpad() const { return mAirpad; }

    void print() {
        std::cout<<"*******************************************//DETECTORS_DATA*******************************************"<<std::endl;
        std::cout<<"Numéro identifiant detecteur : "<<getId()<<std::endl;
        std::cout<<"Nom du detecteur : "<<getName().toStdString()<<std::endl;
        std::cout<<"Constante Airpad on :"<<getAirpad()<<std::endl;
    }

protected:
private:
    int mId;
    QString mName;
    float mAirpad;

};

#endif // DETECTOR_H
