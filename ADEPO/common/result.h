#ifndef RESULT_H
#define RESULT_H

#include "ctime"
#include "point3d.h"

#include <QString>
#include <QJsonObject>

class Result
{
public:
    Result() {
        dateTime = "1970.01.01.00.00.00";
        value = Point3d(false);
        std = Point3d(false);
        n = 0;
    }
    Result(QJsonObject json) {
        dateTime = json["time"].toString();
        value = Point3d(json["value"].toObject());
        std = Point3d(json["std"].toObject());
        n = json["n"].toInt();
    }

    ~Result() {};

    void setTime(QString _dateTime) {
        dateTime = _dateTime;
    }

    QString getTime() const {
        return dateTime;
    }

    void setN(int _n) {
        n = _n;
    }

    int getN() const {
        return n;
    }

    void setStd(Point3d _std) {
        std = _std;
    }

    Point3d getStd() const {
        return std;
    }

    void setValue(Point3d _value) {
        value = _value;
    }

    Point3d getValue() const {
        return value;
    }

    void toString() {
        std::cout << dateTime.toStdString() << " " << n << " "
                  << value.isValid() << " value(" << value.x() << " " << value.y() << " " << value.z() << ") "
                  << std.isValid() << " std(" << std.x() << " " << std.y() << " " << std.z() << ") "
                  << std::endl;
    }

    QJsonObject toJson() {
        QJsonObject json;
        json["time"] = dateTime;
        json["value"] = value.toJson();
        json["std"] = std.toJson();
        json["n"] = n;

        return json;
    }

private:
    QString dateTime;
    Point3d value;
    Point3d std;
    int n;
};

#endif // RESULT_H
