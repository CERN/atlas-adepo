#include <QCoreApplication>

#include <iostream>
#include <QtNetwork>

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    std::cout << "Start" << std::endl;

    QTcpSocket* tcpSocket = new QTcpSocket();

    connect(tcpSocket, SIGNAL(readyRead()), this, SLOT(readFortune()));

    s.connectToHost("localhost",1090);

    return a.exec();
}
