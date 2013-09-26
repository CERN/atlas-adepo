#include "header/liste_bcam_from_id_detector.h"

std::vector<BCAM> liste_bcam_from_id_detector(bdd & base_donnees, int id_detector)
{
    //on cree un vecteur de BCAMs
    std::vector<BCAM> liste_bcam;


    for(int i=0; i<base_donnees.Get_liste_BCAM().size(); i++)
    {
        if(base_donnees.Get_liste_BCAM().at(i).Get_id_detector() == id_detector)
        {
            //enregistrement des donnees de la bcam
            std::string nom_bcam = base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM();
            int num_id_detector = base_donnees.Get_liste_BCAM().at(i).Get_id_detector();
            int num_port_driver = base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Driver();
            int num_port_mux = base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux();
            int num_cheap = base_donnees.Get_liste_BCAM().at(i).Get_num_chip();
            std::string nom_objet_vise = base_donnees.Get_liste_BCAM().at(i).Get_objet_vise();
            std::string type_bcam = base_donnees.Get_liste_BCAM().at(i).Get_type_bool_BCAM();

            if(nom_objet_vise.length() > 20 )
            {
                std::string nom_prisme1 = nom_objet_vise.substr(0,8);
                std::string nom_prisme2 = nom_objet_vise.substr(9,17-9);
                std::string nom_bcam_visee = nom_objet_vise.substr(18,nom_objet_vise.length());

                BCAM data1(nom_bcam, num_id_detector, num_port_driver, num_port_mux, type_bcam, num_cheap, nom_prisme1);
                BCAM data2(nom_bcam, num_id_detector, num_port_driver, num_port_mux, type_bcam, num_cheap, nom_prisme2);
                BCAM data3(nom_bcam, num_id_detector, num_port_driver, num_port_mux, type_bcam, num_cheap, nom_bcam_visee);
                liste_bcam.push_back(data1);
                liste_bcam.push_back(data2);
                liste_bcam.push_back(data3);
            }
            else
            {
                BCAM data(nom_bcam, num_id_detector, num_port_driver, num_port_mux, type_bcam, num_cheap, nom_objet_vise);
                liste_bcam.push_back(data);
            }


        }
    }

    return liste_bcam;

}
