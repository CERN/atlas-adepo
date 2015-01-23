#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

#include "socket_server.h"
#include "json_rpc.h"

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
        call->start(params[0].toString(), params[1].toInt(), params[2].toBool(), JsonRpc::fromIntArray(params[3].toArray()));
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
    JsonRpc rpc("setMode");
    rpc.append(mode);
    sendJson(rpc);
}

void SocketServer::setSelectedDetectors(std::vector<int> detectors) {
    JsonRpc rpc("setSelectedDetectors");
    rpc.append(rpc.toIntArray(detectors));
    sendJson(rpc);
}

void SocketServer::updateState(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds) {
    JsonRpc rpc("updateState");
    rpc.append(adepoStatus);
    rpc.append(adepoSeconds);
    rpc.append(lwdaqStatus);
    rpc.append(lwdaqSeconds);
    sendJson(rpc);
}

void SocketServer::updateConfigurationFile(QString filename) {
    JsonRpc rpc("updateConfigurationFile");
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::updateCalibrationFile(QString filename) {
    JsonRpc rpc("updateCalibrationFile");
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::updateReferenceFile(QString filename) {
    JsonRpc rpc("updateReferenceFile");
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::updateResultFile(QString filename) {
    JsonRpc rpc("updateResultFile");
    rpc.append(filename);
    sendJson(rpc);
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

