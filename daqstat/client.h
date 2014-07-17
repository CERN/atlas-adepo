#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QtNetwork>

class Client : public QObject {

    Q_OBJECT

public:
    Client(QObject *parent = 0);
    void connectToHost();
    void runOnHost(int seconds);

private slots:
    void connected();
    void disconnected();
    void readStatus();
    void displayError(QAbstractSocket::SocketError socketError);
    void updateStatus();
    void stopRun();

private:
    void command(int no);
    void write(QString s);

    bool open;
    QTcpSocket *tcpSocket;
    QTimer *statusTimer;
    QTimer *runTimer;

    QStringList cmd;
    QStringList ret;
    int cmdNo;

    bool stopped;
    bool error;
    QString errorText;
};

#endif // CLIENT_H
