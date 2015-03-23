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
    connect(&webSocket, &QWebSocket::disconnected, this, &SocketClient::socketDisconnected);

    reconnectTimer = new QTimer(this);
    reconnectTimer->setSingleShot(true);
    reconnectTimer->setInterval(RECONNECT_TIME * 1000);
    connect(reconnectTimer, &QTimer::timeout, this, &SocketClient::reconnect);

    callback.changedState(ADEPO_CONNECTING, 0, LWDAQ_UNKNOWN, 0);

    webSocket.open(QUrl(url));
}

void SocketClient::onConnected()
{
    qDebug() << "CLIENT WebSocket connected";
    connect(&webSocket, &QWebSocket::textMessageReceived, this, &SocketClient::onTextMessageReceived);

    updateAll();
}

void SocketClient::socketDisconnected() {
    qDebug() << "CLIENT disconnected, reconnecting in " << RECONNECT_TIME << "s...";

    callback.changedState(ADEPO_CONNECTING, 0, LWDAQ_UNKNOWN, 0);

    reconnectTimer->start();
}

void SocketClient::reconnect() {
    webSocket.open(QUrl(url));
}

void SocketClient::onTextMessageReceived(QString message)
{
//    qDebug() << "CLIENT Message received:" << message;
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
    } else if (method == "changedResults") {
        QJsonArray params = json["params"].toArray();
        Result t;
        callback.changedResults(JsonUtil::fromJsonObject(params[0].toObject(), t));
    } else if (method == "changedResultFile") {
        QJsonArray params = json["params"].toArray();
        callback.changedResultFile(params[0].toString());
    } else {
        qWarning() << "CLIENT Unimplemented client rpc method: " << method;
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

void SocketClient::resetDelta() {
    JsonRpc rpc("resetDelta");
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

