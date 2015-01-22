#include "callback.h"

#include "client.h"
#include "ui_client.h"

void Client::setMode(QString mode) {
    setModeLabel(mode);
}

void Client::updateStatus(QString adepoStatus, int adepoSeconds, QString lwdaqStatus, int lwdaqSeconds) {
    updateStatusBar();
}
