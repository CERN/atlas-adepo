<<<<<<< HEAD
=======

>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
#include "header/bdd.h"
#include "header/read_input.h"
#include "header/read_lwdaq_output.h"
#include "header/read_calibration_database.h"
#include "header/detect_flash.h"
#include "header/write_bash_script.h"


#include "header/clean_calib.h"
#include "header/liste_bcam_from_id_detector.h"

#include <QApplication>
#include <QtGui>
#include "header/atlas_bcam.h"
<<<<<<< HEAD
#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>
=======
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

int main(int argc, char *argv[])
{

QApplication app(argc, argv);
<<<<<<< HEAD
QString locale = QLocale::system().name().section('_', 0, 0);
QTranslator translator;
translator.load(QString("qt_") + locale, QLibraryInfo::location(QLibraryInfo::TranslationsPath));
app.installTranslator(&translator);
ATLAS_BCAM fenetre;
//system("mkdir Archive");
=======
ATLAS_BCAM fenetre;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
fenetre.show();
return app.exec();
/*

     //je crée aussi la base de données qui va contenir les acquisitions
     data *ma_bdd_data = new data();

     //je lis les fichier de sortie de LWDAQ
     std::string fichier_sortie = "/home/cern-mehdi/Documents/LWDAQ/Tools/Data/Acquisifier_Results.txt";
     lecture_sortie(fichier_sortie, *ma_bdd, *ma_bdd_data);

     //je lis le fichier des paramètres de calibration
     std::string fichier_calibration = "BCAM_Parameters.txt";
     lecture_calibration(fichier_calibration, *ma_bdd);

     //je nettoie la base de donnees qui contient les calibrations
     //

     //je commence les transformations du capteur au repere BCAM



    */




     //std::cout<<ma_bdd->Get_liste_calib().size()<<std::endl;
     //Point3f val(0,0,0);

     /*for(int i=0; i<ma_bdd->Get_liste_calib().size(); i++)
     {

         //if(ma_bdd->Get_liste_calib().at(i).Get_id_BCAM() == "20MABNDA000349")
            //ma_bdd->Get_liste_calib().at(i).Affiche();

         if(i==ma_bdd->Get_liste_calib().size()-1)
            break;

          if(ma_bdd->Get_liste_calib().at(i+1).Get_coord_flash_1().Est_egal(ma_bdd->Get_liste_calib().at(i).Get_coord_flash_1()))
          {
              ma_bdd->Get_liste_calib().at(i+1).Set_coord_flash_1(val);
              ma_bdd->Get_liste_calib().at(i+1).Set_coord_flash_2(val);

          }

     }
     for(int i=0; i<ma_bdd->Get_liste_calib().size(); i++)
     {
         if(ma_bdd->Get_liste_calib().at(i).Get_id_BCAM() == "20MABNDA000463")
         ma_bdd->Get_liste_calib().at(i).Affiche();
     }*/
 }
