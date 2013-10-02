#include "header/Point3f.h"
#include <iostream>
using namespace std;

<<<<<<< HEAD
Point3f::Point3f(float X,float Y,float Z):m_X(X),m_Y(Y),m_Z(Z)
=======
Point3f::Point3f(double X,double Y,double Z):m_X(X),m_Y(Y),m_Z(Z)
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
{
    //ctor
}

Point3f::Point3f()
{
    this->m_X = 0;
    this->m_Y = 0;
    this->m_Z = 0;
}

Point3f::~Point3f()
{
    //dtor
}

Point3f::Point3f(const Point3f& copie):m_X(copie.m_X),m_Y(copie.m_Y),m_Z(copie.m_Z)
{
    //copy ctor
}

bool Point3f::Est_egal(Point3f pt)
{
    if(this->m_X==pt.Get_X() && this->m_Y==pt.Get_Y() && this->m_Z==pt.Get_Z())
        {
            return true;
        }
    else
        {
            return false;
        }
}

void Point3f::Affiche()
{
    cout<<"Affichage du point"<<endl;
    cout<<"X : "<<this->m_X<<endl;
    cout<<"Y : "<<this->m_Y<<endl;
    cout<<"Z : "<<this->m_Z<<endl;
    cout<<"\n";
}
