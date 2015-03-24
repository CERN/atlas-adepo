#ifndef CLIENT_H
#define CLIENT_H

#include <vector>

#include <QMainWindow>
#include <QWidget>
#include <QTextBrowser>
#include <QLineEdit>
#include <QLabel>
#include <QTextEdit>
#include <QString>
#include <QDebug>

#include "call.h"
#include "callback.h"
#include "configuration.h"
#include "run.h"
#include "results.h"

#include "result.h"
#include "util.h"

namespace Ui {
class Client;
}

class Client: public QMainWindow, public Callback
{
        Q_OBJECT

public:
    explicit Client(QWidget *parent = 0);
    ~Client();

    void setServer(Call& callImpl) { call = &callImpl; }

    void changedState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds);

    void changedRunFile(QString filename);
    void changedConfigurationFile(QString filename);
    void changedCalibrationFile(QString filename);
    void changedOffsetFile(QString filename);
    void changedOutputFile(QString filename);
    void changedResultFile(QString filename);
    void changedResults(std::map<QString, Result> results);

public slots:

signals:

private slots:
    void selectDetectorRow(int row, int column);
    void showBCAMimage(int row, int column);
    void changedAirpad(int index) { run.setAirpad(index == 1); ; call->updateRunFile(); }
    void changedAcquisitionTimeValue(int value) { run.setAcquisitionTime(value); ; call->updateRunFile(); }
    void changedWaitingTimeValue(int value) { run.setWaitingTime(value); call->updateRunFile(); }
    void changedFormat(int state) { run.setFullPrecisionFormat(state); ; call->updateRunFile(); updateResults(); }
    void resetDelta();
    void startClosure();
    void startMonitoring();
    void stop();

private:
    Call* call;

    Run run;
    Configuration config;
    Reference offset;
    Reference output;

    Ui::Client *ui;
    int selectedBCAM;

    QLabel adepoStatus;
    QLabel lwdaqStatus;

    QString adepoState;
    QString lwdaqState;

    bool askQuestion;

    void fillDetectorTable();
    void fillBCAMandResultTable();
    void setResult(int row, Result& result, Result &offset);
    void setResult(int row, Point3d point, int columnSet, int precision);
    void updateResults();
    void setEnabled();
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
};

#endif // CLIENT_H
