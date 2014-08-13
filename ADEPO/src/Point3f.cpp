#include "Point3f.h"
#include <iostream>
using namespace std;

Point3f::Point3f(float X,float Y,float Z):valid(true),m_X(X),m_Y(Y),m_Z(Z)
{
    //ctor
}

Point3f::Point3f():valid(true),m_X(0),m_Y(0),m_Z(0)
{
    //ctor
}

Point3f::Point3f(bool _valid):valid(_valid),m_X(0),m_Y(0),m_Z(0)
{
    // ctor
}

Point3f::~Point3f()
{
    //dtor
}

Point3f::Point3f(const Point3f& copie):valid(copie.valid),m_X(copie.m_X),m_Y(copie.m_Y),m_Z(copie.m_Z)
{
    //copy ctor
}

Point3f::Point3f(const Point3f& value, const Point3f& offset):valid(value.valid && offset.valid),m_X(value.m_X-offset.m_X),m_Y(value.m_Y-offset.m_Y),m_Z(value.m_Z-offset.m_Z)
{
    //value - offset
}

Point3f::Point3f(const Point3f& value, float multiplier):valid(value.valid),m_X(value.m_X*multiplier),m_Y(value.m_Y*multiplier),m_Z(value.m_Z*multiplier)
{
    //value * multiplier
}

bool Point3f::Est_egal(Point3f pt)
{
    return (this->valid == pt.isValid() && this->m_X==pt.Get_X() && this->m_Y==pt.Get_Y() && this->m_Z==pt.Get_Z());
}

void Point3f::Affiche()
{
    cout<<"Affichage du point"<<endl;
    cout<<"Valid : "<<this->valid<<endl;
    cout<<"X : "<<this->m_X<<endl;
    cout<<"Y : "<<this->m_Y<<endl;
    cout<<"Z : "<<this->m_Z<<endl;
    cout<<"\n";
}
