#ifndef CALLBACK_H
#define CALLBACK_H

#include <string>

class CallBack
{
public:
    CallBack() {};
    ~CallBack() {};

    virtual void setMode(std::string mode) = 0;
    virtual void updateAdepoStatus(std::string status) = 0;
    virtual void updateLwdaqStatus(std::string status) = 0;
};

#endif // CALLBACK_H
