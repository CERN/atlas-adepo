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

    virtual void changedState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds) = 0;

    virtual void changedRunFile(QString filename) = 0;
    virtual void changedConfigurationFile(QString filename) = 0;
    virtual void changedCalibrationFile(QString filename) = 0;
    virtual void changedReferenceFile(QString filename) = 0;
    virtual void changedResultFile(QString filename) = 0;
};

#endif // CALLBACK_H
