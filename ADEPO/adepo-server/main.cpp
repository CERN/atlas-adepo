#include <QtCore/QCoreApplication>

#include "server.h"
#include "socket_server.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    SocketServer webSocketServer(5687);
    Server server(webSocketServer);
    webSocketServer.setServer(server);

//    QObject::connect(&webSocketServer, &SocketServer::closed, &app, &QCoreApplication::quit);

    return app.exec();
}
