#ifndef CALLBACK_H
#define CALLBACK_H

#include <QString>

#include "bridge.h"

class Callback: public Bridge
{
public:
    Callback() {};
    ~Callback() {};

    virtual void setMode(QString mode) = 0;
    virtual void updateStatus(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds) = 0;
};

#endif // CALLBACK_H
