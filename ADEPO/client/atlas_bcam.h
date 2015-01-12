#ifndef ATLAS_BCAM_H
#define ATLAS_BCAM_H

#include <QMainWindow>
#include <QWidget>
#include <QTextBrowser>
#include <QLineEdit>
#include <QLabel>
#include <QTextEdit>

#include "lwdaq_client.h"
#include "bdd.h"
#include "result.h"
#include "util.h"

#include "server.h"
#include "calibration.h"
#include "setup.h"

namespace Ui {
class ATLAS_BCAM;
}

class ATLAS_BCAM : public QMainWindow
{
        Q_OBJECT

public:
    enum state { IDLE, RUN, STOP, WAITING, CALCULATING };

    explicit ATLAS_BCAM(QWidget *parent = 0);
    ~ATLAS_BCAM();
    //fonction qui remplie le tableau de detecteurs affiche dans l'interface
    void fillDetectorTable();

    //fonction qui permet de calculer les coordonnees de chaque prisme
    void calculateCoordinates();

    //fonction qui ecrit un fichier tcl avec les parametres par defaut pour l'onglet acquisifier de LWDAQ et lance automatiquement l'auto-run
    int writeSettingsFile(QString settings_file);

    //fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ
    int writeParamsFile(QString params_file);

public slots:

signals:

private slots:
    void showBCAMTable();
    void showBCAM(int row, int);
    void lwdaqStateChanged();
    void timeChanged();
    void changedAirpad(int index);
    void changedTimeValue(int value);
    void changedWaitingTimeValue(int value);
    void changedFormat(int state);
    void resetDelta();
    void startClosure();
    void startMonitoring();
    void startAcquisition();
    void stopAcquisition();
    void stopRepeatAcquisition();
    void helpAtlasBCAM();
    void openDialog();

private:
    // tbr
    Server server;
    Calibration calibration;
    Setup setup;

    Ui::ATLAS_BCAM *ui;
    BDD m_bdd;
    Configuration config;
    QString path_fich;
    std::map<std::string, result> results;
    int selectedBCAM;
    std::string mode;

    QDir lwdaqDir;
    QFile resultFile;
    QString refFile;
    LWDAQ_Client *lwdaq_client;
    QLabel lwdaqStatus;
    bool needToCalculateResults;
    LWDAQ_Client::state previousState;

    state adepoState;
    bool askQuestion;
    QTimer *waitingTimer;
    QTimer *updateTimer;

    QString getDateTime();
    QString appDirPath();
    void openInputDir();
    void setResult(int row, result& result);
    void setResult(int row, Point3f point, int columnSet, int precision);
    void calculateResults(BDD &base_donnees, std::map<std::string, result> &results);
    void updateResults(std::map<std::string, result> &results);
    void setEnabled(bool enabled);
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
    void setMode(std::string mode);

    int writeBCAMScript(std::ofstream& file, BCAM bcam, int spots, std::string sourceDeviceElement);
    std::string getSourceDeviceElement(bool isPrism, bool flashSeparate, int deviceElement, bool first);
    QString getStateAsString();
    void updateStatusBar();
};

#endif // ATLAS_BCAM_H
