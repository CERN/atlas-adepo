#ifndef JSONRPC_H
#define JSONRPC_H

#include <QJsonObject>
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

private:
    QJsonArray params;
};

#endif // JSONRPC_H
