#include <fstream>

#include <QDebug>

#include "iostream"
#include "iomanip"

#include "reference.h"

int Reference::write() {
    std::ofstream file(filename.toStdString().c_str(), std::ios::out | std::ios::trunc);
    if(!file) {
        qWarning() << "Cannot write reference file " << filename;
        return 0;
    }

    // setup default precision
    file << std::fixed << std::setprecision(8);

    for (std::map<QString, Result>::iterator i = results.begin(); i != results.end(); i++) {
        Result& result = i->second;
        Point3d value = result.getValue();
        Point3d std = result.getStd();

        QString datetime = result.getTime();

        file << std::left << std::setw(18) << i->first.toStdString() << " "
             << datetime.toStdString() << " "
             << std::right
             << std::setw(4) << result.getN() << " "
             << std::setw(14) << value.x() << " "
             << std::setw(14) << value.y() << " "
             << std::setw(14) << value.z() << " "
             << std::setw(2) << value.isValid() << " "
             << std::setw(14) << std.x() << " "
             << std::setw(14) << std.y() << " "
             << std::setw(14) << std.z() << " "
             << std::setw(2) << std.isValid()
             << std::endl;
    }

    file.close();

    return 1;
}

int Reference::read(QString filename) {

    std::ifstream file(filename.toStdString().c_str(), std::ios::in);
    if(!file) {
        qWarning() << "Cannot read reference file " << filename;
        return 0;
    }

    std::string line;

    while(getline(file,line)) {
        // take ending off the line
        line.erase(line.find_last_not_of(" \n\r\t")+1);

        char *x, *y, *z, *valid;
        if(!line.empty())
        {
            char *buffer = strdup((char*)line.c_str());
            QString name = QString::fromStdString(strtok(buffer, " " ));
            QString dateTime = QString::fromStdString(strtok( NULL, " " ));
            char *n = strtok( NULL, " " );
            // value
            x = strtok( NULL, " " );
            y = strtok( NULL, " " );
            z = strtok( NULL, " " );
            valid = strtok( NULL, " " );
            Point3d value(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));
            // std
            x = strtok( NULL, " " );
            y = strtok( NULL, " " );
            z = strtok( NULL, " " );
            valid = strtok( NULL, " " );
            Point3d std(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));
            // offset, ignored in future versions
//            x = strtok( NULL, " " );
//            y = strtok( NULL, " " );
//            z = strtok( NULL, " " );
//            valid = strtok( NULL, " " );
//            Point3d offset(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));

            // get it and put it back
            Result r = results[name];
            r.setTime(dateTime);
            r.setN(atoi(n));
            r.setValue(value);
            r.setStd(std);
            results[name] = r;
        }
    }

    this->filename = filename;

    return 1;
}

