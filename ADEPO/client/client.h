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
    void updateState(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds);
    void updateConfigurationFile(QString filename);
    void updateCalibrationFile(QString filename);
    void updateReferenceFile(QString filename);
    void updateResultFile(QString filename);

public slots:

signals:

private slots:
    void showBCAMTable();
    void showBCAM(int row, int);
    void changedAirpad(int index);
    void changedTimeValue(int value);
    void changedWaitingTimeValue(int value);
    void changedFormat(int state);
    void resetDelta();
    void startClosure();
    void startMonitoring();
    void stopAcquisition();
    void stopRepeatAcquisition();

private:
    Call* call;

    Configuration config;
    Setup setup;

    Ui::Client *ui;
    std::map<QString, Result> results;
    int selectedBCAM;

    std::vector<int> selectedDetectors;

    QString refFile;
    QLabel lwdaqStatus;

    bool lwdaqCanStart;

    bool askQuestion;

    //fonction qui remplie le tableau de detecteurs affiche dans l'interface
    void fillDetectorTable();
    void setResult(int row, Result& result);
    void setResult(int row, Point3f point, int columnSet, int precision);
    void updateResults(std::map<QString, Result> &results);
    void setEnabled(bool enabled);
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
    QString getMode();

    void updateStatusBar(QString adepoState, int adepoSeconds, QString lwdaqState, int lwdaqSeconds);
};

#endif // CLIENT_H
