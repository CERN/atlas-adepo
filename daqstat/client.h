#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QtNetwork>

class Client : public QObject {

    Q_OBJECT

public:
    enum state { INIT, READY, RUNNING };

    Client(QString hostName, quint16 port, QObject *parent = 0);
    bool isConnected() { return currentState == READY || currentState == RUNNING; }
    bool isReady() { return currentState == READY; }
    state getState() { return currentState; }
    bool startRun(int seconds);

signals:
    void stateChanged();

public slots:
    void connectToHost();
    void stopRun();

private slots:
    void gotConnected();
    void gotDisconnected();
    void readStatus();
    void displayError(QAbstractSocket::SocketError socketError);
    void updateStatus();

private:
    void stateChange(state newState);
    void command(int no);
    void write(QString s);

    QString hostName;
    quint16 portNo;

    QTcpSocket *tcpSocket;
    QTimer *connectTimer;
    QTimer *statusTimer;
    QTimer *runTimer;

    state currentState;

    QStringList cmd;
    QStringList ret;
    int cmdNo;

    bool error;
    QString errorText;
};

#endif // CLIENT_H
