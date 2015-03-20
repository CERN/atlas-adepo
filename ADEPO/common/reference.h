#ifndef REFERENCE_H
#define REFERENCE_H

#include <map>

#include <QString>

#include "result.h"

#define REFERENCE_FILE "reference_file.txt"

class Reference
{
public:
    Reference() {};
    ~Reference() {};

    int write();
    int read(QString fileName);

    QString getFilename() const { return filename; }
    std::map<QString, Result>& getResults() { return results; }

private:
    QString filename;
    std::map<QString, Result> results;
};

#endif // REFERENCE_H
