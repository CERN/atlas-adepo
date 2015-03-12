#ifndef RUN_H
#define RUN_H

#include "qstring.h"
#include "qjsondocument.h"
#include "qjsonobject.h"

#include "json_util.h"
#include "json_rpc.h"

#define RUN_INPUT_FOLDER "/../../ADEPO/input_folder/"
#define RUN_FILE "run_file.json"

#define AIRPAD "Airpad"
#define AIRPAD_DEFAULT false

#define FULL_PRECISION_FORMAT "FullPrecisionFormat"
#define FULL_PRECISION_FORMAT_DEFAULT false

#define ACQUISITION_TIME "AcquisitionTime"
#define ACQUISITION_TIME_DEFAULT 45

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

    std::vector<int> getDetectors() {
        return JsonUtil::fromIntArray(json[DETECTORS].toArray());
    }

    void setDetectors(std::vector<int> detectors) {
        json[DETECTORS] = JsonUtil::toIntArray(detectors);
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

    int getAcquisitionTime() {
        return json[ACQUISITION_TIME].isNull() ? ACQUISITION_TIME_DEFAULT : json[ACQUISITION_TIME].toInt();
    }

    void setAcquisitionTime(int value) {
        json[ACQUISITION_TIME] = value;
        write();
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
