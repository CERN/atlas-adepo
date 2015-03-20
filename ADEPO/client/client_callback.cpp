#include "callback.h"

#include "client.h"
#include "ui_client.h"

void Client::changedRunFile(QString filename) {
    qDebug() << "CLIENT Changed Run File " << filename;

    if (filename == "") {
        return;
    }

    run.read(filename, config);

    // select selected detectors
    ui->tableWidget_liste_detectors->clearSelection();
    std::vector<int> selectedDetectors = run.getDetectors();
    for (int row=0; row < ui->tableWidget_liste_detectors->rowCount(); row++) {
        int id = ui->tableWidget_liste_detectors->item(row, 0)->data(Qt::DisplayRole).toInt();
        // select id in list
        if (std::find(selectedDetectors.begin(), selectedDetectors.end(), id) != selectedDetectors.end()) {
            ui->tableWidget_liste_detectors->selectRow(row);
        }
    }

    fillBCAMandResultTable();

    // set the other params
    ui->mode->setText(run.getMode());
    ui->airpad->setCurrentIndex(run.getAirpad() ? 1 : 0);
    ui->acquisitionTime->setValue(run.getAcquisitionTime());
    ui->waitingTime->setValue(run.getWaitingTime());
    ui->fullPrecision->setChecked(run.getFullPrecisionFormat());
}

void Client::changedState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds) {
    QString adepo;
    this->adepoState = adepoState;
    this->lwdaqState = lwdaqState;

    setEnabled();

    if (lwdaqState == LWDAQ_RUN) {
        adepo = adepoState.append(" ").append(QString::number(lwdaqSeconds)).append(" seconds remaining...");
    }

    if (adepoState == ADEPO_WAITING) {
        adepo = adepoState.append(" ").append(QString::number(adepoSeconds)).append(" seconds remaining...");
    } else {
        adepo = adepoState;
    }

    lwdaqStatus.setText("LWDAQ: "+lwdaqState);
    adepoStatus.setText("ADEPO: "+adepo);
    QCoreApplication::flush();
}

void Client::changedConfigurationFile(QString filename) {
    display(ui->configurationFileLabel, ui->configurationFile, filename);

    config.read(filename);
    fillDetectorTable();

    changedRunFile(run.getFileName());
}

void Client::changedCalibrationFile(QString filename) {
    display(ui->calibrationFileLabel, ui->calibrationFile, filename);
}

void Client::changedReferenceFile(QString filename) {
    display(ui->refFileLabel, ui->refFile, filename);
}

void Client::changedResultFile(QString filename) {
    display(ui->resultFileLabel, ui->resultFile, filename);
}

void Client::changedResults(std::map<QString, Result> results) {
    qDebug() << "CLIENT changedResults";

    updateResults(results);
}
