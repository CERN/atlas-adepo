#ifndef POINT3F_H
#define POINT3F_H

#include <iostream>

class Point3f
{
    public:

        //constructeurs et destructeurs
        Point3f() : mValid(true),mX(0),mY(0),mZ(0) {};
        Point3f(float X,float Y,float Z) : mValid(true),mX(X),mY(Y),mZ(Z) {};
        Point3f(bool valid) : mValid(valid),mX(0),mY(0),mZ(0) {};
        virtual ~Point3f() {};
        Point3f(const Point3f& copie) : mValid(copie.mValid),mX(copie.mX),mY(copie.mY),mZ(copie.mZ) {};
        Point3f(const Point3f& value, const Point3f& ref) : mValid(value.mValid && ref.mValid),mX(value.mX-ref.mX),mY(value.mY-ref.mY),mZ(value.mZ-ref.mZ) {};
        Point3f(const Point3f& value, float multiplier) : mValid(value.mValid),mX(value.mX*multiplier),mY(value.mY*multiplier),mZ(value.mZ*multiplier) {};

        //setter et getter
        bool isValid() { return mValid; }
        float x() const { return mX; }
//        void Set_X(float val) { m_X = val; }
        float y() const { return mY; }
//        void Set_Y(float val) { m_Y = val; }
        float z() const { return mZ; }
//        void Set_Z(float val) { m_Z = val; }

        //methodes
        void print() {
            std::cout<<"Affichage du point"<<std::endl;
            std::cout<<"Valid : "<<isValid()<<std::endl;
            std::cout<<"X : "<<x()<<std::endl;
            std::cout<<"Y : "<<y()<<std::endl;
            std::cout<<"Z : "<<z()<<std::endl;
            std::cout<<std::endl;
        }

        bool equals(Point3f pt) { return (mValid == pt.isValid() && mX==pt.x() && mY==pt.y() && this->mZ==pt.z()); }

    protected:
    private:
        bool mValid;
        float mX;
        float mY;
        float mZ;
};

#endif // POINT3F_H
