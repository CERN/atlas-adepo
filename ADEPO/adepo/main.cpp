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

    Client client;
    Server server(client);
    client.setServer(server);
    //system("mkdir Archive");
    client.show();

    server.update();

    return app.exec();
}
