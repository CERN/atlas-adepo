
#include <iomanip>
#include <iostream>

#include "Eigen/Core"
#include "Eigen/LU"
#include "Eigen/Householder"
#include "Eigen/QR"

#include "adepo.h"
#include "helmert.h"
#include "configuration.h"

void helmert(Configuration& config, Data &data) {

    for(unsigned int i=0; i<config.getBCAMConfigs().size(); i++) //je parcours la liste des BCAMs dont je dispose
    {
        //definition de 2 sous-vecteurs d'observations
        Eigen::VectorXd l_terrain(12); l_terrain.setZero();
        Eigen::VectorXd l_modele(12);  l_modele.setZero();

        if(config.getBCAMConfigs().at(i).getName().mid(7,1) == "A" || config.getBCAMConfigs().at(i).getName().mid(7,1) == "L") //si la bcam est noire
        {
            int cmpt=0;
            for(unsigned int j=0; j<config.getBCAMAdapters().size(); j++) //je parcours la liste des coordonnees modele
            {
                if(config.getBCAMAdapters().at(j).getTypeBCAM() == "Black")
                {
                    l_modele(3*cmpt,0)=config.getBCAMAdapters().at(j).getTargetCoord().x();
                    l_modele(3*cmpt+1,0)=config.getBCAMAdapters().at(j).getTargetCoord().y();
                    l_modele(3*cmpt+2,0)=config.getBCAMAdapters().at(j).getTargetCoord().z();
                    cmpt++;
                }
            }

        }
        if(config.getBCAMConfigs().at(i).getName().mid(7,1) == "B" || config.getBCAMConfigs().at(i).getName().mid(7,1) == "M")
        {
            int cmpt=0;
            for(unsigned int j=0; j<config.getBCAMAdapters().size(); j++) //je parcours la liste des coordonnees modele
            {
                if(config.getBCAMAdapters().at(j).getTypeBCAM() == "Blue")
                {
                    l_modele(3*cmpt)=config.getBCAMAdapters().at(j).getTargetCoord().x();
                    l_modele(3*cmpt+1)=config.getBCAMAdapters().at(j).getTargetCoord().y();
                    l_modele(3*cmpt+2)=config.getBCAMAdapters().at(j).getTargetCoord().z();
                    cmpt++;
                }
            }
        }
        //std::cout<<l_modele<<std::endl;
        //std::cout<<"----------------------"<<std::endl;
        //je remplie le vecteur des mesures terrain
        int cmpt=0;
        for(unsigned int j=0; j<config.getATLASCoordinates().size(); j++)
        {
            if(config.getBCAMConfigs().at(i).getName() == config.getATLASCoordinates().at(j).getBCAM())
            {
                    l_terrain(3*cmpt,0)=config.getATLASCoordinates().at(j).getTarget().x();
                    l_terrain(3*cmpt+1,0)=config.getATLASCoordinates().at(j).getTarget().y();
                    l_terrain(3*cmpt+2,0)=config.getATLASCoordinates().at(j).getTarget().z();
                    cmpt++;
            }
        }

        //le vecteur des observations global
        Eigen::VectorXd l(24); l.setZero();
        //remplissage du vecteur des observations
        int compt=0;
        for(int k=0; k<4; k++)
        {
            l(3*k+compt)=l_terrain(3*k);
            l(3*k+1+compt)=l_terrain(3*k+1);
            l(3*k+2+compt)=l_terrain(3*k+2);
            l(3*k+3+compt)=l_modele(3*k);
            l(3*k+4+compt)=l_modele(3*k+1);
            l(3*k+5+compt)=l_modele(3*k+2);
            compt=compt+3;
        }
        //std::cout<<l<<std::endl;
        //std::cout<<"-----------------------------------"<<std::endl;

          //facteur unitaire de variance a priori
 //         int sigma_0=1;

          //matrice des co-facteurs
          Eigen::MatrixXd Qll(24,24); Qll.setIdentity();

          //matrice des poids
          Eigen::MatrixXd P(24,24); P.setIdentity();

          //valeurs initiales
          float Tx0=0; float Ty0=0; float Tz0=0;
          float phi0=0; float teta0=0; float psi0=0;

          //valeur aberrante pour le critere d'arret
        //  float sigma_test=1e15;

          for (int m=0; m<50; m++) //iterations pour la convergence
          {
              //definition de la matrice rotation
              float a11 = cos(teta0)*cos(phi0);
              float a12 = cos(teta0)*sin(phi0);
              float a13 = -sin(teta0);
              float a21 = sin(psi0)*sin(teta0)*cos(phi0)-cos(psi0)*sin(phi0);
              float a22 = sin(psi0)*sin(teta0)*sin(phi0)+cos(psi0)*cos(phi0);
              float a23 = cos(teta0)*sin(psi0);
              float a31 = cos(psi0)*sin(teta0)*cos(phi0)+sin(psi0)*sin(phi0);
              float a32 = cos(psi0)*sin(teta0)*sin(phi0)-sin(psi0)*cos(phi0);
              float a33 = cos(teta0)*cos(psi0);

              Eigen::MatrixXd R(3,3); R.setZero();
              R(0,0)=a11; R(0,1)=a12; R(0,2)=a13;
              R(1,0)=a21; R(1,1)=a22; R(1,2)=a23;
              R(2,0)=a31; R(2,1)=a32; R(2,2)=a33;
              //std::cout<<"matrice R"<<std::endl;
              //std::cout<<std::setprecision(14)<<R<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //vecteur translation
              Eigen::MatrixXd T(1,3); T.setZero();
              T(0,0)=Tx0; T(0,1)=Ty0; T(0,2)=Tz0;
              //std::cout<<"matrice T"<<std::endl;
              //std::cout<<std::setprecision(8)<<T<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //vecteur des residus a priori temporaire
              Eigen::MatrixXd l_modele_l(4,3); l_modele_l.setZero();
              Eigen::MatrixXd l_terrain_l(4,3); l_terrain_l.setZero();
              int compt=0;
              for(int i=0; i<4; i++)
              {
                  for(int j=0; j<3; j++)
                  {
                      l_modele_l(i,j)=l_modele(j+3*compt);
                      l_terrain_l(i,j)=l_terrain(j+3*compt);
                  }
                   compt++;
              }

              Eigen::MatrixXd w_tmp(4,3); w_tmp.setZero();
              for(int i=0; i<4; i++)
              {
                  w_tmp.row(i)=l_terrain_l.row(i).transpose()-T.transpose()-R*l_modele_l.row(i).transpose();
              }
              //std::cout<<"matrice w_tmp"<<std::endl;
              //std::cout<<w_tmp<<std::endl;
              //std::cout<<"---------->"<<std::endl;;

              //vecteur des residus a priori (le rendre en ligne)
              Eigen::VectorXd w(12); w.setZero();
              for(int i=0; i<4; i++)
              {
                  w(3*i,0)=w_tmp(i,0);
                  w(3*i+1)=w_tmp(i,1);
                  w(3*i+2)=w_tmp(i,2);

              }
              //std::cout<<"matrice w"<<std::endl;
              //std::cout<<w<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              int compteur=0;
              //matrice modele A
              Eigen::MatrixXd A(12,6); A.setZero();
              for(int i=0; i<4; i++)
              {
                  A(compteur,0)=1;
                  A(compteur,1)=0;
                  A(compteur,2)=0;
                  A(compteur,3)=-l_modele_l(i,0)*cos(teta0)*sin(phi0)+l_modele_l(i,1)*cos(teta0)*cos(phi0);
                  A(compteur,4)=-l_modele_l(i,0)*cos(phi0)*sin(teta0)-l_modele_l(i,1)*sin(phi0)*sin(teta0)-l_modele_l(i,2)*cos(teta0);
                  A(compteur,5)=0;

                  compteur=compteur+1;

                  A(compteur,0)=0;
                  A(compteur,1)=1;
                  A(compteur,2)=0;
                  A(compteur,3)=-l_modele_l(i,0)*sin(psi0)*sin(teta0)*sin(phi0)-l_modele_l(i,0)*cos(psi0)*cos(phi0)+l_modele_l(i,1)*sin(psi0)*sin(teta0)*cos(phi0)-l_modele_l(i,1)*cos(psi0)*sin(phi0);
                  A(compteur,4)=l_modele_l(i,0)*sin(psi0)*cos(phi0)*cos(teta0)+l_modele_l(i,1)*sin(psi0)*sin(phi0)*cos(teta0)-l_modele_l(i,2)*sin(psi0)*sin(teta0);
                  A(compteur,5)=l_modele_l(i,0)*sin(teta0)*cos(phi0)*cos(psi0)+l_modele_l(i,0)*sin(phi0)*sin(psi0)+l_modele_l(i,1)*sin(teta0)*sin(phi0)*cos(psi0)-l_modele_l(i,1)*cos(phi0)*sin(psi0)+l_modele_l(i,2)*cos(teta0)*cos(psi0);

                  compteur=compteur+1;

                  A(compteur,0)=0;
                  A(compteur,1)=0;
                  A(compteur,2)=1;
                  A(compteur,3)=-l_modele_l(i,0)*cos(psi0)*sin(teta0)*sin(phi0)+l_modele_l(i,0)*sin(psi0)*cos(phi0)+l_modele_l(i,1)*cos(psi0)*sin(teta0)*cos(phi0)+l_modele_l(i,1)*sin(psi0)*sin(phi0);
                  A(compteur,4)=l_modele_l(i,0)*cos(psi0)*cos(phi0)*cos(teta0)+l_modele_l(i,1)*cos(psi0)*sin(phi0)*cos(teta0)-l_modele_l(i,2)*cos(psi0)*sin(teta0);
                  A(compteur,5)=-l_modele_l(i,0)*sin(teta0)*cos(phi0)*sin(psi0)+l_modele_l(i,0)*sin(phi0)*cos(psi0)-l_modele_l(i,1)*sin(teta0)*sin(phi0)*sin(psi0)-l_modele_l(i,1)*cos(phi0)*cos(psi0)-l_modele_l(i,2)*cos(teta0)*sin(psi0);

                  compteur=compteur+1;
              }
              //on prend - la matrice modele;
              A=(-1)*A;
              //std::cout<<"matrice A"<<std::endl;
              //std::cout<<A<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //matrice modele G : derivees par rapport aux observations
              //matrice identite
              Eigen::MatrixXd Id(3,3); Id.setIdentity();

              //matrice temporaire
              Eigen::MatrixXd g(3,6); g.setZero();
              for(int i=0; i<3; i++)
              {
                  g.col(i)=Id.col(i);
                  g.col(i+3)=-R.col(i);
              }
              //std::cout<<"matrice g"<<std::endl;
              //std::cout<<g<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //la vraie matrice modele
              Eigen::MatrixXd G(12,24); G.setZero();
              for(int i=0; i<3; i++)
              {
                  for(int j=0; j<6; j++)
                  {
                      G(i,j)=g(i,j);
                      G(i+3,j+6)=g(i,j);
                      G(i+6,j+12)=g(i,j);
                      G(i+9,j+18)=g(i,j);
                  }
              }
              //std::cout<<"matrice G"<<std::endl;
              //std::cout<<G<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              Eigen::MatrixXd s2;
              s2=G*G.transpose();
              //std::cout<<"matrice s2"<<std::endl;
              //std::cout<<s2<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              Eigen::HouseholderQR<Eigen::MatrixXd> qr(s2);
              Eigen::MatrixXd S;
              S=qr.solve(G);
              //std::cout<<"matrice S"<<std::endl;
              //std::cout<<S<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              Eigen::MatrixXd S_bis;
              S_bis=S.transpose();
              //std::cout<<"matrice S_bis"<<std::endl;
              //std::cout<<S_bis<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //matrice modele bis
              Eigen::MatrixXd A_bis(24,6); A_bis.setZero();
              A_bis=-S_bis*A;
              //std::cout<<"matrice A_bis"<<std::endl;
              //std::cout<<A_bis<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //matrice des obs bis
              Eigen::VectorXd B_bis(24); B_bis.setZero();
              B_bis=S_bis*w;

              //compensation
              Eigen::VectorXd delta_x(6); delta_x.setZero();
              delta_x=(A_bis.transpose()*P*A_bis).inverse()*(A_bis.transpose()*P*B_bis);
              //std::cout<<"matrice DX"<<std::endl;
              //std::cout<<delta_x<<std::endl;
              //std::cout<<"---------->"<<std::endl;

              //mise a jour des parametres
              Tx0=Tx0+delta_x(0);
              Ty0=Ty0+delta_x(1);
              Tz0=Tz0+delta_x(2);
              phi0=phi0+delta_x(3);
              teta0=teta0+delta_x(4);
              psi0=psi0+delta_x(5);

              //matrices variance-covariances apres compensation pour les parametres
              Eigen::MatrixXd Qxx(6,6); Qxx.setZero();
              Qxx=(A_bis.transpose()*P*A_bis).inverse();

              //vecteur des residus estimes
              Eigen::VectorXd v_estime(24); v_estime.setZero();
              v_estime=B_bis-A_bis*delta_x;

              //matrice variance-covariances pour les observations
              Eigen::MatrixXd Qvv(24,24); Qvv.setZero();
              Qvv=S_bis*G*Qll-A_bis*Qxx*A_bis.transpose();

              //vecteur des observations estimees
              Eigen::VectorXd l_estime(24); l_estime.setZero();
              l_estime=l-v_estime;
              Eigen::MatrixXd Qll_estime(24,24); Qll.setZero();
              Qll_estime=Qll-Qvv;

              //facteur unitaire de variance apres compensation
              //Eigen::VectorXd sigma0_estime(1); sigma0_estime.setZero();
              //sigma0_estime=(v_estime.transpose()*P*v_estime)/(18); //18 = 24-6

          }
            //enregistrement dans la base de donnees des parametres de chaque BCAM
            QString id_bcam = config.getBCAMConfigs().at(i).getName();
            Point3f translation(Tx0,Ty0,Tz0);
            Point3f rotation(phi0,teta0,psi0);
            BCAMParams parametres_bcam(id_bcam, translation, rotation);
            data.add(parametres_bcam);
     }

    //affichage des paramteres pour toutes les bcams
#ifdef ADEPO_DEBUG
    for(unsigned int i=0; i<data.getBCAMParams().size(); i++)
    {
        data.getBCAMParams().at(i).print();
    }
#endif
}
