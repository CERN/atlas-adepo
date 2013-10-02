#include "header/mythread.h"
#include <iostream>
#include "time.h"


mythread::mythread(QObject *parent, std::string bash_name) : QThread(parent)
{
}

void mythread::run()
{
    std::cout<<"maintenant la fenetre n'est pas blockee"<<std::endl;

    //lancement du programme LWDAQ + arret apres nombre de secondes specifiees par le user
    if(system(("bash "+ bash_name).c_str()))
       std::cout << "ACCESS_SUCCESS_to_LWDAQ"<<std::endl;
    else
       std::cout << "ACCESS_ENDED_to_LWDAQ"<<std::endl;


    //qDebug() << "Execution done";

    //exec();
}
