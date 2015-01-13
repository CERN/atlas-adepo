#ifndef CALL_H
#define CALL_H

class Call
{
public:
    Call() {};
    ~Call() {};

    virtual void start() = 0;
    virtual void stop() = 0;
};

#endif // CALL_H
