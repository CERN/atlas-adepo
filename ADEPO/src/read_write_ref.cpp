#include "iostream"
#include "iomanip"
#include "ctime"
#include "sstream"
#include <fstream>
#include <QString>
#include <map>
#include <string>

#include "result.h"
#include "Point3f.h"

int write_ref(QString fileName, std::map<std::string, result> &results) {
    std::ofstream file(fileName.toStdString().c_str(), std::ios::out | std::ios::trunc);
    if(!file) {
        std::cout << "WARNING Cannot write reference file " << fileName.toStdString() << std::endl;
        return 0;
    }

    // setup default precision
    file<<std::fixed<<std::setprecision(8);

    for (std::map<std::string, result>::iterator i = results.begin(); i != results.end(); i++) {
        result& result = i->second;
        Point3f offset = result.getOffset();
        file << i->first << " " << offset.isValid() << " " << offset.x() << " " << offset.y() << " " << offset.z() << std::endl;
    }

    file.close();
    return 1;
}

int read_ref(QString fileName, std::map<std::string, result> &results) {
    std::ifstream file(fileName.toStdString().c_str(), std::ios::in);
    if(!file) {
        std::cout << "WARNING Cannot read reference file " << fileName.toStdString() << std::endl;
        return 0;
    }

    std::string line;

    while(std::getline(file,line)) {
        // take ending off the line
        line.erase(line.find_last_not_of(" \n\r\t")+1);

        if(!line.empty())
        {
            char *buffer = strdup((char*)line.c_str());
            std::string name = strtok(buffer, " " );
            char *valid = strtok( NULL, " " );
            char *x = strtok( NULL, " " );
            char *y = strtok( NULL, " " );
            char *z = strtok( NULL, " " );
            Point3f value(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));
            result r;
            r.setName(name);
            r.setValue(value);
            r.setOffset();
            results[name] = r;
        }
    }

    return 1;
}
