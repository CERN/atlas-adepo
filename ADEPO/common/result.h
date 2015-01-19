#ifndef RESULT_H
#define RESULT_H

#include "ctime"
#include "point3f.h"

#include <QString>

class Result
{
public:
    Result() {
        dateTime = "1970.01.01.00.00.00";
        value = Point3f(false);
        std = Point3f(false);
        n = 0;
        setOffset(value);
    }
    ~Result() {};

    void setName(QString _name) {
        name = _name;
    }

    QString getName() {
        return name;
    }

    void setTime(QString _dateTime) {
        dateTime = _dateTime;
    }

    QString getTime() {
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
        std::cout << name.toStdString() << "  " << dateTime.toStdString() << " " << n << " "
                  << value.isValid() << " value(" << value.x() << " " << value.y() << " " << value.z() << ") "
                  << std.isValid() << " std(" << std.x() << " " << std.y() << " " << std.z() << ") "
                  << offset.isValid() << " offset(" << offset.x() << " " << offset.y() << " " << offset.z() << ")"
                  << std::endl;
    }

private:
    QString name;
    QString dateTime;
    Point3f value;
    Point3f std;
    int n;
    Point3f offset;
};

#endif // RESULT_H
