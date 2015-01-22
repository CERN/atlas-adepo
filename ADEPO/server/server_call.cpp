#include "server.h"

void Server::start(QString mode, int runTime, bool airpad) {
    startDAQ(mode, runTime, airpad);
}

void Server::stop() {
    stopDAQ();
}
