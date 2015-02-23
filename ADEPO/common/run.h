#ifndef RUN_H
#define RUN_H

#include "qstring.h"
#include "qjsondocument.h"
#include "qjsonobject.h"

#include "json_rpc.h"

#define RUN_INPUT_FOLDER "/../../ADEPO/input_folder/"
#define RUN_FILE "run_file.json"

#define AIRPAD "Airpad"
#define AIRPAD_DEFAULT false

#define FULL_PRECISION_FORMAT "FullPrecisionFormat"
#define FULL_PRECISION_FORMAT_DEFAULT false

#define SINGLE_SHOT_TIME "SingleShotTime"
#define SINGLE_SHOT_TIME_DEFAULT 45

#define MONITORING_TIME "MonitoringTime"
#define MONITORING_TIME_DEFAULT 45

#define WAITING_TIME "WaitingTime"
#define WAITING_TIME_DEFAULT 360

#define MODE "Mode"
#define DETECTORS "Detectors"

class Run
{
public:
    Run() {};
    virtual ~Run() {};

    void write();
    void read(QString fileName);

    QString getFileName() {
        return fileName;
    }

    void setMode(QString mode) {
        json[MODE] = mode;
        write();
    }

    void setDetectors(std::vector<int> detectors) {
        json[DETECTORS] = JsonRpc::toIntArray(detectors);
        write();
    }

    bool getAirpad() {
        return json[AIRPAD].isNull() ? AIRPAD_DEFAULT : json[AIRPAD].toBool();
    }

    void setAirpad(bool state) {
        json[AIRPAD] = state;
        write();
    }

    bool getFullPrecisionFormat() {
        return json[FULL_PRECISION_FORMAT].isNull() ? FULL_PRECISION_FORMAT_DEFAULT : json[FULL_PRECISION_FORMAT].toBool();
    }

    void setFullPrecisionFormat(bool state) {
        json[FULL_PRECISION_FORMAT] = state;
        write();
    }

    int getSingleShotTime() {
        return json[SINGLE_SHOT_TIME].isNull() ? SINGLE_SHOT_TIME_DEFAULT : json[SINGLE_SHOT_TIME].toInt();
    }

    void setSingleShotTime(int value) {
        json[SINGLE_SHOT_TIME] = value;
        write();
    }

    int getMonitoringTime() {
        return json[MONITORING_TIME].isNull() ? MONITORING_TIME_DEFAULT : json[MONITORING_TIME].toInt();
    }

    int getWaitingTime() {
        return json[WAITING_TIME].isNull() ? WAITING_TIME_DEFAULT : json[WAITING_TIME].toInt();
    }

    void setWaitingTime(int value) {
        json[WAITING_TIME] = value;
        write();
    }

private:
    QString fileName;
    QJsonObject json;
};

#endif // RUN_H
