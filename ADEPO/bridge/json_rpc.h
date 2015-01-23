#ifndef JSONRPC_H
#define JSONRPC_H

#include <QJsonObject>
#include <QJsonArray>
#include <QString>

class JsonRpc : public QJsonObject
{
public:
    JsonRpc(QString method) {
        value("jsonrpc") = "2.0";
        value("method") = method;
        value("params") = params;
    }
    ~JsonRpc() {}

    void append(QString s) {
        params.append(s);
    }

    void append(int i) {
        params.append(i);
    }

    void append(bool b) {
        params.append(b);
    }

    void append(QJsonArray a) {
        params.append(a);
    }

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

private:
    QJsonArray params;
};

#endif // JSONRPC_H
