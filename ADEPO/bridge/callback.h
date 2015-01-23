#ifndef CALLBACK_H
#define CALLBACK_H

#include <vector>

#include <QString>

#include "bridge.h"

class Callback: public Bridge
{
public:
    Callback() {};
    ~Callback() {};

    virtual void setMode(QString mode) = 0;
    virtual void setSelectedDetectors(std::vector<int> detectors) = 0;

    virtual void updateState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds) = 0;
    virtual void updateConfigurationFile(QString filename) = 0;
    virtual void updateCalibrationFile(QString filename) = 0;
    virtual void updateReferenceFile(QString filename) = 0;
    virtual void updateResultFile(QString filename) = 0;
};

#endif // CALLBACK_H
