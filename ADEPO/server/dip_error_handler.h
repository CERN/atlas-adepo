#ifndef DIP_ERROR_HANDLER
#define DIP_ERROR_HANDLER

#ifdef USE_DIP

#include <QDebug>

#include "Dip.h"

class DipErrorHandler:public DipPublicationErrorHandler {

    void handleException(DipPublication* publication, DipException& ex) {
        Q_UNUSED(publication)
        qDebug() << "Error DIP Information";
printf("Error because %s", ex.what());
        qWarning() << "DIP Error because " << ex.what();
    }

};

#endif // USE_DIP

#endif // DIP_ERROR_HANDLER

