#ifndef SOCKET_CLIENT_H
#define SOCKET_CLIENT_H

#include "call.h"
#include "callback.h"

class SocketClient : public Callback
{
public:
    SocketClient() {};
    ~SocketClient() {};

    void setServer(Call& callImpl) {};

    void setMode(QString mode) {};
    void updateAdepoStatus(QString status, int seconds) {};
    void updateLwdaqStatus(QString status, int seconds) {};
};

#endif // SOCKET_CLIENT_H
