#ifndef MYTHREAD_H
#define MYTHREAD_H

#include "QtGui"
#include "header/bdd.h"

class mythread : public QThread
{
    Q_OBJECT

public:
    mythread(QObject *parent, std::string bash_name);
    void run(); // this is virtual method, we must implement it in our subclass of QThread
};

#endif // MYTHREAD_H
