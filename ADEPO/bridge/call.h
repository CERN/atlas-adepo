#ifndef CALL_H
#define CALL_H

#include "bridge.h"

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

    virtual void updateRunFile() = 0;
    virtual void updateConfigurationFile() = 0;
    virtual void updateCalibrationFile() = 0;
    virtual void updateOffsetFile() = 0;
    virtual void updateReferenceFile() = 0;
    virtual void updateOutputFile() = 0;
    virtual void resetDelta() = 0;

    virtual void updateAll() = 0;
};

#endif // CALL_H
