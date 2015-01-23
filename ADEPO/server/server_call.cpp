#include "server.h"

void Server::start(QString mode, int runTime, bool airpad, std::vector<int> detectors) {
    startDAQ(mode, runTime, airpad, detectors);
}

void Server::stop() {
    stopDAQ();
}
