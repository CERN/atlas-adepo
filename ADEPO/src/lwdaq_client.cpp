
#include <iostream>

#include "lwdaq_client.h"

LWDAQ_Client::LWDAQ_Client(QString host, quint16 port, QObject *parent) : QObject(parent),
                                  hostName(host),
                                  portNo(port),
                                  currentState(UNSET),
                                  cmdNo(0),
                                  redirect(true),
                                  error(false),
                                  errorText("") {

    tcpSocket = new QTcpSocket(this);

    connect(tcpSocket, SIGNAL(connected()), this, SLOT(gotConnected()));
    connect(tcpSocket, SIGNAL(disconnected()), this, SLOT(gotDisconnected()));
    connect(tcpSocket, SIGNAL(readyRead()), this, SLOT(readStatus()));
    connect(tcpSocket, SIGNAL(error(QAbstractSocket::SocketError)),
                this, SLOT(displayError(QAbstractSocket::SocketError)));

    connectTimer = new QTimer(this);
    connectTimer->setInterval(RECONNECT_TIME*1000);
    connectTimer->setSingleShot(true);
    connect(connectTimer, SIGNAL(timeout()), this, SLOT(init()));

    statusTimer = new QTimer(this);
    statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
    statusTimer->setSingleShot(true);
    connect(statusTimer, SIGNAL(timeout()), this, SLOT(updateStatus()));

    runTimer = new QTimer(this);
    runTimer->setInterval(DEFAULT_RUN_TIME*1000);
    runTimer->setSingleShot(true);
    connect(runTimer, SIGNAL(timeout()), this, SLOT(stopRun()));

    updateTimer = new QTimer(this);
    updateTimer->setInterval(DEFAULT_UPDATE_TIME*1000);
    updateTimer->setSingleShot(false);
    connect(updateTimer, SIGNAL(timeout()), this, SLOT(updateRemainingTime()));
}

QDir LWDAQ_Client::find(QDir dir) {
    QStringList list = dir.entryList(QStringList("LWDAQ"), QDir::Dirs);
    QString absPath = dir.absolutePath().append("/");
    if (list.size() == 1) {
        return QDir(absPath.append(list[0]));
    } else if (dir != QDir::root()) {
        return find(QDir(absPath.append("..")));
    } else {
        return QDir("fkdshkjfhdskjfh"); // non existing directory
    }
}

void LWDAQ_Client::init() {
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

    // redirect
    if (redirect) {
        cmd.append("set Acquisifier_config(upload_target) [lindex $server_info 0]");
        ret.append("<to be filled by LWDAQ_server_info command>");  // #2
        cmd.append("set Acquisifier_config(upload_step_result) 1");
        ret.append("1");
    }

    // setup acquisifier
    cmd.append("LWDAQ_run_tool Acquisifier.tcl");
    ret.append("1");

    // get initial status
    cmd.append("Acquisifier_status");
    ret.append("*");

    // try to connect
    tcpSocket->abort();
    tcpSocket->connectToHost(hostName, portNo);
}

bool LWDAQ_Client::startRun(QString dir, int seconds) {
    if (seconds < 0) {
        seconds = DEFAULT_RUN_TIME;
    }

    cmdNo = 0;
    cmd.clear();
    ret.clear();

    // setup run
    cmd.append("LWDAQ_run_tool "+dir+"/"+DEFAULT_PARAM_FILE);
    ret.append(DEFAULT_PARAM_FILE);
    cmd.append("LWDAQ_run_tool "+dir+"/"+DEFAULT_SETTINGS_FILE);
    ret.append(DEFAULT_SETTINGS_FILE);
    cmd.append("Acquisifier_load_script");
    ret.append("1");

    cmd.append("Acquisifier_command Repeat_Run\r");
    ret.append("1");

    cmd.append("Acquisifier_status");
    ret.append("*");

    // setup runtime
    runTimer->start(seconds*1000);

    // start a run
    command(cmdNo);
    cmdNo++;

    return true;
}

void LWDAQ_Client::stopRun() {
    if (currentState == RUN) {
        std::cout << "Stopping run..." << std::endl;

        write("Acquisifier_command Stop");
        write("Acquisifier_status");

        runTimer->stop();
    }
}

void LWDAQ_Client::updateStatus() {
    std::cout << "Updating status..." << std::endl;
    if (isConnected()) {
        write("Acquisifier_status");
    } else {
        std::cout << "Ending status update" << std::endl;
        statusTimer->stop();
        statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
    }
}


void LWDAQ_Client::gotConnected() {
    std::cout << "Connected to " << tcpSocket->peerAddress().toString().toStdString()
              << ":" << tcpSocket->peerPort() << std::endl;

    command(cmdNo);
    cmdNo++;
}

void LWDAQ_Client::gotDisconnected() {
    std::cout << "Disconnected" << std::endl;
    runTimer->stop();
    statusTimer->stop();
    statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
    stateChange(INIT);

    connectTimer->start();
}

void LWDAQ_Client::readStatus() {
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
        QString returnSocket = parts[0];
        cmd[1] = QString("set server_info ").append(returnSocket);
        ret[1] = returnSocket;
        if (redirect) {
            ret[2] = returnSocket;
        }
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
        write("Acquisifier_status");
        return;
    }

    // check status updates
    if (line.startsWith("Idle")) {
        stateChange(IDLE);
        statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
        statusTimer->start();
    } else if (line.startsWith("Run")) {
        stateChange(RUN);
        statusTimer->setInterval(FAST_UPDATE_TIME*1000);
        statusTimer->start();
    } else if (line.startsWith("Repeat_Run")) {
        stateChange(RUN);
        statusTimer->setInterval(FAST_UPDATE_TIME*1000);
        statusTimer->start();
    } else if (line.startsWith("Stop")) {
        stateChange(STOP);
        statusTimer->setInterval(FAST_UPDATE_TIME*1000);
        statusTimer->start();
    }

    // verify if the current command finished with expected return value
    bool retOk = (ret[cmdNo-1] == "*") || line.endsWith(ret[cmdNo-1]);

    // bail out if out of commands, set next state is done by LWDAQ
    if (retOk && (cmdNo >= cmd.length())) {
        return;
    }

    // send next command
    if (retOk) {
        command(cmdNo);
        cmdNo++;
    }
}

void LWDAQ_Client::displayError(QAbstractSocket::SocketError socketError) {
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

void LWDAQ_Client::stateChange(state newState) {
    if (currentState == newState) {
        return;
    }
    if (currentState == INIT && newState > INIT) {
        std::cout << "Starting update timer " << statusTimer->interval() << std::endl;
        statusTimer->start();
    }
    currentState = newState;
    stateChanged();
}

void LWDAQ_Client::updateRemainingTime() {
    remainingTimeChanged();
}

void LWDAQ_Client::command(int no) {
    std::cout << std::endl << "CMD" << no << ":" << cmd[no].toStdString() << std::endl;
    write(cmd[no]);
}

void LWDAQ_Client::write(QString c) {
    tcpSocket->write(c.append("\r").toLatin1());
}
