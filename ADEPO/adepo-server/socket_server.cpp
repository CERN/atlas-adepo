#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

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
    processBinaryMessage(message.toUtf8());
}

void SocketServer::processBinaryMessage(QByteArray message)
{
    QJsonDocument doc(QJsonDocument::fromJson(message));
    QJsonObject json = doc.object();
    QString version = json["jsonrpc"].toString();
    QString method = json["method"].toString();
    if (method == "start") {
        QJsonArray params = json["params"].toArray();
        call->start(params[0].toString(), params[1].toInt(), params[2].toBool());
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


void SocketServer::setMode(QString mode) {
    QJsonObject o;
    o["jsonrpc"] = "2.0";
    o["method"] = "setMode";
    QJsonArray p;
    p.append(mode);
    o["params"] = p;
    sendJson(o);
}

void SocketServer::updateStatus(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds) {
    QJsonObject o;
    o["jsonrpc"] = "2.0";
    o["method"] = "updateStatus";
    QJsonArray p;
    p.append(adepoStatus);
    p.append(adepoSeconds);
    p.append(lwdaqStatus);
    p.append(lwdaqSeconds);
    o["params"] = p;
    sendJson(o);
}

void SocketServer::sendJson(QJsonObject o) {
    QJsonDocument doc(o);
    QByteArray json = doc.toJson();
    QList<QWebSocket*>::iterator client = clients.begin();
    while (client != clients.end()) {
        (*client)->sendTextMessage(json);
        ++client;
    }
}

