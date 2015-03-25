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

    virtual void changedRun(QString filename) = 0;
    virtual void changedConfiguration(QString filename) = 0;
    virtual void changedCalibration(QString filename) = 0;
    virtual void changedOffset(QString filename) = 0;
    virtual void changedReference(QString filename) = 0;
    virtual void changedOutput(QString filename) = 0;
    virtual void changedResult(QString filename) = 0;
};

#endif // CALLBACK_H
