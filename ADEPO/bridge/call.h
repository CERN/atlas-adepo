#ifndef CALL_H
#define CALL_H

#include "bridge.h"

class Call: public Bridge
{
public:
    Call() {};
    ~Call() {};

    virtual void start() = 0;
    virtual void stop() = 0;
};

#endif // CALL_H
