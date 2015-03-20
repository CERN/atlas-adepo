#ifndef CALLBACK_H
#define CALLBACK_H

#include <vector>
#include <map>

#include <QString>

#include "bridge.h"
#include "result.h"

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
    virtual void changedResults(std::map<QString, Result> results) = 0;
};

#endif // CALLBACK_H
