#ifndef CALIBRATION_H
#define CALIBRATION_H

#include <QList>

#include <QString>

#include "calib1.h"
#include "calib2.h"

#define CALIBRATION_FILE "BCAM_Parameters.txt"

class Calibration
{
public:
    Calibration() {};
    ~Calibration() {};

    int read(QString filename);
    QString getFilename() const { return filename; }
    QString check() const;

    QList<Calib1> getCalibs1() const {return mCalibs1;}
    QList<Calib2> getCalibs2() const {return mCalibs2;}

    void clear() {
        mCalibs1.clear();
        mCalibs2.clear();
    }

private:
    QString filename;

    void add(Calib1 val) { mCalibs1.push_back(val); }
    void add(Calib2 val) { mCalibs2.push_back(val);}

    QList<Calib1> mCalibs1;
    QList<Calib2> mCalibs2;

};

#endif // CALIBRATION_H
