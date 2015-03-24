#ifndef RESULTS_H
#define RESULTS_H

#include <QHash>
#include <QFile>
#include <QJsonObject>
#include <QJsonDocument>
#include <QString>

#include "result.h"

#define OFFSET_FILE "offset_file.json"
#define OUTPUT_FILE "output_file.json"

class Results
{
public:
    Results() {};
    ~Results() {};

    int read(QString filename) {
       this->filename = filename;

       QFile jsonFile(filename);
       jsonFile.open(QFile::ReadOnly);
       QJsonObject json = QJsonDocument().fromJson(jsonFile.readAll()).object();
       read(json);

       write();

       return 1;
    }

    int write() {
        QFile jsonFile(filename);
        jsonFile.open(QFile::WriteOnly);
        QJsonDocument doc;
        QJsonObject json;
        write(json);
        doc.setObject(json);
        jsonFile.write(doc.toJson());
        return 1;
    }

    QString getFilename() const { return filename; }
    Result& getResult(QString prism) { return results[prism]; }
    void setResult(QString prism, Result& result) { results[prism] = result; }

    void read(const QJsonObject &json) {
        results.clear();
        for (QJsonObject::const_iterator i = json.begin(); i != json.end(); i++) {
            Result value;
            value.read(json[i.key()].toObject());
            results[i.key()] = value;
        }
    }

    void write(QJsonObject &json) const {
        for (QHash<QString, Result>::const_iterator i = results.begin(); i != results.end(); i++) {
            QJsonObject value;
            i.value().write(value);
            json[i.key()] = value;
        }
    }


private:
    QString filename;
    QHash<QString, Result> results;
};

#endif // RESULTS_H
