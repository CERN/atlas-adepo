#include <QApplication>
#include <QtGui>
#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>

#include "client.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    QCoreApplication::setOrganizationName("ATLAS CERN");
    QCoreApplication::setOrganizationDomain("atlas.cern.ch");
    QCoreApplication::setApplicationName("ADEPO");
    QCoreApplication::setApplicationVersion("1.4");

    QString locale = QLocale::system().name().section('_', 0, 0);
    QTranslator translator;
    translator.load(QString("qt_") + locale, QLibraryInfo::location(QLibraryInfo::TranslationsPath));
    app.installTranslator(&translator);
    Client window;
    //system("mkdir Archive");
    window.show();
    return app.exec();
}
