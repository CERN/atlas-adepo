#include "run.h"

#include <iostream>

#include <QFile>
#include <QJsonDocument>
#include <QDebug>

void Run::write() {
    QFile jsonFile(fileName);
    jsonFile.open(QFile::WriteOnly);
    QJsonDocument doc;
    doc.setObject(data);
    jsonFile.write(doc.toJson());
}

void Run::read(QString fileName) {
    this->fileName = fileName;

    QFile jsonFile(fileName);
    jsonFile.open(QFile::ReadOnly);
    data = QJsonDocument().fromJson(jsonFile.readAll()).object();
}




