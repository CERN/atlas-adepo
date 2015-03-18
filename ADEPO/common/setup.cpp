#include <stdexcept>

#include <QDebug>

#include "setup.h"
#include "bcam_config.h"

BCAM Setup::getBCAM(QString bcam_prism) {
    for(unsigned int i=0; i < mBCAMs.size(); i++) {
       if (bcam_prism == mBCAMs[i].getName() + "_" + mBCAMs[i].getPrism().getName()) {
           return mBCAMs[i];
       }
    }
    qWarning() << "BCAM with name " << bcam_prism << " not defined in current selection.";
    throw std::invalid_argument(bcam_prism.toStdString());
}

std::vector<BCAM> Setup::getBCAMs(int id_detector, Configuration& config)
{
    //on cree un vecteur de BCAMs
    std::vector<BCAM> liste_bcam;

    for(unsigned int i=0; i<config.getBCAMConfigs().size(); i++)
    {
        BCAMConfig bcamConfig = config.getBCAMConfigs().at(i);
        if(bcamConfig.getDetectorId() == id_detector)
        {
            std::vector<Prism> prisms = bcamConfig.getPrisms();
            for (unsigned int j=0; j<prisms.size(); j++) {
                BCAM bcam(bcamConfig.getName(), bcamConfig.getDetectorId(), bcamConfig.getDriverSocket(), bcamConfig.getMuxSocket(), prisms[j]);
                liste_bcam.push_back(bcam);
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


