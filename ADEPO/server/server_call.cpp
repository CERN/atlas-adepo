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
    run.read(run.getFileName(), config);

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

void Server::updateOffsetFile() {
    qDebug() << "SERVER UpdateOffsetFile called...";

    offset.read(offset.getFilename());

    callback.changedOffsetFile(offset.getFilename());
}

void Server::updateReferenceFile() {
    qDebug() << "SERVER UpdateReferenceFile called...";

    reference.read(reference.getFilename());

    callback.changedReferenceFile(reference.getFilename());
}

void Server::updateOutputFile() {
    qDebug() << "SERVER UpdateOutputFile called...";

    output.read(output.getFilename());

    callback.changedOutputFile(output.getFilename());
}

void Server::resetDelta() {
    qDebug() << "SERVER resetDelta";

    for(int i=0; i<run.getBCAMs().size(); i++) {
        BCAM bcam = run.getBCAMs().at(i);
        QString prismName = config.getName(bcam.getPrism().getName());
        Result& r = output.getResult(prismName);
        offset.setResult(prismName, r);
    }

    offset.write();
    callback.changedOffsetFile(offset.getFilename());
}


void Server::updateAll() {
    qDebug() << "SERVER UpdateAll called...";

    updateConfigurationFile();
    updateCalibrationFile();
    updateOffsetFile();
    updateReferenceFile();
    updateOutputFile();
    // needs to be last, needs config
    updateRunFile();

    callback.changedState(adepoState, waitingTimer->remainingTime(), lwdaq_client->getState(), lwdaq_client->getRemainingTime());
    callback.changedResultFile(Util::workPath().append(DEFAULT_RESULT_FILE));
}
