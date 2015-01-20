#include <QApplication>
#include <QtGui>
#include <QApplication>
#include <QTranslator>
#include <QLocale>
#include <QLibraryInfo>
#include <QUrl>
#include <QString>

#include "client.h"
#include "socket_client.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);

    Client client;
    SocketClient webSocketClient(client, QStringLiteral("ws://localhost:5687"));
    client.setServer(webSocketClient);
    //system("mkdir Archive");
    client.show();
    return app.exec();
}
