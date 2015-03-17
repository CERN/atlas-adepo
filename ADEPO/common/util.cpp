#include "util.h"

#include <QCoreApplication>
#include <QDir>

QString Util::getSourceDeviceElement(bool isPrism, bool flashSeparate, int deviceElement, bool first) {
    if (flashSeparate) {
        if (isPrism) {
            return deviceElement == 2 ? first ? "3" : "4" : first ? "1" : "2";
        } else {
            return deviceElement == 2 ? first ? "1" : "2" : first ? "3" : "4";
        }
    } else {
        if (isPrism) {
            return deviceElement == 2 ? "3 4" : "1 2";
        } else {
            return deviceElement == 2 ? "1 2" : "3 4";
        }
    }
}

QString Util::appPath() {
    QString appPath = QCoreApplication::instance()->applicationDirPath();
    if (appPath.endsWith("/Contents/MacOS")) {
        QDir dir(appPath + "/../../..");
        appPath = dir.absolutePath();
    }
    if (!appPath.endsWith("/")) {
        appPath += "/";
    }
    return appPath;
}

QString Util::inputPath() {
    QString inputPath = Util::appPath();
    QDir dir(inputPath + "../../ADEPO/input_folder");
    inputPath = dir.absolutePath();
    if (!inputPath.endsWith("/")) {
        inputPath += "/";
    }
    return inputPath;
}

QString Util::workPath() {
    QString workPath = Util::appPath();
    QDir dir(workPath + "../");
    workPath = dir.absolutePath();
    if (!workPath.endsWith("/")) {
        workPath += "/";
    }
    return workPath;
}





