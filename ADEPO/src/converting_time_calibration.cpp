#include "header/converting_time_calibration.h"

double converting_time_calibration(std::string tps)
{
    double annee = atof(tps.substr(0,4).c_str());
    double mois = atof(tps.substr(4,6).c_str());
    double jour = atof(tps.substr(6,8).c_str());
    double heure = atof(tps.substr(8,10).c_str());
    double min = atof(tps.substr(10,12).c_str());
    double sec = atof(tps.substr(12,14).c_str());

    double annee_decimale = annee+(mois/12)+(jour/365)+(heure/8760)+(min/525600)+(sec/31536000);

    return annee_decimale;
}
