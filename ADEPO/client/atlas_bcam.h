#ifndef ATLAS_BCAM_H
#define ATLAS_BCAM_H

#include <QMainWindow>
#include <QWidget>
#include <QTextBrowser>
#include <QLineEdit>
#include <QLabel>
#include <QTextEdit>
#include <QString>

#include "callback.h"
#include "configuration.h"
#include "setup.h"

#include "server.h"

#include "result.h"
#include "util.h"

namespace Ui {
class ATLAS_BCAM;
}

class ATLAS_BCAM : public QMainWindow, Callback
{
        Q_OBJECT

public:
    explicit ATLAS_BCAM(QWidget *parent = 0);
    ~ATLAS_BCAM();

    void setMode(QString mode);
    void updateAdepoStatus(QString status, int seconds);
    void updateLwdaqStatus(QString status, int seconds);

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
    // tbr
    Server server;

    Configuration config;
    Setup setup;

    Ui::ATLAS_BCAM *ui;
//    QString path_fich;
    std::map<QString, Result> results;
    int selectedBCAM;
    QString mode;

    QString refFile;
    QLabel lwdaqStatus;

    bool askQuestion;

    QString lwdaqState;
    int lwdaqRemainingSeconds;
    QString adepoState;
    int adepoRemainingSeconds;

    //fonction qui remplie le tableau de detecteurs affiche dans l'interface
    void fillDetectorTable();
    void setResult(int row, Result& result);
    void setResult(int row, Point3f point, int columnSet, int precision);
    void updateResults(std::map<QString, Result> &results);
    void setEnabled(bool enabled);
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
    void setModeLabel(QString mode);

    void updateStatusBar();
};

#endif // ATLAS_BCAM_H
