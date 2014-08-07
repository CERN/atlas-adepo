#ifndef READ_LWDAQ_OUTPUT_H
#define READ_LWDAQ_OUTPUT_H

#include <QFile>

#include <header/bdd.h>

int read_lwdaq_output(QFile& file, bdd & base_donnees);

#endif // READ_LWDAQ_OUTPUT_H
