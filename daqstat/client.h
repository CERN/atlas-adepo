#ifndef CLIENT_H
#define CLIENT_H

#include <QObject>
#include <QtNetwork>

class Client : public QObject {

    Q_OBJECT

public:
    enum state { UNSET, INIT, IDLE, RUN, STOP };    // last three states are set by LWDAQ Acquisifier

    Client(QString hostName, quint16 port, QObject *parent = 0);
    bool isConnected() { return currentState > INIT; }
    bool isIdle() { return currentState == IDLE; }
    state getState() { return currentState; }
    QString getStateAsString() {
        switch(getState()) {
        case UNSET: return "UNSET";
        case INIT: return "INIT";
        case IDLE: return "IDLE";
        case RUN: return "RUN";
        case STOP: return "STOP";
        default: return "Unknown State";
        }
    }

    bool startRun(QString dir = ".", int seconds = -1);

signals:
    void stateChanged();

public slots:
    void init();
    void stopRun();

private slots:
    void gotConnected();
    void gotDisconnected();
    void readStatus();
    void displayError(QAbstractSocket::SocketError socketError);
    void updateStatus();

private:
    const int DEFAULT_RUN_TIME = 30;
    const QString DEFAULT_PARAM_FILE = "Acquisifier_Params.tcl";
    const QString DEFAULT_SETTINGS_FILE = "Acquisifier_Settings.tcl";

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
