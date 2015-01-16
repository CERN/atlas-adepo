#ifndef SETUP_H
#define SETUP_H

#include <vector>

#include <QString>

#include "configuration.h"
#include "bcam.h"

class Setup
{
public:
    Setup() {};
    virtual ~Setup() {};

    void clear() {
        mBCAMs.clear();
    }

    std::vector<BCAM> getBCAMs(int id_detector, Configuration& config);
    std::vector<BCAM>& getBCAMs() { return mBCAMs; }
    BCAM getBCAM(QString bcam_prism);

private:
    std::vector<BCAM> mBCAMs;
};

#endif // SETUP_H
