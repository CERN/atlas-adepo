#include <QCoreApplication>

#include <iostream>

#include "example.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    std::cout << "Start" << std::endl;

    Example *example = new Example(&a);
    example->run();

    return a.exec();
}

