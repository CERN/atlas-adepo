
#include "client.h"
#include <iostream>

Client::Client(QObject *parent) : QObject(parent) {

    tcpSocket = new QTcpSocket(this);

    connect(tcpSocket, SIGNAL(connected()), this, SLOT(connected()));
    connect(tcpSocket, SIGNAL(disconnected()), this, SLOT(disconnected()));
    connect(tcpSocket, SIGNAL(readyRead()), this, SLOT(readStatus()));
    connect(tcpSocket, SIGNAL(error(QAbstractSocket::SocketError)),
                this, SLOT(displayError(QAbstractSocket::SocketError)));
}

void Client::getStatus() {
    tcpSocket->abort();
    tcpSocket->connectToHost("localhost", 1090);

    tcpSocket->write("LWDAQ_run_tool Acquisifier_params.tcl\r");
    tcpSocket->write("LWDAQ_run_tool Acquisifier_Settings.tcl\r");
    tcpSocket->write("Acquisifier_load_script\r");
    tcpSocket->write("Acquisifier_status\r");

    tcpSocket->write("LWDAQ_server_info\r");
    tcpSocket->write("set server_info sock13\r");
    tcpSocket->write("set Acquisifier_config(upload_target) [lindex $server_info 0]\r");
    tcpSocket->write("set Acquisifier_config(upload_step_result) 1\r");

    tcpSocket->write("Acquisifier_command Run\r");
}

void Client::connected() {
    std::cout << "Connected" << std::endl;
}

void Client::disconnected() {
    std::cout << "Disconnected" << std::endl;
}

bool first = true;

void Client::readStatus() {
    std::cout << "readyRead " << tcpSocket->bytesAvailable() << std::endl;
    QByteArray a = tcpSocket->readAll();
    std::cout << a.data();
//    QDataStream in(tcpSocket);
//    in.setVersion(QDataStream::Qt_4_0);

//    if (blockSize == 0) {
//        if (tcpSocket->bytesAvailable() < (int)sizeof(quint16))
 //           return;

 //       in >> blockSize;
 //   }

//    if (tcpSocket->bytesAvailable() < blockSize)
//        return;

//    QString line;
//    in >> line;

//    std::cout << line.toStdString() << std::endl;
}

void Client::displayError(QAbstractSocket::SocketError socketError) {
    switch (socketError) {
    case QAbstractSocket::RemoteHostClosedError:
        break;
    case QAbstractSocket::HostNotFoundError:
        std::cerr << "Host not found" << std::endl;
        break;
    case QAbstractSocket::ConnectionRefusedError:
        std::cerr << "Connection refused" << std::endl;
        break;
    default:
        std::cerr << "The following error occurred: " << tcpSocket->errorString().toStdString() << std::endl;
    }
}
