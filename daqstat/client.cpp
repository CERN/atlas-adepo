
#include "client.h"
#include <iostream>

Client::Client(QString host, quint16 port, QObject *parent) : QObject(parent),
                                  hostName(host),
                                  portNo(port),
                                  currentState(INIT),
                                  cmdNo(0),
                                  error(false),
                                  errorText("") {

    tcpSocket = new QTcpSocket(this);

    connect(tcpSocket, SIGNAL(connected()), this, SLOT(gotConnected()));
    connect(tcpSocket, SIGNAL(disconnected()), this, SLOT(gotDisconnected()));
    connect(tcpSocket, SIGNAL(readyRead()), this, SLOT(readStatus()));
    connect(tcpSocket, SIGNAL(error(QAbstractSocket::SocketError)),
                this, SLOT(displayError(QAbstractSocket::SocketError)));

    connectTimer = new QTimer(this);
    connectTimer->setInterval(15000);
    connectTimer->setSingleShot(true);
    connect(connectTimer, SIGNAL(timeout()), this, SLOT(connectToHost()));

    statusTimer = new QTimer(this);
    statusTimer->setInterval(20000);
    statusTimer->setSingleShot(false);
    connect(statusTimer, SIGNAL(timeout()), this, SLOT(updateStatus()));

    runTimer = new QTimer(this);
    runTimer->setInterval(30000);
    runTimer->setSingleShot(true);
    connect(runTimer, SIGNAL(timeout()), this, SLOT(stopRun()));
}

void Client::connectToHost() {
    stateChange(INIT);

    std::cout << "Connecting to " << hostName.toStdString() << ":" << portNo << std::endl;

    cmdNo = 0;
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

    // try to connect
    tcpSocket->abort();
    tcpSocket->connectToHost(hostName, portNo);
}

bool Client::startRun(int seconds) {
    cmdNo = 0;
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

    // start a run
    command(cmdNo);
    cmdNo++;

    return true;
}

void Client::stopRun() {
    if (currentState == RUNNING) {
        std::cout << "Stopping run..." << std::endl;

        write("Acquisifier_command Stop");

        runTimer->stop();

        stateChange(READY);
    }
}

void Client::updateStatus() {
    std::cout << "Updating status..." << std::endl;
    if (isConnected()) {
        write("Acquisifier_status");
    } else {
        std::cout << "Ending status update" << std::endl;
        statusTimer->stop();
    }
}


void Client::gotConnected() {
    std::cout << "Connected to " << tcpSocket->peerAddress().toString().toStdString()
              << ":" << tcpSocket->peerPort() << std::endl;

    command(cmdNo);
    cmdNo++;
}

void Client::gotDisconnected() {
    std::cout << "Disconnected" << std::endl;
    runTimer->stop();
    statusTimer->stop();
    stateChange(INIT);

    connectTimer->start();
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
        stateChange(currentState == INIT ? READY : (cmd[cmdNo-1].contains("Repeat_Run")) ? RUNNING : READY);
        return;
    }

    // send next command if the current command finished with expected return value
    if (line.endsWith(ret[cmdNo-1])) {
        // start status timer if last command was "LWDAQ_run_tool..."
        if (cmd[cmdNo-1] == "LWDAQ_run_tool Acquisifier.tcl") {
            statusTimer->start();
        }

        command(cmdNo);
        cmdNo++;
    }
}

void Client::displayError(QAbstractSocket::SocketError socketError) {
    switch (socketError) {
    case QAbstractSocket::RemoteHostClosedError:
        std::cerr << "Remote host closed connection, reconnect in " << connectTimer->interval() << " ms." << std::endl;
        connectTimer->start();
        break;
    case QAbstractSocket::HostNotFoundError:
        std::cerr << "Host not found" << std::endl;
        break;
    case QAbstractSocket::ConnectionRefusedError:
        std::cerr << "Connection refused, reconnect in " << connectTimer->interval() << " ms." << std::endl;
        connectTimer->start();
        break;
    default:
        std::cerr << "The following error occurred: " << tcpSocket->errorString().toStdString() << std::endl;
    }
}

void Client::stateChange(state newState) {
    if (currentState == newState) {
        return;
    }
    currentState = newState;
    stateChanged();
}

void Client::command(int no) {
    std::cout << "CMD" << no << ":" << cmd[no].toStdString() << std::endl;
    write(cmd[no]);
}

void Client::write(QString c) {
    tcpSocket->write(c.append("\r").toLatin1());
}
