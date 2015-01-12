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

using namespace std;

int writeRef(QString fileName, map<string, result> &results) {
    ofstream file(fileName.toStdString().c_str(), ios::out | ios::trunc);
    if(!file) {
        cout << "WARNING Cannot write reference file " << fileName.toStdString() << endl;
        return 0;
    }

    // setup default precision
    file << fixed<< setprecision(8);

    for (map<string, result>::iterator i = results.begin(); i != results.end(); i++) {
        result& result = i->second;
        Point3f value = result.getValue();
        Point3f std = result.getStd();
        Point3f offset = result.getOffset();

        string datetime = result.getTime();

        file << left << setw(18) << i->first << " "
             << datetime << " "
             << right
             << setw(4) << result.getN() << " "
             << setw(14) << value.x() << " "
             << setw(14) << value.y() << " "
             << setw(14) << value.z() << " "
             << setw(2) << value.isValid() << " "
             << setw(14) << std.x() << " "
             << setw(14) << std.y() << " "
             << setw(14) << std.z() << " "
             << setw(2) << std.isValid() << " "
             << setw(14) << offset.x() << " "
             << setw(14) << offset.y() << " "
             << setw(14) << offset.z() << " "
             << setw(2) << offset.isValid()
             << endl;
    }

    file.close();
    return 1;
}

int readRef(QString fileName, map<string, result> &results) {
    ifstream file(fileName.toStdString().c_str(), ios::in);
    if(!file) {
        cout << "WARNING Cannot read reference file " << fileName.toStdString() << endl;
        return 0;
    }

    string line;

    while(getline(file,line)) {
        // take ending off the line
        line.erase(line.find_last_not_of(" \n\r\t")+1);

        char *x, *y, *z, *valid;
        if(!line.empty())
        {
            char *buffer = strdup((char*)line.c_str());
            string name = strtok(buffer, " " );
            string dateTime = strtok( NULL, " " );
            char *n = strtok( NULL, " " );
            // value
            x = strtok( NULL, " " );
            y = strtok( NULL, " " );
            z = strtok( NULL, " " );
            valid = strtok( NULL, " " );
            Point3f value(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));
            // std
            x = strtok( NULL, " " );
            y = strtok( NULL, " " );
            z = strtok( NULL, " " );
            valid = strtok( NULL, " " );
            Point3f std(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));
            // offset
            x = strtok( NULL, " " );
            y = strtok( NULL, " " );
            z = strtok( NULL, " " );
            valid = strtok( NULL, " " );
            Point3f offset(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));

            // get it and put it back
            result r = results[name];
            r.setName(name);
            r.setTime(dateTime);
            r.setN(atoi(n));
            r.setValue(value);
            r.setStd(std);
            r.setOffset(offset);
            results[name] = r;
        }
    }

    return 1;
}
