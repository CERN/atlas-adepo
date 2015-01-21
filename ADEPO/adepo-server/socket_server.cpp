#include <QJsonDocument>
#include <QJsonObject>

#include "socket_server.h"

SocketServer::SocketServer(quint16 port, QObject *parent) :
    QObject(parent),
    webSocketServer(new QWebSocketServer(QStringLiteral("ADEPO WebSocket Server"),
                                         QWebSocketServer::NonSecureMode, this)),
    clients()
{
    if (webSocketServer->listen(QHostAddress::Any, port)) {
        qDebug() << "ADEPO WebSocket Server listening on port" << port;
        connect(webSocketServer, &QWebSocketServer::newConnection, this, &SocketServer::onNewConnection);
//        connect(webSocketServer, &QWebSocketServer::closed, this, &SocketServer::closed);
    }
}

SocketServer::~SocketServer()
{
    webSocketServer->close();
    qDeleteAll(clients.begin(), clients.end());
}

void SocketServer::onNewConnection()
{
    QWebSocket *socket = webSocketServer->nextPendingConnection();

    connect(socket, &QWebSocket::textMessageReceived, this, &SocketServer::processTextMessage);
    connect(socket, &QWebSocket::binaryMessageReceived, this, &SocketServer::processBinaryMessage);
    connect(socket, &QWebSocket::disconnected, this, &SocketServer::socketDisconnected);

    clients << socket;
}

void SocketServer::processTextMessage(QString message)
{
    QWebSocket *client = qobject_cast<QWebSocket *>(sender());
    if (client) {
//        client->sendTextMessage(message);
    }
}

void SocketServer::processBinaryMessage(QByteArray message)
{
    QJsonDocument doc(QJsonDocument::fromJson(message));
    QJsonObject json = doc.object();
    QString version = json["jsonrpc"].toString();
    QString method = json["method"].toString();
    if (method == "start") {
        call->start();
    } else if (method == "stop") {
        call->stop();
    } else {
        std::cerr << "Unimplemented rpc method: " << method.toStdString() << std::endl;
    }
}

void SocketServer::socketDisconnected()
{
    QWebSocket *client = qobject_cast<QWebSocket *>(sender());
    if (client) {
        clients.removeAll(client);
        client->deleteLater();
    }
}
