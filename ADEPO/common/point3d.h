#ifndef POINT3D_H
#define POINT3D_H

#include <iostream>

#include <QJsonObject>

class Point3d
{
    public:

        //constructeurs et destructeurs
        Point3d() : mValid(true),mX(0),mY(0),mZ(0) {};

        Point3d(float X,float Y,float Z) : mValid(true),mX(X),mY(Y),mZ(Z) {};
        Point3d(bool valid, float X,float Y,float Z) : mValid(valid),mX(X),mY(Y),mZ(Z) {};
        Point3d(bool valid) : mValid(valid),mX(0),mY(0),mZ(0) {};
        virtual ~Point3d() {};
        Point3d(const Point3d& copie) : mValid(copie.mValid),mX(copie.mX),mY(copie.mY),mZ(copie.mZ) {};
        Point3d(const Point3d& value, const Point3d& ref) : mValid(value.mValid && ref.mValid),mX(value.mX-ref.mX),mY(value.mY-ref.mY),mZ(value.mZ-ref.mZ) {};
        Point3d(const Point3d& value, float multiplier) : mValid(value.mValid),mX(value.mX*multiplier),mY(value.mY*multiplier),mZ(value.mZ*multiplier) {};

        //setter et getter
        bool isValid() { return mValid; }
        double x() const { return mX; }
        double y() const { return mY; }
        double z() const { return mZ; }

        //methodes
        void print() {
            std::cout<<"Affichage du point"<<std::endl;
            std::cout<<"Valid : "<<isValid()<<std::endl;
            std::cout<<"X : "<<x()<<std::endl;
            std::cout<<"Y : "<<y()<<std::endl;
            std::cout<<"Z : "<<z()<<std::endl;
            std::cout<<std::endl;
        }

        void read(const QJsonObject &json) {
            mValid = json["valid"].toBool();
            mX = json["x"].toDouble();
            mY = json["y"].toDouble();
            mZ = json["z"].toDouble();
        }

        void write(QJsonObject &json) const {
            json["valid"] = mValid;
            json["x"] = mX;
            json["y"] = mY;
            json["z"] = mZ;
        }

        bool equals(Point3d pt) { return (mValid == pt.isValid() && mX==pt.x() && mY==pt.y() && this->mZ==pt.z()); }

    protected:
    private:
        bool mValid;
        double mX;
        double mY;
        double mZ;
};

#endif // POINT3D_H
