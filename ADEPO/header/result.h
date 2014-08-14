#ifndef RESULT_H
#define RESULT_H

#include "ctime"
#include "Point3f.h"

class result
{
public:
    result() {
        value = Point3f(false);
        std = Point3f(false);
        n = 0;
        setOffset();
    }
    ~result() {};

    void setName(std::string _name) {
        name = _name;
    }

    void setTime(tm *_ltm) {
        ltm = _ltm;
    }

    void setN(int _n) {
        n = _n;
    }

    int getN() {
        return n;
    }

    void setStd(Point3f _std) {
        std = _std;
    }

    Point3f getStd() {
        return std;
    }

    void setValue(Point3f _value) {
        value = _value;
        if (value.isValid() && !offset.isValid()) {
            setOffset();
        }
    }

    Point3f getValue() {
        return value;
    }

    void setOffset() {
        offset = value;
    }

    Point3f getOffset() {
        return offset;
    }

    void toString() {
        std::cout << name << " " << n << ""
                  << value.isValid() << " " << value.x() << " " << value.y() << " " << value.z() << " "
                  << std.isValid() << " " << std.x() << " " << std.y() << " " << std.z() << ""
                  << offset.isValid() << " " << offset.x() << " " << offset.y() << " " << offset.z() <<
                     std::endl;
    }

private:
    std::string name;
    tm *ltm;
    Point3f value;
    Point3f std;
    int n;
    Point3f offset;
};

#endif // RESULT_H
