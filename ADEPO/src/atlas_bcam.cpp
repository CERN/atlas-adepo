#include "atlas_bcam.h"
#include "ouverture_projet.h"
#include "read_input.h"
#include "ui_ATLAS_BCAM.h"
#include "read_calibration_database.h"
#include "bdd.h"
#include "write_aquisifier_script.h"
#include "write_bash_script.h"
#include "read_lwdaq_output.h"
#include "img_coord_to_bcam_coord.h"
#include "write_file_obs_mount_system.h"
#include "calcul_coord_bcam_system.h"
#include "helmert.h"
#include "mythread.h"
#include "mount_prism_to_global_prism.h"
#include "float_table_widget_item.h"
#include "Eigen/Eigen"
#include "read_write_ref.h"

#include <iostream>
#include <QtGui>
#include "QWidget"
#include "QtTest/QTest"
#include <time.h>
#include <QString>

#define NBR_DETECTORS 8
#define ID_LENGTH_BCAM 14

#define INPUT_FOLDER "input_folder"
#define AIRPAD_INDEX "airpad_index"
#define MODE_INDEX "mode_index"
#define TIME_VALUE "time_value"
#define FULL_PRESICION_FORMAT "full_precision_format"
#define SELECTED_DETECTORS "selected_detectors"
#define RESULT_FILE "result_file"

/********************************************************************************************/
#define NAME_CONFIGURATION_FILE "configuration_file.txt"
#define NAME_CALIBRATION_FILE "BCAM_Parameters.txt"
#define NAME_REF_FILE "reference_file.txt"
#define NAME_LWDAQ_FOLDER "LWDAQ"
/********************************************************************************************/


//declaration des variables globales
QSettings settings;

QString path_input_folder;
bool input_folder_read = false;

//nom du fichier script qui va lancer l'acquisition que sur les detecteurs selectionnes
QString fichier_script = DEFAULT_SCRIPT_FILE;

//bool pour savoir si y a eu une erreur dans le format de l'input
//format_input = 1 --> tout est bon
//format_input = 0 --> il y a une erreur et on ne charge pas le fichier
int format_input=1;

//compteur pour savoir combien de fois l'utilisateur a charge un fichier d'input

//timer pour le mode monitoring
QTimer *timer = new QTimer();

ATLAS_BCAM::ATLAS_BCAM(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::ATLAS_BCAM)                                                                        //[---> ok
{
        QString appPath = appDirPath();
        std::cout << appPath.toStdString() << std::endl;

        // connect to LWDAQ server
        lwdaq_client = new LWDAQ_Client("localhost", 1090, this);
        connect(lwdaq_client, SIGNAL(stateChanged()), this, SLOT(lwdaqStateChanged()));
        connect(lwdaq_client, SIGNAL(remainingTimeChanged()), this, SLOT(lwdaqTimeChanged()));

        ui->setupUi(this);
        ui->statusBar->addPermanentWidget(&lwdaqStatus);
//        QFont font = QFont();
//        font.setPointSize(10);
//        ui->tableWidget_results->setFont(font);

        // headers seem to become invisible after editing UI
        ui->tableWidget_liste_detectors->horizontalHeader()->setVisible(true);
        ui->tableWidget_liste_bcams->horizontalHeader()->setVisible(true);

        //ouverture de l'input file
        QObject::connect(ui->actionCharger,SIGNAL(triggered()),this,SLOT(ouvrirDialogue()));
        ui->actionCharger->setShortcut(QKeySequence("Ctrl+O"));

        QObject::connect(ui->action_Quitter,SIGNAL(triggered()),qApp,SLOT(quit()));
        ui->action_Quitter->setShortcut(QKeySequence("Ctrl+Q"));

        QObject::connect(ui->actionAbout_Qt,SIGNAL(triggered()),qApp,SLOT(aboutQt()));
        ui->actionAbout_Qt->setShortcut(QKeySequence("Ctrl+I"));

        QObject::connect(ui->action_Aide,SIGNAL(triggered()),this,SLOT(aide_atlas_bcam()));
        ui->action_Aide->setShortcut(QKeySequence("Ctrl+A"));

        //clic detecteur-affichage bcam
        QObject::connect(ui->tableWidget_liste_detectors, SIGNAL(cellClicked(int,int)),this, SLOT(showBCAMTable()));
        QObject::connect(ui->tableWidget_liste_bcams, SIGNAL(cellClicked(int,int)),this, SLOT(showBCAM(int,int)));

        //lancer les acquisitions (arret automoatique)
        QObject::connect(ui->Boutton_lancer,SIGNAL(clicked()), this,SLOT(startCalcul()));
        QObject::connect(ui->nextMeasurement,SIGNAL(clicked()), this,SLOT(startCalcul()));

        //QObject::connect(timer,SIGNAL(timeout()),this,SLOT(lancer_acquisition()));

        //stopper l'acquisition (arret force)
        QObject::connect(ui->boutton_arreter,SIGNAL(clicked()),this,SLOT(stop_acquisition()));
        QObject::connect(ui->stop,SIGNAL(clicked()),this,SLOT(stop_acquisition()));

        QObject::connect(ui->reset,SIGNAL(clicked()),this,SLOT(resetDelta()));

        QObject::connect(ui->fullPrecision,SIGNAL(stateChanged(int)),this,SLOT(changedFormat(int)));
        QObject::connect(ui->timeBox, SIGNAL(valueChanged(int)), this, SLOT(changedTimeValue(int)));
        QObject::connect(ui->modeBox, SIGNAL(currentIndexChanged(int)), this, SLOT(changedMode(int)));
        QObject::connect(ui->airpadBox, SIGNAL(currentIndexChanged(int)), this, SLOT(changedAirpad(int)));

        previousState = LWDAQ_Client::UNSET;
        needToCalculateResults = false;

        setEnabled(true);

        lwdaqDir = lwdaq_client->find(QDir(appPath));
        if (!lwdaqDir.exists()) {
            std::cerr << "FATAL: could not find LWDAQ directory up from " << appPath.toStdString() << std::endl;
            exit(1);
        } else {
            std::cout << "Found LWDAQ installation at " << lwdaqDir.absolutePath().toStdString() << std::endl;
        }

        QString dir = appDirPath();
        resultFile.setFileName(dir.append("/").append(DEFAULT_RESULTS_FILE));

        lwdaq_client->init();

        ui->tabWidget->setCurrentIndex(0);

        path_input_folder = settings.value(INPUT_FOLDER).value<QString>();
        if (path_input_folder != NULL) {
            openInputDir();
        }

        int timeValue = settings.value(TIME_VALUE).value<int>();
        if (timeValue < 30) {
            timeValue = 30;
        }
        ui->timeBox->setValue(timeValue);

        int airpadIndex = settings.value(AIRPAD_INDEX).value<int>();
        ui->airpadBox->setCurrentIndex(airpadIndex);

        int modeIndex = settings.value(MODE_INDEX).value<int>();
        ui->modeBox->setCurrentIndex(modeIndex);

        int fullPrecisionFormat = settings.value(FULL_PRESICION_FORMAT).value<int>();
        ui->fullPrecision->setChecked(fullPrecisionFormat);

        QString selectedDetectors = settings.value(SELECTED_DETECTORS).value<QString>();
        QStringList selectedDetectorList = selectedDetectors.split(" ");
        for (int i=0; i<selectedDetectorList.size(); i++) {
            for (int r=0; r<ui->tableWidget_liste_detectors->rowCount(); r++) {
                if (selectedDetectorList[i] == ui->tableWidget_liste_detectors->item(r, 0)->text()) {
                    ui->tableWidget_liste_detectors->selectRow(r);
                }
            }
        }

        showBCAMTable();

        QString resultFile = settings.value(RESULT_FILE).value<QString>();
        display(ui->resultFileLabel, ui->resultFile, resultFile);
}

ATLAS_BCAM::~ATLAS_BCAM()
{
    delete ui;
}

QString ATLAS_BCAM::appDirPath() {
    QString appPath = qApp->applicationDirPath();
    if (appPath.endsWith("/Contents/MacOS")) {
        QDir dir(appPath + "/../../..");
        appPath = dir.absolutePath();
    }
    return appPath;
}

void ATLAS_BCAM::showBCAM(int row, int /* column */) {
//    std::cout << "Selected " << row << std::endl;
    selectedBCAM = row;
    QString prism = ui->tableWidget_liste_bcams->item(row,5)->text();
    QString name =  ui->tableWidget_liste_bcams->item(row, 0)->text().append("_").append(prism);
    bool isPrism = prism.startsWith("PR");
    bool flashSeparate = ui->tableWidget_liste_bcams->item(row, 8)->text().toStdString() == "Yes";
    int deviceElement = ui->tableWidget_liste_bcams->item(row, 4)->text().toStdString() == "2" ? 2 : 1;
    ui->bcamLabel->setText(name);
    QPixmapCache::clear();
    QString dir = appDirPath();
    QString suffix1 = QString::fromStdString(getSourceDeviceElement(isPrism, flashSeparate, deviceElement, true)).replace(" ", "-");
    QString imageName1 = dir.append("/").append(name).append("-").append(suffix1).append(".gif");
//    QList<QByteArray> list = QImageReader::supportedImageFormats();
//    for (int i=0; i<list.size(); i++) {
//        std::cout << QString(list[i]).toStdString() << std::endl;
//    }
    QFileInfo file(imageName1);
    if (file.exists()) {
        QDateTime dateTime = file.lastModified();
        QPixmap pix1(imageName1);
        ui->bcamImage1->setPixmap(pix1);
        ui->bcamDateTime->setText(dateTime.toString());
        ui->bcamImage2->setVisible(flashSeparate);
        if (flashSeparate) {
            QString suffix2 = QString::fromStdString(getSourceDeviceElement(isPrism, flashSeparate, deviceElement, false));
            QString imageName2 = dir.append("/").append(name).append("-").append(suffix2).append(".gif");
            QPixmap pix2(imageName2);
            ui->bcamImage2->setPixmap(pix2);
            ui->bcamImage2->setText("Test=");
        }
    } else {
        ui->bcamImage1->setText("No BCAM Image");
        ui->bcamImage2->setVisible(false);
        ui->bcamDateTime->setText("");
    }
}

void ATLAS_BCAM::lwdaqStateChanged() {
    std::cout << "state changed to " << lwdaq_client->getStateAsString().toStdString() << std::endl;
    lwdaqStatus.setText(lwdaq_client->getStateAsString());
    QMainWindow::statusBar()->showMessage("ADEPO");  // Used for Adepos status later on

    switch (lwdaq_client->getState()) {
        case LWDAQ_Client::IDLE:
            setEnabled(true);

            if (needToCalculateResults) {
                // rename startup script file
                // TODO

                // calculate
                calcul_coord();
                needToCalculateResults = false;
            }
            break;
        case LWDAQ_Client::RUN:
            setEnabled(false);
            break;
        case LWDAQ_Client::STOP:
            ui->Boutton_lancer->setEnabled(false);
            ui->nextMeasurement->setEnabled(false);
            ui->boutton_arreter->setEnabled(false);
            ui->stop->setEnabled(false);
            break;
        case LWDAQ_Client::INIT:
            ui->Boutton_lancer->setEnabled(false);
            ui->boutton_arreter->setEnabled(false);
            ui->boutton_arreter->setEnabled(false);
            ui->stop->setEnabled(false);
            needToCalculateResults = false;
            break;

        default:
//            ui->Boutton_lancer->setEnabled(false);
//            ui->boutton_arreter->setEnabled(false);
            break;
    }

    previousState = lwdaq_client->getState();
}

void ATLAS_BCAM::changedAirpad(int index) {
    settings.setValue(AIRPAD_INDEX, index);
}

void ATLAS_BCAM::lwdaqTimeChanged() {
   QMainWindow::statusBar()->showMessage(QString("ADEPO ").append(QString::number(lwdaq_client->getRemainingTime()/1000)).
                                          append(" seconds remaining..."));
   showBCAM(selectedBCAM, 0);
}

void ATLAS_BCAM::setEnabled(bool enabled) {
    bool canStart = enabled &&
            !path_input_folder.isEmpty() &&
            ui->tableWidget_liste_bcams->rowCount() > 0 &&
            lwdaq_client->getState() > LWDAQ_Client::INIT;
    ui->Boutton_lancer->setEnabled(canStart);
    ui->nextMeasurement->setEnabled(canStart);
    ui->boutton_arreter->setEnabled(!enabled);
    ui->stop->setEnabled(!enabled);

    ui->tableWidget_liste_detectors->setEnabled(enabled);
    ui->modeBox->setEnabled(enabled);
    ui->airpadBox->setEnabled(enabled);
    ui->timeBox->setEnabled(enabled);
}

//ouverture d'une boite de dialogue                                                                 [----> ok
void ATLAS_BCAM::ouvrirDialogue()
{
    path_input_folder = QFileDialog::getExistingDirectory(this, "Chemin du dossier", QString());
    openInputDir();
}

void ATLAS_BCAM::openInputDir() {
    settings.setValue(INPUT_FOLDER, path_input_folder);

    if(input_folder_read) //gestion du probleme lorsqu'on charge un fichier par dessus l'autre
    {
        m_bdd.vidage_complet(); //on vide tout car nouveau fichier
    }
    input_folder_read = true;

    //chemin du fichier d'entree
    //path_input_folder = fenetre_ouverture->Get_path_fich();

    //appel pour la lecture de fichier
    QString inputFile = path_input_folder;
    inputFile.append("/").append(NAME_CONFIGURATION_FILE);
    read_input(inputFile.toStdString(), m_bdd);

    display(ui->configurationFileLabel, ui->configurationFile, inputFile);

    //estimation des 6 parametres pour chaque BCAM
    helmert(m_bdd);

    //verification des infos du fichier d'entree
    check_input_data();

    //remplissage tableau detectors que si le format du fichier input est bon !
    if(format_input == 1)
    {
        remplir_tableau_detectors();
    }

    //lecture du fichier de calibration
    QString calibrationFile = path_input_folder;
    calibrationFile.append("/").append(NAME_CALIBRATION_FILE);
    read_calibration_database(calibrationFile.toStdString(), m_bdd);

    display(ui->calibrationFileLabel, ui->calibrationFile, calibrationFile);

    //recuperation de la partie qui nous interesse du fichier de calibration
    //clean_calib(m_bdd);

    // read reference file
    refFile = path_input_folder;
    refFile.append("/").append(NAME_REF_FILE);
    read_ref(refFile, results);
    display(ui->refFileLabel, ui->refFile, refFile);

    //activation du boutton pour lancer les acquisitions
    setEnabled(true);
}

void ATLAS_BCAM::display(QLabel *label, QTextBrowser *browser, QString filename) {
    label->setText(filename);
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

//fonction qui enregistre la valeur du temps d'acquisition entree par l'utilisateur                 [----> ok
void ATLAS_BCAM::changedTimeValue(int value)
{
    settings.setValue(TIME_VALUE, value);
}

//fonction d'ouverture de la fenêtre d'aide de l'outil ARCAPA                                       [----> not yet]
void ATLAS_BCAM::aide_atlas_bcam()
{
    QDialog *aideatlasbcam = new QDialog(this);

    aideatlasbcam->setWindowTitle("Aide à l'utilisation d\'ATLAS_BCAM");
    aideatlasbcam->setGeometry(50,50,800,500);
    aideatlasbcam->setWindowFlags(Qt::Window);
    aideatlasbcam->setWindowIcon(QIcon(QPixmap("help_icon.png")));

    QVBoxLayout *layout = new QVBoxLayout(aideatlasbcam);

    QTextEdit *texte = new QTextEdit("");
    texte->setReadOnly(true);

    layout->addWidget(texte);
    aideatlasbcam->setLayout(layout);
    aideatlasbcam->show();

}

//fonction permettant de charger la liste des detectors après ouverture d'un projet                 [---> ok
void ATLAS_BCAM::remplir_tableau_detectors()
{
    //recuperation de la liste des nom des detecteurs
    std::vector<detector> detectors_data = this->m_bdd.getDetectors();

    // nombre de lignes du tableau de detecteurs dans l'interface
    int nb_lignes = detectors_data.size();
    ui->tableWidget_liste_detectors->setRowCount(nb_lignes);

    for(int i=0; i<nb_lignes; i++)
    {

        //ajout du numero id du detetcteur
        QTableWidgetItem *item_num = new QTableWidgetItem();
        item_num->setData(Qt::DisplayRole,detectors_data.at(i).getId());
        ui->tableWidget_liste_detectors->setItem(i,0,item_num);

        //ajout du nom du detecteur
        QTableWidgetItem *item_nom = new QTableWidgetItem();
        item_nom->setText(QString::fromStdString(detectors_data.at(i).getName()));
        ui->tableWidget_liste_detectors->setItem(i,1,item_nom);

        //ajout de la constante de airpad
        QTableWidgetItem *item_dist_const = new QTableWidgetItem();
        item_dist_const->setData(Qt::DisplayRole,detectors_data.at(i).getAirpad());
        ui->tableWidget_liste_detectors->setItem(i,2,item_dist_const);
    }


}

//fonction permettant de charger la liste des BCAMs qui appartiennent a un detector                 [---> ok
void ATLAS_BCAM::showBCAMTable()
{
    std::cout << "Show BCAM Table" << std::endl;
    int noColumn = ui->tableWidget_liste_detectors->columnCount();

    //recuperation du nombre de detecteurs
    int nb_detectors = ui->tableWidget_liste_detectors->selectedItems().size()/noColumn;

    m_bdd.getBCAMs().clear();

    QString selectedDetectors("");

    //recuperation des donnees a afficher
    for(int i=0; i<nb_detectors; i++)
    {
        //recuperation de l'identifiant du detecteur
        QString id_detector = ui->tableWidget_liste_detectors->selectedItems().at(i*noColumn)->text();

        if (i > 0) selectedDetectors = selectedDetectors.append(" ");
        selectedDetectors = selectedDetectors.append(id_detector);

        //recuperation des donnes a afficher
        std::vector<BCAM> bcams = m_bdd.getBCAMs(id_detector.toInt());

        //insertion dans la tableWidget qui affiche les bcams
        for (unsigned int j=0; j<bcams.size(); j++) {
            m_bdd.getBCAMs().push_back(bcams.at(j));
        }

        //ecriture du script d'acquisition des detecteurs selectionnees
        write_script_file(appDirPath()+"/"+fichier_script, m_bdd.getBCAMs());
    }

    settings.setValue(SELECTED_DETECTORS, selectedDetectors);

    // nombre de lignes dans la table
    ui->tableWidget_liste_bcams->setRowCount(m_bdd.getBCAMs().size());
    ui->tableWidget_results->setRowCount(100);

    int row = 0;
    for(unsigned int i=0; i<m_bdd.getBCAMs().size(); i++)
    {
        BCAM bcam = m_bdd.getBCAMs().at(i);

      //ajout dans la tableWidget qui affiche les BCAMs
      QTableWidgetItem *nom_bcam = new QTableWidgetItem();
      nom_bcam->setText(QString::fromStdString(bcam.getName()));
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
      objet_vise->setText(QString::fromStdString(prism.getName()));
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
      std::string prismName = m_bdd.getName(prism.getName());
      result& result = results[prismName];

      QTableWidgetItem *name = new QTableWidgetItem();
      name->setText(QString::fromStdString(prismName));
      ui->tableWidget_results->setItem(row, 0, name);

      QTableWidgetItem *bcamName = new QTableWidgetItem();
      bcamName->setText(QString::fromStdString(bcam.getName()));
      ui->tableWidget_results->setItem(row, 1, bcamName);

      QTableWidgetItem *prismCell = new QTableWidgetItem();
      prismCell->setText(QString::fromStdString(prism.getName()));
      ui->tableWidget_results->setItem(row, 2, prismCell);

      setResult(row, result);
      row++;
    }

    ui->tableWidget_results->setRowCount(row);
    ui->tableWidget_liste_bcams->resizeColumnsToContents();
    ui->tableWidget_results->resizeColumnsToContents();

    setEnabled(true);
    if (ui->tableWidget_liste_bcams->rowCount() > 0) {
        ui->tableWidget_liste_bcams->selectRow(0);
        showBCAM(0, 0);
    }
}

void ATLAS_BCAM::setResult(int row, result& result) {
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

void ATLAS_BCAM::setResult(int row, Point3f point, int columnSet, int precision) {
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

//fonction qui lance les acquisitions LWDAQ                                                         ----> ok mais qu'est ce qui se passe apres les acquisitions ?
void ATLAS_BCAM::lancer_acquisition()
{
    QString dir = appDirPath();

    write_params_file(dir + "/" + DEFAULT_PARAM_FILE);

    write_settings_file(dir + "/" + DEFAULT_SETTINGS_FILE);

    //si un fichier de resultats existe deja dans le dossier LWDAQ, je le supprime avant
    std::cout << "*** Removing " << resultFile.fileName().toStdString() << std::endl;
    if (resultFile.exists() && !resultFile.remove()) {
        std::cout << "WARNING Cannot remove result file " << resultFile.fileName().toStdString() << std::endl;
        std::cout << "WARNING Start aborted." << std::endl;
        return;
    }

    setEnabled(false);

    //lancement du programme LWDAQ + arret apres nombre de secondes specifiees par le user
    std::cout << "Starting LWDAQ on " << m_bdd.getDriverIpAddress() << std::endl;

    lwdaq_client->startRun(dir, ui->timeBox->value());
}

//fonction qui permet d'arreter l'acquisition LWDAQ (seuleuement en mode monitoring)                [----> ok
void ATLAS_BCAM::stop_acquisition()
{
    needToCalculateResults = false;

    lwdaq_client->stopRun();

    setEnabled(true);
}

void ATLAS_BCAM::resetDelta() {
    for (int row = 0; row < ui->tableWidget_results->rowCount(); row++) {
        std::string name = ui->tableWidget_results->item(row, 0)->text().toStdString();
        result& r = results[name];
        r.setOffset(r.getValue());
        results[name] = r;
    }

    updateResults(results);
}

void ATLAS_BCAM::changedFormat(int state) {
    settings.setValue(FULL_PRESICION_FORMAT, state);
    updateResults(results);
}

//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM + suavegarde            [----> ok
void ATLAS_BCAM::calcul_coord()
{
   //je lis le fichier de sortie de LWDAQ qui contient les observations puis je stocke ce qui nous interesse dans la bdd
   int lecture_output_result = read_lwdaq_output(resultFile, m_bdd);

   if(lecture_output_result == 0 )
   {
       QMessageBox::critical(this,"Attention","le fichier de resultats est inexistant ou illisible. Verifiez la connexion avec le driver. ");
       std::cout << lecture_output_result << std::endl;
   }
   /*else if(lecture_output_result == 2)
   {
       std::string str = m_bdd.Get_driver_ip_adress();
       QString message = QString::fromStdString("ERROR: Failed to connect to : %1").arg(str);
       QMessageBox::critical(this,"Attention", message);
   }*/
   else
   {
   //je fais la transformation du capteur CCD au systeme MOUNT. Attention, la lecture du fichier de calibration est deja faite !
   img_coord_to_bcam_coord(m_bdd);

   //je calcule les coordonnees du prisme en 3D dans le repere MOUNT
   calcul_coord_bcam_system(m_bdd);

   //je calcule les coordonnees du prisme en 3D dans le repere ATLAS
   mount_prism_to_global_prism(m_bdd, ui->airpadBox->currentText() == "ON");

   calculateResults(m_bdd, results);

   std::cout << "Updating Results..." << std::endl;
   updateResults(results);

   //enregistrement du fichier qui contient les observations dans le repere CCD et dans le repere MOUNT : spots + prismes
   QDir(".").mkpath(appDirPath().append("/Archive"));

   QString fileName = appDirPath();
   fileName.append("/Archive/Observations_MOUNT_System_");

   // current date/time based on current system
   QString now = getDateTime();

   fileName = fileName.append(now).append(".txt");

   write_file_obs_mount_system(fileName, now, m_bdd);

   display(ui->resultFileLabel, ui->resultFile, fileName);

   settings.setValue(RESULT_FILE, fileName);

   //vidage des acquisitions
   m_bdd.vidage();
   }
}

QString ATLAS_BCAM::getDateTime() {
    time_t now = time(0);
    tm* ltm = localtime(&now);

    // print various components of tm structure.
    int year = 1900 + ltm->tm_year;
    int month = 1 + ltm->tm_mon;
    int day = ltm->tm_mday;
    int hour = ltm->tm_hour;
    int min = ltm->tm_min;
    int sec = ltm->tm_sec;

    QString dateTime = QString("%1.%2.%3.%4.%5.%6").arg(year, 4).arg(month, 2, 10, QChar('0')).arg(day, 2, 10, QChar('0')).
            arg(hour, 2, 10, QChar('0')).arg(min, 2, 10, QChar('0')).arg(sec, 2, 10, QChar('0'));
    return dateTime;
}

void ATLAS_BCAM::calculateResults(bdd &base_donnees, std::map<std::string, result> &results) {

    //on parcourt tous les points transformes dans le repere global : moyenne + dispersion
    // current date/time based on current system
    QString now = getDateTime();

    //sauvegarde des coordonnees du prisme dans le repere ATLAS pour chaque paire de spots
    std::string premier_prisme_atlas = base_donnees.getGlobalCoordPrisms().at(0).getName();

    for(unsigned int i=0; i<base_donnees.getGlobalCoordPrisms().size(); i++)
    {
        if(i>0 && base_donnees.getGlobalCoordPrisms().at(i).getName() == premier_prisme_atlas)
            break;

        global_coord_prism prism = base_donnees.getGlobalCoordPrisms().at(i);

        //nomenclature dans le repere ATLAS
        std::string name_prism_atlas = base_donnees.getName(prism.getPrism().getName());

        result& result = results[name_prism_atlas];
        result.setName(name_prism_atlas);
        result.setTime(now.toStdString());

        Eigen::MatrixXd coord(Eigen::DynamicIndex,3);
        int ligne=0;

        for(unsigned int j=0; j<base_donnees.getGlobalCoordPrisms().size(); j++)
        {
            global_coord_prism checkedPrism = base_donnees.getGlobalCoordPrisms().at(j);
            if(prism.getName() == checkedPrism.getName())
            {
                coord(ligne,0)=checkedPrism.getCoordPrismMountSys().x();
                coord(ligne,1)=checkedPrism.getCoordPrismMountSys().y();
                coord(ligne,2)=checkedPrism.getCoordPrismMountSys().z();
                ligne=ligne+1;
            }
        }

        result.setN(ligne);

        Eigen::MatrixXd mean(1,3);
        mean = coord.colwise().sum()/ligne; //somme de chaque colonne / par le nombre de lignes

        Eigen::MatrixXd result_var(ligne,3); //calcul de la variance
        for(int k=0; k<ligne; k++)
        {
            result_var(k,0)=(coord(k,0)-mean(0,0))*(coord(k,0)-mean(0,0));
            result_var(k,1)=(coord(k,1)-mean(0,1))*(coord(k,1)-mean(0,1));
            result_var(k,2)=(coord(k,2)-mean(0,2))*(coord(k,2)-mean(0,2));
        }

        Eigen::MatrixXd result_std_square(1,3); //calcul de l'ecart-type au carre
        result_std_square=result_var.colwise().sum()/ligne;

        result.setStd(Point3f(sqrt(result_std_square(0,0)),sqrt(result_std_square(0,1)),sqrt(result_std_square(0,2))));

        //delta selon composantes axiales
        float dx=0;
        float dy=0;
        float dz=0;
        //ajout de la constante de prisme
        for(unsigned int n=0; n<base_donnees.getPrismCorrections().size(); n++)
        {
            prism_correction correction = base_donnees.getPrismCorrections().at(n);
            if(base_donnees.getGlobalCoordPrisms().at(i).getPrism().getName() == correction.getPrism())
            {
                dx = correction.getDelta().x();
                dy = correction.getDelta().y();
                dz = correction.getDelta().z();
            }
        }

        result.setValue(Point3f(mean(0,0) + dx, mean(0,1) + dy, mean(0,2) + dz));

        results[name_prism_atlas] = result;
    }
}

void ATLAS_BCAM::updateResults(std::map<std::string, result> &results) {
    for (int row = 0; row < ui->tableWidget_results->rowCount(); row++) {
        std::string prism = ui->tableWidget_results->item(row, 0)->text().toStdString();

        result& r = results[prism];
        r.setName(prism);
        results[prism] = r;

        setResult(row, r);
    }
    ui->tableWidget_results->resizeColumnsToContents();

    write_ref(refFile, results);
    display(ui->refFileLabel, ui->refFile, refFile);
}

//fonction qui verifie qu'il n'y a pas d'erreurs dans le fichier de configuration                   [----> ok mais peut etre amelioree
void ATLAS_BCAM::check_input_data()
{
    //test des numéros des ports driver : sur les driver les numéros de ports possibles sont compris entre 1 et 8
    for (unsigned int i=0; i<m_bdd.getBCAMConfigs().size(); i++)
    {
        if(m_bdd.getBCAMConfigs().at(i).getDriverSocket()>8 || m_bdd.getBCAMConfigs().at(i).getDriverSocket()<1)
        {
            QMessageBox::critical(this,"Attention","les numéros des ports driver sont impérativement compris entre 1 et 8");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }

    //test des numéros des ports multiplexer : sur les multiplexer les numéros des ports possibles sont compris entre 1 et 10
    for (unsigned int i=0; i<m_bdd.getBCAMConfigs().size(); i++)
    {
        if(m_bdd.getBCAMConfigs().at(i).getMuxSocket()>10 || m_bdd.getBCAMConfigs().at(i).getMuxSocket()<1)
        {
            QMessageBox::critical(this,"Attention","les numéros des ports multiplexer sont impérativement compris entre 1 et 10");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }

    //test sur le nombre de détecteurs (ce nombre == 8 )
    if (m_bdd.getDetectors().size() != NBR_DETECTORS)
    {
        int nbr_detectors = m_bdd.getDetectors().size();
        QString str;
        str.setNum(nbr_detectors);

        QMessageBox::information(this,"Information","Le nombre de detecteurs est different de 7", QMessageBox::Ok, QMessageBox::Cancel);
    }

    //test pour vérifier si dans le fichier d'entrée, il y a un seul et unique détecteur avec un seul et unique identifiant
    for (unsigned int i=0; i<m_bdd.getDetectors().size(); i++)
    {

         for (unsigned int j=0; j<m_bdd.getDetectors().size(); j++)
        {
             if( j != i && m_bdd.getDetectors().at(i).getName() == m_bdd.getDetectors().at(j).getName())
             {
                 QMessageBox::critical(this,"Attention","Vous avez entre 2 fois le meme nom de detecteur !");
                 //mauvais format
                 format_input = 0;
                 //arrêt du programme
                 std::exit(EXIT_FAILURE);
             }
             if(j != i && m_bdd.getDetectors().at(i).getId() == m_bdd.getDetectors().at(j).getId())
             {
                 QMessageBox::critical(this,"Attention","Vous avez entre 2 fois le meme numero d'identifiant pour un detectuer !");
                 //mauvais format
                 format_input = 0;
                 //arrêt du programme
                 std::exit(EXIT_FAILURE);
             }
        }
    }

    //test sur la longueur des chaînes de caractères (identifiant des BCAMs)
    for (unsigned int i=0; i<m_bdd.getBCAMConfigs().size(); i++)
    {
        if(m_bdd.getBCAMConfigs().at(i).getName().size() != ID_LENGTH_BCAM)
        {
            QMessageBox::critical(this,"Attention","Au moins 1 BCAM comporte un identifiant de longueur inapropriee !");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }


    //test pour vérifier si dans le fichier d'entrée, il y a une seule et unique BCAM (vu la structure du fichier elle appartient à un unique detecteur)
    for (unsigned int i=0; i<m_bdd.getBCAMConfigs().size(); i++)
    {
        for (unsigned int j=0; j<m_bdd.getBCAMConfigs().size(); j++)
        {
            if(j != i && m_bdd.getBCAMConfigs().at(i).getName() == m_bdd.getBCAMConfigs().at(j).getName())
            {
                QMessageBox::critical(this,"Attention","Vous avez entre 2 fois le meme numero d'identifiant de BCAM !");
                //mauvais format
                format_input = 0;
                //arrêt du programme
                std::exit(EXIT_FAILURE);
            }
        }
    }

    //test pour éviter que 2 BCAMs ne soient branchées sur le même port multiplexer et même port driver à la fois
    for (unsigned int i=0; i<m_bdd.getBCAMConfigs().size(); i++)
    {
        for (unsigned int j=0; j<m_bdd.getBCAMConfigs().size(); j++)
        {
            if((i != j) && (m_bdd.getBCAMConfigs().at(i).getDriverSocket() == m_bdd.getBCAMConfigs().at(j).getDriverSocket()) &&
                    (m_bdd.getBCAMConfigs().at(i).getMuxSocket() == m_bdd.getBCAMConfigs().at(j).getMuxSocket()))
            {
                QMessageBox::critical(this,"Attention","2 BCAMs ne peut pas être branchée sur le même port driver et multiplexer à la fois !");
                //mauvais format
                format_input = 0;
                //arrêt du programme
                std::exit(EXIT_FAILURE);
            }
        }
    }
}

//fonction qui verifie si toutes les BCAMS sont contenues dans le fichier de calibration            [----> not yet, on suppose que le fichier de calibration est correct
void ATLAS_BCAM::check_calibration_database()
{
    /*int exist_l1 = 0;
    int exist_l2 = 0;

    //verifier si toutes les informations de calibration existent dans le fichier
    for(int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        for(int j=0; j<m_bdd.Get_liste_calib1().size(); j++)
        {
            if(m_bdd.Get_liste_BCAM().at(i).Get_nom_BCAM() == m_bdd.Get_liste_calib1().at(j).Get_id_BCAM())
            {
                exist_l1++;
            }
        }
    }

    for(int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        for(int j=0; j<m_bdd.Get_liste_calib2().size(); j++)
        {
            if(m_bdd.Get_liste_BCAM().at(i).Get_nom_BCAM() == m_bdd.Get_liste_calib1().at(j).Get_id_BCAM())
            {
                exist_l2++;
            }
        }
    }
    // si les variables ont ete incrementees d'au moins le nombre de BCAM
    if(exist_l1 <= m_bdd.Get_liste_BCAM().size() || exist_l2 <= m_bdd.Get_liste_BCAM().size())
    QMessageBox::critical(this,"Attention","Il manque des donnees de calibration pour au moins 1 BCAM");*/
}


//fonction qui ecrit un fichier tcl avec les parametres par defaut pour la fenetre Acquisifier      [---> ok
int ATLAS_BCAM::write_settings_file(QString settings_file)
{
    //écriture dans un fichier
    std::ofstream fichier(settings_file.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(!fichier) return 0;

    //écriture la partie du script qui lance l'acquisition automatique
    fichier<<"set Acquisifier_config(auto_load) \"0\" \n"
           <<"set Acquisifier_config(title_color) \"purple\" \n"
           <<"set Acquisifier_config(extended_acquisition) \"0\" \n"
           <<"set Acquisifier_config(auto_repeat) \"0\" \n"
           <<"set Acquisifier_config(analyze) \"0\" \n"
           <<"set Acquisifier_config(auto_run) \"0\" \n"
           <<"set Acquisifier_config(cycle_period_seconds) \"0\" \n"
           <<"set Acquisifier_config(daq_script) \""<<appDirPath().append("/").append(fichier_script).toStdString()<<"\" \n"
           <<"set Acquisifier_config(run_results) \""<<resultFile.fileName().toStdString()<<"\" \n"
           <<"set Acquisifier_config(analysis_color) \"green\" \n"
           <<"set Acquisifier_config(auto_quit) \"0\" \n"
           <<"set Acquisifier_config(result_color) \"green\" \n"
           <<"set Acquisifier_config(num_steps_show) \"20\" \n"
           <<"set Acquisifier_config(num_lines_keep) \"1000\" \n"
           <<"set Acquisifier_config(restore_instruments) \"0\" \n";

      fichier.close();
      return 1;
}

//fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ   [----> ok
int ATLAS_BCAM::write_params_file(QString params_file)
{
    //écriture dans un fichier
    std::ofstream fichier(params_file.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(!fichier) return 0;

    fichier<<"#~ Settings pour les BCAMs"
           <<"set LWDAQ_info_BCAM(daq_password) \"no_password\" \n"
           <<"set LWDAQ_info_BCAM(ambient_exposure_seconds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(counter) \"0\" \n"
           <<"set LWDAQ_info_BCAM(verbose_description) \"  {Spot Position X (um)}  {Spot Position Y (um) or Line Rotation Anticlockwise (mrad)}  {Number of Pixels Above Threshold in Spot}  {Peak Intensity in Spot}  {Accuracy (um)}  {Threshold (counts)}\" \n"
           <<"set LWDAQ_info_BCAM(flash_max_tries) \"30\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_max) \"0.1\" \n"
           <<"set LWDAQ_info_BCAM(control) \"Idle\" \n"
           <<"set LWDAQ_info_BCAM(analysis_return_intensity) \"0\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_left) \"20\" \n"
           <<"set LWDAQ_info_BCAM(analysis_show_timing) \"0\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_bottom) \"243\" \n"
           <<"set LWDAQ_info_BCAM(extended_parameters) \"0.6 0.9 0 1\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_right) \"343\" \n"
           <<"set LWDAQ_info_BCAM(text) \".bcam.text\" \n"
           <<"set LWDAQ_info_BCAM(daq_source_device_type) \"2\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_step) \"0.000002\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_width) \"344\" \n"
           <<"set LWDAQ_info_BCAM(state_label) \".bcam.buttons.state\" \n"
           <<"set LWDAQ_info_BCAM(daq_source_ip_addr) \"*\" \n"
           <<"set LWDAQ_info_BCAM(analysis_pixel_size_um) \"10\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_height) \"244\" \n"
           <<"set LWDAQ_info_BCAM(window) \".bcam\" \n"
           <<"set LWDAQ_info_BCAM(analysis_show_pixels) \"0\" \n"
           <<"set LWDAQ_info_BCAM(name) \"BCAM\" \n"
           <<"set LWDAQ_info_BCAM(daq_image_top) \"1\" \n"
           <<"set LWDAQ_info_BCAM(photo) \"bcam_photo\" \n"
           <<"set LWDAQ_info_BCAM(flash_num_tries) \"0\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_reduce) \"0.1\" \n"
           <<"set LWDAQ_info_BCAM(file_use_daq_bounds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(peak_min) \"100\" \n"
           <<"set LWDAQ_info_BCAM(zoom) \"1\" \n"
           <<"set LWDAQ_info_BCAM(analysis_return_bounds) \"0\" \n"
           <<"set LWDAQ_info_BCAM(delete_old_images) \"1\" \n"
           <<"set LWDAQ_info_BCAM(daq_device_type) \"2\" \n"
           <<"set LWDAQ_info_BCAM(file_try_header) \"1\" \n"
           <<"set LWDAQ_info_BCAM(peak_max) \"180\" \n"
           <<"set LWDAQ_info_BCAM(flash_seconds_transition) \"0.000030\" \n"
           <<"set LWDAQ_info_BCAM(daq_extended) \"0\" \n"
           <<"set LWDAQ_config_BCAM(analysis_threshold) \"10 #\" \n"
           <<"set LWDAQ_config_BCAM(daq_ip_addr) \""<<m_bdd.getDriverIpAddress()<<"\" \n"
           <<"set LWDAQ_config_BCAM(daq_flash_seconds) \"0.000010\" \n"
           <<"set LWDAQ_config_BCAM(daq_driver_socket) \"5\" \n"
           <<"set LWDAQ_config_BCAM(analysis_num_spots) \"2\" \n"
           <<"set LWDAQ_config_BCAM(image_source) \"daq\" \n"
           <<"set LWDAQ_config_BCAM(daq_subtract_background) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_adjust_flash) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_device_element) \"3 4\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_mux_socket) \"1\" \n"
           <<"set LWDAQ_config_BCAM(file_name) \"./images/BCAM*\" \n"
           <<"set LWDAQ_config_BCAM(intensify) \"exact\" \n"
           <<"set LWDAQ_config_BCAM(memory_name) \"BCAM_0\" \n"
           <<"set LWDAQ_config_BCAM(daq_source_driver_socket) \"8\" \n"
           <<"set LWDAQ_config_BCAM(analysis_enable) \"1\" \n"
           <<"set LWDAQ_config_BCAM(verbose_result) \"0\" \n"
           <<"set LWDAQ_config_BCAM(daq_device_element) \"2\" \n"
           <<"set LWDAQ_config_BCAM(daq_mux_socket) \"1\" \n";

    fichier.close();
    return 1;
}

//fonction qui gere les selections dans les checkbox                                                [----> ok
void ATLAS_BCAM::changedMode(int /* index */)
{
    QString mode_adepo = ui->modeBox->currentText();
    if(mode_adepo == "MONITORING")
    {
        //changement du texte
        ui->textEdit_function_mode->setText("Frequence d\'acquisition (s) :");
        //changement des valeurs d'interval pour le temps
        ui->timeBox->setMinimum(240);  //frequence maxi : 1 mesure toutes les 15 min: 900
        ui->timeBox->setMaximum(86400); //frequence mini ; 1 mesure par jour
    }
    else
    {
        //changement du text
        ui->textEdit_function_mode->setText("Temps d\'acquisition (s) :");
        //changement des valeurs d'interval pour le temps
        ui->timeBox->setMinimum(11);
        ui->timeBox->setMaximum(300);
        ui->timeBox->setValue(30);
    }
}

//fonction thread pour lancer les modes d'acquisition                                               [-----> ok
void ATLAS_BCAM::startCalcul()
{
    if(ui->modeBox->currentText() == "CLOSURE")
    {
        ui->boutton_arreter->setEnabled(true);

        needToCalculateResults = true;

        //lancement des acquisitions + calcul
        lancer_acquisition();
    }
    else
    {
        //boite de dialogue avant de debuter le mode monitoring
        int reponse = QMessageBox::question(this, "Mode monitoring", "Attention, vous etes en mode monitoring. Assurez vous d'avoir selectionner tous les detecteurs avant de continuer.", QMessageBox::Yes | QMessageBox::No);
        //si la reponse est positive
        if (reponse == QMessageBox::Yes)
        {
            //desactivation de toute la fenetre sauf le bouton stop qui permet de tuer le QTimer
            ui->boutton_arreter->setEnabled(true);
            ui->tableWidget_liste_detectors->setEnabled(false);
            ui->modeBox->setEnabled(false);
            ui->airpadBox->setEnabled(false);
            ui->timeBox->setEnabled(false);
            ui->Boutton_lancer->setEnabled(false);
            ui->tableWidget_liste_bcams->setEnabled(false);
            //lancement des acquisitions + calcul
            QObject::connect(timer,SIGNAL(timeout()),this,SLOT(lancer_acquisition()));
            //boucle selon la frequence precisee par le user
            timer->start(ui->timeBox->value()*1000); //en mode monitoring time_value est utilisee comme frequence et non pas comme temps d'acquisition
            // fire initial time
            lancer_acquisition();
        }
        //si la reponse est negative
        else if (reponse == QMessageBox::No)
        {
            //rien ne se passe
        }
    }
}
