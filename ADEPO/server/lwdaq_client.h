#ifndef LWDAQ_CLIENT_H
#define LWDAQ_CLIENT_H

#include <QObject>
#include <QtNetwork>
#include <QString>

#include "bridge.h"

#define SLOW_UPDATE_TIME 10
#define FAST_UPDATE_TIME 2
#define RECONNECT_TIME 15
#define DEFAULT_UPDATE_TIME 1

#define DEFAULT_RUN_TIME 45
#define DEFAULT_PARAM_FILE "Acquisifier_Params.tcl"
#define DEFAULT_SETTINGS_FILE "Acquisifier_Settings.tcl"
#define DEFAULT_RESULTS_FILE "Acquisifier_Results.txt"
#define DEFAULT_SCRIPT_FILE "Acquisifier_Script.tcl"

class LWDAQ_Client : public QObject {

    Q_OBJECT

public:

    LWDAQ_Client(QString hostName, quint16 port, QObject *parent = 0);
    bool isConnected() { return (currentState != LWDAQ_IDLE) && (currentState != LWDAQ_INIT); }
    bool isIdle() { return currentState == LWDAQ_IDLE; }
    QString getState() { return currentState; }
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
    void stateChange(QString newState);
    void command(int no);
    void write(QString s);

    QString hostName;
    quint16 portNo;

    QTcpSocket *tcpSocket;
    QTimer *connectTimer;
    QTimer *statusTimer;
    QTimer *runTimer;
    QTimer *updateTimer;

    QString currentState;

    QStringList cmd;
    QStringList ret;
    int cmdNo;
    bool redirect;

    bool error;
    QString errorText;
};

#endif // LWDAQ_CLIENT_H
