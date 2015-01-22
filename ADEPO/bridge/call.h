#ifndef CALL_H
#define CALL_H

#include "bridge.h"

#include <QString>

class Call: public Bridge
{
public:
    Call() {};
    ~Call() {};

    virtual void start(QString mode, int runTime, bool airpad) = 0;
    virtual void stop() = 0;
};

#endif // CALL_H
