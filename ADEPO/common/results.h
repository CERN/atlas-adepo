#ifndef REFERENCE_H
#define REFERENCE_H

#include <map>

#include <QString>

#include "result.h"

#define OFFSET_FILE "offset_file.txt"
#define OUTPUT_FILE "output_file.txt"

class Reference
{
public:
    Reference() {};
    ~Reference() {};

    int write();
    int read(QString fileName);

    QString getFilename() const { return filename; }
    Result& getResult(QString prism) { return results[prism]; }
    void setResult(QString prism, Result& result) { results[prism] = result; }

private:
    QString filename;
    std::map<QString, Result> results;
};

#endif // REFERENCE_H
