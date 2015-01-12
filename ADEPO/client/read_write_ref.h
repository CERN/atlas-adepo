#ifndef WRITE_REF_H
#define WRITE_REF_H

#include <map>
#include <string>
#include <QString>

#include "result.h"

int writeRef(QString fileName, std::map<std::string, result> &results);
int readRef(QString fileName, std::map<std::string, result> &results);

#endif // WRITE_REF_H
