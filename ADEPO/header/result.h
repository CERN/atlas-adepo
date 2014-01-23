#ifndef RESULT_H
#define RESULT_H

#include "ctime"
#include "Point3f.h"

class result
{
public:
    result() {
        value = Point3f();
        std = Point3f();
        setOffset();
    }
    ~result() {};

    void setOffset() {
        offset = value;
    }

    void toString() {
        std::cout << name << " "
                  << value.Get_X() << " " << value.Get_Y() << " " << value.Get_Z() << " "
                  << std.Get_X() << " " << std.Get_Y() << " " << std.Get_Z() << ""
                  << offset.Get_X() << " " << offset.Get_Y() << " " << offset.Get_Z() <<
                     std::endl;
    }

    std::string name;
    tm *ltm;
    Point3f value;
    Point3f std;
    Point3f offset;
};

#endif // RESULT_H
