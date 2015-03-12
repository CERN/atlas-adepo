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

#include "call.h"
#include "callback.h"
#include "configuration.h"
#include "setup.h"
#include "run.h"

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

    void setMode(QString mode);
    void setSelectedDetectors(std::vector<int> detectors);
    void updateState(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds);
    void updateConfigurationFile(QString filename);
    void updateCalibrationFile(QString filename);
    void updateReferenceFile(QString filename);
    void updateResultFile(QString filename);

public slots:

signals:

private slots:
    void showBCAMTable();
    void showBCAM(int row, int);
    void changedAirpad(int index) { run.setAirpad(index == 1); }
    void changedAcquisitionTimeValue(int value) { run.setAcquisitionTime(value); }
    void changedWaitingTimeValue(int value) { run.setWaitingTime(value);}
    void changedFormat(int state) { run.setFullPrecisionFormat(state); updateResults(results); }
    void resetDelta();
    void startClosure();
    void startMonitoring();
    void stop();

private:
    Call* call;

    Configuration config;
    Setup setup;
    Run run;

    Ui::Client *ui;
    std::map<QString, Result> results;
    int selectedBCAM;

    std::vector<int> selectedDetectors;

    QString refFile;
    QLabel lwdaqStatus;

    QString adepoState;
    QString lwdaqState;

    bool askQuestion;

    //fonction qui remplie le tableau de detecteurs affiche dans l'interface
    void fillDetectorTable();
    void setResult(int row, Result& result);
    void setResult(int row, Point3f point, int columnSet, int precision);
    void updateResults(std::map<QString, Result> &results);
    void setEnabled();
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
    QString getMode();
};

#endif // CLIENT_H
