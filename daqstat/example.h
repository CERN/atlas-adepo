#ifndef EXAMPLE_H
#define EXAMPLE_H

#include <iostream>
#include <QObject>
#include <QtNetwork>

#include "lwdaq_client.h"

class Example : public QObject {

    Q_OBJECT

public:
    Example(QCoreApplication *parent = 0) : QObject(parent), app(parent) {
        client = new LWDAQ_Client("localhost", 1090, this);

        connect(client, SIGNAL(stateChanged()), this, SLOT(stateChanged()));
    }

    void run() {
        client->init();
    }

private slots:
    void stateChanged() {
        std::cout << "state changed to " << client->getStateAsString().toStdString() << std::endl;

        LWDAQ_Client::state newState = client->getState();
        switch (newState) {
            case LWDAQ_Client::IDLE: {
                std::cout << "Idle, starting a run in a moment..." << std::endl;

                QTimer* timer = new QTimer(this);
                timer->setSingleShot(true);
                connect(timer, SIGNAL(timeout()), this, SLOT(startRun()));
                timer->start(10000);
                break;
            }
            default: {
                break;
            }
        }
    }

    void startRun() {
        std::cout << "Starting a run " << client->isConnected() << " " << client->isIdle() << std::endl;
        client->startRun(app->applicationDirPath(), 30);
    }

private:
    LWDAQ_Client *client;
    QCoreApplication *app;
};
#endif // EXAMPLE_H
