#include "adepo.h"
#include "bdd.h"
#include "bcam.h"
#include <QString>
#include <QStringList>

std::vector<BCAM> bdd::getBCAMs(int id_detector)
{
    //on cree un vecteur de BCAMs
    std::vector<BCAM> liste_bcam;

    for(unsigned int i=0; i<getBCAMs().size(); i++)
    {
        BCAM bcam = getBCAMs().at(i);
        if(bcam.getDetectorId() == id_detector)
        {

            int numChip = bcam.getNumChip();
            QString objects = QString::fromStdString(bcam.getPrisms());

            // split in case double bcam: objects contains '/'
            QStringList sides = objects.split('/');
            addList(bcam, numChip, sides[0], liste_bcam);

            if (sides.size() > 1) {
                numChip = numChip == 1 ? 2 : 1;
                addList(bcam, numChip, sides[1], liste_bcam);
            }
        }
    }

    //affichage de la liste temporaire de BCAMs
#ifdef ADEPO_DEBUG
    for(unsigned int i=0; i<liste_bcam.size(); i++)
    {
        liste_bcam.at(i).print();
    }
#endif

    return liste_bcam;
}

void bdd::addList(BCAM bcam, int numChip, QString side, std::vector<BCAM>& liste_bcam) {
    std::string bcamName = bcam.getName();
    int detectorId = bcam.getDetectorId();
    int driverSocket = bcam.getDriverSocket();
    int muxSocket = bcam.getMuxSocket();

    QStringList prismList = side.split('_');
    QString prisms("");
    QString bcamSource("");
    int i = 0;
    for(int j=0; j<prismList.size(); j++) {
        if (prismList[j].startsWith("PR")) {
            if (i>0) prisms.append("_");
            prisms.append(prismList[j]);
            i++;
        } else {
            bcamSource = prismList[j];
        }
    }
    if (prisms != "") {
        BCAM bcam(bcamName, detectorId, driverSocket, muxSocket, numChip, prisms.toStdString());
        liste_bcam.push_back(bcam);
    }
    if (bcamSource != "") {
        BCAM bcam(bcamName, detectorId, driverSocket, muxSocket, numChip, bcamSource.toStdString());
        liste_bcam.push_back(bcam);
    }
}

