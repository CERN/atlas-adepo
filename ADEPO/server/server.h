#ifndef SERVER_H
#define SERVER_H

#include <vector>
#include <fstream>
#include <iomanip>

#include <QString>
#include <QFile>
#include <QTimer>

#include "bcam.h"
#include "calibration.h"
#include "configuration.h"
#include "data.h"
#include "reference.h"

#include "lwdaq_client.h"
#include "point3f.h"
#include "setup.h"
#include "call.h"

class Server : public Call
{
public:
    Server();
    virtual ~Server() {};

    void startDAQ(QString runMode, int runTime, bool airpad);
    void stopDAQ();
    QString calculateCoordinates();
    int writeScriptFile(QString fileName, std::vector<BCAM> &bcams);
    int readLWDAQOutput();

    // implementation of Call
    void start();
    void stop();

private slots:
    void lwdaqStateChanged();
    void timeChanged();

private:
    int writeSettingsFile(QString settings_file);
    int writeParamsFile(QString params_file);

    QString getDateTime();
    int writeBCAMScript(Configuration &config, std::ofstream &file, BCAM bcam, int spots, QString sourceDeviceElement);

    void imgCoordToBcamCoord(Calibration &calibration, Setup &setup, Data &data);
    void calculCoordBcamSystem(Configuration &config, Calibration &calibration, Setup &setup, Data& data);
    void mountPrismToGlobalPrism();
    int writeFileObsMountSystem(QString fileName, QString datetime);
    Point3f changeReference(Point3f coord_sys1, Point3f translation, Point3f rotation);

    void helmert(Configuration &config, Data& data);

    QTimer *waitingTimer;
    QTimer *updateTimer;

    QString adepoState;
    QString runMode;
    bool useAirpads;

    QString resultFile;
    QString scriptFile;

    LWDAQ_Client *lwdaq_client;
    QString previousState;
    bool needToCalculateResults;

    Configuration config;
    Calibration calibration;
    Setup setup;
    Data data;
    Reference reference;
};

#endif // SERVER_H

