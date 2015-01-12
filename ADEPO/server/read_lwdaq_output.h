#ifndef READ_LWDAQ_OUTPUT_H
#define READ_LWDAQ_OUTPUT_H

#include <QFile>

#include "bdd.h"
#include "setup.h"

int readLWDAQOutput(QFile& file, BDD & base_donnees, Setup &setup);

#endif // READ_LWDAQ_OUTPUT_H
