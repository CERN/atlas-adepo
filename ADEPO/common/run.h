#ifndef RUN_H
#define RUN_H

#include <QString>
#include <QJsonDocument>
#include <QJsonObject>
#include <QList>

#include "json_util.h"
#include "json_rpc.h"

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
#define MODE_CLOSURE "Closure"
#define MODE_MONITORING "Monitoring"
#define MODE_DEFAULT MODE_CLOSURE

#define DETECTORS "Detectors"

class Run
{
public:
    Run() {};
    virtual ~Run() {};

    void write();
    void read(QString fileName);

    QString getFileName() const {
        return fileName;
    }

    void setFileName(QString fileName) {
        this->fileName = fileName;
    }

    QString getMode() const {
        return data[MODE].isNull() ? MODE_DEFAULT : data[MODE].toString();
    }

    void setMode(QString mode) {
        data[MODE] = mode;
    }

    QList<int> getDetectors() const {
        return JsonUtil::fromIntArray(data[DETECTORS].toArray());
    }

    void setDetectors(QList<int> detectors) {
        data[DETECTORS] = JsonUtil::toIntArray(detectors);
    }

    bool getAirpad() const {
        return data[AIRPAD].isNull() ? AIRPAD_DEFAULT : data[AIRPAD].toBool();
    }

    void setAirpad(bool state) {
        data[AIRPAD] = state;
    }

    bool getFullPrecisionFormat() const {
        return data[FULL_PRECISION_FORMAT].isNull() ? FULL_PRECISION_FORMAT_DEFAULT : data[FULL_PRECISION_FORMAT].toBool();
    }

    void setFullPrecisionFormat(bool state) {
        data[FULL_PRECISION_FORMAT] = state;
    }

    int getAcquisitionTime() const {
        return data[ACQUISITION_TIME].isNull() ? ACQUISITION_TIME_DEFAULT : data[ACQUISITION_TIME].toInt();
    }

    void setAcquisitionTime(int value) {
        data[ACQUISITION_TIME] = value;
    }

    int getWaitingTime() const {
        return data[WAITING_TIME].isNull() ? WAITING_TIME_DEFAULT : data[WAITING_TIME].toInt();
    }

    void setWaitingTime(int value) {
        data[WAITING_TIME] = value;
    }

    void read(const QJsonObject &json) {
        fileName = json["fileName"].toString();
        data = json["data"].toObject();
    }

    void write(QJsonObject &json) const {
        json["fileName"] = fileName;
        json["data"] = data;
    }

private:
    QString fileName;
    QJsonObject data;
};

#endif // RUN_H
