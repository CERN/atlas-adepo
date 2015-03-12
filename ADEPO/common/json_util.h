#ifndef JSONUTIL_H
#define JSONUTIL_H

#include <vector>

#include <QJsonArray>

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
};

#endif // JSONUTIL_H

