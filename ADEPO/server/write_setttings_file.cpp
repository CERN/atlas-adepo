#include "server.h"

//fonction qui ecrit un fichier tcl avec les parametres par defaut pour la fenetre Acquisifier      [---> ok
int Server::writeSettingsFile(QString settings_file, QString scriptFile, QString resultFile)
{
    //écriture dans un fichier
    std::ofstream fichier(settings_file.toStdString().c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert

    if(!fichier) return 0;

    //écriture la partie du script qui lance l'acquisition automatique
    fichier<<"set Acquisifier_config(auto_load) \"0\" \n"
           <<"set Acquisifier_config(title_color) \"purple\" \n"
           <<"set Acquisifier_config(extended_acquisition) \"0\" \n"
           <<"set Acquisifier_config(auto_repeat) \"0\" \n"
           <<"set Acquisifier_config(analyze) \"0\" \n"
           <<"set Acquisifier_config(auto_run) \"0\" \n"
           <<"set Acquisifier_config(cycle_period_seconds) \"0\" \n"
           <<"set Acquisifier_config(daq_script) \""<<scriptFile.toStdString()<<"\" \n"
           <<"set Acquisifier_config(run_results) \""<<resultFile.toStdString()<<"\" \n"
           <<"set Acquisifier_config(analysis_color) \"green\" \n"
           <<"set Acquisifier_config(auto_quit) \"0\" \n"
           <<"set Acquisifier_config(result_color) \"green\" \n"
           <<"set Acquisifier_config(num_steps_show) \"20\" \n"
           <<"set Acquisifier_config(num_lines_keep) \"1000\" \n"
           <<"set Acquisifier_config(restore_instruments) \"0\" \n";

      fichier.close();
      return 1;
}

