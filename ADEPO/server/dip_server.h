#ifndef DIPSERVER_H
#define DIPSERVER_H

#include <QHash>
#include <QList>
#include <QString>

#include "Dip.h"
#include "log4cplus/configurator.h"

#include "dip_error_handler.h"
#include "results.h"
#include "setup.h"
#include "util.h"

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

        QList<QString> names = setup.getNames();
        for (int i=0; i<names.size(); i++) {
            QString dipName = names[i].replace('-','_');
            qDebug() << "DIP created: " << dipName;
            createPublishers(dipName);
        }
    }

    void sendResults(Results& results) {
        if (dip == NULL) return;

        qDebug() << "Updating DIP";

        DipTimestamp time;
        foreach(const QString &name, map.keys()) {
            const QList<DipPublication*>& list = map.value(name);

            Result result = results.getResult(name);

            Point3d p = result.getValue();
            qDebug() << p.x() << " " << name;
            list[0]->send((DipFloat)p.x(), time);
            list[1]->send((DipFloat)p.y(), time);
            list[2]->send((DipFloat)p.z(), time);

            p = result.getStd();
            list[3]->send((DipFloat)p.x(), time);
            list[4]->send((DipFloat)p.y(), time);
            list[5]->send((DipFloat)p.z(), time);

            list[6]->send((DipInt)0, time);  // Not Used
            list[7]->send((DipBool)result.isVerified() > 0, time);
        }
    }

private:
    DipErrorHandler dipErrorHandler;
    DipFactory *dip;
    QString rootName;

    QHash<QString, QList<DipPublication*> > map;

    void createPublishers(QString name) {
        QList<DipPublication*>& list = map[name];
        for (int i=0; i<list.size(); i++) {
            dip->destroyDipPublication(list[i]);
        }
        list.clear();

        // 8 items
        list.append(dip->createDipPublication((rootName+name+"/X_COORDINATE").toStdString().c_str(), &dipErrorHandler));
        list.append(dip->createDipPublication((rootName+name+"/Y_COORDINATE").toStdString().c_str(), &dipErrorHandler));
        list.append(dip->createDipPublication((rootName+name+"/Z_COORDINATE").toStdString().c_str(), &dipErrorHandler));

        list.append(dip->createDipPublication((rootName+name+"/X_STD").toStdString().c_str(), &dipErrorHandler));
        list.append(dip->createDipPublication((rootName+name+"/Y_STD").toStdString().c_str(), &dipErrorHandler));
        list.append(dip->createDipPublication((rootName+name+"/Z_STD").toStdString().c_str(), &dipErrorHandler));

        list.append(dip->createDipPublication((rootName+name+"/COMMENT").toStdString().c_str(), &dipErrorHandler));
        list.append(dip->createDipPublication((rootName+name+"/DATA_QUALITY").toStdString().c_str(), &dipErrorHandler));
    }
};

#endif // DIPSERVER_H
