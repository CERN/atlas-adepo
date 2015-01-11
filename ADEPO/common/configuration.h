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

    void add(Detector val) { mDetectors.push_back(val);}
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

    void add(BCAMAdapter val) {mBCAMAdapters.push_back(val);}
    std::vector<BCAMAdapter> getBCAMAdapters() const {return mBCAMAdapters;}

    void add(BCAMConfig val) { mBCAMConfigs.push_back(val); }
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

    void add(AbsoluteDistances val) {mAbsoluteDistances.push_back(val);}
    std::vector<AbsoluteDistances> getAbsoluteDistances() const {return mAbsoluteDistances;}

    void add(PrismCorrection val) {mPrismCorrections.push_back(val);}
    std::vector<PrismCorrection> getPrismCorrections() const {return mPrismCorrections;}

    void add(ATLASCoordinates val) {mATLASCoordinates.push_back(val);}
    std::vector<ATLASCoordinates> getATLASCoordinates() const {return mATLASCoordinates;}

    void addName(std::string id, std::string name) { names[id] = name; }
    std::string getName(std::string id) { return names.at(id); }

    void setDriverIpAddress(std::string val) {mDriverIpAddress = val;}
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
