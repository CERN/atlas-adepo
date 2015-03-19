#ifndef SERVER_H
#define SERVER_H

#include <vector>
#include <fstream>
#include <iomanip>

#include <QObject>
#include <QString>
#include <QFile>
#include <QTimer>

#include "bcam.h"
#include "calibration.h"
#include "configuration.h"
#include "data.h"
#include "reference.h"
#include "run.h"

#include "lwdaq_client.h"
#include "point3f.h"
#include "call.h"
#include "callback.h"

class Server : public QObject, public Call
{
    Q_OBJECT

public:
    Server(Callback& callback, QObject *parent = 0);
    ~Server() {};

    void startDAQ();
    void stopDAQ();
    void calculateCoordinates();
    int readLWDAQOutput(QString resultFile);

    // implementation of Call
    void start();
    void stop();

    void updateRunFile();
    void updateConfigurationFile();
    void updateCalibrationFile();
    void updateReferenceFile();

    void updateAll();

private slots:
    void lwdaqStateChanged();
    void timeChanged();
    void runDAQ();

private:
    Callback& callback;

    int writeSettingsFile(QString settings_file, QString scriptFile, QString resultFile);
    int writeParamsFile(QString params_file);
    int writeScriptFile(QString fileName);

    QString getDateTime();
    int writeBCAMScript(Configuration &config, std::ofstream &file, BCAM bcam, int spots, QString sourceDeviceElement);

    void imgCoordToBcamCoord(Calibration &calibration, Run &run, Data &data);
    void calculCoordBcamSystem(Configuration &config, Calibration &calibration, Run &run, Data& data);
    void mountPrismToGlobalPrism();
    int writeFileObsMountSystem(QString fileName, QString datetime);
    Point3f changeReference(Point3f coord_sys1, Point3f translation, Point3f rotation);

    void helmert(Configuration &config, Data& data);

    void updateState(bool timeChange = false);

    QTimer *waitingTimer;
    QTimer *updateTimer;

    QString adepoState;

    LWDAQ_Client *lwdaq_client;
    QString previousState;
    bool needToCalculateResults;

    Run run;
    Configuration config;
    Calibration calibration;
    Data data;
    Reference reference;
    QString resultFile;
};

#endif // SERVER_H

