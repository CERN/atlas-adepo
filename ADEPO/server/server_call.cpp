#include "server.h"

void Server::start() {
    startDAQ();
}

void Server::stop() {
    stopDAQ();
}

void Server::update() {
    qDebug() << "Update called...";

    callback.setMode(runMode);
    callback.setSelectedDetectors(detectors);

    // TODO
    callback.updateState(adepoState, waitingTimer->remainingTime(), lwdaq_client->getState(), lwdaq_client->getRemainingTime());
    callback.updateConfigurationFile(config.getFilename());
    callback.updateCalibrationFile(calibration.getFilename());
    callback.updateReferenceFile(reference.getFilename());
    callback.updateResultFile(resultFile);
}
