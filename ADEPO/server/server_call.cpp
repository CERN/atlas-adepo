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

void Server::updateRun() {
    qDebug() << "SERVER UpdateRun called...";

    // reread run file
    run.read(run.getFileName(), config);

    callback.changedRun(run.getFileName());
}

void Server::updateConfiguration() {
    qDebug() << "SERVER UpdateConfig called...";

    config.read(config.getFilename());

    callback.changedConfiguration(config.getFilename());
}

void Server::updateCalibration() {
    qDebug() << "SERVER UpdateCalib called...";

    calibration.read(calibration.getFilename());

    callback.changedCalibration(calibration.getFilename());
}

void Server::updateOffset() {
    qDebug() << "SERVER UpdateOffset called...";

    offset.read(offset.getFilename());

    callback.changedOffset(offset.getFilename());
}

void Server::updateReference() {
    qDebug() << "SERVER UpdateReference called...";

    reference.read(reference.getFilename());

    callback.changedReference(reference.getFilename());
}

void Server::updateOutput() {
    qDebug() << "SERVER UpdateOutput called...";

    output.read(output.getFilename());

    callback.changedOutput(output.getFilename());
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
    callback.changedOffset(offset.getFilename());
}


void Server::updateAll() {
    qDebug() << "SERVER UpdateAll called...";

    updateConfiguration();
    updateCalibration();
    updateOffset();
    updateReference();
    updateOutput();
    // needs to be last, needs config
    updateRun();

    callback.changedState(adepoState, waitingTimer->remainingTime(), lwdaq_client->getState(), lwdaq_client->getRemainingTime());
    callback.changedResult(Util::workPath().append(DEFAULT_RESULT_FILE));
}
