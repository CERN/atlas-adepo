#ifndef ATLAS_BCAM_H
#define ATLAS_BCAM_H

#include <QMainWindow>
#include "bdd.h"
#include "result.h"
#include <QWidget>
#include <QTextBrowser>
#include <QLineEdit>
#include <QLabel>
#include <QTextEdit>
#include "mythread.h"
#include "lwdaq_client.h"

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
    void remplir_tableau_detectors();

    //fonction qui verifie si les donnees en entree dans le fichier de configuration sont correctes
    void check_input_data();

    //fonction qui verifie si les donnees de fichier de calibration existent pour chaque BCAM
    void check_calibration_database();

    //fonction qui genere un script tcl pour lancer les acquisitions LWDAQ que sur la liste de detetcteurs selectionnes
    int write_script_file(QString nom_fichier_script_acquisition, std::vector<BCAM> &liste_temp_bcam);

    //fonction qui permet de calculer les coordonnees de chaque prisme
    void calcul_coord();

    ////fonction qui ecrit un fichier tcl avec les parametres par defaut pour l'onglet acquisifier de LWDAQ et lance automatiquement l'auto-run
    int write_settings_file(QString settings_file);

    //fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ
    int write_params_file(QString params_file);

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
    void lancer_acquisition();
    void stop_acquisition();
    void stop_repeat_acquisition();
    void aide_atlas_bcam();
    void ouvrirDialogue();

private:
    Ui::ATLAS_BCAM *ui;
    bdd m_bdd;
    QString path_fich;
    mythread *thread; // this is our thread
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
    void calculateResults(bdd &base_donnees, std::map<std::string, result> &results);
    void updateResults(std::map<std::string, result> &results);
    void setEnabled(bool enabled);
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
    void setMode(std::string mode);

    int write_bcam_script(std::ofstream& file, BCAM bcam, int spots, std::string sourceDeviceElement);
    std::string getSourceDeviceElement(bool isPrism, bool flashSeparate, int deviceElement, bool first);
    QString getStateAsString();
    void updateStatusBar();
};

#endif // ATLAS_BCAM_H
