#ifndef RESULT_H
#define RESULT_H

#include "ctime"
#include "point3f.h"

class result
{
public:
    result() {
        dateTime = "1970.01.01.00.00.00";
        value = Point3f(false);
        std = Point3f(false);
        n = 0;
        setOffset(value);
    }
    ~result() {};

    void setName(std::string _name) {
        name = _name;
    }

    std::string getName() {
        return name;
    }

    void setTime(std::string _dateTime) {
        dateTime = _dateTime;
    }

    std::string getTime() {
        return dateTime;
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
            setOffset(value);
        }
    }

    Point3f getValue() {
        return value;
    }

    void setOffset(Point3f _offset) {
        offset = _offset;
    }

    Point3f getOffset() {
        return offset;
    }

    void toString() {
        std::cout << name << "  " << dateTime << " " << n << " "
                  << value.isValid() << " value(" << value.x() << " " << value.y() << " " << value.z() << ") "
                  << std.isValid() << " std(" << std.x() << " " << std.y() << " " << std.z() << ") "
                  << offset.isValid() << " offset(" << offset.x() << " " << offset.y() << " " << offset.z() << ")"
                  << std::endl;
    }

private:
    std::string name;
    std::string dateTime;
    Point3f value;
    Point3f std;
    int n;
    Point3f offset;
};

#endif // RESULT_H
