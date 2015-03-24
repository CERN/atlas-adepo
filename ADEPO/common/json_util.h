#ifndef JSONUTIL_H
#define JSONUTIL_H

#include <QList>
#include <QHash>

#include <QJsonArray>
#include <QJsonObject>
#include <QStringList>
#include <QString>

class JsonUtil {

public:
    static QJsonArray toIntArray(QList<int> v) {
        QJsonArray a;
        for (int i=0; i<v.size(); i++) {
            a.push_back(v[i]);
        }
        return a;
    }

    static QList<int> fromIntArray(QJsonArray a) {
        QList<int> v;
        for (int i=0; i< a.size(); i++) {
            v.push_back(a[i].toInt());
        }
        return v;
    }
};

#endif // JSONUTIL_H

