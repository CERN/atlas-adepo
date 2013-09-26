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



#include <iostream>
#include <QtGui>
#include "QWidget"

#define NBR_DETECTORS 7
#define ID_LENGTH_BCAM 14

/********************************************************************************************/
#define NAME_CONFIGURATION_FILE "configuration_file.txt"
#define NAME_CALIBRATION_FILE "calibration_file.txt"
#define NAME_LWDAQ_FOLDER "LWDAQ"
/********************************************************************************************/


//declaration des variables globales
std::string path_lwdaq;
QString path_input_folder;
QString time_value;

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

ATLAS_BCAM::ATLAS_BCAM(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::ATLAS_BCAM)
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
        QObject::connect(ui->Boutton_lancer,SIGNAL(clicked()), this,SLOT(lancer_acquisition()));

        //stopper l'acquisition (arret force)
        QObject::connect(ui->boutton_arreter,SIGNAL(clicked()),this,SLOT(stop_acquisition()));

        //calcul des coordonnees du Prisme
        //QObject::connect(ui->boutton_calculer,SIGNAL(clicked()),this,SLOT(calcul_coord()));

        //recuperer la valeur du temps d'acquisition
        QObject::connect(ui->lineEdit_value_seconds, SIGNAL(textEdited(QString)), this, SLOT(save_time_value()));

}

ATLAS_BCAM::~ATLAS_BCAM()
{
    delete ui;
}

void ATLAS_BCAM::ouvrirDialogue()
{
    path_input_folder = QFileDialog::getExistingDirectory(this, "Chemin du dossier", QString());

    //chemin du fichier d'entree
    //path_input_folder = fenetre_ouverture->Get_path_fich();

    //appel pour la lecture de fichier
    read_input(path_input_folder.toStdString().append("/").append(NAME_CONFIGURATION_FILE),m_bdd);

    //verification des infos du fichier d'entree
    //check_input_data();

    //activation du boutton pour lancer les acquisitions
    enable_PushButton();

    //remplissage tableau detectors
    if(format_input == 1)
    {
        remplir_tableau_detectors();
    }

    //lecture du fichier de calibration
    read_calibration_database(path_input_folder.toStdString().append("/").append(NAME_CALIBRATION_FILE),m_bdd);

    // chemin d'acces a l'emplacement de LWDAQ
    path_lwdaq = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("lwdaq");
}

//fonction qui enregistre la valeur du temps d'acquisition entree par l'utilisateur
void ATLAS_BCAM::save_time_value()
{
    time_value = ui->lineEdit_value_seconds->text();
    enable_PushButton();
}

//fonction d'ouverture de la fenêtre d'aide de l'outil ARCAPA
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

//fonction permettant de charger la liste des detectors après ouverture d'un projet
void ATLAS_BCAM::remplir_tableau_detectors()
{
    //recuperation de la liste des nom des detecteurs
    std::vector<detector> detectors_data = this->m_bdd.Get_liste_detector();

    // nombre de lignes du tableau de detecteurs dans l'interface
    int nb_lignes = detectors_data.size();
    ui->tableWidget_liste_detectors->setRowCount(nb_lignes);

    for(int i=0; i<nb_lignes; i++)
    {
        //ajout du nom du detecteur
        QTableWidgetItem *item_nom = new QTableWidgetItem();
        item_nom->setText(QString::fromStdString(detectors_data.at(i).Get_nom_detector()));
        ui->tableWidget_liste_detectors->setItem(i,1,item_nom);

        //ajout du numero id du detetcteur
        QTableWidgetItem *item_num = new QTableWidgetItem();
        item_num->setData(0,detectors_data.at(i).Get_num_id_detector());
        ui->tableWidget_liste_detectors->setItem(i,0,item_num);
    }


}

//fonction permettant de charger la liste des BCAMs qui appartiennent a un detector
void ATLAS_BCAM::affiche_liste_BCAMs(int ligne, int colonne)
{
    //recuperation du nombre de detecteurs
    int nb_detetctors = ui->tableWidget_liste_detectors->selectedItems().size()/2;

    //vecteur qui va contenir la liste des BCAMs temporaires selectionnees dans le tableau
    std::vector<BCAM> *liste_bcam = new std::vector<BCAM>;

    //nom du fichier script qui va lancer l'acquisition que sur les detecteurs selectionnes
    std::string fichier_script = "Acquisifier_script_file.tcl";

    //recuperation des donnees a afficher
    for(int i=0; i<nb_detetctors; i++)
    {
        //recuperation de l'identifiant du detecteur
        QString id_detector = ui->tableWidget_liste_detectors->selectedItems().at(i*2)->text();

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

      QTableWidgetItem *type_bcam = new QTableWidgetItem();
      type_bcam->setText(QString::fromStdString(liste_bcam->at(i).Get_type_bool_BCAM()));
      ui->tableWidget_liste_bcams->setItem(i,4,type_bcam);

      QTableWidgetItem *objet_vise = new QTableWidgetItem();
      objet_vise->setText(QString::fromStdString(liste_bcam->at(i).Get_objet_vise()));
      ui->tableWidget_liste_bcams->setItem(i,5,objet_vise);

    }
    tab_bcam =1;
    enable_PushButton();
}

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

//fonction qui verifie si toutes les BCAMS sont contenues dans le fichier de calibration
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
int ATLAS_BCAM::ecriture_script_acquisition(std::string nom_fichier_script_acquisition, std::vector<BCAM> &liste_temp_bcam)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_script_acquisition.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        //écriture la partie du script qui gère l'enregistrement dans un fichier externe
        fichier<<"config: \n"
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

        //écriture dans le fichier de la partie acquisition du script : un paragraphe par BCAM
        for(int i=0; i<liste_temp_bcam.size(); i++)
        {
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
        }

        fichier.close();
        return 1;
    }

    else
    {
        return 0;
    }
}

//fonction qui permet de generer un bash en shell pour lancer et arreter LWDAQ
int ATLAS_BCAM::ecriture_script_bash(std::string nom_fichier_bash)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_bash.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(fichier)
    {
       fichier<<"#!/bin/bash \n"
               //<<"cp "<</home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_params.tcl /home/cern-mehdi/Documents/LWDAQ/LWDAQ.app/Contents/LWDAQ/Startup \n"
               //<<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_Settings.tcl /home/cern-mehdi/Documents/LWDAQ/Tools/Data \n"
               //<<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_script.tcl /home/cern-mehdi/Documents/LWDAQ/Tools/Data \n"
               <<path_lwdaq<<" --no-console"<<" \n"
               <<"ps -eH | grep tclsh8.5 > PID.txt \n"
               <<"read pid reste < PID.txt \n"
              <<"sleep "<<time_value.toStdString()<<"s"<<"\n"
               <<"kill \"$pid\" \n";

           fichier.close();
           return 1;
    }
    else
    {
           return 0;
    }
}

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
               <<"set Acquisifier_config(daq_script) \"/home/cern-mehdi/Documents/LWDAQ/Tools/Data/Acquisifier_script.tcl\" \n"
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

//fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ
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
               <<"set LWDAQ_config_BCAM(daq_ip_addr) \"10.0.0.37\" \n"
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
