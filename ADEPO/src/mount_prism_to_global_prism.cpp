#include "adepo.h"
#include "mount_prism_to_global_prism.h"
#include "changement_repere.h"
#include "mount_coord_prism.h"

void mount_prism_to_global_prism(bdd & base_donnees)
{
    bool found = false;
    for(unsigned int i=0; i<base_donnees.Get_liste_mount_coord_prism().size(); i++)
    {
        mount_coord_prism prism = base_donnees.Get_liste_mount_coord_prism().at(i);

        for(unsigned int j=0; j<base_donnees.Get_liste_BCAM_params().size(); j++)
        {
            BCAM_params params = base_donnees.Get_liste_BCAM_params().at(j);

            if(prism.getId().substr(0,14) == params.getId())
            {
                 Point3f point_transforme = changement_repere(prism.getCoordPrismMountSys(),
                                                              params.getTranslation(),
                                                              params.getRotation());
                 mount_coord_prism pt_global(prism.getId(), point_transforme, prism.getAirpad());
                 base_donnees.Add_global_coord_prism(pt_global);
                 found = true;
            }
        }
    }

    //affichage base de donnee des prismes dans le repere global
#ifdef ADEPO_DEBUG
    for(unsigned int k=0; k<base_donnees.Get_liste_global_coord_prism().size(); k++)
    {
        base_donnees.Get_liste_global_coord_prism().at(k).print();
    }
#endif

    if (!found) {
        std::cout << "WARNING: no mount_prism_to_global_prism found, some setup file may be missing..." << std::endl;
    }
}
