#ifndef SERVER_H
#define SERVER_H

#include <vector>
#include <string>
#include <fstream>
#include <QString>

#include "configuration.h"
#include "bcam.h"

class Server
{
public:
    Server() {};
    virtual ~Server() {};

    int write_script_file(Configuration& config, QString fileName, std::vector<BCAM> &bcams);

private:
    int write_bcam_script(Configuration &configuration, std::ofstream &file, BCAM bcam, int spots, std::string sourceDeviceElement);
};

#endif // SERVER_H

