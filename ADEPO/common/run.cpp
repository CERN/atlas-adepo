#include "run.h"

#include <iostream>

#include "qfile.h"
#include "qjsondocument.h"

void Run::write() {
    QFile jsonFile(fileName);
    jsonFile.open(QFile::WriteOnly);
    QJsonDocument doc;
    doc.setObject(json);
    jsonFile.write(doc.toJson());
}

void Run::read(QString fileName) {
    QFile jsonFile(fileName);
    jsonFile.open(QFile::ReadOnly);
    json = QJsonDocument().fromJson(jsonFile.readAll()).object();

    this->fileName = fileName;

    write();
}

