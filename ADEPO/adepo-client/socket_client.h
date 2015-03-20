#ifndef SOCKET_CLIENT_H
#define SOCKET_CLIENT_H

#include <QString>
#include <QWebSocket>
#include <QUrl>
#include <QObject>
#include <QTimer>

#include <QJsonObject>

#include "call.h"
#include "callback.h"

#define RECONNECT_TIME 15

class SocketClient : public QObject, public Call
{
public:
    SocketClient(Callback& callback, const QUrl &url, QObject *parent = Q_NULLPTR);
    ~SocketClient() {};

    void start();
    void stop();
    void updateRunFile();
    void updateConfigurationFile();
    void updateCalibrationFile();
    void updateReferenceFile();
    void resetDelta();
    void updateAll();

Q_SIGNALS:
    void closed();

private Q_SLOTS:
    void onConnected();
    void socketDisconnected();
    void reconnect();
    void onTextMessageReceived(QString message);

private:
    void sendJson(QJsonObject o);

    Callback& callback;
    QUrl url;
    QWebSocket webSocket;
    QTimer* reconnectTimer;
};

#endif // SOCKET_CLIENT_H
