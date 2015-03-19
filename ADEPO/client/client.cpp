#include <fstream>

#include <QPixmapCache>
#include <QFileDialog>
#include <QFileInfo>
#include <QMessageBox>
#include <QDateTime>

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

    QObject::connect(ui->quit, SIGNAL(triggered()), qApp, SLOT(quit()));

    //clic detecteur-affichage bcam
    QObject::connect(ui->tableWidget_liste_detectors, SIGNAL(cellClicked(int,int)), this, SLOT(selectDetectorRow(int,int)));
    QObject::connect(ui->tableWidget_liste_bcams, SIGNAL(cellClicked(int,int)), this, SLOT(showBCAM(int,int)));

    //lancer les acquisitions
    QObject::connect(ui->singleShot, SIGNAL(clicked()), this, SLOT(startClosure()));
    QObject::connect(ui->nextMeasurement, SIGNAL(clicked()), this, SLOT(startClosure()));
    QObject::connect(ui->monitoring, SIGNAL(clicked()), this, SLOT(startMonitoring()));

    //stopper l'acquisition
    QObject::connect(ui->singleShotStop, SIGNAL(clicked()), this, SLOT(stop()));
    QObject::connect(ui->stop, SIGNAL(clicked()), this, SLOT(stop()));
    QObject::connect(ui->monitoringStop, SIGNAL(clicked()), this, SLOT(stop()));

    QObject::connect(ui->reset, SIGNAL(clicked()),this,SLOT(resetDelta()));

    QObject::connect(ui->fullPrecision, SIGNAL(stateChanged(int)), this, SLOT(changedFormat(int)));
    QObject::connect(ui->acquisitionTime, SIGNAL(valueChanged(int)), this, SLOT(changedAcquisitionTimeValue(int)));
    QObject::connect(ui->waitingTime, SIGNAL(valueChanged(int)), this, SLOT(changedWaitingTimeValue(int)));
    QObject::connect(ui->airpad, SIGNAL(currentIndexChanged(int)), this, SLOT(changedAirpad(int)));

    askQuestion = true;

    ui->tabWidget->setCurrentIndex(0);
    ui->tableWidget_liste_detectors->setSelectionBehavior(QAbstractItemView::SelectRows);

    setEnabled();
}

Client::~Client()
{
    delete ui;
}

void Client::showBCAM(int row, int /* column */) {
    qDebug() << "CLIENT ShowBCAM";
    selectedBCAM = row;
    QString prism = ui->tableWidget_liste_bcams->item(row,5)->text();
    QString name =  ui->tableWidget_liste_bcams->item(row, 0)->text().append("_").append(prism);
    bool isPrism = prism.startsWith("PR");
    bool flashSeparate = ui->tableWidget_liste_bcams->item(row, 8)->text().toStdString() == "Yes";
    int deviceElement = ui->tableWidget_liste_bcams->item(row, 4)->text().toStdString() == "2" ? 2 : 1;
    ui->bcamLabel->setText(name);
    QPixmapCache::clear();

    //    QList<QByteArray> list = QImageReader::supportedImageFormats();
    //    for (int i=0; i<list.size(); i++) {
    //        std::cout << QString(list[i]).toStdString() << std::endl;
    //    }

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


void Client::setEnabled() {
    bool enabled = (adepoState == ADEPO_CONNECTING) || (adepoState == ADEPO_IDLE);
    bool canStart = (adepoState == ADEPO_IDLE) &&
            ui->tableWidget_liste_bcams->rowCount() > 0;
    bool canStop = !enabled && (adepoState != ADEPO_CALCULATING) && (adepoState != ADEPO_STOP);

    ui->singleShot->setEnabled(canStart);
    ui->nextMeasurement->setEnabled(canStart);
    ui->monitoring->setEnabled(canStart);

    ui->singleShotStop->setEnabled(canStop && run.getMode() == MODE_CLOSURE);
    ui->stop->setEnabled(canStop && run.getMode() == MODE_CLOSURE);
    ui->monitoringStop->setEnabled(canStop && run.getMode() == MODE_MONITORING);

    ui->tableWidget_liste_detectors->setEnabled(enabled);
    ui->mode->setEnabled(enabled);
    ui->airpad->setEnabled(enabled);
    ui->acquisitionTime->setEnabled(enabled);
    ui->waitingTime->setEnabled(enabled);
}

void Client::display(QLabel *label, QTextBrowser *browser, QString filename) {
    QFileInfo info = QFileInfo(filename);

    label->setText(filename + " - " + info.lastModified().toString());
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
    std::vector<Detector> detectors_data = config.getDetectors();

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

void Client::selectDetectorRow(int row, int /* column */) {
    int id = ui->tableWidget_liste_detectors->item(row, 0)->data(Qt::DisplayRole).toInt();
    std::vector<int> selectedDetectors = run.getDetectors();

    // find the id
    std::vector<int>::iterator it = std::find(selectedDetectors.begin(), selectedDetectors.end(), id);
    if (it == selectedDetectors.end()) {
        selectedDetectors.push_back(id);
    } else {
        selectedDetectors.erase(it);
    }
    run.setDetectors(selectedDetectors, config);
    call->updateRunFile();

    showBCAMTable();
}

void Client::showBCAMTable()
{
    qDebug() << "CLIENT Show BCAM Table";

    // nombre de lignes dans la table
    ui->tableWidget_liste_bcams->clearContents();
    ui->tableWidget_liste_bcams->setRowCount(run.getBCAMs().size());
    ui->tableWidget_results->setRowCount(100);

    int row = 0;
    for(int i=0; i<ui->tableWidget_liste_bcams->rowCount(); i++) {
        BCAM bcam = run.getBCAMs().at(i);

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
        Result& result = results[prismName];

        QTableWidgetItem *name = new QTableWidgetItem();
        name->setText(prismName);
        ui->tableWidget_results->setItem(row, 0, name);

        QTableWidgetItem *bcamName = new QTableWidgetItem();
        bcamName->setText(bcam.getName());
        ui->tableWidget_results->setItem(row, 1, bcamName);

        QTableWidgetItem *prismCell = new QTableWidgetItem();
        prismCell->setText(prism.getName());
        ui->tableWidget_results->setItem(row, 2, prismCell);

        setResult(row, result);
        row++;
    }

    ui->tableWidget_results->setRowCount(row);
    ui->tableWidget_liste_bcams->resizeColumnsToContents();
    ui->tableWidget_results->resizeColumnsToContents();

    setEnabled();
    if (ui->tableWidget_liste_bcams->rowCount() > 0) {
        ui->tableWidget_liste_bcams->selectRow(0);
        showBCAM(0, 0);
    }
}

void Client::setResult(int row, Result &result) {
    qDebug() << "CLIENT setResult";
    QTableWidgetItem *n = new QTableWidgetItem(QString::number(result.getN()));
    ui->tableWidget_results->setItem(row, 3, n);

    if (ui->fullPrecision->isChecked()) {
        setResult(row, Point3f(result.getValue(), 1000), 0, 8);
        setResult(row, Point3f(result.getStd(), 1000), 1, 8);
        setResult(row, Point3f(Point3f(result.getValue(), result.getOffset()), 1000), 2, 8);
    } else {
        setResult(row, Point3f(result.getValue(), 1000), 0, 3);
        setResult(row, Point3f(result.getStd(), 1000), 1, 3);
        setResult(row, Point3f(Point3f(result.getValue(), result.getOffset()), 1000), 2, 3);
    }
}

void Client::setResult(int row, Point3f point, int columnSet, int precision) {
    int firstColumn = 4;

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
    for (int row = 0; row < ui->tableWidget_results->rowCount(); row++) {
        QString name = ui->tableWidget_results->item(row, 0)->text();
        Result& r = results[name];
        r.setOffset(r.getValue());
        results[name] = r;
    }

    updateResults(results);
}

void Client::updateResults(std::map<QString, Result> &results) {
    for (int row = 0; row < ui->tableWidget_results->rowCount(); row++) {
        QString prism = ui->tableWidget_results->item(row, 0)->text();

        Result& r = results[prism];
        r.setName(prism);
        results[prism] = r;

        setResult(row, r);
    }
    ui->tableWidget_results->resizeColumnsToContents();

    // TODO write ref file
//    writeRef(refFile, results);
    display(ui->refFileLabel, ui->refFile, refFile);
}


void Client::startClosure()
{
    run.setMode(MODE_CLOSURE);
    call->updateRunFile();
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
    call->updateRunFile();
    call->start();
}

void Client::stop()
{
    call->stop();
    call->updateRunFile();
}
