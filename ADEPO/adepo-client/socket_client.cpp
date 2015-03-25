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
    if (method == CHANGED_STATE) {
        QJsonArray params = json["params"].toArray();
        callback.changedState(params[0].toString(), params[1].toInt(), params[2].toString(), params[3].toInt());
    } else if (method == CHANGED_RUN) {
        QJsonArray params = json["params"].toArray();
        Run run;
        run.read(params[0].toObject());
        callback.changedRun(run);
    } else if (method == CHANGED_CONFIGURATION) {
        QJsonArray params = json["params"].toArray();
        callback.changedConfiguration(params[0].toString());
    } else if (method == CHANGED_CALIBRATION) {
        QJsonArray params = json["params"].toArray();
        callback.changedCalibration(params[0].toString());
    } else if (method == CHANGED_OFFSET) {
        QJsonArray params = json["params"].toArray();
        callback.changedOffset(params[0].toString());
    } else if (method == CHANGED_REFERENCE) {
        QJsonArray params = json["params"].toArray();
        callback.changedReference(params[0].toString());
    } else if (method == CHANGED_OUTPUT) {
        QJsonArray params = json["params"].toArray();
        callback.changedOutput(params[0].toString());
    } else if (method == CHANGED_RESULTS) {
        QJsonArray params = json["params"].toArray();
        callback.changedResult(params[0].toString());
    } else {
        qWarning() << "CLIENT Unimplemented client rpc method: " << method;
    }
}

void SocketClient::start() {
    JsonRpc rpc(START);
    sendJson(rpc);
}

void SocketClient::stop() {
    JsonRpc rpc(STOP);
    sendJson(rpc);
}

void SocketClient::updateCalibration() {
    JsonRpc rpc(UPDATE_CALIBRATION);
    sendJson(rpc);
}

void SocketClient::updateConfiguration() {
    JsonRpc rpc(UPDATE_CONFIGURATION);
    sendJson(rpc);
}

void SocketClient::updateOffset() {
    JsonRpc rpc(UPDATE_OFFSET);
    sendJson(rpc);
}

void SocketClient::updateReference() {
    JsonRpc rpc(UPDATE_OFFSET);
    sendJson(rpc);
}

void SocketClient::updateOutput() {
    JsonRpc rpc(UPDATE_OUTPUT);
    sendJson(rpc);
}

void SocketClient::updateRun(Run run) {
    JsonRpc rpc(UPDATE_RUN);
    QJsonObject json;
    run.write(json);
    rpc.append(json);
    sendJson(rpc);
}

void SocketClient::resetDelta() {
    JsonRpc rpc(RESET_DELTA);
    sendJson(rpc);
}

void SocketClient::updateAll() {
    JsonRpc rpc(UPDATE_ALL);
    sendJson(rpc);
}

void SocketClient::sendJson(QJsonObject o) {
    QJsonDocument doc(o);
    QByteArray json = doc.toJson();
    webSocket.sendTextMessage(json);
}

