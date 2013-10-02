#include "header/atlas_bcam.h"
#include "header/ouverture_projet.h"
#include "header/read_input.h"
#include "header/ui_ATLAS_BCAM.h"
#include "header/read_calibration_database.h"
#include "header/liste_bcam_from_id_detector.h"
#include "header/write_aquisifier_script.h"
#include "header/write_bash_script.h"
#include "header/read_lwdaq_output.h"
#include "header/img_coord_to_bcam_coord.h"
#include "header/write_file_obs_mount_system.h"
<<<<<<< HEAD
#include "header/calcul_coord_bcam_system.h"
#include "header/helmert.h"
#include "header/mythread.h"
#include "header/mount_prism_to_global_prism.h"
=======

>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518


#include <iostream>
#include <QtGui>
#include "QWidget"
<<<<<<< HEAD
#include "QtTest/QTest"
#include <time.h>

#define NBR_DETECTORS 8
=======

#define NBR_DETECTORS 7
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
#define ID_LENGTH_BCAM 14

/********************************************************************************************/
#define NAME_CONFIGURATION_FILE "configuration_file.txt"
<<<<<<< HEAD
#define NAME_CALIBRATION_FILE "BCAM_Parameters.txt"
=======
#define NAME_CALIBRATION_FILE "calibration_file.txt"
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
#define NAME_LWDAQ_FOLDER "LWDAQ"
/********************************************************************************************/


//declaration des variables globales
std::string path_lwdaq;
QString path_input_folder;
<<<<<<< HEAD
//valeur par defaut si l'utilisateur ne touche pas au spinbox
QString time_value = "30";
//valeur par defaut du mode d'utilisation est CLOSURE
QString mode_adepo = "CLOSURE";
//valeur par defaut du mode des airpads
QString mode_airpad = "OFF";

//nom du fichier script qui va lancer l'acquisition que sur les detecteurs selectionnes
std::string fichier_script = "Acquisifier_script_file.tcl";
=======
QString time_value;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

//bool pour savoir si le programme est entrain d'acquerir des obs
//action = 0 --> pas d'observations
//action = 1 --> LWDAQ est entrain de tourner
int action=0;

//bool pour savoir si le tableau des BCAM et remplie
//tab_bcam= 0 --> pas encore rempli
//tab_bcam = 1 --> remplie et j'active le boutton des acquis
int tab_bcam=0;

//bool pour savoir si y a eu une erreur dans le format de l'input
//format_input = 1 --> tout est bon
//format_input = 0 --> il y a une erreur et on ne charge pas le fichier
int format_input=1;

<<<<<<< HEAD
//compteur pour savoir combien de fois l'utilisateur a charge un fichier d'input
int compteur_chargement = 0;

//timer pour le mode monitoring
QTimer *timer = new QTimer();

ATLAS_BCAM::ATLAS_BCAM(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::ATLAS_BCAM)                                                                        //[---> ok
=======
ATLAS_BCAM::ATLAS_BCAM(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::ATLAS_BCAM)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
{
        ui->setupUi(this);
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
        QObject::connect(ui->tableWidget_liste_detectors, SIGNAL(cellClicked(int,int)),this, SLOT(affiche_liste_BCAMs(int,int)));

        //lancer les acquisitions (arret automoatique)
<<<<<<< HEAD
        QObject::connect(ui->Boutton_lancer,SIGNAL(clicked()), this,SLOT(startCalcul()));

        //QObject::connect(timer,SIGNAL(timeout()),this,SLOT(lancer_acquisition()));
=======
        QObject::connect(ui->Boutton_lancer,SIGNAL(clicked()), this,SLOT(lancer_acquisition()));
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

        //stopper l'acquisition (arret force)
        QObject::connect(ui->boutton_arreter,SIGNAL(clicked()),this,SLOT(stop_acquisition()));

<<<<<<< HEAD
        //recuperer la valeur du temps d'acquisition
        QObject::connect(ui->spinBox, SIGNAL(valueChanged(int)), this, SLOT(save_time_value()));

        //recuperer la valeur du mode : CLOSURE ou MONITORING
        QObject::connect(ui->comboBox, SIGNAL(currentIndexChanged(int)), this, SLOT(get_mode()));

        //recuperer la valeur des airpads : ON ou OFF
        QObject::connect(ui->comboBox_2, SIGNAL(currentIndexChanged(int)), this, SLOT(get_airpad_state()));
=======
        //calcul des coordonnees du Prisme
        //QObject::connect(ui->boutton_calculer,SIGNAL(clicked()),this,SLOT(calcul_coord()));

        //recuperer la valeur du temps d'acquisition
        QObject::connect(ui->lineEdit_value_seconds, SIGNAL(textEdited(QString)), this, SLOT(save_time_value()));
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

}

ATLAS_BCAM::~ATLAS_BCAM()
{
    delete ui;
}

<<<<<<< HEAD
//ouverture d'une boite de dialogue                                                                 [----> ok
void ATLAS_BCAM::ouvrirDialogue()
{
    path_input_folder = QFileDialog::getExistingDirectory(this, "Chemin du dossier", QString());
    compteur_chargement++;
    std::cout<<compteur_chargement<<std::endl;

    if(compteur_chargement > 1) //gestion du probleme lorsqu'on charge un fichier par dessus l'autre
    {
        m_bdd.vidage_complet(); //on vide tout car nouveau fichier
        compteur_chargement = 1; //comme si c'etait le premier chargement
    }
=======
void ATLAS_BCAM::ouvrirDialogue()
{
    path_input_folder = QFileDialog::getExistingDirectory(this, "Chemin du dossier", QString());
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

    //chemin du fichier d'entree
    //path_input_folder = fenetre_ouverture->Get_path_fich();

    //appel pour la lecture de fichier
    read_input(path_input_folder.toStdString().append("/").append(NAME_CONFIGURATION_FILE),m_bdd);

<<<<<<< HEAD
    //estimation des 6 parametres pour chaque BCAM
    helmert(m_bdd);

=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    //verification des infos du fichier d'entree
    //check_input_data();

    //activation du boutton pour lancer les acquisitions
    enable_PushButton();

<<<<<<< HEAD
    //remplissage tableau detectors que si le format du fichier input est bon !
=======
    //remplissage tableau detectors
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    if(format_input == 1)
    {
        remplir_tableau_detectors();
    }

    //lecture du fichier de calibration
    read_calibration_database(path_input_folder.toStdString().append("/").append(NAME_CALIBRATION_FILE),m_bdd);

<<<<<<< HEAD
    //recuperation de la partie qui nous interesse du fichier de calibration
    //clean_calib(m_bdd);

=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    // chemin d'acces a l'emplacement de LWDAQ
    path_lwdaq = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("lwdaq");
}

<<<<<<< HEAD
//fonction qui enregistre la valeur du temps d'acquisition entree par l'utilisateur                 [----> ok
void ATLAS_BCAM::save_time_value()
{
    time_value = ui->spinBox->text();
}

//fonction d'ouverture de la fenêtre d'aide de l'outil ARCAPA                                       [----> not yet]
=======
//fonction qui enregistre la valeur du temps d'acquisition entree par l'utilisateur
void ATLAS_BCAM::save_time_value()
{
    time_value = ui->lineEdit_value_seconds->text();
    enable_PushButton();
}

//fonction d'ouverture de la fenêtre d'aide de l'outil ARCAPA
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
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

<<<<<<< HEAD
//fonction permettant de charger la liste des detectors après ouverture d'un projet                 [---> ok
=======
//fonction permettant de charger la liste des detectors après ouverture d'un projet
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
void ATLAS_BCAM::remplir_tableau_detectors()
{
    //recuperation de la liste des nom des detecteurs
    std::vector<detector> detectors_data = this->m_bdd.Get_liste_detector();

    // nombre de lignes du tableau de detecteurs dans l'interface
    int nb_lignes = detectors_data.size();
    ui->tableWidget_liste_detectors->setRowCount(nb_lignes);

    for(int i=0; i<nb_lignes; i++)
    {
<<<<<<< HEAD

        //ajout du numero id du detetcteur
        QTableWidgetItem *item_num = new QTableWidgetItem();
        item_num->setData(0,detectors_data.at(i).Get_num_id_detector());
        ui->tableWidget_liste_detectors->setItem(i,0,item_num);

=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
        //ajout du nom du detecteur
        QTableWidgetItem *item_nom = new QTableWidgetItem();
        item_nom->setText(QString::fromStdString(detectors_data.at(i).Get_nom_detector()));
        ui->tableWidget_liste_detectors->setItem(i,1,item_nom);

<<<<<<< HEAD
        //ajout de la constante de aipad
        QTableWidgetItem *item_dist_const = new QTableWidgetItem();
        item_dist_const->setData(0,detectors_data.at(i).Get_airpad_on_add_dist());
        ui->tableWidget_liste_detectors->setItem(i,2,item_dist_const);
=======
        //ajout du numero id du detetcteur
        QTableWidgetItem *item_num = new QTableWidgetItem();
        item_num->setData(0,detectors_data.at(i).Get_num_id_detector());
        ui->tableWidget_liste_detectors->setItem(i,0,item_num);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    }


}

<<<<<<< HEAD
//fonction permettant de charger la liste des BCAMs qui appartiennent a un detector                 [---> ok
void ATLAS_BCAM::affiche_liste_BCAMs(int ligne, int colonne)
{
    //recuperation du nombre de detecteurs
    int nb_detetctors = ui->tableWidget_liste_detectors->selectedItems().size()/3;
=======
//fonction permettant de charger la liste des BCAMs qui appartiennent a un detector
void ATLAS_BCAM::affiche_liste_BCAMs(int ligne, int colonne)
{
    //recuperation du nombre de detecteurs
    int nb_detetctors = ui->tableWidget_liste_detectors->selectedItems().size()/2;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

    //vecteur qui va contenir la liste des BCAMs temporaires selectionnees dans le tableau
    std::vector<BCAM> *liste_bcam = new std::vector<BCAM>;

<<<<<<< HEAD
=======
    //nom du fichier script qui va lancer l'acquisition que sur les detecteurs selectionnes
    std::string fichier_script = "Acquisifier_script_file.tcl";

>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    //recuperation des donnees a afficher
    for(int i=0; i<nb_detetctors; i++)
    {
        //recuperation de l'identifiant du detecteur
<<<<<<< HEAD
        QString id_detector = ui->tableWidget_liste_detectors->selectedItems().at(i*3)->text();
=======
        QString id_detector = ui->tableWidget_liste_detectors->selectedItems().at(i*2)->text();
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

        //recuperation des donnes a afficher
        std::vector<BCAM> *m_liste_bcam = new std::vector<BCAM>(liste_bcam_from_id_detector(m_bdd, id_detector.toInt()));

        //insertion dans la tableWidget qui affiche les bcams
        liste_bcam->insert(liste_bcam->begin(), m_liste_bcam->begin(), m_liste_bcam->end());

        //ecriture du script d'acquisition des detecteurs selectionnees
        ecriture_script_acquisition(fichier_script, *liste_bcam);

        //on supprime le pointeur a la fin
        delete m_liste_bcam;
    }

    // nombre de lignes dans la table
    int nb_lignes = liste_bcam->size();
    ui->tableWidget_liste_bcams->setRowCount(nb_lignes);

    for(int i=0; i<liste_bcam->size(); i++)
    {
      //ajout dans la tableWidget qui affiche les BCAMs
      QTableWidgetItem *nom_bcam = new QTableWidgetItem();
      nom_bcam->setText(QString::fromStdString(liste_bcam->at(i).Get_nom_BCAM()));
      ui->tableWidget_liste_bcams->setItem(i,0,nom_bcam);

      QTableWidgetItem *num_detector = new QTableWidgetItem();
      num_detector->setData(0,liste_bcam->at(i).Get_id_detector());
      ui->tableWidget_liste_bcams->setItem(i,1,num_detector);

      QTableWidgetItem *num_port_driver = new QTableWidgetItem();
      num_port_driver->setData(0,liste_bcam->at(i).Get_num_Port_Driver());
      ui->tableWidget_liste_bcams->setItem(i,2,num_port_driver);

      QTableWidgetItem *num_port_mux = new QTableWidgetItem();
      num_port_mux->setData(0,liste_bcam->at(i).Get_num_Port_Mux());
      ui->tableWidget_liste_bcams->setItem(i,3,num_port_mux);

<<<<<<< HEAD
      QTableWidgetItem *objet_vise = new QTableWidgetItem();
      objet_vise->setText(QString::fromStdString(liste_bcam->at(i).Get_objet_vise()));
      ui->tableWidget_liste_bcams->setItem(i,4,objet_vise);
=======
      QTableWidgetItem *type_bcam = new QTableWidgetItem();
      type_bcam->setText(QString::fromStdString(liste_bcam->at(i).Get_type_bool_BCAM()));
      ui->tableWidget_liste_bcams->setItem(i,4,type_bcam);

      QTableWidgetItem *objet_vise = new QTableWidgetItem();
      objet_vise->setText(QString::fromStdString(liste_bcam->at(i).Get_objet_vise()));
      ui->tableWidget_liste_bcams->setItem(i,5,objet_vise);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

    }
    tab_bcam =1;
    enable_PushButton();
}

<<<<<<< HEAD
//fonction qui lance les acquisitions LWDAQ                                                         ----> ok mais qu'est ce qui se passe apres les acquisitions ?
void ATLAS_BCAM::lancer_acquisition()
{
        //le programme est en mode acquisition
        action = 1;

        //je supprime le repertoire de meme nom si il existe deja
        system("rm -rf scripts_lwdaq");

        //creation d'un repertoire qui va contenir les scripts en Tcl
        system("mkdir scripts_lwdaq");

        //input : startup pour LWDAQ
        std::string startup_file = "Acquisifier_params.tcl";
        write_input_script(startup_file);

        //input : startup pour les settings de l'acquisifier
        std::string acquisifier_settings = "Acquisifier_Settings.tcl";
        write_settings_file(acquisifier_settings);

        //input : le bash pour copier les fichiers + lancer l'acquisition de LWDAQ + arret de LWDAQ apres xx secondes
        std::string bash_script = "bash_script.sh";
        ecriture_script_bash(bash_script);

        //deplacer les fichiers en Tcl dans le repertoire script_lwdaq
        system("cp Acquisifier_* scripts_lwdaq");

        //si un fichier de resultats existe deja dans le dossier LWDAQ, je le supprime avant
        std::string name_file_result = path_input_folder.toStdString().append("/").append("LWDAQ").append("/Tools").append("/Data/").append("Acquisifier_Results.txt");
        system(("rm -rf "+name_file_result).c_str());

        //lancement du programme LWDAQ + arret apres nombre de secondes specifiees par le user
        if(system(("bash "+bash_script).c_str()))
           std::cout << "ACCESS_SUCCESS_to_LWDAQ"<<std::endl;
        else
           std::cout << "ACCESS_ENDED_to_LWDAQ"<<std::endl;

        //je calcule les coordonnees des prismes dans le repere lie a chaque BCAM (la lecture du fichier de coordonnees images se fait dans la fonction "calcul_coord()"
        calcul_coord();
}

//fonction qui permet d'arreter l'acquisition LWDAQ (seuleuement en mode monitoring)                [----> ok
void ATLAS_BCAM::stop_acquisition()
{
    //le boutton stop ne marche qu'en mode monitoring <==> arreter le QTimer
    timer->stop();
    //activation de la fenetre
    ui->tableWidget_liste_detectors->setEnabled(true);
    ui->comboBox->setEnabled(true);
    ui->comboBox_2->setEnabled(true);
    ui->spinBox->setEnabled(true);
    ui->Boutton_lancer->setEnabled(true);
    ui->tableWidget_liste_bcams->setEnabled(true);
    ui->boutton_arreter->setEnabled(false);
}

//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM + suavegarde            [----> ok
void ATLAS_BCAM::calcul_coord()
{

   //je lis le fichier de sortie de LWDAQ qui contient les observations puis je stocke ce qui nous interesse dans la bdd
   std::string fichier_obs_brutes = path_input_folder.toStdString().append("/").append("LWDAQ").append("/Tools").append("/Data/").append("Acquisifier_Results.txt");

   int lecture_output_result = read_lwdaq_output(fichier_obs_brutes, m_bdd);

   if(lecture_output_result == 0 )
   {
       QMessageBox::critical(this,"Attention","le fichier de resultats et inexistant ou illisible. Verifiez la connextion avec le dirver.");
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
   mount_prism_to_global_prism(m_bdd);

   //enregistrement du fichier qui contient les observations dans le repere CCD et dans le repere MOUNT : spots + prismes
   //on recupere la date dans une variable
   time_t t = time(NULL);
   std::string tps_calcul = asctime(localtime(&t));
   //std::cout<<tps_calcul<<std::endl;

   std::string file_name = "Archive/Observations_MOUNT_System";

   std::string fichier_obs_mount = file_name.append("_").append(tps_calcul).append(".txt");
   write_file_obs_mount_system(fichier_obs_mount, m_bdd);

   //vidage des acquisitions
   m_bdd.vidage();
   }
}

//fonction qui verifie qu'il n'y a pas d'erreurs dans le fichier de configuration                   [----> ok mais peut etre amelioree
=======
//fonction qui lance les acquisitions LWDAQ
void ATLAS_BCAM::lancer_acquisition()
{
    //le programme est en mode acquisition
    action = 1;

    // activation du boutton pour arreter l'acquisition
    enable_PushButton();

    //creation d'un repertoire qui va contenir les scripts en Tcl
    system("mkdir scripts_lwdaq");

    //input : startup pour LWDAQ
    std::string startup_file = "Acquisifier_params.tcl";
    write_input_script(startup_file);

    //input : startup pour les settings de l'acquisifier
    std::string acquisifier_settings = "Acquisifier_Settings.tcl";
    write_settings_file(acquisifier_settings);

    //input : le bash pour copier les fichiers + lancer l'acquisition de LWDAQ
    std::string bash_script = "bash_script.sh";
    ecriture_script_bash(bash_script);

    //deplacer les fichiers en Tcl dans le repertoire scripta_lwdaq
    system("mv Acquisifier_* scripts_lwdaq");

    //lancement du programme LWDAQ par commande systeme
    if(system(("bash "+bash_script).c_str()))
        std::cout << "ACCESS_SUCCESS"<<std::endl;
    else
    {
        std::cout << "ACCESS_FAILURE"<<std::endl;
    }

    //creation d'un dossier qui va contenir les resultats
    system("mkdir Resultats");

    //copie des observations lwdaq en coordonnees images
    //system("cp ../LWDAQ/Tools/Data/Acquisifier_Results.txt /home/cern-mehdi/Documents/Projet_BCAM/Resultats");

}

//fonction qui permet d'arreter l'acquisition LWDAQ (seuleuement en mode monitoring ?)
void ATLAS_BCAM::stop_acquisition()
{
    std::string nom_fichier_bash_stop = "bash_script_stop_acquisition.sh";
    ecriture_script_bash_stop(nom_fichier_bash_stop);
}

//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM
void ATLAS_BCAM::calcul_coord()
{


   //je lis le fichier de sortie de LWDAQ qui contient les observations
   std::string fichier_obs_brutes = "Resultats/Acquisifier_Results.txt";
   read_lwdaq_output(fichier_obs_brutes, m_bdd);

   //je fais la transformation du capteur CCD au systeme MOUNT
   img_coord_to_bcam_coord(m_bdd);

   //enregistrement du fichier qui contient les observations dans le repere MOUNT
   std::string fichier_obs_mount = "Resultats/Observations_MOUNT_System.txt";
   write_file_obs_mount_system(fichier_obs_mount, m_bdd);

   //je calcule les coordonnees du prisme en 3D dans le repere MOUNT

}

//fonction qui verifie qu'il n'y a pas d'erreurs dans le fichier de configuration
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
void ATLAS_BCAM::check_input_data()
{
    //test des numéros des ports driver : sur les driver les numéros de ports possibles sont compris entre 1 et 8
    for (int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        if(m_bdd.Get_liste_BCAM().at(i).Get_num_Port_Driver()>8 || m_bdd.Get_liste_BCAM().at(i).Get_num_Port_Driver()<1)
        {
            QMessageBox::critical(this,"Attention","les numéros des ports driver sont impérativement compris entre 1 et 8");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }

    //test des numéros des ports multiplexer : sur les multiplexer les numéros des ports possibles sont compris entre 1 et 10
    for (int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        if(m_bdd.Get_liste_BCAM().at(i).Get_num_Port_Mux()>10 || m_bdd.Get_liste_BCAM().at(i).Get_num_Port_Mux()<1)
        {
            QMessageBox::critical(this,"Attention","les numéros des ports multiplexer sont impérativement compris entre 1 et 10");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }

<<<<<<< HEAD
=======
    //test sur le type booléen d'une BCAM : single ou double ?
    for (int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        if(m_bdd.Get_liste_BCAM().at(i).Get_type_bool_BCAM() != "S" && m_bdd.Get_liste_BCAM().at(i).Get_type_bool_BCAM() != "D")
        {
            QMessageBox::warning(this,"Attention","Les BCAMs ne peuvent être que Single ou Double");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }

>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
    //test sur le nombre de détecteurs (ce nombre == 7 )
    if (m_bdd.Get_liste_detector().size() != NBR_DETECTORS)
    {
        int nbr_detectors = m_bdd.Get_liste_detector().size();
        QString str;
        str.setNum(nbr_detectors);

        QMessageBox::information(this,"Information","Le nombre de detecteurs est different de 7", QMessageBox::Ok, QMessageBox::Cancel);
    }

    //test pour vérifier si dans le fichier d'entrée, il y a un seul et unique détecteur avec un seul et unique identifiant
    for (int i=0; i<m_bdd.Get_liste_detector().size(); i++)
    {

         for (int j=0; j<m_bdd.Get_liste_detector().size(); j++)
        {
             if( j != i && m_bdd.Get_liste_detector().at(i).Get_nom_detector() == m_bdd.Get_liste_detector().at(j).Get_nom_detector())
             {
                 QMessageBox::critical(this,"Attention","Vous avez entre 2 fois le meme nom de detecteur !");
                 //mauvais format
                 format_input = 0;
                 //arrêt du programme
                 std::exit(EXIT_FAILURE);
             }
             if(j != i && m_bdd.Get_liste_detector().at(i).Get_num_id_detector() == m_bdd.Get_liste_detector().at(j).Get_num_id_detector())
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
    for (int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        if(m_bdd.Get_liste_BCAM().at(i).Get_nom_BCAM().size() != ID_LENGTH_BCAM)
        {
            QMessageBox::critical(this,"Attention","Au moins 1 BCAM comporte un identifiant de longueur inapropriee !");
            //mauvais format
            format_input = 0;
            //arrêt du programme
            std::exit(EXIT_FAILURE);
        }
    }


    //test pour vérifier si dans le fichier d'entrée, il y a une seule et unique BCAM (vu la structure du fichier elle appartient à un unique detecteur)
    for (int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        for (int j=0; j<m_bdd.Get_liste_BCAM().size(); j++)
        {
            if(j != i && m_bdd.Get_liste_BCAM().at(i).Get_nom_BCAM() == m_bdd.Get_liste_BCAM().at(j).Get_nom_BCAM())
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
    for (int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        for (int j=0; j<m_bdd.Get_liste_BCAM().size(); j++)
        {
            if((i != j) && (m_bdd.Get_liste_BCAM().at(i).Get_num_Port_Driver() == m_bdd.Get_liste_BCAM().at(j).Get_num_Port_Driver()) && (m_bdd.Get_liste_BCAM().at(i).Get_num_Port_Mux() == m_bdd.Get_liste_BCAM().at(j).Get_num_Port_Mux()))
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

<<<<<<< HEAD
//fonction qui verifie si toutes les BCAMS sont contenues dans le fichier de calibration            [----> not yet, on suppose que le fichier de calibration est correct
=======
//fonction qui verifie si toutes les BCAMS sont contenues dans le fichier de calibration
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
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

<<<<<<< HEAD
//fonction permettant d'activer les boutons                                                         [----> ok
void ATLAS_BCAM::enable_PushButton()
{

    //si le chemin du fichier d'entree a ete specifie et un detecteur non vide selectionne
    if(!path_input_folder.isEmpty() && tab_bcam == 1)
    {
        // activation du boutton pour lancer l'acquisition et le calcul
        ui->Boutton_lancer->setEnabled(true);
    }

}

//fonction qui permet de generer un script d'acquisition                                            [---> ok
=======
//fonction permettant d'activer les boutons
void ATLAS_BCAM::enable_PushButton()
{

    //si le chemin du fichier d'entree a ete specifie
    if(!path_input_folder.isEmpty() && !time_value.isEmpty() && tab_bcam == 1)
    {
        // activation du boutton pour charger le fichier de calibration
        ui->Boutton_lancer->setEnabled(true);
    }

    //si le logiciel est en mode acquisition
    if(action == 1)
    {
        // activation du boutton qui permet de stopper l'acquisition
        ui->boutton_arreter->setEnabled(true);
    }

}

//fonction qui permet de generer un script d'acquisition
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
int ATLAS_BCAM::ecriture_script_acquisition(std::string nom_fichier_script_acquisition, std::vector<BCAM> &liste_temp_bcam)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_script_acquisition.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        //écriture la partie du script qui gère l'enregistrement dans un fichier externe
<<<<<<< HEAD
        fichier<<"acquisifier: \n"
               <<"config: \n"
=======
        fichier<<"config: \n"
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
               <<"\t cycle_period_seconds 0 \n"
               <<"end. \n"
               <<"\n"
               <<"default: \n"
               <<"name: BCAM_Default \n"
               <<"instrument: BCAM \n"
               <<"default_post_processing: { \n"
               <<"if {![LWDAQ_is_error_result $result]} { \n"
               <<"append config(run_result) \"[lrange $result 1 2]\" ; \n"
               <<" } { \n"
               <<"append config(run_result) \" -1 -1 \" ; # append joue le meme role que 'set' \n"
               <<" } \n"
               <<"  set f [open $config(run_results) a] \n"
               <<" puts $f $result \n"
               <<" close $f \n"
               <<" LWDAQ_print $info(text) \"Appended modified result to [file tail $config(run_results)].\" blue ;  \n"
               <<" set fn [file join [file dirname $config(run_results)] $name\.lwdaq] \n"
<<<<<<< HEAD
               <<" # LWDAQ_write_image_file $iconfig(memory_name) $fn \n"
               <<" LWDAQ_print $info(text) \"Saved raw image to [file tail $fn]\" blue ; \n"
               <<" } \n"
               <<"\n"
               <<"config: \n"
               <<"\t image_source daq \n"
               <<"\t analysis_enable 1 \n"
               <<"\t daq_flash_seconds 0.0000033 \n"
               <<"\t daq_adjust_flash 1 \n"
               <<"\t daq_ip_addr "<<m_bdd.Get_driver_ip_adress()<<"\n"
               <<"\t daq_source_ip_addr * \n"
               <<"\t ambient_exposure_seconds 0 \n"
               <<"\t intensify exact \n"
               <<"end. \n"
               <<"\n";
=======
               <<" LWDAQ_write_image_file $iconfig(memory_name) $fn \n"
               <<" LWDAQ_print $info(text) \"Saved raw image to [file tail $fn]\" blue ; \n"
               <<" } \n"
               <<"config: \n"
               <<"\t image_source daq \n"
               <<"\t analysis_enable 1 \n"
               <<"\t daq_adjust_flash 1 \n"
              <<"\t daq_flash_seconds 0.05 \n"
               <<"\t daq_ip_addr 10.0.0.37 \n"
               <<"\t daq_source_ip_addr * \n"
               <<"\t ambient_exposure_seconds 0 \n"
               <<"\t intensify exact \n"
               <<"end. \n";
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

        //écriture dans le fichier de la partie acquisition du script : un paragraphe par BCAM
        for(int i=0; i<liste_temp_bcam.size(); i++)
        {
<<<<<<< HEAD
            // on separe les visees BCAM-Prisme des visees BCAM-BCAM
            if(liste_temp_bcam.at(i).Get_objet_vise().length() == 14) //configuration de visee BCAM-BCAM
            {
                fichier<<"acquire: \n"
                       <<"name: "<<liste_temp_bcam.at(i).Get_nom_BCAM().append("_").append(liste_temp_bcam.at(i).Get_objet_vise())<<"\n"
                       <<"instrument: BCAM \n"
                       <<"result: None \n"
                       <<"time: 0 \n"
                       <<"config: \n"
                       <<"\n"
                       <<"\t analysis_num_spots 2 \n"
                       <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                       <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n";

                for(int j=0; j<liste_temp_bcam.size(); j++)
                {
                    if(liste_temp_bcam.at(i).Get_objet_vise() == liste_temp_bcam.at(j).Get_nom_BCAM())
                    {
                        fichier<<"\t daq_source_mux_socket "<<liste_temp_bcam.at(j).Get_num_Port_Mux()<<"\n"
                               <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(j).Get_num_Port_Driver()<<"\n";
                        if(liste_temp_bcam.at(i).Get_num_chip() == 2)
                        {
                            fichier<<"\t daq_device_element 1 \n"
                                   <<"\t daq_source_device_element \"3 4\" \n";
                        }
                        else
                        {
                            fichier<<"\t daq_device_element 2 \n"
                                   <<"\t daq_source_device_element \"1 2\" \n";
                        }
                     break;

                    }
                    //break;
                }

                fichier<<"\t daq_image_left 20 \n"
                       <<"\t daq_image_top 1 \n"
                       <<"\t daq_image_right 343 \n"
                       <<"\t daq_image_bottom 243 \n"
                        <<"end. \n"
                       <<"\n";
            }

            else //configuration BCAM-Prisme
            {
                fichier<<"acquire: \n"
                       <<"name: "<<liste_temp_bcam.at(i).Get_nom_BCAM().append("_").append(liste_temp_bcam.at(i).Get_objet_vise())<<"\n"
                       <<"instrument: BCAM \n"
                       <<"result: None \n"
                       <<"time: 0 \n"
                       <<"config: \n";

                if(liste_temp_bcam.at(i).Get_objet_vise().length() == 5)         //cas de 1 bcam qui vise 1 prisme (port source et port enregistreure sont les memes)
                {
                           fichier<<"\t analysis_num_spots 2 \n"
                                 <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                                  <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                                  <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                                  <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                                  <<"\t daq_device_element "<<liste_temp_bcam.at(i).Get_num_chip()<<"\n";
                           if(liste_temp_bcam.at(i).Get_num_chip() == 2)
                           {
                               fichier<<"\t daq_source_device_element \"3 4\" \n";
                           }
                           else
                           {
                                fichier<<"\t daq_source_device_element \"1 2\" \n";
                           }
                           fichier<<"\t daq_image_left 20 \n"
                                  <<"\t daq_image_top 1 \n"
                                  <<"\t daq_image_right 343 \n"
                                  <<"\t daq_image_bottom 243 \n"
                                   <<"end. \n"
                                  <<"\n";
                }
                else if(liste_temp_bcam.at(i).Get_objet_vise().length() == 11)   //cas de 1 bcam qui vise 2 prismes (port source et port enregistreure sont les memes)
                {
                           fichier<<"\t analysis_num_spots 4 \n"
                                 <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                                 <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                                  <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                                  <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                                  <<"\t daq_device_element "<<liste_temp_bcam.at(i).Get_num_chip()<<"\n";
                           if(liste_temp_bcam.at(i).Get_num_chip() == 2)
                           {
                               fichier<<"\t daq_source_device_element \"3 4\" \n";
                           }
                           else
                           {
                                fichier<<"\t daq_source_device_element \"1 2\" \n";
                           }
                           fichier<<"\t daq_image_left 20 \n"
                                  <<"\t daq_image_top 1 \n"
                                  <<"\t daq_image_right 343 \n"
                                  <<"\t daq_image_bottom 243 \n"
                                   <<"end. \n"
                                  <<"\n";

                 }
                else  //cas d'une BCAM qui vise 3 prismes (port source et port enregistreure sont les memes)
                       {
                           fichier<<"\t analysis_num_spots 6 \n"
                                  <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                                  <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                                  <<"\t daq_device_element "<<liste_temp_bcam.at(i).Get_num_chip()<<"\n"
                                  <<"\t daq_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                                  <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                                  <<"\t daq_image_left 20 \n"
                                  <<"\t daq_image_top 1 \n"
                                  <<"\t daq_image_right 343 \n"
                                  <<"\t daq_image_bottom 243 \n";
                          if(liste_temp_bcam.at(i).Get_num_chip() == 2)
                          {
                              fichier<<"\t daq_source_device_element \"3 4\" \n";
                          }
                          else
                          {
                               fichier<<"\t daq_source_device_element \"1 2\" \n";
                          }
                          fichier<<"\t daq_image_left 20 \n"
                                 <<"\t daq_image_top 1 \n"
                                 <<"\t daq_image_right 343 \n"
                                 <<"\t daq_image_bottom 243 \n"
                                  <<"end. \n"
                                 <<"\n";

                       }
            }


=======
         fichier<<"acquire: \n"
                <<"name: "<<liste_temp_bcam.at(i).Get_nom_BCAM().append("_").append(liste_temp_bcam.at(i).Get_objet_vise())<<"\n"
                <<"instrument: BCAM \n"
                <<"result: None \n"
                <<"time: 0 \n"
                <<"config: \n";

         if(liste_temp_bcam.at(i).Get_objet_vise().length() == 8)
                {
                    fichier<<"\t analysis_num_spots 2 \n"
                           <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_device_element 2 \n"
                           <<"\t daq_source_device_element \"3 4\" \n";
                }
         else if(liste_temp_bcam.at(i).Get_objet_vise().length() == 17)
                {
                    fichier<<"\t analysis_num_spots 4 \n"
                           <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_source_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n"
                           <<"\t daq_device_element "<<liste_temp_bcam.at(i).Get_num_chip()<<"\n";
                    if(liste_temp_bcam.at(i).Get_num_chip() == 2)
                    {
                        fichier<<"\t daq_source_device_element \"3 4\" \n";
                    }
                    else
                    {
                         fichier<<"\t daq_source_device_element \"1 2\" \n";
                    }

                }
         else
                {
                    fichier<<"\t analysis_num_spots 2 \n"
                           <<"\t daq_mux_socket "<<liste_temp_bcam.at(i).Get_num_Port_Mux()<<"\n";

                    for(int j=0; j<liste_temp_bcam.size(); j++)
                    {
                        if(liste_temp_bcam.at(i).Get_nom_BCAM() == liste_temp_bcam.at(j).Get_objet_vise())
                        {
                            fichier<<"\t daq_source_mux_socket "<<liste_temp_bcam.at(j).Get_num_Port_Mux()<<"\n";
                            if(liste_temp_bcam.at(i).Get_num_chip() == 2)
                            {
                                fichier<<"\t daq_device_element 2 \n"
                                       <<"\t daq_source_device_element \"1 2\" \n";
                            }
                            else
                            {
                                fichier<<"\t daq_device_element 1 \n"
                                       <<"\t daq_source_device_element \"3 4\" \n";
                            }
                        }
                    }


                }

                fichier<<"\t daq_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                        <<"\t daq_source_driver_socket "<<liste_temp_bcam.at(i).Get_num_Port_Driver()<<"\n"
                        <<"\t daq_image_left 20 \n"
                        <<"\t daq_image_top 1 \n"
                        <<"\t daq_image_right 343 \n"
                        <<"\t daq_image_bottom 243 \n";

                fichier<<"end. \n";
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
        }

        fichier.close();
        return 1;
    }

    else
    {
        return 0;
    }
}

<<<<<<< HEAD
//fonction qui permet de generer un bash en shell pour lancer et arreter LWDAQ                      [---> ok
=======
//fonction qui permet de generer un bash en shell pour lancer et arreter LWDAQ
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
int ATLAS_BCAM::ecriture_script_bash(std::string nom_fichier_bash)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_bash.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(fichier)
    {
<<<<<<< HEAD
        std::string chemin_lWDAQ_startup = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("LWDAQ.app").append("/").append("Contents").append("/").append("LWDAQ").append("/").append("Startup/");
        std::string chemin_lwdaq_data = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("Tools").append("/").append("Data/");
        fichier<<"#!/bin/bash \n"
               <<"cp scripts_lwdaq/Acquisifier_params.tcl "<<chemin_lWDAQ_startup<<"\n"
              <<"cp scripts_lwdaq/Acquisifier_Settings.tcl "<<chemin_lwdaq_data<<"\n"
               <<"cp scripts_lwdaq/Acquisifier_script_file.tcl "<<chemin_lwdaq_data<<"\n"
               <<path_lwdaq<<" --no-console"<<" \n"
               <<"ps -eH | grep tclsh8.5 > PID.txt \n"
               <<"read pid reste < PID.txt \n";
       if(mode_adepo == "CLOSURE")
           fichier<<"sleep "<<time_value.toStdString()<<"s"<<"\n";    //en mode closure c'est directement le temps donnees par l'operateur
       else
           fichier<<"sleep 10s"<<"\n";          //en mode monitoring l'operateur choisit la frequence, le temps d'acquisition sera de 3 min pour etre sur de passer par chaque capteur
           fichier<<"kill \"$pid\" \n";
=======
       fichier<<"#!/bin/bash \n"
               //<<"cp "<</home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_params.tcl /home/cern-mehdi/Documents/LWDAQ/LWDAQ.app/Contents/LWDAQ/Startup \n"
               //<<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_Settings.tcl /home/cern-mehdi/Documents/LWDAQ/Tools/Data \n"
               //<<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_script.tcl /home/cern-mehdi/Documents/LWDAQ/Tools/Data \n"
               <<path_lwdaq<<" --no-console"<<" \n"
               <<"ps -eH | grep tclsh8.5 > PID.txt \n"
               <<"read pid reste < PID.txt \n"
              <<"sleep "<<time_value.toStdString()<<"s"<<"\n"
               <<"kill \"$pid\" \n";
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

           fichier.close();
           return 1;
    }
    else
    {
           return 0;
    }
}

<<<<<<< HEAD
//fonction qui ecrit un fichier tcl avec les parametres par defaut pour la fenetre Acquisifier      [---> ok
=======
//fonction qui permet de generer un bash en shell pour arreter instantanement LWDAQ
int ATLAS_BCAM::ecriture_script_bash_stop(std::string nom_fichier_bash_stop)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_bash_stop.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(fichier)
    {
       fichier<<"#!/bin/bash \n"
               <<"ps -eH | grep tclsh8.5 > PID_stop.txt \n"
               <<"read pid reste < PID_stop.txt \n"
               <<"kill \"$pid\" \n";

           fichier.close();
           return 1;
    }
    else
    {
           return 0;
    }
}

//fonction qui ecrit un fichier tcl avec les parametres par defaut pour la fenetre Acquisifier de LWDAQ et lance automatiquement l'auto-run
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
int ATLAS_BCAM::write_settings_file(std::string setting_name_file)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)setting_name_file.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        //écriture la partie du script qui lance l'acquisition automatique
        fichier<<"set Acquisifier_config(auto_load) \"1\" \n"
               <<"set Acquisifier_config(title_color) \"purple\" \n"
               <<"set Acquisifier_config(extended_acquisition) \"0\" \n"
               <<"set Acquisifier_config(auto_repeat) \"1\" \n"
               <<"set Acquisifier_config(analyze) \"0\" \n"
               <<"set Acquisifier_config(auto_run) \"1\" \n"
               <<"set Acquisifier_config(cycle_period_seconds) \"0\" \n"
<<<<<<< HEAD
               <<"set Acquisifier_config(daq_script) \""<<path_input_folder.toStdString().append("/").append("LWDAQ").append("/Tools").append("/Data/").append(fichier_script)<<"\" \n"
=======
               <<"set Acquisifier_config(daq_script) \"/home/cern-mehdi/Documents/LWDAQ/Tools/Data/Acquisifier_script.tcl\" \n"
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
               <<"set Acquisifier_config(analysis_color) \"green\" \n"
               <<"set Acquisifier_config(upload_target) \"stdout\" \n"
               <<"set Acquisifier_config(auto_quit) \"0\" \n"
               <<"set Acquisifier_config(result_color) \"green\" \n"
               <<"set Acquisifier_config(num_steps_show) \"20\" \n"
               <<"set Acquisifier_config(upload_step_result) \"0\" \n"
               <<"set Acquisifier_config(num_lines_keep) \"1000\" \n"
               <<"set Acquisifier_config(restore_instruments) \"0\" \n";

               fichier.close();
               return 1;
      }
      else
      {
               return 0;
      }
}

<<<<<<< HEAD
//fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ   [----> ok
=======
//fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
int ATLAS_BCAM::write_input_script(std::string startup_lwdaq_script_file)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)startup_lwdaq_script_file.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(fichier)
    {
        fichier<<"#~ Lancer l'acquisifier \n"
               <<"LWDAQ_run_tool Acquisifier.tcl \n"
               <<"#~ Settings pour les BCAMs"
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
<<<<<<< HEAD
               <<"set LWDAQ_config_BCAM(daq_ip_addr) \" "<<m_bdd.Get_driver_ip_adress()<<" \" \n"
=======
               <<"set LWDAQ_config_BCAM(daq_ip_addr) \"10.0.0.37\" \n"
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
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
    else
    {
           return 0;
    }
}
<<<<<<< HEAD

//fonction qui gere les selections dans les checkbox                                                [----> ok
void ATLAS_BCAM::get_mode()
{
    mode_adepo = ui->comboBox->currentText();
    if(mode_adepo == "MONITORING")
    {
        //changement du texte
        ui->textEdit_function_mode->setHtml("</style></head><body style=\" font-family:\'Ubuntu\'; font-size:11pt; font-weight:400; font-style:normal;\"><p align=\"center\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-size:10pt; font-weight:600;\">Frequence d\'acquisition (s) :</span></p></body></html>");
        //changement des valeurs d'interval pour le temps
        ui->spinBox->setMinimum(900);  //frequence maxi : 1 mesure toutes les 15 min
        ui->spinBox->setMaximum(86400); //frequence mini ; 1 mesure par jour
    }
    else
    {
        //changement du text
        ui->textEdit_function_mode->setHtml("</style></head><body style=\" font-family:\'Ubuntu\'; font-size:11pt; font-weight:400; font-style:normal;\"><p align=\"center\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-size:10pt; font-weight:600;\">Temps d\'acquisition (s) :</span></p></body></html>");
        //changement des valeurs d'interval pour le temps
        ui->spinBox->setMinimum(11);
        ui->spinBox->setMaximum(300);
        ui->spinBox->setValue(30);
    }
}

//fonction qui recupere l'etat des airpads                                                          [----> not yet
void ATLAS_BCAM::get_airpad_state()
{
    mode_airpad = ui->comboBox_2->currentText();
    if(mode_airpad == "ON")
    {
        for(int i=0; i<m_bdd.Get_liste_absolutes_distances().size(); i++)
        {
            float val_x = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances().Get_X();
            float val_y = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances().Get_Y();
            float val_z = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances().Get_Z();

            Point3f pt(val_x+0.003, val_y+0.003, val_y+0.003);
            //Point3f val_temp = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances();
            //m_bdd.Get_liste_absolutes_distances().at(i).Set_distances(pt);
        }
    }
    /*for(int j=0; j<m_bdd.Get_liste_absolutes_distances().size(); j++)
    {
        //m_bdd.Get_liste_absolutes_distances().at(j).Affiche();
    }*/
}

//fonction thread pour lancer les modes d'acquisition                                               [-----> ok
void ATLAS_BCAM::startCalcul()
{
    if(mode_adepo == "CLOSURE")
    {
        //desactivation du bouttoon stop : en mode closure pas d'arret possible
        ui->boutton_arreter->setEnabled(false);
        //lancement des acquisitions + calcul
        lancer_acquisition();
    }
    else
    {
        //boite de dialogue avant de debuter le mode monitoring
        int reponse = QMessageBox::question(this, "Mode monitoring", "Attention, vous etes en mode monitoring. Assurez vous d'avoir selectionner tous les detecteurs avant de continuer.", QMessageBox::Yes | QMessageBox::No);
        //si la reponse est positiove
        if (reponse == QMessageBox::Yes)
        {
            //desactivation de toute la fenetre sauf le bouton stop qui permet de tuer le QTimer
            ui->boutton_arreter->setEnabled(true);
            ui->tableWidget_liste_detectors->setEnabled(false);
            ui->comboBox->setEnabled(false);
            ui->comboBox_2->setEnabled(false);
            ui->spinBox->setEnabled(false);
            ui->Boutton_lancer->setEnabled(false);
            ui->tableWidget_liste_bcams->setEnabled(false);
            //lancement des acquisitions + calcul
            QObject::connect(timer,SIGNAL(timeout()),this,SLOT(lancer_acquisition()));
            //boucle selon la frequence precisee par le user
            timer->start((time_value.toInt())*1000); //en mode monitoring time_value est utilisee comme frequence et non pas comme temps d'acquisition
        }
        //si la reponse est negative
        else if (reponse == QMessageBox::No)
        {
            //rien ne se passe
        }

    }
}
=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
