#include "socket_client.h"

SocketClient::SocketClient(Callback& callback, const QUrl &url, QObject *parent) :
    QObject(parent),
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
    webSocket.sendTextMessage(QStringLiteral("Hello, world!"));
}

void SocketClient::onTextMessageReceived(QString message)
{
    qDebug() << "Message received:" << message;
//    webSocket.close();
}

