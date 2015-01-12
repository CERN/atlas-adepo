#ifndef CONFIGURATION_H
#define CONFIGURATION_H

#include "detector.h"
#include "bcam_adapter.h"
#include "bcam_config.h"
#include "absolute_distances.h"
#include "atlas_coordinates.h"
#include "prism_correction.h"

#include <vector>
#include <map>
#include <stdexcept>

class Configuration
{
public:
    Configuration() {};
    virtual ~Configuration() {};

    int read(std::string filename);
    std::string check();

    std::vector<Detector> getDetectors() const {return mDetectors;}
    Detector getDetector(std::string bcamName) {
        BCAMConfig bcam = getBCAMConfig(bcamName);
        for(unsigned int j=0; j < mDetectors.size(); j++) {
            if (bcam.getDetectorId() == mDetectors[j].getId()) {
                return mDetectors[j];
            }
        }
        std::cout << "WARNING detector with id " << bcam.getDetectorId() << " not defined in configuration." << std::endl;
        throw std::invalid_argument(bcamName);
    }

    std::vector<BCAMAdapter> getBCAMAdapters() const {return mBCAMAdapters;}

    std::vector<BCAMConfig> getBCAMConfigs() const {return mBCAMConfigs;}
    BCAMConfig getBCAMConfig(std::string name) {
        for(unsigned int i=0; i < mBCAMConfigs.size(); i++) {
            if (name == mBCAMConfigs[i].getName()) {
                return mBCAMConfigs[i];
            }
        }
        std::cout << "WARNING BCAMConfig with name " << name << " not defined in configuration." << std::endl;
        throw std::invalid_argument(name);
    }

    std::vector<AbsoluteDistances> getAbsoluteDistances() const {return mAbsoluteDistances;}

    std::vector<PrismCorrection> getPrismCorrections() const {return mPrismCorrections;}

    std::vector<ATLASCoordinates> getATLASCoordinates() const {return mATLASCoordinates;}

    std::string getName(std::string id) { return names.at(id); }

    std::string getDriverIpAddress() const {return mDriverIpAddress;}

    void clear() {
        mBCAMConfigs.clear();
        mDetectors.clear();
        mDriverIpAddress.clear();
        mBCAMAdapters.clear();
        mAbsoluteDistances.clear();
        mATLASCoordinates.clear();
    }

private:
    void add(Detector val) { mDetectors.push_back(val);}
    void add(BCAMAdapter val) {mBCAMAdapters.push_back(val);}
    void add(BCAMConfig val) { mBCAMConfigs.push_back(val); }
    void add(AbsoluteDistances val) {mAbsoluteDistances.push_back(val);}
    void add(PrismCorrection val) {mPrismCorrections.push_back(val);}
    void add(ATLASCoordinates val) {mATLASCoordinates.push_back(val);}
    void addName(std::string id, std::string name) { names[id] = name; }
    void setDriverIpAddress(std::string val) {mDriverIpAddress = val;}

    std::vector<Detector> mDetectors;
    std::vector<BCAMAdapter> mBCAMAdapters;
    std::string mDriverIpAddress;
    std::vector<BCAMConfig> mBCAMConfigs;
    std::vector<AbsoluteDistances> mAbsoluteDistances;
    std::vector<PrismCorrection> mPrismCorrections;
    std::vector<ATLASCoordinates> mATLASCoordinates;
    std::map<std::string, std::string> names;
};

#endif // CONFIGURATION_H
