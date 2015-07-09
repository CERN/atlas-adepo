#include <iostream>

#include <QCoreApplication>
#include <QDir>
#include <QDebug>
#include <QtGlobal>

#include "util.h"

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

void Util::setApplicationInfo(QString name) {
    QCoreApplication::setOrganizationName("ATLAS CERN");
    QCoreApplication::setOrganizationDomain("atlas.cern.ch");
    QCoreApplication::setApplicationName(name);
    QCoreApplication::setApplicationVersion("1.4");
}

bool Util::debug;

void Util::handleDebug(QCoreApplication &app) {
    qInstallMessageHandler(messageHandler);
    debug = app.arguments().contains("-d");
}

void Util::messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    Q_UNUSED(context);

    switch (type) {
        case QtInfoMsg:
            if (debug) {
                std::cerr << "Info: " << msg.toStdString() << std::endl;
            }
            break;
        case QtDebugMsg:
            if (debug) {
                std::cerr << "Debug: " << msg.toStdString() << std::endl;
            }
            break;
        case QtWarningMsg:
            std::cerr << "Warning: " << msg.toStdString() << std::endl;
            break;
        case QtCriticalMsg:
            std::cerr << "Critical: " << msg.toStdString() << std::endl;
            abort();
            break;
        case QtFatalMsg:
            std::cerr << "Fatal: " << msg.toStdString() << std::endl;
            abort();
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





