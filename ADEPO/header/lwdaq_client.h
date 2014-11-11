#ifndef LWDAQ_CLIENT_H
#define LWDAQ_CLIENT_H

#include <QObject>
#include <QtNetwork>

#define SLOW_UPDATE_TIME 10
#define FAST_UPDATE_TIME 2
#define RECONNECT_TIME 15
#define DEFAULT_UPDATE_TIME 1

#define DEFAULT_RUN_TIME 30
#define DEFAULT_PARAM_FILE "Acquisifier_Params.tcl"
#define DEFAULT_SETTINGS_FILE "Acquisifier_Settings.tcl"
#define DEFAULT_RESULTS_FILE "Acquisifier_Results.tcl"
#define DEFAULT_SCRIPT_FILE "Acquisifier_Script.tcl"

class LWDAQ_Client : public QObject {

    Q_OBJECT

public:
    enum state { UNSET, INIT, IDLE, RUN, STOP };    // last three states are set by LWDAQ Acquisifier

    LWDAQ_Client(QString hostName, quint16 port, QObject *parent = 0);
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
    int getRemainingTime() {
        return runTimer->remainingTime();
    }

    QDir find(QDir dir);
    bool startRun(QString dir = ".", int seconds = -1);

signals:
    void stateChanged();
    void remainingTimeChanged();

public slots:
    void init();
    void stopRun();

private slots:
    void gotConnected();
    void gotDisconnected();
    void readStatus();
    void displayError(QAbstractSocket::SocketError socketError);
    void updateStatus();
    void updateRemainingTime();

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
    QTimer *updateTimer;

    state currentState;

    QStringList cmd;
    QStringList ret;
    int cmdNo;
    bool redirect;

    bool error;
    QString errorText;
};

#endif // LWDAQ_CLIENT_H
