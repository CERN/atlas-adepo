#include "header/atlas_bcam.h"
#include "header/ouverture_projet.h"
#include "header/read_input.h"
#include "ui_ATLAS_BCAM.h"
#include "header/read_calibration_database.h"
#include "header/liste_bcam_from_id_detector.h"
#include "header/write_aquisifier_script.h"
#include "header/write_bash_script.h"
#include "header/read_lwdaq_output.h"
#include "header/img_coord_to_bcam_coord.h"
#include "header/write_file_obs_mount_system.h"
#include "header/calcul_coord_bcam_system.h"
#include "header/helmert.h"
#include "header/mythread.h"
#include "header/mount_prism_to_global_prism.h"
#include "eigen-eigen-ffa86ffb5570/Eigen/Eigen"

#include <iostream>
#include <QtGui>
#include "QWidget"
#include "QtTest/QTest"
#include <time.h>

#define NBR_DETECTORS 8
#define ID_LENGTH_BCAM 14

/********************************************************************************************/
#define NAME_CONFIGURATION_FILE "configuration_file.txt"
#define NAME_CALIBRATION_FILE "BCAM_Parameters.txt"
#define NAME_LWDAQ_FOLDER "LWDAQ"
/********************************************************************************************/


//declaration des variables globales
QSettings settings;

std::string path_lwdaq;
QString path_input_folder;
bool input_folder_read = false;

//valeur par defaut si l'utilisateur ne touche pas au spinbox
QString time_value = "30";
//valeur par defaut du mode d'utilisation est CLOSURE
QString mode_adepo = "CLOSURE";
//valeur par defaut du mode des airpads
QString mode_airpad = "OFF";

//nom du fichier script qui va lancer l'acquisition que sur les detecteurs selectionnes
std::string fichier_script = "Acquisifier_script_file.tcl";

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

//compteur pour savoir combien de fois l'utilisateur a charge un fichier d'input

//timer pour le mode monitoring
QTimer *timer = new QTimer();

ATLAS_BCAM::ATLAS_BCAM(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::ATLAS_BCAM)                                                                        //[---> ok
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
        QObject::connect(ui->Boutton_lancer,SIGNAL(clicked()), this,SLOT(startCalcul()));
        QObject::connect(ui->nextMeasurement,SIGNAL(clicked()), this,SLOT(startCalcul()));

        //QObject::connect(timer,SIGNAL(timeout()),this,SLOT(lancer_acquisition()));

        //stopper l'acquisition (arret force)
        QObject::connect(ui->boutton_arreter,SIGNAL(clicked()),this,SLOT(stop_acquisition()));
        QObject::connect(ui->stop,SIGNAL(clicked()),this,SLOT(stop_acquisition()));

        QObject::connect(ui->reset,SIGNAL(clicked()),this,SLOT(resetDelta()));

        //recuperer la valeur du temps d'acquisition
        QObject::connect(ui->spinBox, SIGNAL(valueChanged(int)), this, SLOT(save_time_value()));

        //recuperer la valeur du mode : CLOSURE ou MONITORING
        QObject::connect(ui->comboBox, SIGNAL(currentIndexChanged(int)), this, SLOT(get_mode()));

        //recuperer la valeur des airpads : ON ou OFF
        QObject::connect(ui->comboBox_2, SIGNAL(currentIndexChanged(int)), this, SLOT(get_airpad_state()));

        path_input_folder = settings.value("input_folder").toString();
        if (path_input_folder != NULL) {
            openInputDir();
        }
}

ATLAS_BCAM::~ATLAS_BCAM()
{
    delete ui;
}

//ouverture d'une boite de dialogue                                                                 [----> ok
void ATLAS_BCAM::ouvrirDialogue()
{
    path_input_folder = QFileDialog::getExistingDirectory(this, "Chemin du dossier", QString());
    openInputDir();
}

void ATLAS_BCAM::openInputDir() {
    settings.setValue("input_folder", path_input_folder);

    if(input_folder_read) //gestion du probleme lorsqu'on charge un fichier par dessus l'autre
    {
        m_bdd.vidage_complet(); //on vide tout car nouveau fichier
    }
    input_folder_read = true;

    //chemin du fichier d'entree
    //path_input_folder = fenetre_ouverture->Get_path_fich();

    //appel pour la lecture de fichier
    read_input(path_input_folder.toStdString().append("/").append(NAME_CONFIGURATION_FILE),m_bdd);

    //estimation des 6 parametres pour chaque BCAM
    helmert(m_bdd);

    //verification des infos du fichier d'entree
    //check_input_data();

    //activation du boutton pour lancer les acquisitions
    enable_PushButton();

    //remplissage tableau detectors que si le format du fichier input est bon !
    if(format_input == 1)
    {
        remplir_tableau_detectors();
    }

    //lecture du fichier de calibration
    read_calibration_database(path_input_folder.toStdString().append("/").append(NAME_CALIBRATION_FILE),m_bdd);

    //recuperation de la partie qui nous interesse du fichier de calibration
    //clean_calib(m_bdd);

    // chemin d'acces a l'emplacement de LWDAQ
    path_lwdaq = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("lwdaq");
}

//fonction qui enregistre la valeur du temps d'acquisition entree par l'utilisateur                 [----> ok
void ATLAS_BCAM::save_time_value()
{
    time_value = ui->spinBox->text();
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
    std::vector<detector> detectors_data = this->m_bdd.Get_liste_detector();

    // nombre de lignes du tableau de detecteurs dans l'interface
    int nb_lignes = detectors_data.size();
    ui->tableWidget_liste_detectors->setRowCount(nb_lignes);

    for(int i=0; i<nb_lignes; i++)
    {

        //ajout du numero id du detetcteur
        QTableWidgetItem *item_num = new QTableWidgetItem();
        item_num->setData(0,detectors_data.at(i).Get_num_id_detector());
        ui->tableWidget_liste_detectors->setItem(i,0,item_num);

        //ajout du nom du detecteur
        QTableWidgetItem *item_nom = new QTableWidgetItem();
        item_nom->setText(QString::fromStdString(detectors_data.at(i).Get_nom_detector()));
        ui->tableWidget_liste_detectors->setItem(i,1,item_nom);

        //ajout de la constante de aipad
        QTableWidgetItem *item_dist_const = new QTableWidgetItem();
        item_dist_const->setData(0,detectors_data.at(i).Get_airpad_on_add_dist());
        ui->tableWidget_liste_detectors->setItem(i,2,item_dist_const);
    }


}

//fonction permettant de charger la liste des BCAMs qui appartiennent a un detector                 [---> ok
void ATLAS_BCAM::affiche_liste_BCAMs(int /* ligne */, int /* colonne */)
{
    int noColumn = ui->tableWidget_liste_detectors->columnCount();

    //recuperation du nombre de detecteurs
    int nb_detectors = ui->tableWidget_liste_detectors->selectedItems().size()/noColumn;

    //vecteur qui va contenir la liste des BCAMs temporaires selectionnees dans le tableau
    std::vector<BCAM> *liste_bcam = new std::vector<BCAM>;

    //recuperation des donnees a afficher
    for(int i=0; i<nb_detectors; i++)
    {
        //recuperation de l'identifiant du detecteur
        QString id_detector = ui->tableWidget_liste_detectors->selectedItems().at(i*noColumn)->text();

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
    ui->tableWidget_results->setRowCount(nb_lignes);

    for(unsigned int i=0; i<liste_bcam->size(); i++)
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

      QTableWidgetItem *objet_vise = new QTableWidgetItem();
      objet_vise->setText(QString::fromStdString(liste_bcam->at(i).Get_objet_vise()));
      ui->tableWidget_liste_bcams->setItem(i,4,objet_vise);

      QTableWidgetItem *name = new QTableWidgetItem();
      name->setText(QString::fromStdString(m_bdd.getName(liste_bcam->at(i).Get_objet_vise())));
      ui->tableWidget_results->setItem(i, 0, name);

      QTableWidgetItem *bcam = new QTableWidgetItem();
      bcam->setText(QString::fromStdString(liste_bcam->at(i).Get_nom_BCAM()));
      ui->tableWidget_results->setItem(i, 1, bcam);

      QTableWidgetItem *prism = new QTableWidgetItem();
      prism->setText(QString::fromStdString(liste_bcam->at(i).Get_objet_vise()));
      ui->tableWidget_results->setItem(i, 2, prism);

      setResult(i, Point3f(), 0);
      setResult(i, Point3f(), 1);
      setResult(i, Point3f(), 2);
    }
    ui->tableWidget_results->resizeColumnsToContents();

    tab_bcam =1;
    enable_PushButton();
}

void ATLAS_BCAM::setResult(int row, Point3f point, int columnSet) {
    int firstColumn = 3;

    QTableWidgetItem *x = new QTableWidgetItem(QString::number(point.Get_X()));
    ui->tableWidget_results->setItem(row, firstColumn + (columnSet * 3), x);

    QTableWidgetItem *y = new QTableWidgetItem(QString::number(point.Get_Y()));
    ui->tableWidget_results->setItem(row, firstColumn + 1 + (columnSet * 3), y);

    QTableWidgetItem *z = new QTableWidgetItem(QString::number(point.Get_Z()));
    ui->tableWidget_results->setItem(row, firstColumn + 2 + (columnSet * 3), z);
}

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
        std::cout << "Starting LWDAQ on " << m_bdd.Get_driver_ip_adress() << std::endl;
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

void ATLAS_BCAM::resetDelta() {
    for (std::map<std::string, result>::iterator i = results.begin(); i != results.end(); i++) {
        i->second.setOffset();
    }
    updateResults(results);
}

//fonction qui calcule les coordonnees de chaque prisme dans le repere BCAM + suavegarde            [----> ok
void ATLAS_BCAM::calcul_coord()
{
   //je lis le fichier de sortie de LWDAQ qui contient les observations puis je stocke ce qui nous interesse dans la bdd
   std::string fichier_obs_brutes = path_input_folder.toStdString().append("/").append("LWDAQ").append("/Tools").append("/Data/").append("Acquisifier_Results.txt");

   int lecture_output_result = read_lwdaq_output(fichier_obs_brutes, m_bdd);

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
   mount_prism_to_global_prism(m_bdd);

   calculateResults(m_bdd, results);

   updateResults(results);

   //enregistrement du fichier qui contient les observations dans le repere CCD et dans le repere MOUNT : spots + prismes
   //on recupere la date dans une variable
   time_t t = time(NULL);
   char* tps_calcul = asctime(localtime(&t));

   std::string file_name = "Archive/Observations_MOUNT_System";

   std::string fichier_obs_mount = file_name.append("_").append(tps_calcul, strlen(tps_calcul)-1).append(".txt");
   write_file_obs_mount_system(fichier_obs_mount, m_bdd);

   //vidage des acquisitions
   m_bdd.vidage();
   }
}

void ATLAS_BCAM::calculateResults(bdd &base_donnees, std::map<std::string, result> &results) {

    //on parcourt tous les points transformes dans le repere global : moyenne + dispersion
    // current date/time based on current system
    time_t now = time(0);
    tm* ltm = localtime(&now);

    //sauvegarde des coordonnees du prisme dans le repere ATLAS pour chaque paire de spots
    std::string premier_prisme_atlas = base_donnees.Get_liste_global_coord_prism().at(0).Get_id();

    for(unsigned int i=0; i<base_donnees.Get_liste_global_coord_prism().size(); i++)
    {
        if(i>0 && base_donnees.Get_liste_global_coord_prism().at(i).Get_id() == premier_prisme_atlas)
            break;

        mount_coord_prism prism = base_donnees.Get_liste_global_coord_prism().at(i);

        //nomenclature dans le repere ATLAS
        std::string name_prism_atlas = base_donnees.getName(prism.Get_id().substr(15,5));

        result& result = results[name_prism_atlas];
        result.name = name_prism_atlas;
        result.ltm = ltm;

        Eigen::MatrixXd coord(Eigen::DynamicIndex,3);
        int ligne=0;

        for(unsigned int j=0; j<base_donnees.Get_liste_global_coord_prism().size(); j++)
        {
            mount_coord_prism checkedPrism = base_donnees.Get_liste_global_coord_prism().at(j);
            if(prism.Get_id() == checkedPrism.Get_id())
            {
                coord(ligne,0)=checkedPrism.Get_coord_prism_mount_sys().Get_X();
                coord(ligne,1)=checkedPrism.Get_coord_prism_mount_sys().Get_Y();
                coord(ligne,2)=checkedPrism.Get_coord_prism_mount_sys().Get_Z();
                ligne=ligne+1;
            }
        }
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

        result.std = Point3f(sqrt(result_std_square(0,0)),sqrt(result_std_square(0,1)),sqrt(result_std_square(0,2)));

        //delta selon composantes axiales
        float dx=0;
        float dy=0;
        float dz=0;
        //ajout de la constante de prisme
        for(unsigned int n=0; n<base_donnees.Get_liste_correction_excentrement().size(); n++)
        {
            if(base_donnees.Get_liste_global_coord_prism().at(i).Get_id().substr(15,5) == base_donnees.Get_liste_correction_excentrement().at(n).Get_id_prism())
            {
                dx = base_donnees.Get_liste_correction_excentrement().at(n).Get_delta().Get_X();
                dy = base_donnees.Get_liste_correction_excentrement().at(n).Get_delta().Get_Y();
                dz = base_donnees.Get_liste_correction_excentrement().at(n).Get_delta().Get_Z();
            }
        }

        result.value = Point3f(mean(0,0) + dx, mean(0,1) + dy, mean(0,2) + dz);
    }
}

void ATLAS_BCAM::updateResults(std::map<std::string, result> &results) {
    for (int row = 0; row < ui->tableWidget_results->rowCount(); row++) {
        std::string prism = ui->tableWidget_results->item(row, 0)->text().toStdString();
        std::cout << prism << std::endl;

        result& r = results[prism];
        setResult(row, r.value, 0);
        setResult(row, r.std, 1);
        setResult(row, Point3f(Point3f(r.value, r.offset), 1000), 2);
    }
    ui->tableWidget_results->resizeColumnsToContents();
}

//fonction qui verifie qu'il n'y a pas d'erreurs dans le fichier de configuration                   [----> ok mais peut etre amelioree
void ATLAS_BCAM::check_input_data()
{
    //test des numéros des ports driver : sur les driver les numéros de ports possibles sont compris entre 1 et 8
    for (unsigned int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
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
    for (unsigned int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
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

    //test sur le nombre de détecteurs (ce nombre == 7 )
    if (m_bdd.Get_liste_detector().size() != NBR_DETECTORS)
    {
        int nbr_detectors = m_bdd.Get_liste_detector().size();
        QString str;
        str.setNum(nbr_detectors);

        QMessageBox::information(this,"Information","Le nombre de detecteurs est different de 7", QMessageBox::Ok, QMessageBox::Cancel);
    }

    //test pour vérifier si dans le fichier d'entrée, il y a un seul et unique détecteur avec un seul et unique identifiant
    for (unsigned int i=0; i<m_bdd.Get_liste_detector().size(); i++)
    {

         for (unsigned int j=0; j<m_bdd.Get_liste_detector().size(); j++)
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
    for (unsigned int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
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
    for (unsigned int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        for (unsigned int j=0; j<m_bdd.Get_liste_BCAM().size(); j++)
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
    for (unsigned int i=0; i<m_bdd.Get_liste_BCAM().size(); i++)
    {
        for (unsigned int j=0; j<m_bdd.Get_liste_BCAM().size(); j++)
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

//fonction permettant d'activer les boutons                                                         [----> ok
void ATLAS_BCAM::enable_PushButton()
{
    //si le chemin du fichier d'entree a ete specifie et un detecteur non vide selectionne
    if(!path_input_folder.isEmpty() && tab_bcam == 1)
    {
        // activation du boutton pour lancer l'acquisition et le calcul
        ui->Boutton_lancer->setEnabled(true);
        ui->nextMeasurement->setEnabled(true);
    }
}

//fonction qui permet de generer un script d'acquisition                                            [---> ok
int ATLAS_BCAM::ecriture_script_acquisition(std::string nom_fichier_script_acquisition, std::vector<BCAM> &liste_temp_bcam)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_script_acquisition.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(fichier)
    {
        //écriture la partie du script qui gère l'enregistrement dans un fichier externe
        fichier<<"acquisifier: \n"
               <<"config: \n"
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
               <<" set fn [file join [file dirname $config(run_results)] $name.lwdaq] \n"
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

        //écriture dans le fichier de la partie acquisition du script : un paragraphe par BCAM
        for(unsigned int i=0; i<liste_temp_bcam.size(); i++)
        {
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

                for(unsigned int j=0; j<liste_temp_bcam.size(); j++)
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


        }

        fichier.close();
        return 1;
    }

    else
    {
        return 0;
    }
}

//fonction qui permet de generer un bash en shell pour lancer et arreter LWDAQ                      [---> ok
int ATLAS_BCAM::ecriture_script_bash(std::string nom_fichier_bash)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)nom_fichier_bash.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(fichier)
    {
        std::string chemin_lWDAQ_startup = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("LWDAQ.app").append("/").append("Contents").append("/").append("LWDAQ").append("/").append("Startup/");
        std::string chemin_lwdaq_data = path_input_folder.toStdString().append("/").append(NAME_LWDAQ_FOLDER).append("/").append("Tools").append("/").append("Data/");
        fichier<<"#!/bin/bash \n"
               <<"cp scripts_lwdaq/Acquisifier_params.tcl "<<chemin_lWDAQ_startup<<"\n"
              <<"cp scripts_lwdaq/Acquisifier_Settings.tcl "<<chemin_lwdaq_data<<"\n"
               <<"cp scripts_lwdaq/Acquisifier_script_file.tcl "<<chemin_lwdaq_data<<"\n"
               <<path_lwdaq<<" --no-console"<<" \n"
               <<"ps -e | grep tclsh | grep -v grep > PID.txt \n"
               <<"read pid reste < PID.txt \n";
       if(mode_adepo == "CLOSURE")
           fichier<<"sleep "<<time_value.toStdString()<<"s"<<"\n";    //en mode closure c'est directement le temps donnees par l'operateur
       else
           fichier<<"sleep 10s"<<"\n";          //en mode monitoring l'operateur choisit la frequence, le temps d'acquisition sera de 3 min pour etre sur de passer par chaque capteur
           fichier<<"kill \"$pid\" \n";

           fichier.close();
           return 1;
    }
    else
    {
           return 0;
    }
}

//fonction qui ecrit un fichier tcl avec les parametres par defaut pour la fenetre Acquisifier      [---> ok
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
               <<"set Acquisifier_config(daq_script) \""<<path_input_folder.toStdString().append("/").append("LWDAQ").append("/Tools").append("/Data/").append(fichier_script)<<"\" \n"
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

//fonction qui genere un fichier tcl avec les parametres par defaut pour la fenetre BCAM de LWDAQ   [----> ok
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
               <<"set LWDAQ_config_BCAM(daq_ip_addr) \" "<<m_bdd.Get_driver_ip_adress()<<" \" \n"
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

//fonction qui gere les selections dans les checkbox                                                [----> ok
void ATLAS_BCAM::get_mode()
{
    mode_adepo = ui->comboBox->currentText();
    if(mode_adepo == "MONITORING")
    {
        //changement du texte
        ui->textEdit_function_mode->setText("</style></head><body style=\" font-family:\'Ubuntu\'; font-size:11pt; font-weight:400; font-style:normal;\"><p align=\"center\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-size:10pt; font-weight:600;\">Frequence d\'acquisition (s) :</span></p></body></html>");
        //changement des valeurs d'interval pour le temps
        ui->spinBox->setMinimum(240);  //frequence maxi : 1 mesure toutes les 15 min: 900
        ui->spinBox->setMaximum(86400); //frequence mini ; 1 mesure par jour
    }
    else
    {
        //changement du text
        ui->textEdit_function_mode->setText("</style></head><body style=\" font-family:\'Ubuntu\'; font-size:11pt; font-weight:400; font-style:normal;\"><p align=\"center\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><span style=\" font-size:10pt; font-weight:600;\">Temps d\'acquisition (s) :</span></p></body></html>");
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
        for(unsigned int i=0; i<m_bdd.Get_liste_absolutes_distances().size(); i++)
        {
            float val_x = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances().Get_X();
            float val_y = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances().Get_Y();
            float val_z = m_bdd.Get_liste_absolutes_distances().at(i).Get_distances().Get_Z();

            Point3f pt(val_x+0.003, val_y+0.003, val_z+0.003);
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
