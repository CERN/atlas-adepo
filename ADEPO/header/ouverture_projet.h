#ifndef OUVERTURE_PROJET_H
#define OUVERTURE_PROJET_H

#include <QPushButton>
#include <QLineEdit>
#include <QDialog>
#include <QFormLayout>
#include <QHBoxLayout>
#include <QMessageBox>
#include <QFileDialog>

#include "bdd.h"

class ouverture_projet  : public QDialog
{
     Q_OBJECT

public:
    explicit ouverture_projet(QWidget *parent);
    QString path_fich;
    QLineEdit *chemin_fichier_entree;
    QPushButton *button_ok;
    QString Get_path_fich(){return path_fich;}

signals:
    void path_fich_changed(QString path);
    void envoi_ok();

public slots:
    void ouverture_du_fichier();
    void envoi();
};

#endif // OUVERTURE_PROJET_H
