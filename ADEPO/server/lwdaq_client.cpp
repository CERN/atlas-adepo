
#include <iostream>

#include "lwdaq_client.h"

LWDAQ_Client::LWDAQ_Client(QString host, quint16 port, QObject *parent) : QObject(parent),
                                  hostName(host),
                                  portNo(port),
                                  currentState(LWDAQ_UNKNOWN),
                                  cmdNo(0),
                                  redirect(true),
                                  error(false),
                                  errorText("") {

    tcpSocket = new QTcpSocket(this);

    connect(tcpSocket, &QTcpSocket::connected, this, &LWDAQ_Client::gotConnected);
    connect(tcpSocket, &QTcpSocket::disconnected, this, &LWDAQ_Client::gotDisconnected);
    connect(tcpSocket, &QTcpSocket::readyRead, this, &LWDAQ_Client::readStatus);
    connect(tcpSocket, SIGNAL(error(QAbstractSocket::SocketError)),
                this, SLOT(displayError(QAbstractSocket::SocketError)));

    connectTimer = new QTimer(this);
    connectTimer->setInterval(RECONNECT_TIME*1000);
    connectTimer->setSingleShot(true);
    connect(connectTimer, &QTimer::timeout, this, &LWDAQ_Client::init);

    statusTimer = new QTimer(this);
    statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
    statusTimer->setSingleShot(true);
    connect(statusTimer, &QTimer::timeout, this, &LWDAQ_Client::updateStatus);

    runTimer = new QTimer(this);
    runTimer->setInterval(DEFAULT_RUN_TIME*1000);
    runTimer->setSingleShot(true);
    connect(runTimer, &QTimer::timeout, this, &LWDAQ_Client::stopRun);

    updateTimer = new QTimer(this);
    updateTimer->setInterval(DEFAULT_UPDATE_TIME*1000);
    updateTimer->setSingleShot(false);
    connect(updateTimer, &QTimer::timeout, this, &LWDAQ_Client::updateRemainingTime);
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
    stateChange(LWDAQ_CONNECTING);

    qDebug() << "LWDAQ Connecting to " << hostName << ":" << portNo;

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

bool LWDAQ_Client::startRun(QString workDir, int seconds) {
    if (seconds < 0) {
        seconds = DEFAULT_RUN_TIME;
    }

    cmdNo = 0;
    cmd.clear();
    ret.clear();

    // setup run
    cmd.append("LWDAQ_run_tool "+workDir+DEFAULT_PARAM_FILE);
    ret.append(DEFAULT_PARAM_FILE);
    cmd.append("LWDAQ_run_tool "+workDir+DEFAULT_SETTINGS_FILE);
    ret.append(DEFAULT_SETTINGS_FILE);
    cmd.append("Acquisifier_load_script");
    ret.append("1");

    cmd.append("Acquisifier_command Repeat_Run\r");
    ret.append("1");

    cmd.append("Acquisifier_status");
    ret.append("*");

    // setup runtime
    runTimer->start(seconds*1000);
    updateTimer->start();

    // start a run
    command(cmdNo);
    cmdNo++;

    return true;
}

void LWDAQ_Client::stopRun() {
    if (currentState == LWDAQ_RUN) {
        qDebug() << "LWDAQ Stopping run...";

        runTimer->stop();
        updateTimer->stop();

        cmdNo = 0;
        cmd.clear();
        ret.clear();

        cmd.append("Acquisifier_command Stop");
        ret.append("1");

        cmd.append("Acquisifier_status");
        ret.append("*");

        command(cmdNo);
        cmdNo++;
    }
}

void LWDAQ_Client::updateStatus() {
    qDebug() << "LWDAQ Updating status...";
    if (isConnected()) {
        write("Acquisifier_status");
    } else {
        qDebug() << "Ending status update";
        statusTimer->stop();
        statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
    }
}


void LWDAQ_Client::gotConnected() {
    qDebug() << "Connected to " << tcpSocket->peerAddress() << ":" << tcpSocket->peerPort();

    command(cmdNo);
    cmdNo++;
}

void LWDAQ_Client::gotDisconnected() {
    qDebug() << "Disconnected";
    runTimer->stop();
    updateTimer->stop();
    statusTimer->stop();
    statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
    stateChange(LWDAQ_CONNECTING);

    connectTimer->start();
}

void LWDAQ_Client::readStatus() {
//    qDebug() << "readyRead " << tcpSocket->bytesAvailable();
    if (!tcpSocket->canReadLine()) {
        std::cout << "Line incomplete..." << std::endl;
        return;
    }

    char buf[8192];
    qint64 lineLength = tcpSocket->readLine(buf, sizeof(buf));
    if (lineLength < 0) {
        std::cout << "Could not read line" << std::endl;
        return;
    }
    QString line(buf);

//    QByteArray buffer = tcpSocket->readLine();
//    QString line = QString::fromLatin1(buffer);

    line.chop(2);
    QStringList parts = line.split(" ", QString::SkipEmptyParts);

    qDebug() << "RET: " << line << " #" << parts.length();

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
        qWarning() << "ERR: " << errorText;
        write("Acquisifier_status");
        return;
    }

    // check status updates
    if (line.startsWith("Idle")) {
        stateChange(LWDAQ_IDLE);
        statusTimer->setInterval(SLOW_UPDATE_TIME*1000);
        statusTimer->stop();
    } else if (line.startsWith("Run")) {
        stateChange(LWDAQ_RUN);
        statusTimer->setInterval(FAST_UPDATE_TIME*1000);
        statusTimer->stop();
    } else if (line.startsWith("Repeat_Run")) {
        stateChange(LWDAQ_RUN);
        statusTimer->setInterval(FAST_UPDATE_TIME*1000);
        statusTimer->stop();
    } else if (line.startsWith("Stop")) {
        stateChange(LWDAQ_STOP);
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
        qWarning() << "Remote host closed connection, reconnect in " << connectTimer->interval() << " ms.";
        connectTimer->start();
        break;
    case QAbstractSocket::HostNotFoundError:
        qWarning() << "Host not found";
        break;
    case QAbstractSocket::ConnectionRefusedError:
        qWarning() << "Connection refused, reconnect in " << connectTimer->interval() << " ms.";
        connectTimer->start();
        break;
    default:
        qWarning() << "The following error occurred: " << tcpSocket->errorString();
    }
}

void LWDAQ_Client::stateChange(QString newState) {
    if (currentState == newState) {
        return;
    }
    if (currentState == LWDAQ_CONNECTING && (newState != LWDAQ_UNKNOWN || newState != LWDAQ_CONNECTING)) {
//        qDebug() << "Starting update timer " << statusTimer->interval();
    //    statusTimer->start();
    }
    currentState = newState;
    stateChanged();
}

void LWDAQ_Client::updateRemainingTime() {
    remainingTimeChanged();
}

void LWDAQ_Client::command(int no) {
    qDebug() << "";
    qDebug() << "CMD" << no << ":" << cmd[no];
    write(cmd[no]);
}

void LWDAQ_Client::write(QString c) {
    tcpSocket->write(c.append("\r").toLatin1());
}
