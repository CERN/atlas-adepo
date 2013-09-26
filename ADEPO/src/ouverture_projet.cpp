#include "header/ouverture_projet.h"

ouverture_projet::ouverture_projet(QWidget *parent = 0) : QDialog(parent)
{
    setWindowTitle("Acces au fichier");
    setGeometry(200*0.5,200*0.5,1000*0.5,200*0.5);

    //fichier input
    QPushButton *ouv_fichier_entree = new QPushButton("Ouvrir");
    QLineEdit *chemin_fichier_entree = new QLineEdit();
    chemin_fichier_entree->setReadOnly(true);

    QFormLayout *form = new QFormLayout;
    form->addRow("Cliquez sur Ouvrir :", ouv_fichier_entree);
    form->addRow("Chemin du &fichier : ", chemin_fichier_entree);

    // boutons annuler et continuer
    QPushButton *bt_ok = new QPushButton("&Valider");
    QPushButton *bt_annuler = new QPushButton("&Annuler");

    //layout principal
    QHBoxLayout *layout_bt = new QHBoxLayout;
    layout_bt->addWidget(bt_ok);
    layout_bt->addWidget(bt_annuler);

    QVBoxLayout *layout_principal = new QVBoxLayout;
    layout_principal->addLayout(form);
    layout_principal->addLayout(layout_bt);

    setLayout(layout_principal);

    connect(ouv_fichier_entree, SIGNAL(clicked()),this, SLOT(ouverture_du_fichier()));
    connect(this, SIGNAL(path_fich_changed(QString)),chemin_fichier_entree, SLOT(setText(QString)));

    connect(bt_ok, SIGNAL(clicked()),this,SLOT(envoi()));
    connect(this,SIGNAL(envoi_ok()),this,SLOT(accept()));
    connect(bt_annuler, SIGNAL(clicked()),this, SLOT(close()));

}

void ouverture_projet::ouverture_du_fichier()
{
    this->path_fich = QFileDialog::getExistingDirectory(this);
    emit path_fich_changed(path_fich);

}

void ouverture_projet::envoi()
{
    if (!(this->path_fich.isEmpty()))//&&this->path_img.isEmpty()))
    {
        emit envoi_ok();
    }
    else
        QMessageBox::warning(this,"Attention","Veuillez remplir toutes les informations");

}
