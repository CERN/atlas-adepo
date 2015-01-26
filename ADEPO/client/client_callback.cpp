#include "callback.h"

#include "client.h"
#include "ui_client.h"

void Client::setMode(QString mode) {
    ui->modeBox->setText(mode);
    ui->modeBox->setReadOnly(true);
}

void Client::setSelectedDetectors(std::vector<int> detectors) {
   for (unsigned int i=0; i<detectors.size(); i++) {
       ui->tableWidget_liste_detectors->selectRow(detectors[i]);
   }
}

void Client::updateState(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds) {
    updateStatusBar(adepoStatus, adepoSeconds, lwdaqStatus, lwdaqSeconds);
}

void Client::updateConfigurationFile(QString filename) {
    display(ui->configurationFileLabel, ui->configurationFile, filename);

    config.read(filename);
    fillDetectorTable();
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
