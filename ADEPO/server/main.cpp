#include <QtCore/QCoreApplication>

#include "server.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);
    Server *server = new Server();

//    QObject::connect(server, &Server::closed, &a, &QCoreApplication::quit);

    return app.exec();
}


