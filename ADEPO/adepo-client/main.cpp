#include <QApplication>
#include <QtGui>
#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>

#include "client.h"
#include "socket_server.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    Client client;
    SocketServer server(client);
    client.setServer(server);
    //system("mkdir Archive");
    client.show();
    return app.exec();
}
