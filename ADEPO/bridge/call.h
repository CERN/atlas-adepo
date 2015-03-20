#ifndef CALL_H
#define CALL_H

#include "bridge.h"

#include <QString>

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
    virtual void updateReferenceFile() = 0;
    virtual void resetDelta() = 0;

    virtual void updateAll() = 0;
};

#endif // CALL_H
