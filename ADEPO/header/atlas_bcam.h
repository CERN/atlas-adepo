#ifndef ATLAS_BCAM_H
#define ATLAS_BCAM_H

#include <QMainWindow>
#include "bdd.h"
#include "result.h"
#include "QWidget"
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
    //fonction qui recupere la valeur du temps d'acqusiition specifiee par l'utilisateur
    void save_time_value();

    //fonction qui ouvre une fenetre de dialogue pour specifier l'emplacement du dossier input
    void ouvrirDialogue();

    //fonction qui ouvre une fenetre pour l'aide au logiciel
    void aide_atlas_bcam();

    //fonction qui affiche les BCAMs qui qppqrtiennent a la liste de detecteurs selectionnes
    void affiche_liste_BCAMs(int ligne, int colonne);

    //fonction qui lance les acquisitions lorsqu'on clicke sur le boutton correspondant
    void lancer_acquisition();

    //fonction qui permet l'arret des acquisitions lorsqu'on clicke sur le boutton correspondant
    void stop_acquisition();

    //fonction qui gere les selections dans les checkbox
    void get_mode();

    //fonction qui recupere l'etat des airpads
    void get_airpad_state();

    //fonction qui agit apres un press bouton sur "Lancer"
    void startCalcul();

    void resetDelta();


signals:


private slots:
    void lwdaqStateChanged();
    void lwdaqTimeChanged();

private:
    Ui::ATLAS_BCAM *ui;
    bdd m_bdd;
    QString path_fich;
    mythread *thread; // this is our thread
    std::map<std::string, result> results;

    QDir lwdaqDir;
    QFile resultFile;
    LWDAQ_Client *lwdaq_client;
    QLabel lwdaqStatus;
    bool needToCalculateResults;
    LWDAQ_Client::state previousState;

    void openInputDir();
    void setResult(int row, Point3f point, int columnSet);
    void calculateResults(bdd &base_donnees, std::map<std::string, result> &results);
    void updateResults(std::map<std::string, result> &results);
    void setEnabled(bool enabled);
};

#endif // ATLAS_BCAM_H
