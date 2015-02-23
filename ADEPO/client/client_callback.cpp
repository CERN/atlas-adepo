#include "callback.h"

#include "client.h"
#include "ui_client.h"

void Client::setMode(QString mode) {
    ui->mode->setText(mode);
    ui->mode->setReadOnly(true);
}

void Client::setSelectedDetectors(std::vector<int> detectors) {
   for (unsigned int i=0; i<detectors.size(); i++) {
       ui->tableWidget_liste_detectors->selectRow(detectors[i]);
   }
}

void Client::updateState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds) {
    QString adepo;
    this->adepoState = adepoState;
    this->lwdaqState = lwdaqState;

    setEnabled();

    if (lwdaqState == LWDAQ_RUN) {
        adepo = adepoState.append(" ").append(QString::number(lwdaqSeconds)).
                append(" seconds remaining...");
    }

    if (adepoState == ADEPO_RUN) {
            // filled already
    } else if (adepoState == ADEPO_WAITING) {
        adepo = adepoState.append(" ").append(QString::number(adepoSeconds)).
                append(" seconds remaining...");
    } else {
        adepo = adepoState;
    }

    lwdaqStatus.setText("LWDAQ: "+lwdaqState);
    QMainWindow::statusBar()->showMessage("ADEPO: "+adepo);
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
