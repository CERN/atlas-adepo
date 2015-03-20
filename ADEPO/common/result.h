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
        name = "";
        dateTime = "1970.01.01.00.00.00";
        value = Point3d(false);
        std = Point3d(false);
        n = 0;
        setOffset(value);
    }
    Result(QJsonObject json) {
        name = json["name"].toString();
        dateTime = json["time"].toString();
        value = Point3d(json["value"].toObject());
        std = Point3d(json["std"].toObject());
        n = json["n"].toInt();
        offset = Point3d(json["offset"].toObject());
    }

    ~Result() {};

    void setName(QString _name) {
        name = _name;
    }

    QString getName() const {
        return name;
    }

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
        if (value.isValid() && !offset.isValid()) {
            setOffset(value);
        }
    }

    Point3d getValue() const {
        return value;
    }

    void setOffset(Point3d _offset) {
        offset = _offset;
    }

    Point3d getOffset() const {
        return offset;
    }

    void toString() {
        std::cout << name.toStdString() << "  " << dateTime.toStdString() << " " << n << " "
                  << value.isValid() << " value(" << value.x() << " " << value.y() << " " << value.z() << ") "
                  << std.isValid() << " std(" << std.x() << " " << std.y() << " " << std.z() << ") "
                  << offset.isValid() << " offset(" << offset.x() << " " << offset.y() << " " << offset.z() << ")"
                  << std::endl;
    }

    QJsonObject toJson() {
        QJsonObject json;
        json["name"] = name;
        json["time"] = dateTime;
        json["value"] = value.toJson();
        json["std"] = std.toJson();
        json["n"] = n;
        json["offset"] = offset.toJson();

        return json;
    }

private:
    QString name;
    QString dateTime;
    Point3d value;
    Point3d std;
    int n;
    Point3d offset;
};

#endif // RESULT_H
