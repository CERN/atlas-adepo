#include "adepo.h"
#include "mount_prism_to_global_prism.h"
#include "changement_repere.h"
#include "mount_coord_prism.h"
#include "global_coord_prism.h"

void mount_prism_to_global_prism(bdd & base_donnees)
{
    bool found = false;
    for(unsigned int i=0; i<base_donnees.getMountCoordPrisms().size(); i++)
    {
        mount_coord_prism prism = base_donnees.getMountCoordPrisms().at(i);

        for(unsigned int j=0; j<base_donnees.getBCAMParams().size(); j++)
        {
            BCAM_params params = base_donnees.getBCAMParams().at(j);

            if(prism.getBCAM() == params.getBCAM())
            {
                 Point3f point_transforme = changement_repere(prism.getCoordPrismMountSys(),
                                                              params.getTranslation(),
                                                              params.getRotation());
                 global_coord_prism pt_global(prism.getBCAM(), prism.getPrism(), point_transforme, prism.getAirpad());
                 base_donnees.add(pt_global);
                 found = true;
            }
        }
    }

    //affichage base de donnee des prismes dans le repere global
#ifdef ADEPO_DEBUG
    for(unsigned int k=0; k<base_donnees.getGlobalCoordPrisms().size(); k++)
    {
        base_donnees.getGlobalCoordPrisms().at(k).print();
    }
#endif

    if (!found) {
        std::cout << "WARNING: no mount_prism_to_global_prism found, some setup file may be missing..." << std::endl;
    }
}
