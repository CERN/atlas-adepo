#include "callback.h"

#include "client.h"
#include "ui_client.h"

void Client::setMode(QString mode) {
    setModeLabel(mode);
}

void Client::updateStatus(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds) {
    updateStatusBar(adepoStatus, adepoSeconds, lwdaqStatus, lwdaqSeconds);
}

void Client::updateConfigurationFile(QString filename) {
    display(ui->configurationFileLabel, ui->configurationFile, filename);
}

void Client::updateCalibrationFile(QString filename) {
    display(ui->calibrationFileLabel, ui->calibrationFile, filename);
}

void Client::updateReferenceFile(QString filename) {
    display(ui->refFileLabel, ui->refFile, filename);
}

void Client::updateResultFile(QString filename) {
    display(ui->resultFileLabel, ui->resultFile, filename);
}
