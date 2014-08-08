#include "changement_repere.h"
#include <iostream>
#include "Eigen/Core"
#include "Eigen/LU"

Point3f changement_repere(Point3f coord_sys1, Point3f translation, Point3f rotation)
{

    float x_sys1 = coord_sys1.Get_X();
    float y_sys1 = coord_sys1.Get_Y();
    float z_sys1 = coord_sys1.Get_Z();

    //vecteur point dans systeme 1
    Eigen::MatrixXd pt_sys1(1,3); pt_sys1.setZero();
    pt_sys1(0,0)=x_sys1; pt_sys1(0,1)=y_sys1; pt_sys1(0,2)=z_sys1;
    /*std::cout<<"pt_sys1"<<std::endl;
    std::cout<<pt_sys1<<std::endl;
    std::cout<<"---------->"<<std::endl;*/

    float Tx0 = translation.Get_X();
    float Ty0 = translation.Get_Y();
    float Tz0 = translation.Get_Z();

    //vecteur translation
    Eigen::MatrixXd T(1,3); T.setZero();
    T(0,0)=Tx0; T(0,1)=Ty0; T(0,2)=Tz0;
    /*std::cout<<"translation"<<std::endl;
    std::cout<<T<<std::endl;
    std::cout<<"---------->"<<std::endl;*/

    float phi0 = rotation.Get_X();
    float teta0 = rotation.Get_Y();
    float psi0 = rotation.Get_Z();

    /*std::cout<<teta0<<std::endl;
    std::cout<<phi0<<std::endl;
    std::cout<<psi0<<std::endl;*/

    //definition de la matrice rotation
    float a11=cos(teta0)*cos(phi0);
    float a12=cos(teta0)*sin(phi0);
    float a13=-sin(teta0);
    float a21=sin(psi0)*sin(teta0)*cos(phi0)-cos(psi0)*sin(phi0);
    float a22=sin(psi0)*sin(teta0)*sin(phi0)+cos(psi0)*cos(phi0);
    float a23=cos(teta0)*sin(psi0);
    float a31=cos(psi0)*sin(teta0)*cos(phi0)+sin(psi0)*sin(phi0);
    float a32=cos(psi0)*sin(teta0)*sin(phi0)-sin(psi0)*cos(phi0);
    float a33=cos(teta0)*cos(psi0);

    Eigen::MatrixXd R(3,3); R.setZero();
    R(0,0)=a11; R(0,1)=a12; R(0,2)=a13;
    R(1,0)=a21; R(1,1)=a22; R(1,2)=a23;
    R(2,0)=a31; R(2,1)=a32; R(2,2)=a33;
    /*std::cout<<"rotation"<<std::endl;
    std::cout<<R<<std::endl;
    std::cout<<"---------->"<<std::endl;*/

    //vecteur point dans le systeme 2
    Eigen::MatrixXd pt_sys2;
    pt_sys2=T.transpose() + R*pt_sys1.transpose();
    //std::cout<<"pt_sy2"<<std::endl;
    //std::cout<<pt_sys2<<std::endl;
    //std::cout<<"---------->"<<std::endl;

    //transformation en point3f
    float x_sys2 = pt_sys2(0);
    float y_sys2 = pt_sys2(1);
    float z_sys2 = pt_sys2(2);

    Point3f pt_transforme(x_sys2, y_sys2, z_sys2);
    //pt_transforme.Affiche();

    //retourne le point transfrome
    return pt_transforme;
}

