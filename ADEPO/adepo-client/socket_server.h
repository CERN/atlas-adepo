#ifndef SOCKET_SERVER_H
#define SOCKET_SERVER_H

#include "call.h"
#include "callback.h"

class SocketServer : public Call
{
public:
    SocketServer(Callback& callback) {};
    ~SocketServer() {};

    void start();
    void stop();
};

#endif // SOCKET_SERVER_H
