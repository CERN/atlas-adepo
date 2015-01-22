#include <iostream>

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonArray>

#include "socket_client.h"

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
//    webSocket.sendTextMessage(QStringLiteral("Hello, world!"));
}

void SocketClient::onTextMessageReceived(QString message)
{
    qDebug() << "Message received:" << message;
    QJsonDocument doc(QJsonDocument::fromJson(message.toUtf8()));
    QJsonObject json = doc.object();
    QString version = json["jsonrpc"].toString();
    QString method = json["method"].toString();
    if (method == "setMode") {
        QJsonArray params = json["params"].toArray();
        callback.setMode(params.at(0).toString());
    } else if (method == "updateStatus") {
        QJsonArray params = json["params"].toArray();
        callback.updateStatus(params.at(0).toString(), params.at(1).toInt(), params.at(2).toString(), params.at(3).toInt());
    } else {
        std::cerr << "Unimplemented rpc method: " << method.toStdString() << std::endl;
    }
}

void SocketClient::start(QString mode) {
    QJsonObject o;
    o["jsonrpc"] = "2.0";
    o["method"] = "start";
    QJsonArray p;
    p.append(mode);
    o["params"] = p;
    QJsonDocument doc(o);
    webSocket.sendTextMessage(doc.toJson());
}

void SocketClient::stop() {
    QJsonObject o;
    o["jsonrpc"] = "2.0";
    o["method"] = "stop";
    QJsonDocument doc(o);
    webSocket.sendTextMessage(doc.toJson());
}

