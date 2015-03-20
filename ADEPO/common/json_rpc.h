#ifndef JSONRPC_H
#define JSONRPC_H

#include <vector>

#include <QJsonObject>
#include <QJsonArray>
#include <QString>

class JsonRpc : public QJsonObject
{
public:
    JsonRpc(QString method) {
        insert("jsonrpc", "2.0");
        insert("method", method);
    }
    ~JsonRpc() {}

    void append(QString s) {
        params.append(s);
        insert("params", params);
    }

    void append(int i) {
        params.append(i);
        insert("params", params);
    }

    void append(bool b) {
        params.append(b);
        insert("params", params);
    }

    void append(QJsonArray a) {
        params.append(a);
        insert("params", params);
    }

    void append(QJsonObject o) {
        params.append(o);
        insert("params", params);
    }

private:
    QJsonArray params;
};

#endif // JSONRPC_H
