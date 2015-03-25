#ifndef CLIENT_H
#define CLIENT_H

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

    void changedRun(QString filename);
    void changedConfiguration(QString filename);
    void changedCalibration(QString filename);
    void changedOffset(QString filename);
    void changedReference(QString filename);
    void changedOutput(QString filename);
    void changedResult(QString filename);
    void changedResults(std::map<QString, Result> results);

public slots:

signals:

private slots:
    void selectDetectorRow(int row, int column);
    void showBCAMimage(int row, int column);
    void changedAirpad(int index) { run.setAirpad(index == 1); ; call->updateRun(); }
    void changedAcquisitionTimeValue(int value) { run.setAcquisitionTime(value); ; call->updateRun(); }
    void changedWaitingTimeValue(int value) { run.setWaitingTime(value); call->updateRun(); }
    void changedFormat(int state) { run.setFullPrecisionFormat(state); ; call->updateRun(); updateResults(); }
    void resetDelta();
    void startClosure();
    void startMonitoring();
    void stop();

private:
    Call* call;

    Run run;
    Configuration config;
    Results offset;
    Results reference;
    Results output;

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
