#ifndef DIPSERVER_H
#define DIPSERVER_H

#include <QHash>
#include <QList>
#include <QString>

#include "Dip.h"
#include "DipData.h"
#include "log4cplus/configurator.h"

#include "dip_error_handler.h"
#include "results.h"
#include "setup.h"
#include "util.h"

#define m2mm 1000

class DipServer
{
public:
    DipServer()  {};
    ~DipServer() {};

    void connect() {
#ifndef __APPLE__
        // NOTE: does not seem to work... we still get an information message...
        QString log4cplusProperties = Util::workPath().append("log4cplus.properties");
        qDebug() << "Using " << log4cplusProperties;
        // NOTE: cannot seem to find this at link time in OSX
        log4cplus::PropertyConfigurator::doConfigure(log4cplusProperties.toStdString());
#endif

        rootName = "dip/ATLAS/BCAM/";
        QString dipServerName = "ATLAS-ADEPO";

        dip = Dip::create(dipServerName.toStdString().c_str());

        if (dip == NULL) {
            qDebug() << "Ignoring DIP";
        } else {
            qDebug() << "Started DIP with prefix '" << rootName << "'";
        }
    }

    void createPublishers(Setup& setup) {
        if (dip == NULL) return;

        QSet<QString> add = setup.getNames() - publications.keys().toSet();
        QSet<QString> remove = publications.keys().toSet() - setup.getNames();

        for (QSet<QString>::iterator i = remove.begin(); i != remove.end(); i++) {
            qDebug() << "DIP destroyed: " << *i;
            removePublishers(*i);
        }

        for (QSet<QString>::iterator i = add.begin(); i != add.end(); i++) {
            qDebug() << "DIP created: " << *i;
            addPublishers(*i);
        }
    }

    void sendResults(Results& results) {
        if (dip == NULL) return;

        qDebug() << "Updating DIP";

        foreach(const QString &name, publications.keys()) {
            DipPublication* pub = publications.value(name);

            Result result = results.getResult(name);

            DipData* d = data.value(name);

            Point3d p = result.getValue();
            d->insert((DipFloat)p.x()*m2mm, "X_COORDINATE");
            d->insert((DipFloat)p.y()*m2mm, "Y_COORDINATE");
            d->insert((DipFloat)p.z()*m2mm, "Z_COORDINATE");

            p = result.getStd();
            d->insert((DipFloat)p.x()*m2mm, "X_STD");
            d->insert((DipFloat)p.y()*m2mm, "Y_STD");
            d->insert((DipFloat)p.z()*m2mm, "Z_STD");

            d->insert((DipInt)0, "COMMENT");  // Not Used
            d->insert((DipBool)result.isVerified() > 1, "DATA_QUALITY");

            DipTimestamp time;
            pub->send(*d, time);
        }
    }

private:
    DipErrorHandler dipErrorHandler;
    DipFactory *dip;
    QString rootName;

    QHash<QString, DipPublication*> publications;
    QHash<QString, DipData*> data;

    void removePublishers(QString name) {
        DipPublication* pub = publications[name];
        if (pub != NULL) {
            dip->destroyDipPublication(pub);
        }
        publications.remove(name);
        data.remove(name);
    }

    void addPublishers(QString name) {
        QString dipName = name;
        dipName.replace('-','_');

        publications[name] = dip->createDipPublication((rootName+dipName).toStdString().c_str(), &dipErrorHandler);
        data[name] = dip->createDipData();
    }
};

#endif // DIPSERVER_H
