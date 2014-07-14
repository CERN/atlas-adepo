#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QtNetwork>

class Client : public QObject {

    Q_OBJECT

public:
    Client(QObject *parent = 0);
    void getStatus();

private slots:
    void connected();
    void disconnected();
    void readStatus();
    void displayError(QAbstractSocket::SocketError socketError);

private:
    QTcpSocket *tcpSocket;
};

#endif // CLIENT_H
