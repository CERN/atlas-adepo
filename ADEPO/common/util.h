#ifndef UTIL_H
#define UTIL_H

#include <QString>

class Util
{
public:
    Util() {};
    virtual ~Util() {};

    static QString appPath();
    static QString inputPath();
    static QString outputPath();
    static QString getSourceDeviceElement(bool isPrism, bool flashSeparate, int deviceElement, bool first);
};

#endif // UTIL_H
