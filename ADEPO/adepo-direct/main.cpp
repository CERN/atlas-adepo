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

    QCoreApplication::setApplicationName("ADEPO direct");

    Util::handleDebug(app);

    Client client;
    Server server(client);
    client.setServer(server);
    //system("mkdir Archive");
    client.show();

    server.updateAll();

    return app.exec();
}
