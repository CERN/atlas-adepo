#ifndef SETUP_H
#define SETUP_H

#include <QList>
#include <QString>

#include "configuration.h"
#include "run.h"
#include "bcam.h"

class Setup
{
public:
    Setup() {};
    ~Setup() {};

    void init(Run &run, Configuration& config);
    BCAM getBCAM(QString bcam_prism);
    QList<BCAM> getBCAMs(int id_detector, Configuration& config);
    QList<BCAM> getBCAMs() {
        return bcams;
    }
    QList<QString> getNames() {
        return names;
    }

private:
    QList<BCAM> bcams;
    QList<QString> names;
};

#endif // SETUP_H
