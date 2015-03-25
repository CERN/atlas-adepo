#ifndef CALLBACK_H
#define CALLBACK_H

#include <QString>

#include "bridge.h"
#include "result.h"

#define CHANGED_STATE "ChangedState"
#define CHANGED_RUN "ChangedRun"
#define CHANGED_CONFIGURATION "ChangedConfiguration"
#define CHANGED_CALIBRATION "ChangedCalibration"
#define CHANGED_OFFSET "ChangedOffset"
#define CHANGED_REFERENCE "ChangedReference"
#define CHANGED_OUTPUT "ChangedOutput"
#define CHANGED_RESULTS "ChangedResults"

class Callback: public Bridge
{
public:
    Callback() {};
    ~Callback() {};

    virtual void changedState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds) = 0;

    virtual void changedRunFile(QString filename) = 0;
    virtual void changedConfigurationFile(QString filename) = 0;
    virtual void changedCalibrationFile(QString filename) = 0;
    virtual void changedOffsetFile(QString filename) = 0;
    virtual void changedReferenceFile(QString filename) = 0;
    virtual void changedOutputFile(QString filename) = 0;
    virtual void changedResultFile(QString filename) = 0;
};

#endif // CALLBACK_H
