
#include "client.h"
#include <iostream>

Client::Client(QObject *parent) : QObject(parent),
                                  open(false),
                                  cmdNo(0),
                                  stopped(false),
                                  error(false),
                                  errorText("") {

    tcpSocket = new QTcpSocket(this);

    connect(tcpSocket, SIGNAL(connected()), this, SLOT(connected()));
    connect(tcpSocket, SIGNAL(disconnected()), this, SLOT(disconnected()));
    connect(tcpSocket, SIGNAL(readyRead()), this, SLOT(readStatus()));
    connect(tcpSocket, SIGNAL(error(QAbstractSocket::SocketError)),
                this, SLOT(displayError(QAbstractSocket::SocketError)));

    statusTimer = new QTimer(this);
    statusTimer->setSingleShot(true);
    connect(statusTimer, SIGNAL(timeout()), this, SLOT(updateStatus()));

    runTimer = new QTimer(this);
    runTimer->setSingleShot(true);
    connect(runTimer, SIGNAL(timeout()), this, SLOT(stopRun()));

}

void Client::connectToHost() {
    tcpSocket->abort();
    tcpSocket->connectToHost("localhost", 1090);

    cmd.clear();
    ret.clear();

    // redirect output to incoming socket (same line as input)
    cmd.append("LWDAQ_server_info");
    ret.append("ok");   // will be set receiving proper string 'sock12 1405586706 MacOS 8.1.7 8.5.8'
    cmd.append("<to be filled by LWDAQ_server_info command>");  // #1
    ret.append("<to be filled by LWDAQ_server_info command>");  // #1

    // setup acquisifier
    cmd.append("LWDAQ_run_tool Acquisifier.tcl");
    ret.append("1");

    // redirect
    cmd.append("set Acquisifier_config(upload_target) [lindex $server_info 0]");    // #3
    ret.append("<to be filled by LWDAQ_server_info command>");                      // #3
    cmd.append("set Acquisifier_config(upload_step_result) 1");
    ret.append("1");

    // start updating status
    statusTimer->start(5000);
}

void Client::runOnHost(int seconds) {
    cmd.clear();
    ret.clear();

    // setup run
    cmd.append("LWDAQ_run_tool Acquisifier_params.tcl");
    ret.append("Acquisifier_params.tcl");
    cmd.append("LWDAQ_run_tool Acquisifier_Settings.tcl");
    ret.append("Acquisifier_Settings.tcl");
    cmd.append("Acquisifier_load_script");
    ret.append("1");

    cmd.append("Acquisifier_command Repeat_Run\r");
    ret.append("1");

    // setup runtime
    runTimer->start(seconds*1000);
}

void Client::updateStatus() {
    std::cout << "Updating status..." << std::endl;
    if (open) {
        write("Acquisifier_status");

        statusTimer->start();
    } else {
        std::cout << "Ending status update" << std::endl;
    }
}

void Client::stopRun() {
    if (open) {
        std::cout << "Stopping run..." << std::endl;

        write("Acquisifier_command Stop");

        runTimer->stop();
    }
}

void Client::connected() {
    std::cout << "Connected to " << tcpSocket->peerAddress().toString().toStdString()
              << ":" << tcpSocket->peerPort() << std::endl;
    open = true;

    command(cmdNo);
    cmdNo++;
}

void Client::disconnected() {
    open = false;
    std::cout << "Disconnected" << std::endl;
}

void Client::readStatus() {
//    std::cout << "readyRead " << tcpSocket->bytesAvailable() << std::endl;
    if (!tcpSocket->canReadLine()) {
        std::cout << "Line incomplete..." << std::endl;
        return;
    }

    QByteArray buffer = tcpSocket->readLine();
    QString line = QString::fromLatin1(buffer);
    line.chop(2);
    QStringList parts = line.split(" ", QString::SkipEmptyParts);

    std::cout << "RET: " << line.toStdString() << " #" << parts.length() << std::endl;

    // get originating socket e.g. "sock12"
    if (parts.length() == 5 && parts[0].startsWith("sock")) {
        cmd[1] = QString("set server_info ").append(parts[0]);
        ret[1] = parts[0];
        ret[3] = parts[0];
        line = "ok";
    }

    // is there an error e.g. "ERROR:"
    if (parts.length() > 0 && parts[0].startsWith("ERROR:")) {
        error = true;
        errorText = line;
    } else {
        error = false;
        errorText = "";
    }

    // find out if returncode is error
    if (parts.length() == 1 && parts[0] == "0") {
        error = true;
        errorText = QString("Command FAILED: ").append(cmd[cmdNo-1]);
    }

    // bail out if error
    if (error) {
        std::cout << "ERR: " << errorText.toStdString() << std::endl;
        return;
    }

    // bail out if out of commands
    if (cmdNo >= cmd.length()) {
        return;
    }

    // send next command if the current command finished with expected return value
    if (line.endsWith(ret[cmdNo-1])) {
        command(cmdNo);
        cmdNo++;
    }
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

void Client::command(int no) {
    std::cout << "CMD" << no << ":" << cmd[no].toStdString() << std::endl;
    write(cmd[no]);
}

void Client::write(QString c) {
    tcpSocket->write(c.append("\r").toLatin1());
}
