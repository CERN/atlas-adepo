#include <fstream>
#include <iostream>

#include "calibration.h"
#include "point3f.h"

int Calibration::read(QString filename)
{
       std::ifstream fichier((char*)filename.toStdString().c_str(), std::ios::in);
       if (!fichier) {
           std::cout << "WARNING Cannot read calibration file " << filename.toStdString() << std::endl;
            return 0;
       }

       std::string ligne;  // déclaration d'une chaîne qui contiendra la ligne lue
       unsigned int etape_calcul = 0;

       while(std::getline(fichier,ligne)) // tant que l'on arrive pas a la fin du fichier
       {
           // take ending off the line
           ligne.erase(ligne.find_last_not_of(" \n\r\t")+1);

           if(!ligne.empty())
            {
                // pivot + focale + axis + ccd rotation
                if(ligne.size() == 91)
                {
                    etape_calcul = 1;
                }

                // sources
                if(ligne.size() == 70)
                {
                    etape_calcul = 2;
                }

                if(!ligne.empty())
                {
                    switch(etape_calcul)
                    {
                    case 1:
                    {
                        char *buffer1 = strdup((char*)ligne.c_str());
                        QString id_BCAM = QString::fromStdString(strtok(buffer1," "));
                        QString tps_calib = QString::fromStdString(strtok( NULL, " " ));
                        char *x_pivot = strtok( NULL, " " );
                        char *y_pivot = strtok( NULL, " " );
                        char *z_pivot = strtok( NULL, " " );
                        char *x_axis = strtok( NULL, " " );
                        char *y_axis = strtok( NULL, " " );
                        char *z_axis = strtok( NULL, " " );
                        char *dist_ccd_pivot = strtok( NULL, " " );
                        char *ccd_rotation = strtok( NULL, " " );

                        Point3f pv(atof(x_pivot), atof(y_pivot), atof(z_pivot));
                        Point3f ax(atof(x_axis), atof(y_axis),atof(z_axis));
                        float focale = atof(dist_ccd_pivot);
                        float angle_rotation = atof(ccd_rotation);
                        Calib1 cal1(id_BCAM, tps_calib, pv, ax, focale, angle_rotation);
                        add(cal1);
                    }
                    break;

                    case 2:
                    {
                        char *buffer2 = strdup((char*)ligne.c_str());
                        QString id_BCAM_2 = QString::fromStdString(strtok(buffer2," "));
                        QString tps_calib_2 = QString::fromStdString(strtok( NULL, " " ));
                        char *x1_flash = strtok( NULL, " " );
                        char *y1_flash = strtok( NULL, " " );
                        char *x2_flash = strtok( NULL, " " );
                        char *y2_flash = strtok( NULL, " " );
                        char *z_flash = strtok( NULL, " " );

                        Point3f spt1(atof(x1_flash), atof(y1_flash), atof(z_flash));
                        Point3f spt2(atof(x2_flash), atof(y2_flash), atof(z_flash));
                        Calib2 cal2(id_BCAM_2, spt1, spt2);
                        add(cal2);
                    }
                    break;

                    }

                }
            }
      }
       //affichage du contenu de la base de donnees qui contient le fichier de calibration
       /*for(int i=0; i<base_donnees.Get_liste_calib1().size(); i++)
       {
              base_donnees.Get_liste_calib1().at(i).Affiche();
       }
       for(int j=0; j<base_donnees.Get_liste_calib2().size(); j++)
       {
              base_donnees.Get_liste_calib2().at(j).Affiche();
       }*/

       fichier.close();

       this->filename = filename;
       return 1;
}

//fonction qui verifie si toutes les BCAMS sont contenues dans le fichier de calibration            [----> not yet, on suppose que le fichier de calibration est correct
std::string Calibration::check() const
{
/*
    int exist_l1 = 0;
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
    if (exist_l1 <= m_bdd.Get_liste_BCAM().size() || exist_l2 <= m_bdd.Get_liste_BCAM().size()) {
        return "Attention Il manque des donnees de calibration pour au moins 1 BCAM";
    }
*/
    return "";
}

