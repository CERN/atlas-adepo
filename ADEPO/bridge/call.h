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

    virtual void update() = 0;
};

#endif // CALL_H
