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

int write_ref(QString fileName, map<string, result> &results) {
    ofstream file(fileName.toStdString().c_str(), ios::out | ios::trunc);
    if(!file) {
        cout << "WARNING Cannot write reference file " << fileName.toStdString() << endl;
        return 0;
    }

    // setup default precision
    file << fixed<< setprecision(8);

    for (map<string, result>::iterator i = results.begin(); i != results.end(); i++) {
        result& result = i->second;
        Point3f offset = result.getOffset();
        file << left << setw(14) << i->first
             << right << setw(2) << offset.isValid()
             << setw(12) << offset.x()
             << setw(12) << offset.y()
             << setw(12) << offset.z() << endl;
    }

    file.close();
    return 1;
}

int read_ref(QString fileName, map<string, result> &results) {
    ifstream file(fileName.toStdString().c_str(), ios::in);
    if(!file) {
        cout << "WARNING Cannot read reference file " << fileName.toStdString() << endl;
        return 0;
    }

    string line;

    while(getline(file,line)) {
        // take ending off the line
        line.erase(line.find_last_not_of(" \n\r\t")+1);

        if(!line.empty())
        {
            char *buffer = strdup((char*)line.c_str());
            string name = strtok(buffer, " " );
            char *valid = strtok( NULL, " " );
            char *x = strtok( NULL, " " );
            char *y = strtok( NULL, " " );
            char *z = strtok( NULL, " " );
            Point3f offset(!strncmp(valid, "1", 1), atof(x),atof(y),atof(z));

            // get it and put it back
            result r = results[name];
            r.setName(name);
            r.setOffset(offset);
            results[name] = r;
        }
    }

    return 1;
}
