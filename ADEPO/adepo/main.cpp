#include <QApplication>
#include <QtGui>
#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>

#include "client.h"
#include "server.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

//    QString locale = QLocale::system().name().section('_', 0, 0);
//    QTranslator translator;
//    translator.load(QString("qt_") + locale, QLibraryInfo::location(QLibraryInfo::TranslationsPath));
//    app.installTranslator(&translator);

    Server server;
    Client window(server);
    //system("mkdir Archive");
    window.show();
    return app.exec();
}
