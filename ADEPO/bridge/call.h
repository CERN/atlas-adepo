#ifndef CALL_H
#define CALL_H

#include "bridge.h"
#include "run.h"

#include <QString>

#define START "Start"
#define STOP "Stop"
#define UPDATE_RUN "UpdateRun"
#define UPDATE_CONFIGURATION "UpdateConfiguration"
#define UPDATE_CALIBRATION "UpdateCalibration"
#define UPDATE_OFFSET "UpdateOffset"
#define UPDATE_REFERENCE "UpdateReference"
#define UPDATE_OUTPUT "UpdateOutput"
#define UPDATE_RESULTS "UpdateResults"
#define RESET_DELTA "ResetDelta"
#define UPDATE_ALL "UpdateAll"

class Call: public Bridge
{
public:
    Call() {};
    ~Call() {};

    virtual void start() = 0;
    virtual void stop() = 0;

    virtual void updateRun(Run run) = 0;
    virtual void updateConfiguration() = 0;
    virtual void updateCalibration() = 0;
    virtual void updateOffset() = 0;
    virtual void updateReference() = 0;
    virtual void updateOutput() = 0;
    virtual void resetDelta() = 0;

    virtual void updateAll() = 0;
};

#endif // CALL_H
