#ifndef UTIL_H
#define UTIL_H

#include <QtCore/QCoreApplication>
#include <QString>

class Util
{
public:
    Util() {};
    virtual ~Util() {};

    static void handleDebug(QCoreApplication app);
    static void noMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg);
    static QString appPath();
    static QString inputPath();
    static QString workPath();
    static QString getSourceDeviceElement(bool isPrism, bool flashSeparate, int deviceElement, bool first);
};

#endif // UTIL_H
