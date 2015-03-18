#include "util.h"

#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QtGlobal>

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

void Util::handleDebug(QCoreApplication app) {
    if (!app.arguments().contains("-d")) {
        qInstallMessageHandler(noMessageOutput);
    }
}

void Util::noMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(type);
    Q_UNUSED(context);
    Q_UNUSED(msg);
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





