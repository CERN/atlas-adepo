#include "server.h"

#include "util.h"

void Server::start() {
    qDebug() << "SERVER Start called...";
    startDAQ();
}

void Server::stop() {
    qDebug() << "SERVER Stop called...";
    stopDAQ();
}

void Server::updateRunFile() {
    qDebug() << "SERVER UpdateRunFile called...";

    // reread run file
    run.read(run.getFileName());

    callback.changedRunFile(run.getFileName());
}

void Server::updateConfigurationFile() {
    qDebug() << "SERVER UpdateConfigFile called...";

    config.read(config.getFilename());

    callback.changedConfigurationFile(config.getFilename());
}

void Server::updateCalibrationFile() {
    qDebug() << "SERVER UpdateCalibFile called...";

    calibration.read(calibration.getFilename());

    callback.changedCalibrationFile(calibration.getFilename());
}

void Server::updateReferenceFile() {
    qDebug() << "SERVER UpdateRefFile called...";

    reference.read(reference.getFilename());

    callback.changedReferenceFile(reference.getFilename());
}


void Server::updateAll() {
    qDebug() << "SERVER UpdateAll called...";

    updateRunFile();
    updateConfigurationFile();
    updateCalibrationFile();
    updateReferenceFile();

    callback.changedState(adepoState, waitingTimer->remainingTime(), lwdaq_client->getState(), lwdaq_client->getRemainingTime());
    callback.changedResultFile(Util::workPath().append(DEFAULT_RESULT_FILE));
}
