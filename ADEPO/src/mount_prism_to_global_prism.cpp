#include "adepo.h"
#include "mount_prism_to_global_prism.h"
#include "changement_repere.h"

void mount_prism_to_global_prism(bdd & base_donnees)
{
    bool found = false;
    for(unsigned int i=0; i<base_donnees.Get_liste_mount_coord_prism().size(); i++)
    {
        for(unsigned int j=0; j<base_donnees.Get_liste_BCAM_params().size(); j++)
        {
            if(base_donnees.Get_liste_mount_coord_prism().at(i).getId().substr(0,14) == base_donnees.Get_liste_BCAM_params().at(j).getId())
            {
                 Point3f point_transforme = changement_repere(base_donnees.Get_liste_mount_coord_prism().at(i).getCoordPrismMountSys(),
                                                              base_donnees.Get_liste_BCAM_params().at(j).getTranslation(),
                                                              base_donnees.Get_liste_BCAM_params().at(j).getRotation());
                 mount_coord_prism pt_global(base_donnees.Get_liste_mount_coord_prism().at(i).getId(), point_transforme, base_donnees.Get_liste_mount_coord_prism().at(i).getAirpad());
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
