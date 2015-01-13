#ifndef ATLAS_BCAM_H
#define ATLAS_BCAM_H

#include <QMainWindow>
#include <QWidget>
#include <QTextBrowser>
#include <QLineEdit>
#include <QLabel>
#include <QTextEdit>

#include "bridge.h"
#include "calibration.h"
#include "result.h"
#include "setup.h"
#include "util.h"

namespace Ui {
class ATLAS_BCAM;
}

class ATLAS_BCAM : public QMainWindow
{
        Q_OBJECT

public:
    explicit ATLAS_BCAM(QWidget *parent = 0);
    ~ATLAS_BCAM();

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
    void openDialog();

private:
    Ui::ATLAS_BCAM *ui;
    QString path_fich;
    std::map<std::string, result> results;
    int selectedBCAM;
    std::string mode;

    QString refFile;
    QLabel lwdaqStatus;

    bool askQuestion;
    QTimer *waitingTimer;
    QTimer *updateTimer;

    //fonction qui remplie le tableau de detecteurs affiche dans l'interface
    void fillDetectorTable();
    void openInputDir();
    void setResult(int row, result& result);
    void setResult(int row, Point3f point, int columnSet, int precision);
    void calculateResults(Data& data, std::map<std::string, result> &results);
    void updateResults(std::map<std::string, result> &results);
    void setEnabled(bool enabled);
    void display(QLabel* label, QTextBrowser* textEdit, QString filename);
    void setMode(std::string mode);

    void updateStatusBar();
};

#endif // ATLAS_BCAM_H
