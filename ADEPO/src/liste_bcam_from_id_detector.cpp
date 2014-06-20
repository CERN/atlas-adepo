#include "header/liste_bcam_from_id_detector.h"

std::vector<BCAM> liste_bcam_from_id_detector(bdd & base_donnees, int id_detector)
{
    //on cree un vecteur de BCAMs
    std::vector<BCAM> liste_bcam;

    for(unsigned int i=0; i<base_donnees.Get_liste_BCAM().size(); i++)
    {
        std::cout << Get_liste_BCAM().size() << std::endl;

        if(base_donnees.Get_liste_BCAM().at(i).Get_id_detector() == id_detector)
        {
            //enregistrement des donnees de la bcam
            std::string nom_bcam = base_donnees.Get_liste_BCAM().at(i).Get_nom_BCAM();
            int num_id_detector = base_donnees.Get_liste_BCAM().at(i).Get_id_detector();
            int num_port_driver = base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Driver();
            int num_port_mux = base_donnees.Get_liste_BCAM().at(i).Get_num_Port_Mux();
            int num_cheap = base_donnees.Get_liste_BCAM().at(i).Get_num_chip();
            std::string nom_objet_vise = base_donnees.Get_liste_BCAM().at(i).Get_objet_vise();

            //BCAM bcam_data(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_objet_vise);
            //liste_bcam.push_back(bcam_data);


            if(nom_objet_vise.length() == 32 ) //cas de 3 prismes + 1 bcam
            {
                std::string nom_prisme_1 = nom_objet_vise.substr(0,5);
                std::string nom_prisme_2 = nom_objet_vise.substr(6,5);
                std::string nom_prisme_3 = nom_objet_vise.substr(12,5);
                std::string nom_bcam_visee = nom_objet_vise.substr(18,nom_objet_vise.length());

                BCAM bcam_data_1(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_prisme_1.append("_").append(nom_prisme_2).append("_").append(nom_prisme_3));
                BCAM bcam_data_2(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_bcam_visee);
                //BCAM bcam_data_3(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_prisme_3);
                //BCAM bcam_data_4(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_bcam_visee);

                liste_bcam.push_back(bcam_data_1);
                liste_bcam.push_back(bcam_data_2);
                //liste_bcam.push_back(bcam_data_3);
                //liste_bcam.push_back(bcam_data_4);

            }
            else if(nom_objet_vise.length() == 26) //cas de 2 prismes + 1 bcam
            {
                std::string nom_prisme_1 = nom_objet_vise.substr(0,5);
                std::string nom_prisme_2 = nom_objet_vise.substr(6,5);
                std::string nom_bcam_visee = nom_objet_vise.substr(12,nom_objet_vise.length());

                BCAM bcam_data_1(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_prisme_1.append("_").append(nom_prisme_2));
                BCAM bcam_data_2(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_bcam_visee);
                //BCAM bcam_data_4(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_bcam_visee);

                liste_bcam.push_back(bcam_data_1);
                liste_bcam.push_back(bcam_data_2);
                //liste_bcam.push_back(bcam_data_4);


            }
            else if(nom_objet_vise.length() == 11) //cas de 2 prismes
            {
                std::string nom_prisme_1 = nom_objet_vise.substr(0,5);
                std::string nom_prisme_2 = nom_objet_vise.substr(6,nom_objet_vise.length());

                BCAM bcam_data_1(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_prisme_1.append("_").append(nom_prisme_2));
                //BCAM bcam_data_2(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_prisme_2);

                liste_bcam.push_back(bcam_data_1);
                //liste_bcam.push_back(bcam_data_2);
            }
            else //cas d'un prisme
            {
                BCAM bcam_data(nom_bcam, num_id_detector, num_port_driver, num_port_mux, num_cheap, nom_objet_vise);
                liste_bcam.push_back(bcam_data);
            }


        }
    }

    //affichage de la liste temporaire de BCAMs
    for(unsigned int i=0; i<liste_bcam.size(); i++)
    {
        //liste_bcam.at(i).Affiche();
    }

    return liste_bcam;

}

