#ifndef SOCKET_SERVER_H
#define SOCKET_SERVER_H

#include <QByteArray>
#include <QObject>
#include <QList>
#include <QWebSocket>
#include <QJsonObject>

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

    void setMode(QString mode);
    void updateStatus(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds);

Q_SIGNALS:
    void closed();

private Q_SLOTS:
    void onNewConnection();
    void processTextMessage(QString message);
    void processBinaryMessage(QByteArray message);
    void socketDisconnected();

private:
    void sendJson(QJsonObject o);

    QWebSocketServer *webSocketServer;
    QList<QWebSocket *> clients;
    Call* call;
};

#endif // SOCKET_SERVER_H
