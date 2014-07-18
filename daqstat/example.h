#ifndef EXAMPLE_H
#define EXAMPLE_H

#include <iostream>
#include <QObject>
#include <QtNetwork>

#include "client.h"

class Example : public QObject {

    Q_OBJECT

public:
    Example(QObject *parent = 0) : QObject(parent) {
        client = new Client("localhost", 1090, this);

        connect(client, SIGNAL(stateChanged()), this, SLOT(stateChanged()));
    }

    void run() {
        client->connectToHost();
    }

private slots:
    void stateChanged() {
        Client::state newState = client->getState();

        std::cout << "state changed to " << newState << std::endl;
        switch (newState) {
            case Client::READY: {
                std::cout << "Ready, starting a run in a moment..." << std::endl;

                QTimer* timer = new QTimer(this);
                timer->setSingleShot(true);
                connect(timer, SIGNAL(timeout()), this, SLOT(startRun()));
                timer->start(5000);
                break;
            }
            default: {
                break;
            }
        }
    }

    void startRun() {
        std::cout << "Starting a run " << client->isConnected() << " " << client->isReady() << std::endl;
        client->startRun(30);
    }

private:
    Client *client;
};
#endif // EXAMPLE_H
