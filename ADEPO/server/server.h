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
    Server(Configuration& configuration) : config(configuration) {};
    virtual ~Server() {};

    int write_script_file(QString fileName, std::vector<BCAM> &bcams);

private:
    int write_bcam_script(std::ofstream &file, BCAM bcam, int spots, std::string sourceDeviceElement);
    std::string getSourceDeviceElement(bool isPrism, bool flashSeparate, int deviceElement, bool first);

    Configuration& config;
};

#endif // SERVER_H

