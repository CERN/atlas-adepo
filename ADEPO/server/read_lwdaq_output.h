#ifndef READ_LWDAQ_OUTPUT_H
#define READ_LWDAQ_OUTPUT_H

#include <QFile>

#include <bdd.h>

int read_lwdaq_output(QFile& file, BDD & base_donnees);

#endif // READ_LWDAQ_OUTPUT_H
