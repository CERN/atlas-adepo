#ifndef CLIENT_H
#define CLIENT_H

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
    void updateStatus(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds);

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

#endif // CLIENT_H
