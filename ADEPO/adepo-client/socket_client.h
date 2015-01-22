#ifndef SOCKET_CLIENT_H
#define SOCKET_CLIENT_H

#include <QString>
#include <QWebSocket>
#include <QUrl>
#include <QObject>

#include "call.h"
#include "callback.h"

class SocketClient : public QObject, public Call
{
public:
    SocketClient(Callback& callback, const QUrl &url, QObject *parent = Q_NULLPTR);
    ~SocketClient() {};

    void start(QString mode, int runTime, bool airpad);
    void stop();

Q_SIGNALS:
    void closed();

private Q_SLOTS:
    void onConnected();
    void onTextMessageReceived(QString message);

private:
    Callback& callback;
    QUrl url;
    QWebSocket webSocket;
};

#endif // SOCKET_CLIENT_H
