#include "adepo.h"
#include "bdd.h"
#include "bcam.h"
#include "bcam_config.h"

#include <QString>
#include <QStringList>

std::vector<BCAM> BDD::getBCAMs(int id_detector, Configuration& config)
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

