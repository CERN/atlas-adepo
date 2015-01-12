#include <QApplication>
#include <QtGui>
#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>

#include "atlas_bcam.h"

int main(int argc, char *argv[])
{

QApplication app(argc, argv);

QCoreApplication::setOrganizationName("ATLAS CERN");
QCoreApplication::setOrganizationDomain("atlas.cern.ch");
QCoreApplication::setApplicationName("ADEPO");
QCoreApplication::setApplicationVersion("1.2");

QString locale = QLocale::system().name().section('_', 0, 0);
QTranslator translator;
translator.load(QString("qt_") + locale, QLibraryInfo::location(QLibraryInfo::TranslationsPath));
app.installTranslator(&translator);
ATLAS_BCAM fenetre;
//system("mkdir Archive");
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
