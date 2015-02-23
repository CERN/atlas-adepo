#include <iostream>

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

#include "socket_client.h"
#include "json_rpc.h"

SocketClient::SocketClient(Callback& callback, const QUrl &url, QObject *parent) :
    QObject(parent),
    callback(callback),
    url(url)
{
    connect(&webSocket, &QWebSocket::connected, this, &SocketClient::onConnected);
//    connect(&webSocket, &QWebSocket::disconnected, this, &SocketClient::closed);
    webSocket.open(QUrl(url));
}

void SocketClient::onConnected()
{
    qDebug() << "WebSocket connected";
    connect(&webSocket, &QWebSocket::textMessageReceived, this, &SocketClient::onTextMessageReceived);
//    webSocket.sendTextMessage(QStringLiteral("Hello, world!"))

    update();
}

void SocketClient::onTextMessageReceived(QString message)
{
//    qDebug() << "Message received:" << message;
    QJsonDocument doc(QJsonDocument::fromJson(message.toUtf8()));
    QJsonObject json = doc.object();
    QString version = json["jsonrpc"].toString();
    QString method = json["method"].toString();
    if (method == "setMode") {
        QJsonArray params = json["params"].toArray();
        callback.setMode(params[0].toString());
    } else if (method == "setSelectedDetectors") {
        QJsonArray params = json["params"].toArray();
        callback.setSelectedDetectors(JsonRpc::fromIntArray(params[0].toArray()));
    } else if (method == "updateState") {
        QJsonArray params = json["params"].toArray();
        callback.updateState(params[0].toString(), params[1].toInt(), params[2].toString(), params[3].toInt());
    } else if (method == "updateConfigurationFile") {
        QJsonArray params = json["params"].toArray();
        callback.updateConfigurationFile(params[0].toString());
    } else if (method == "updateCalibrationFile") {
        QJsonArray params = json["params"].toArray();
        callback.updateCalibrationFile(params[0].toString());
    } else if (method == "updateReferenceFile") {
        QJsonArray params = json["params"].toArray();
        callback.updateReferenceFile(params[0].toString());
    } else if (method == "updateResultFile") {
        QJsonArray params = json["params"].toArray();
        callback.updateResultFile(params[0].toString());
    } else {
        std::cerr << "Unimplemented client rpc method: " << method.toStdString() << std::endl;
    }
}

void SocketClient::start() {
    JsonRpc rpc("start");
    sendJson(rpc);
}

void SocketClient::stop() {
    JsonRpc rpc("stop");
    sendJson(rpc);
}


void SocketClient::update() {
    JsonRpc rpc("update");
    sendJson(rpc);
}

void SocketClient::sendJson(QJsonObject o) {
    QJsonDocument doc(o);
    QByteArray json = doc.toJson();
    webSocket.sendTextMessage(json);
}

