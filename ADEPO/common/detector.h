#ifndef DETECTOR_H
#define DETECTOR_H

#include <iostream>

class Detector {
public:
    Detector(int id, std::string name, float airpad) : mId(id), mName(name), mAirpad(airpad) {}

    virtual ~Detector() {};

    int getId() const { return mId; }
    std::string getName() const { return mName; }
    float getAirpad() const { return mAirpad; }

    void print() {
        std::cout<<"*******************************************//DETECTORS_DATA*******************************************"<<std::endl;
        std::cout<<"Numéro identifiant detecteur : "<<getId()<<std::endl;
        std::cout<<"Nom du detecteur : "<<getName()<<std::endl;
        std::cout<<"Constante Airpad on :"<<getAirpad()<<std::endl;
    }

protected:
private:
    int mId;
    std::string mName;
    float mAirpad;

};

#endif // DETECTOR_H
