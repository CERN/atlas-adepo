#include <fstream>

#include <QPixmapCache>
#include <QFileDialog>
#include <QFileInfo>
#include <QMessageBox>
#include <QDateTime>
#include <QImageReader>

#include "client.h"
#include "ui_client.h"
#include "float_table_widget_item.h"
#include "util.h"

// QSettings settings("atlas.cern.ch", "ADEPO");

Client::Client(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::Client)
{
    adepoState = ADEPO_UNKNOWN;
    lwdaqState = LWDAQ_UNKNOWN;

    ui->setupUi(this);
    ui->statusBar->addPermanentWidget(&adepoStatus);
    ui->statusBar->addPermanentWidget(&lwdaqStatus);
    setWindowTitle(QCoreApplication::applicationName()+" "+QCoreApplication::applicationVersion());

    // headers seem to become invisible after editing UI
    ui->tableWidget_liste_detectors->horizontalHeader()->setVisible(true);
    ui->tableWidget_liste_bcams->horizontalHeader()->setVisible(true);

    connect(ui->quit, &QAction::triggered, qApp, &QCoreApplication::quit);

    //clic detecteur-affichage bcam
    connect(ui->tableWidget_liste_detectors, &QTableWidget::cellClicked, this, &Client::selectDetectorRow);
    connect(ui->tableWidget_liste_bcams, &QTableWidget::cellClicked, this, &Client::showBCAMimage);

    //lancer les acquisitions
    connect(ui->singleShot, &QPushButton::clicked, this, &Client::startClosure);
    connect(ui->nextMeasurement, &QPushButton::clicked, this, &Client::startClosure);
    connect(ui->monitoring, &QPushButton::clicked, this, &Client::startMonitoring);

    //stopper l'acquisition
    connect(ui->singleShotStop, &QPushButton::clicked, this, &Client::stop);
    connect(ui->stop, &QPushButton::clicked, this, &Client::stop);
    connect(ui->monitoringStop, &QPushButton::clicked, this, &Client::stop);

    connect(ui->reset, &QPushButton::clicked, this, &Client::resetDelta);

    connect(ui->fullPrecision, &QCheckBox::stateChanged, this, &Client::changedFormat);
    connect(ui->acquisitionTime, SIGNAL(delayedValueChanged(int)), this, SLOT(changedAcquisitionTimeValue(int)));
    connect(ui->waitingTime, SIGNAL(delayedValueChanged(int)), this, SLOT(changedWaitingTimeValue(int)));
    connect(ui->airpad, SIGNAL(currentIndexChanged(int)), this, SLOT(changedAirpad(int)));

    askQuestion = true;

    ui->tabWidget->setCurrentIndex(0);
    ui->tableWidget_liste_detectors->setSelectionBehavior(QAbstractItemView::SelectRows);

    setEnabled();

    // show supported image formats
    QList<QByteArray> list = QImageReader::supportedImageFormats();
    QString imageFormats;
    for (int i=0; i<list.size(); i++) {
        if (i > 0) imageFormats.append(", ");
        imageFormats.append(list[i]);
    }
    qDebug() << "Supported image formats: " << imageFormats;
}

Client::~Client()
{
    delete ui;
}


void Client::setEnabled() {
    bool enabled = (adepoState == ADEPO_CONNECTING) || (adepoState == ADEPO_IDLE);
    bool canStart = (adepoState == ADEPO_IDLE) &&
            ui->tableWidget_liste_bcams->rowCount() > 0;
    bool canStop = !enabled && (adepoState != ADEPO_CALCULATING) && (adepoState != ADEPO_STOP);

    ui->singleShot->setEnabled(canStart);
    ui->nextMeasurement->setEnabled(canStart);
    ui->monitoring->setEnabled(canStart);

    ui->singleShotStop->setEnabled(canStop && run.getMode() == MODE_CLOSURE);
    ui->stop->setEnabled(canStop);
    ui->monitoringStop->setEnabled(canStop && run.getMode() == MODE_MONITORING);

    ui->reset->setEnabled(enabled);
    ui->fullPrecision->setEnabled(true);
    ui->tableWidget_liste_detectors->setEnabled(enabled);
    ui->mode->setEnabled(enabled);
    ui->airpad->setEnabled(enabled);
    ui->acquisitionTime->setEnabled(enabled);
    ui->waitingTime->setEnabled(enabled);
}

void Client::display(QLabel *label, QTextBrowser *browser, QString filename) {
    QFileInfo info = QFileInfo(filename);

    label->setText(filename + " - " + info.lastModified().toString(DATE_FORMAT));
    browser->setReadOnly(true);

    std::ifstream file((char*)filename.toStdString().c_str(), std::ios::in);
    if(!file) {
        browser->setHtml(QString("Cannot find app") + filename);
    }

    std::string line;
    QString text("<b><pre>");

    while(std::getline(file,line)) {
        text.append(QString::fromStdString(line));
        text.append('\n');
    }
    file.close();
    text.append("</pre></b>");

    browser->setHtml(text);
}

void Client::fillDetectorTable()
{
    qDebug() << "CLIENT Fill Detector Table";

    //recuperation de la liste des nom des detecteurs
    QList<Detector> detectors_data = config.getDetectors();

    // nombre de lignes du tableau de detecteurs dans l'interface
    int nb_lignes = detectors_data.size();
    ui->tableWidget_liste_detectors->clearContents();
    ui->tableWidget_liste_detectors->setRowCount(nb_lignes);

    for(int i=0; i<nb_lignes; i++)
    {
        //ajout du numero id du detecteur
        QTableWidgetItem *item_num = new QTableWidgetItem();
        item_num->setData(Qt::DisplayRole,detectors_data.at(i).getId());
        ui->tableWidget_liste_detectors->setItem(i,0,item_num);

        //ajout du nom du detecteur
        QTableWidgetItem *item_nom = new QTableWidgetItem();
        item_nom->setText(detectors_data.at(i).getName());
        ui->tableWidget_liste_detectors->setItem(i,1,item_nom);

        //ajout de la constante de airpad
        QTableWidgetItem *item_dist_const = new QTableWidgetItem();
        item_dist_const->setData(Qt::DisplayRole,detectors_data.at(i).getAirpad());
        ui->tableWidget_liste_detectors->setItem(i,2,item_dist_const);
    }
}

void Client::selectDetectorRow(int row, int column) {
    Q_UNUSED(column);

    int id = ui->tableWidget_liste_detectors->item(row, 0)->data(Qt::DisplayRole).toInt();
    QList<int> selectedDetectors = run.getDetectors();

    // find the id
    int index = selectedDetectors.indexOf(id);
    if (index < 0) {
        selectedDetectors.push_back(id);
    } else {
        selectedDetectors.removeAt(index);
    }
    run.setDetectors(selectedDetectors);
    call->updateRun(run);

    fillBCAMandResultTable();
}

void Client::fillBCAMandResultTable()
{
    qDebug() << "CLIENT Show BCAM Table";

    // nombre de lignes dans la table
    ui->tableWidget_liste_bcams->clearContents();
    ui->tableWidget_liste_bcams->setRowCount(setup.getBCAMs().size());
    ui->tableWidget_results->setRowCount(100);

    int row = 0;
    for(int i=0; i<setup.getBCAMs().size(); i++) {
        BCAM bcam = setup.getBCAMs().at(i);

        //ajout dans la tableWidget qui affiche les BCAMs
        QTableWidgetItem *nom_bcam = new QTableWidgetItem();
        nom_bcam->setText(bcam.getName());
        ui->tableWidget_liste_bcams->setItem(i,0,nom_bcam);

        QTableWidgetItem *num_detector = new QTableWidgetItem();
        num_detector->setData(Qt::DisplayRole,bcam.getDetectorId());
        ui->tableWidget_liste_bcams->setItem(i,1,num_detector);

        QTableWidgetItem *num_port_driver = new QTableWidgetItem();
        num_port_driver->setData(Qt::DisplayRole,bcam.getDriverSocket());
        ui->tableWidget_liste_bcams->setItem(i,2,num_port_driver);

        QTableWidgetItem *num_port_mux = new QTableWidgetItem();
        num_port_mux->setData(Qt::DisplayRole,bcam.getMuxSocket());
        ui->tableWidget_liste_bcams->setItem(i,3,num_port_mux);

        Prism prism = bcam.getPrism();

        QTableWidgetItem *num_chip = new QTableWidgetItem();
        num_chip->setData(Qt::DisplayRole,prism.getNumChip());
        ui->tableWidget_liste_bcams->setItem(i,4,num_chip);

        QTableWidgetItem *objet_vise = new QTableWidgetItem();
        objet_vise->setText(prism.getName());
        ui->tableWidget_liste_bcams->setItem(i,5,objet_vise);

        QTableWidgetItem *left = new QTableWidgetItem();
        left->setData(Qt::DisplayRole,prism.getLeft());
        ui->tableWidget_liste_bcams->setItem(i,6,left);

        QTableWidgetItem *right = new QTableWidgetItem();
        right->setData(Qt::DisplayRole,prism.getRight());
        ui->tableWidget_liste_bcams->setItem(i,7,right);

        QTableWidgetItem *separate = new QTableWidgetItem();
        separate->setData(Qt::DisplayRole,prism.flashSeparate() ? "Yes" : "No");
        ui->tableWidget_liste_bcams->setItem(i,8,separate);

        QTableWidgetItem *adjust = new QTableWidgetItem();
        adjust->setData(Qt::DisplayRole,prism.flashAdjust() ? "Yes" : "No");
        ui->tableWidget_liste_bcams->setItem(i,9,adjust);

        // Result Table
        QString prismName = config.getName(prism.getName());

        QTableWidgetItem *name = new QTableWidgetItem();
        name->setText(prismName);
        ui->tableWidget_results->setItem(row, 0, name);

        QTableWidgetItem *bcamName = new QTableWidgetItem();
        bcamName->setText(bcam.getName());
        ui->tableWidget_results->setItem(row, 1, bcamName);

        QTableWidgetItem *prismCell = new QTableWidgetItem();
        prismCell->setText(prism.getName());
        ui->tableWidget_results->setItem(row, 2, prismCell);

        setResult(row, output.getResult(prismName), offset.getResult(prismName));
        row++;
    }

    ui->tableWidget_results->setRowCount(row);
    ui->tableWidget_liste_bcams->resizeColumnsToContents();
    ui->tableWidget_results->resizeColumnsToContents();

    setEnabled();
    if (ui->tableWidget_liste_bcams->rowCount() > 0) {
        ui->tableWidget_liste_bcams->selectRow(0);
        showBCAMimage(0, 0);
    }
}

void Client::showBCAMimage(int row, int column) {
    Q_UNUSED(column);

    qDebug() << "CLIENT ShowBCAM";
    selectedBCAM = row;
    QString prism = ui->tableWidget_liste_bcams->item(row,5)->text();
    QString name =  ui->tableWidget_liste_bcams->item(row, 0)->text().append("_").append(prism);
    bool isPrism = prism.startsWith("PR");
    bool flashSeparate = ui->tableWidget_liste_bcams->item(row, 8)->text().toStdString() == "Yes";
    int deviceElement = ui->tableWidget_liste_bcams->item(row, 4)->text().toStdString() == "2" ? 2 : 1;
    ui->bcamLabel->setText(name);
    QPixmapCache::clear();

    QString suffix1 = Util::getSourceDeviceElement(isPrism, flashSeparate, deviceElement, true).replace(" ", "-");
    QString imageName = Util::workPath().append("/images/").append(name).append("-").append(suffix1).append(".gif");
    QFileInfo file(imageName);
    if (file.exists()) {
        QDateTime dateTime = file.lastModified();
        QPixmap pix1(imageName);
        ui->bcamImage1->setPixmap(pix1);
        ui->bcamDateTime->setText(dateTime.toString());
        ui->bcamImage2->setVisible(flashSeparate);
        if (flashSeparate) {
            QString suffix2 = Util::getSourceDeviceElement(isPrism, flashSeparate, deviceElement, false);
            QPixmap pix2(Util::workPath().append("/images/").append(name).append("-").append(suffix2).append(".gif"));
            ui->bcamImage2->setPixmap(pix2);
        }
    } else {
        ui->bcamImage1->setText("No BCAM Image");
        ui->bcamImage2->setVisible(false);
        ui->bcamDateTime->setText("");
    }
}


void Client::updateResults() {
    for (int row = 0; row < ui->tableWidget_results->rowCount(); row++) {
        QString prism = ui->tableWidget_results->item(row, 0)->text();

        setResult(row, output.getResult(prism), offset.getResult(prism));
    }
    ui->tableWidget_results->resizeColumnsToContents();
}



void Client::setResult(int row, Result &result, Result &offset) {
    QTableWidgetItem *time = new QTableWidgetItem(result.getTime().toString(DATE_FORMAT));
    ui->tableWidget_results->setItem(row, 3, time);

    QTableWidgetItem *n = new QTableWidgetItem(QString::number(result.getN()));
    ui->tableWidget_results->setItem(row, 4, n);

    int precision = ui->fullPrecision->isChecked() ? 8 : 3;
    setResult(row, Point3d(result.getValue(), 1000), 0, precision);
    setResult(row, Point3d(result.getStd(), 1000), 1, precision);
    setResult(row, Point3d(Point3d(result.getValue(), offset.getValue()), 1000), 2, precision);

    QCheckBox *verified = new QCheckBox();
    verified->setCheckState(static_cast<Qt::CheckState>(result.isVerified()));
    verified->setEnabled(false);
    ui->tableWidget_results->setCellWidget(row, 14, verified);
}

void Client::setResult(int row, Point3d point, int columnSet, int precision) {
    int firstColumn = 5;

    if (point.isValid()) {
        QTableWidgetItem *x = new FloatTableWidgetItem(QString::number(point.x(), 'f', precision));
        ui->tableWidget_results->setItem(row, firstColumn + (columnSet * 3), x);

        QTableWidgetItem *y = new FloatTableWidgetItem(QString::number(point.y(), 'f', precision));
        ui->tableWidget_results->setItem(row, firstColumn + 1 + (columnSet * 3), y);

        QTableWidgetItem *z = new FloatTableWidgetItem(QString::number(point.z(), 'f', precision));
        ui->tableWidget_results->setItem(row, firstColumn + 2 + (columnSet * 3), z);
    } else {
        for (int i=0; i<3; i++) {
            QTableWidgetItem *v = new QTableWidgetItem("Not Valid");
            ui->tableWidget_results->setItem(row, firstColumn + i + (columnSet * 3), v);
        }
    }
}

void Client::resetDelta() {
    call->resetDelta();
}

void Client::startClosure()
{
    run.setMode(MODE_CLOSURE);
    call->updateRun(run);
    call->start();
}

void Client::startMonitoring()
{
    if (askQuestion) {
        //boite de dialogue avant de debuter le mode monitoring
        int reponse = QMessageBox::question(this, "Monitoring Mode",
                                            "Attention, you are in monitoring mode. Make sure you have selected the correct set of detectors.",
                                            QMessageBox::Yes | QMessageBox::No);
        if (reponse == QMessageBox::No) {
            return;
        }
    }

    askQuestion = false;
    run.setMode(MODE_MONITORING);
    call->updateRun(run);
    call->start();
}

void Client::stop()
{
    call->stop();
    call->updateRun(run);
}
