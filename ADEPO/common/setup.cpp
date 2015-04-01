#include <QDebug>

#include "setup.h"

void Setup::init(Run &run, Configuration &config) {
    bcams.clear();

    QList<int> detectors = run.getDetectors();
    for(int i=0; i<detectors.size(); i++)
    {
        QList<BCAM> b = getBCAMs(detectors[i], config);

        for (int j=0; j<b.size(); j++) {
            bcams.push_back(b.at(j));
        }
    }

    names.clear();
    for (int i=0; i<bcams.size(); i++) {
        names.insert(config.getName(bcams[i].getPrism().getName()));
    }
}

BCAM Setup::getBCAM(QString bcam_prism) {
    for(int i=0; i < bcams.size(); i++) {
       if (bcam_prism == bcams[i].getName() + "_" + bcams[i].getPrism().getName()) {
           return bcams[i];
       }
    }
    qWarning() << "BCAM with name " << bcam_prism << " not defined in current selection.";
    throw std::invalid_argument(bcam_prism.toStdString());
}

QList<BCAM> Setup::getBCAMs(int id_detector, Configuration& config) {
    //on cree un vecteur de BCAMs
    QList<BCAM> liste_bcam;

    for(int i=0; i<config.getBCAMConfigs().size(); i++)
    {
        BCAMConfig bcamConfig = config.getBCAMConfigs().at(i);
        if(bcamConfig.getDetectorId() == id_detector)
        {
            QList<Prism> prisms = bcamConfig.getPrisms();
            for (int j=0; j<prisms.size(); j++) {
                BCAM bcam(bcamConfig.getName(), bcamConfig.getDetectorId(), bcamConfig.getDriverSocket(), bcamConfig.getMuxSocket(), prisms[j]);
                liste_bcam.push_back(bcam);
            }
        }
    }

    //affichage de la liste temporaire de BCAMs
#ifdef ADEPO_DEBUG
    for(int i=0; i<liste_bcam.size(); i++)
    {
        liste_bcam.at(i).print();
    }
#endif

    return liste_bcam;
}

