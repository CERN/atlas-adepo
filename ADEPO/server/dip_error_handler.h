#ifndef DIP_ERROR_HANDLER
#define DIP_ERROR_HANDLER

#include <QDebug>

#include "Dip.h"

class DipErrorHandler:public DipPublicationErrorHandler {

    void handleException(DipPublication* publication, DipException& ex) {
        Q_UNUSED(publication)

        qWarning() << "DIP Error because " << ex.what();
    }

};

#endif // DIP_ERROR_HANDLER

