#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

#include "socket_server.h"
#include "json_rpc.h"
#include "json_util.h"

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
//    qDebug() << message;
    QJsonDocument doc(QJsonDocument::fromJson(message));
    QJsonObject json = doc.object();
    QString version = json["jsonrpc"].toString();
    QString method = json["method"].toString();
    if (method == START) {
        QJsonArray params = json["params"].toArray();
        call->start();
    } else if (method == STOP) {
        call->stop();
    } else if (method == UPDATE_RUN) {
        call->updateRunFile();
    } else if (method == UPDATE_CALIBRATION) {
        call->updateCalibrationFile();
    } else if (method == UPDATE_CONFIGURATION) {
        call->updateConfigurationFile();
    } else if (method == UPDATE_OFFSET) {
        call->updateOffsetFile();
    } else if (method == UPDATE_REFERENCE) {
        call->updateReferenceFile();
    } else if (method == UPDATE_OUTPUT) {
        call->updateOutputFile();
    } else if (method == RESET_DELTA) {
        call->resetDelta();
    } else if (method == UPDATE_ALL) {
        call->updateAll();
    } else {
        std::cerr << "Unimplemented server rpc method: " << method.toStdString() << std::endl;
    }
}

void SocketServer::socketDisconnected()
{
    qDebug() << "SERVER Disconnected !";
    QWebSocket *client = qobject_cast<QWebSocket *>(sender());
    if (client) {
        clients.removeAll(client);
        client->deleteLater();
    }
}


void SocketServer::changedRunFile(QString filename) {
    JsonRpc rpc(CHANGED_RUN);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::changedState(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds) {
    JsonRpc rpc(CHANGED_STATE);
    rpc.append(adepoStatus);
    rpc.append(adepoSeconds);
    rpc.append(lwdaqStatus);
    rpc.append(lwdaqSeconds);
    sendJson(rpc);
}

void SocketServer::changedConfigurationFile(QString filename) {
    JsonRpc rpc(CHANGED_CONFIGURATION);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::changedCalibrationFile(QString filename) {
    JsonRpc rpc(CHANGED_CALIBRATION);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::changedOffsetFile(QString filename) {
    JsonRpc rpc(CHANGED_OFFSET);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::changedReferenceFile(QString filename) {
    JsonRpc rpc(CHANGED_REFERENCE);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::changedOutputFile(QString filename) {
    JsonRpc rpc(CHANGED_OUTPUT);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::changedResultFile(QString filename) {
    JsonRpc rpc(CHANGED_RESULTS);
    rpc.append(filename);
    sendJson(rpc);
}

void SocketServer::sendJson(QJsonObject o) {
    QJsonDocument doc(o);
    QByteArray json = doc.toJson();
    QList<QWebSocket*>::iterator client = clients.begin();
    while (client != clients.end()) {
        (*client)->sendTextMessage(json);
        (*client)->flush();
        ++client;
    }
}

