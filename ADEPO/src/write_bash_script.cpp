#include "header/write_bash_script.h"

int write_bash_script(std::string input_bash_file)
{
    //écriture dans un fichier
    std::ofstream fichier((char*)input_bash_file.c_str(), std::ios::out | std::ios::trunc);  // ouverture en écriture avec effacement du fichier ouvert
    if(fichier)
    {
       fichier<<"#!/bin/bash \n"
               <<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_params.tcl /home/cern-mehdi/Documents/LWDAQ/LWDAQ.app/Contents/LWDAQ/Startup \n"
               <<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_Settings.tcl /home/cern-mehdi/Documents/LWDAQ/Tools/Data \n"
               <<"cp /home/cern-mehdi/Documents/Projet_BCAM/scripts_lwdaq/Acquisifier_script.tcl /home/cern-mehdi/Documents/LWDAQ/Tools/Data \n"
               <<"/home/cern-mehdi/Documents/LWDAQ/lwdaq --no-console \n"
               <<"ps -eH | grep tclsh8.5 >/home/cern-mehdi/Documents/Projet_BCAM/PID.txt \n"
               <<"read pid reste < /home/cern-mehdi/Documents/Projet_BCAM/PID.txt \n"
               <<"sleep 10s \n"
               <<"kill \"$pid\" \n";

           fichier.close();
           return 1;
    }
    else
    {
           return 0;
    }
}
