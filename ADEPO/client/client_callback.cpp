#include "callback.h"

#include "client.h"
#include "ui_client.h"

void Client::changedRun(QString filename) {
    qDebug() << "CLIENT Changed Run File " << filename;

    if (filename == "") {
        return;
    }

    run.read(filename, config);

    // select selected detectors
    ui->tableWidget_liste_detectors->clearSelection();
    QList<int> selectedDetectors = run.getDetectors();
    for (int row=0; row < ui->tableWidget_liste_detectors->rowCount(); row++) {
        int id = ui->tableWidget_liste_detectors->item(row, 0)->data(Qt::DisplayRole).toInt();
        // select id in list
        if (selectedDetectors.contains(id)) {
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

void Client::changedConfiguration(QString filename) {
    display(ui->configurationFileLabel, ui->configurationFile, filename);

    config.read(filename);
    fillDetectorTable();

    if (run.getFileName() != "") {
        changedRun(run.getFileName());
    }
}

void Client::changedCalibration(QString filename) {
    display(ui->calibrationFileLabel, ui->calibrationFile, filename);
}

void Client::changedOffset(QString filename) {
    offset.read(filename);

    updateResults();
}

void Client::changedReference(QString filename) {
    reference.read(filename);

    updateResults();
}

void Client::changedOutput(QString filename) {
    output.read(filename);

    updateResults();

    display(ui->refFileLabel, ui->refFile, filename);
}

void Client::changedResult(QString filename) {
    display(ui->resultFileLabel, ui->resultFile, filename);
}
