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
        verified = 0;
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

    void setVerified(Qt::CheckState _verified) {
        verified = _verified;
    }

    int isVerified() {
        return verified;
    }

    void toString() {
        std::cout << dateTime.toStdString() << " " << n << " "
                  << value.isValid() << " value(" << value.x() << " " << value.y() << " " << value.z() << ") "
                  << std.isValid() << " std(" << std.x() << " " << std.y() << " " << std.z() << ") "
                  << verified
                  << std::endl;
    }

    void read(const QJsonObject &json) {
        dateTime = json["time"].toString();
        value.read(json["value"].toObject());
        std.read(json["std"].toObject());
        n = json["n"].toInt();
        verified = json["verified"].toInt();
    }

    void write(QJsonObject &json) const {
        json["time"] = dateTime;
        QJsonObject v;
        value.write(v);
        json["value"] = v;
        QJsonObject s;
        std.write(s);
        json["std"] = s;
        json["n"] = n;
        json["verified"] = verified;
    }

    QString dateTime;
    Point3d value;
    Point3d std;
    int n;
    int verified; // 0 unverified, 1 failed, 2 ok, same as CheckState
};

#endif // RESULT_H
