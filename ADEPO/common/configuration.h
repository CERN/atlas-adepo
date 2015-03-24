#ifndef CONFIGURATION_H
#define CONFIGURATION_H

#include <QList>
#include <QHash>

#include "detector.h"
#include "bcam_adapter.h"
#include "bcam_config.h"
#include "absolute_distances.h"
#include "atlas_coordinates.h"
#include "prism_correction.h"

#include <stdexcept>

#define CONFIGURATION_FILE "configuration_file.txt"

class Configuration
{
public:
    Configuration() {};
    virtual ~Configuration() {};

    int read(QString filename);
    QString getFilename() const { return filename; }
    QString check() const;

    QList<Detector> getDetectors() const {return mDetectors;}
    Detector getDetector(QString bcamName) {
        BCAMConfig bcam = getBCAMConfig(bcamName);
        for(int j=0; j < mDetectors.size(); j++) {
            if (bcam.getDetectorId() == mDetectors[j].getId()) {
                return mDetectors[j];
            }
        }
        std::cout << "WARNING detector with id " << bcam.getDetectorId() << " not defined in configuration." << std::endl;
        throw std::invalid_argument(bcamName.toStdString());
    }

    QList<BCAMAdapter> getBCAMAdapters() const {return mBCAMAdapters;}

    QList<BCAMConfig> getBCAMConfigs() const {return mBCAMConfigs;}
    BCAMConfig getBCAMConfig(QString name) {
        for(int i=0; i < mBCAMConfigs.size(); i++) {
            if (name == mBCAMConfigs[i].getName()) {
                return mBCAMConfigs[i];
            }
        }
        std::cout << "WARNING BCAMConfig with name " << name.toStdString() << " not defined in configuration." << std::endl;
        throw std::invalid_argument(name.toStdString());
    }

    QList<AbsoluteDistances> getAbsoluteDistances() const {return mAbsoluteDistances;}

    QList<PrismCorrection> getPrismCorrections() const {return mPrismCorrections;}

    QList<ATLASCoordinates> getATLASCoordinates() const {return mATLASCoordinates;}

    QString getName(QString id) { return names[id]; }
    QString getDriverIpAddress() const {return mDriverIpAddress;}

    void clear() {
        mDetectors.clear();
        mBCAMConfigs.clear();
        mBCAMAdapters.clear();
        mAbsoluteDistances.clear();
        mPrismCorrections.clear();
        mATLASCoordinates.clear();
        names.clear();
        mDriverIpAddress.clear();
    }

private:
    void add(Detector val) { mDetectors.push_back(val);}
    void add(BCAMAdapter val) {mBCAMAdapters.push_back(val);}
    void add(BCAMConfig val) { mBCAMConfigs.push_back(val); }
    void add(AbsoluteDistances val) {mAbsoluteDistances.push_back(val);}
    void add(PrismCorrection val) {mPrismCorrections.push_back(val);}
    void add(ATLASCoordinates val) {mATLASCoordinates.push_back(val);}
    void addName(QString id, QString name) { names[id] = name; }
    void setDriverIpAddress(QString val) {mDriverIpAddress = val;}

    QString filename;
    QList<Detector> mDetectors;
    QList<BCAMAdapter> mBCAMAdapters;
    QString mDriverIpAddress;
    QList<BCAMConfig> mBCAMConfigs;
    QList<AbsoluteDistances> mAbsoluteDistances;
    QList<PrismCorrection> mPrismCorrections;
    QList<ATLASCoordinates> mATLASCoordinates;
    QHash<QString, QString> names;
};

#endif // CONFIGURATION_H
