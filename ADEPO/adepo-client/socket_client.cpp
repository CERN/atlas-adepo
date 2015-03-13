#include <iostream>

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

#include "socket_client.h"
#include "json_rpc.h"
#include "json_util.h"

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

    updateAll();
}

void SocketClient::onTextMessageReceived(QString message)
{
//    qDebug() << "Message received:" << message;
    QJsonDocument doc(QJsonDocument::fromJson(message.toUtf8()));
    QJsonObject json = doc.object();
    QString version = json["jsonrpc"].toString();
    QString method = json["method"].toString();
    if (method == "changedState") {
        QJsonArray params = json["params"].toArray();
        callback.changedState(params[0].toString(), params[1].toInt(), params[2].toString(), params[3].toInt());
    } else if (method == "changedRunFile") {
        QJsonArray params = json["params"].toArray();
        callback.changedRunFile(params[0].toString());
    } else if (method == "changedConfigurationFile") {
        QJsonArray params = json["params"].toArray();
        callback.changedConfigurationFile(params[0].toString());
    } else if (method == "changedCalibrationFile") {
        QJsonArray params = json["params"].toArray();
        callback.changedCalibrationFile(params[0].toString());
    } else if (method == "changedReferenceFile") {
        QJsonArray params = json["params"].toArray();
        callback.changedReferenceFile(params[0].toString());
    } else if (method == "changedResultFile") {
        QJsonArray params = json["params"].toArray();
        callback.changedResultFile(params[0].toString());
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

void SocketClient::updateCalibrationFile() {
    JsonRpc rpc("updateCalibrationFile");
    sendJson(rpc);
}

void SocketClient::updateConfigurationFile() {
    JsonRpc rpc("updateConfigurationFile");
    sendJson(rpc);
}

void SocketClient::updateReferenceFile() {
    JsonRpc rpc("updateReferenceFile");
    sendJson(rpc);
}

void SocketClient::updateRunFile() {
    JsonRpc rpc("updateRunFile");
    sendJson(rpc);
}

void SocketClient::updateAll() {
    JsonRpc rpc("updateAll");
    sendJson(rpc);
}

void SocketClient::sendJson(QJsonObject o) {
    QJsonDocument doc(o);
    QByteArray json = doc.toJson();
    webSocket.sendTextMessage(json);
}

