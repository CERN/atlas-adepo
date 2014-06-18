#include "header/bdd.h"

bdd::bdd()
{
    //ctor
}

bdd::~bdd()
{
    //dtor
}
bdd::bdd(const bdd& /* copie */)
{

}

void bdd::vidage()
{
    m_liste_spots.clear();
    m_liste_mount_coord_spots.clear();
    m_liste_mount_coord_prism.clear();
    m_liste_global_coord_prism.clear();
}

void bdd::vidage_complet()
{
    m_liste_BCAM.clear();
    m_liste_detector.clear();
    m_liste_calib1.clear();
    m_liste_calib1_clean.clear();
    m_liste_calib2.clear();
    m_liste_calib2_clean.clear();
    m_liste_spots.clear();
    m_liste_mount_coord_spots.clear();
    m_liste_mount_coord_prism.clear();
    m_liste_global_coord_prism.clear();
    m_driver_ip_adress.clear();
    m_liste_bcam_adaptateur.clear();
    m_liste_absolutes_distances.clear();
    m_liste_ATLAS_coordinates.clear();
}
