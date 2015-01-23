#ifndef REFERENCE_H
#define REFERENCE_H

#include <map>

#include <QString>

#include "result.h"

#define REFERENCE_INPUT_FOLDER "/../../ADEPO/input_folder/"
#define REFERENCE_FILE "reference_file.txt"

class Reference
{
public:
    Reference() {};
    ~Reference() {};

    int write(QString fileName);
    int read(QString fileName);

private:
    std::map<QString, Result> results;
};

#endif // REFERENCE_H
