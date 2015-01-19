#include <QtCore/QCoreApplication>

#include "server.h"
#include "socket_client.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    SocketClient client;
    Server server(client);
    client.setServer(server);

//    QObject::connect(server, &Server::closed, &a, &QCoreApplication::quit);

    return app.exec();
}
