
#include <QtGlobal>

#include "Dip.h"

DipFactory* Dip::create(const char *name,const int loggingConfigWatchInterval) throw (DipInternalError) {
    Q_UNUSED(name);
    Q_UNUSED(loggingConfigWatchInterval);

    return NULL;
}

