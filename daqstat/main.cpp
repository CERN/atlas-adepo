#include <QCoreApplication>

#include <iostream>

#include "client.h"


int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    std::cout << "Start" << std::endl;

    Client *client = new Client(&a);

    client->getStatus();

    return a.exec();
}
