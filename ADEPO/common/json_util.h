#ifndef JSONUTIL_H
#define JSONUTIL_H

#include <vector>
#include <map>

#include <QJsonArray>
#include <QJsonObject>
#include <QStringList>
#include <QString>

class JsonUtil {

public:
    static QJsonArray toIntArray(std::vector<int> v) {
        QJsonArray a;
        for (unsigned int i=0; i<v.size(); i++) {
            a.push_back(v[i]);
        }
        return a;
    }

    static std::vector<int> fromIntArray(QJsonArray a) {
        std::vector<int> v;
        for (int i=0; i< a.size(); i++) {
            v.push_back(a[i].toInt());
        }
        return v;
    }

    template<typename T>
    static QJsonObject toJsonObject(std::map<QString, T> m) {
        QJsonObject map;
        for (typename std::map<QString, T>::iterator it=m.begin(); it!=m.end(); ++it) {
            map[it->first] = it->second.toJson();
        }
        return map;
    }

    template<typename T>
    static std::map<QString, T> fromJsonObject(QJsonObject o, T t) {
        Q_UNUSED(t);

        std::map<QString, T> map;
        QStringList keys = o.keys();
        for (int i=0; i<keys.size(); i++) {
            QString key = keys[i];
            map[key] = T(o[key].toObject());
        }
        return map;
    }
};

#endif // JSONUTIL_H

