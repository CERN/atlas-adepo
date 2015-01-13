#ifndef SERVER_H
#define SERVER_H

#include <vector>
#include <string>
#include <fstream>

#include <QString>
#include <QFile>

#include "bcam.h"
#include "bdd.h"
#include "configuration.h"
#include "setup.h"

class Server
{
public:
    Server() {};
    virtual ~Server() {};

    std::string calculateCoordinates(QString resultFile);

    int write_script_file(Configuration& config, QString fileName, std::vector<BCAM> &bcams);

    int readLWDAQOutput(QFile& file, BDD & base_donnees, Setup &setup);

private:
    int writeSettingsFile(QString settings_file, QString script_file, QString result_file);
    int writeParamsFile(QString params_file);

    QString getDateTime();
    int write_bcam_script(std::ofstream &file, BCAM bcam, int spots, std::string sourceDeviceElement);

    Configuration config;
};

#endif // SERVER_H

