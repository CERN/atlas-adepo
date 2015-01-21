#ifndef SOCKET_SERVER_H
#define SOCKET_SERVER_H

#include <QByteArray>
#include <QObject>
#include <QList>
#include <QWebSocket>
#include <iostream>

#include <QWebSocketServer>

#include "call.h"
#include "callback.h"

class SocketServer : public QObject, public Callback
{
public:
    SocketServer(quint16 port, QObject *parent = Q_NULLPTR);
    ~SocketServer();

    void setServer(Call& call) { this->call = &call; }

    void setMode(QString mode) {};
    void updateAdepoStatus(QString status, int seconds) {};
    void updateLwdaqStatus(QString status, int seconds) {};

Q_SIGNALS:
    void closed();

private Q_SLOTS:
    void onNewConnection();
    void processTextMessage(QString message);
    void processBinaryMessage(QByteArray message);
    void socketDisconnected();

private:
    QWebSocketServer *webSocketServer;
    QList<QWebSocket *> clients;
    Call* call;
};

#endif // SOCKET_SERVER_H
