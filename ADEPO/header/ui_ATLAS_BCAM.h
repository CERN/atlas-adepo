/********************************************************************************
** Form generated from reading UI file 'ATLAS_BCAM.ui'
**
** Created: Thu Aug 8 11:04:33 2013
**      by: Qt User Interface Compiler version 4.8.1
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_ATLAS_BCAM_H
#define UI_ATLAS_BCAM_H

#include <QtCore/QVariant>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QButtonGroup>
#include <QtGui/QCheckBox>
#include <QtGui/QGridLayout>
#include <QtGui/QGroupBox>
#include <QtGui/QHeaderView>
#include <QtGui/QLineEdit>
#include <QtGui/QMainWindow>
#include <QtGui/QMenu>
#include <QtGui/QMenuBar>
#include <QtGui/QPushButton>
#include <QtGui/QStatusBar>
#include <QtGui/QTabWidget>
#include <QtGui/QTableWidget>
#include <QtGui/QTextEdit>
#include <QtGui/QVBoxLayout>
#include <QtGui/QWidget>

QT_BEGIN_NAMESPACE

class Ui_ATLAS_BCAM
{
public:
    QAction *actionCharger;
    QAction *actionAbout_Qt;
    QAction *action_Aide;
    QAction *action_Quitter;
    QWidget *centralwidget;
    QGridLayout *gridLayout_6;
    QTabWidget *tabWidget;
    QWidget *tab;
    QVBoxLayout *verticalLayout_6;
    QGroupBox *groupBox;
    QTableWidget *tableWidget_liste_bcams;
    QTableWidget *tableWidget_liste_detectors;
    QLineEdit *lineEdit_value_seconds;
    QTextEdit *textEdit_function_mode;
    QPushButton *Boutton_lancer;
    QPushButton *boutton_arreter;
    QCheckBox *checkBox_airpad_off;
    QCheckBox *checkBox_airpad_on;
    QTextEdit *textEdit_airpad;
    QTextEdit *textEdit_mode;
    QCheckBox *checkBox_closure;
    QCheckBox *checkBox_monitoring;
    QWidget *widget;
    QVBoxLayout *verticalLayout_2;
    QMenuBar *menubar;
    QMenu *menuFichier;
    QMenu *menuAide;
    QStatusBar *statusBar;

    void setupUi(QMainWindow *ATLAS_BCAM)
    {
        if (ATLAS_BCAM->objectName().isEmpty())
            ATLAS_BCAM->setObjectName(QString::fromUtf8("ATLAS_BCAM"));
        ATLAS_BCAM->resize(910, 718);
        ATLAS_BCAM->setSizeIncrement(QSize(0, 0));
        QIcon icon;
        icon.addFile(QString::fromUtf8("Mayan_Pyramid-icon.png"), QSize(), QIcon::Normal, QIcon::Off);
        ATLAS_BCAM->setWindowIcon(icon);
        actionCharger = new QAction(ATLAS_BCAM);
        actionCharger->setObjectName(QString::fromUtf8("actionCharger"));
        actionAbout_Qt = new QAction(ATLAS_BCAM);
        actionAbout_Qt->setObjectName(QString::fromUtf8("actionAbout_Qt"));
        action_Aide = new QAction(ATLAS_BCAM);
        action_Aide->setObjectName(QString::fromUtf8("action_Aide"));
        action_Quitter = new QAction(ATLAS_BCAM);
        action_Quitter->setObjectName(QString::fromUtf8("action_Quitter"));
        centralwidget = new QWidget(ATLAS_BCAM);
        centralwidget->setObjectName(QString::fromUtf8("centralwidget"));
        gridLayout_6 = new QGridLayout(centralwidget);
        gridLayout_6->setObjectName(QString::fromUtf8("gridLayout_6"));
        tabWidget = new QTabWidget(centralwidget);
        tabWidget->setObjectName(QString::fromUtf8("tabWidget"));
        tab = new QWidget();
        tab->setObjectName(QString::fromUtf8("tab"));
        verticalLayout_6 = new QVBoxLayout(tab);
        verticalLayout_6->setObjectName(QString::fromUtf8("verticalLayout_6"));
        groupBox = new QGroupBox(tab);
        groupBox->setObjectName(QString::fromUtf8("groupBox"));
        tableWidget_liste_bcams = new QTableWidget(groupBox);
        if (tableWidget_liste_bcams->columnCount() < 6)
            tableWidget_liste_bcams->setColumnCount(6);
        QTableWidgetItem *__qtablewidgetitem = new QTableWidgetItem();
        tableWidget_liste_bcams->setHorizontalHeaderItem(0, __qtablewidgetitem);
        QTableWidgetItem *__qtablewidgetitem1 = new QTableWidgetItem();
        tableWidget_liste_bcams->setHorizontalHeaderItem(1, __qtablewidgetitem1);
        QTableWidgetItem *__qtablewidgetitem2 = new QTableWidgetItem();
        tableWidget_liste_bcams->setHorizontalHeaderItem(2, __qtablewidgetitem2);
        QTableWidgetItem *__qtablewidgetitem3 = new QTableWidgetItem();
        tableWidget_liste_bcams->setHorizontalHeaderItem(3, __qtablewidgetitem3);
        QTableWidgetItem *__qtablewidgetitem4 = new QTableWidgetItem();
        tableWidget_liste_bcams->setHorizontalHeaderItem(4, __qtablewidgetitem4);
        QTableWidgetItem *__qtablewidgetitem5 = new QTableWidgetItem();
        tableWidget_liste_bcams->setHorizontalHeaderItem(5, __qtablewidgetitem5);
        tableWidget_liste_bcams->setObjectName(QString::fromUtf8("tableWidget_liste_bcams"));
        tableWidget_liste_bcams->setGeometry(QRect(17, 331, 851, 251));
        tableWidget_liste_bcams->setEditTriggers(QAbstractItemView::NoEditTriggers);
        tableWidget_liste_bcams->setSelectionMode(QAbstractItemView::SingleSelection);
        tableWidget_liste_bcams->setSelectionBehavior(QAbstractItemView::SelectRows);
        tableWidget_liste_bcams->setTextElideMode(Qt::ElideNone);
        tableWidget_liste_bcams->setSortingEnabled(true);
        tableWidget_liste_bcams->horizontalHeader()->setVisible(true);
        tableWidget_liste_bcams->horizontalHeader()->setCascadingSectionResizes(false);
        tableWidget_liste_bcams->horizontalHeader()->setDefaultSectionSize(140);
        tableWidget_liste_bcams->horizontalHeader()->setHighlightSections(false);
        tableWidget_liste_bcams->horizontalHeader()->setMinimumSectionSize(140);
        tableWidget_liste_bcams->verticalHeader()->setVisible(false);
        tableWidget_liste_bcams->verticalHeader()->setCascadingSectionResizes(false);
        tableWidget_liste_bcams->verticalHeader()->setMinimumSectionSize(30);
        tableWidget_liste_bcams->verticalHeader()->setProperty("showSortIndicator", QVariant(true));
        tableWidget_liste_detectors = new QTableWidget(groupBox);
        if (tableWidget_liste_detectors->columnCount() < 2)
            tableWidget_liste_detectors->setColumnCount(2);
        QFont font;
        font.setKerning(true);
        QTableWidgetItem *__qtablewidgetitem6 = new QTableWidgetItem();
        __qtablewidgetitem6->setTextAlignment(Qt::AlignHCenter|Qt::AlignVCenter|Qt::AlignCenter);
        __qtablewidgetitem6->setFont(font);
        tableWidget_liste_detectors->setHorizontalHeaderItem(0, __qtablewidgetitem6);
        QTableWidgetItem *__qtablewidgetitem7 = new QTableWidgetItem();
        __qtablewidgetitem7->setTextAlignment(Qt::AlignHCenter|Qt::AlignVCenter|Qt::AlignCenter);
        tableWidget_liste_detectors->setHorizontalHeaderItem(1, __qtablewidgetitem7);
        tableWidget_liste_detectors->setObjectName(QString::fromUtf8("tableWidget_liste_detectors"));
        tableWidget_liste_detectors->setEnabled(true);
        tableWidget_liste_detectors->setGeometry(QRect(17, 25, 450, 300));
        QSizePolicy sizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
        sizePolicy.setHorizontalStretch(20);
        sizePolicy.setVerticalStretch(20);
        sizePolicy.setHeightForWidth(tableWidget_liste_detectors->sizePolicy().hasHeightForWidth());
        tableWidget_liste_detectors->setSizePolicy(sizePolicy);
        tableWidget_liste_detectors->setMinimumSize(QSize(450, 10));
        tableWidget_liste_detectors->setMaximumSize(QSize(200, 300));
        tableWidget_liste_detectors->setContextMenuPolicy(Qt::NoContextMenu);
        tableWidget_liste_detectors->setFrameShape(QFrame::StyledPanel);
        tableWidget_liste_detectors->setLineWidth(1);
        tableWidget_liste_detectors->setEditTriggers(QAbstractItemView::NoEditTriggers);
        tableWidget_liste_detectors->setDragEnabled(false);
        tableWidget_liste_detectors->setSelectionMode(QAbstractItemView::ExtendedSelection);
        tableWidget_liste_detectors->setSelectionBehavior(QAbstractItemView::SelectRows);
        tableWidget_liste_detectors->setTextElideMode(Qt::ElideNone);
        tableWidget_liste_detectors->setShowGrid(true);
        tableWidget_liste_detectors->setSortingEnabled(true);
        tableWidget_liste_detectors->horizontalHeader()->setVisible(true);
        tableWidget_liste_detectors->horizontalHeader()->setCascadingSectionResizes(false);
        tableWidget_liste_detectors->horizontalHeader()->setDefaultSectionSize(224);
        tableWidget_liste_detectors->horizontalHeader()->setHighlightSections(false);
        tableWidget_liste_detectors->horizontalHeader()->setMinimumSectionSize(224);
        tableWidget_liste_detectors->horizontalHeader()->setProperty("showSortIndicator", QVariant(true));
        tableWidget_liste_detectors->verticalHeader()->setVisible(false);
        tableWidget_liste_detectors->verticalHeader()->setCascadingSectionResizes(false);
        tableWidget_liste_detectors->verticalHeader()->setDefaultSectionSize(30);
        tableWidget_liste_detectors->verticalHeader()->setMinimumSectionSize(30);
        tableWidget_liste_detectors->verticalHeader()->setProperty("showSortIndicator", QVariant(true));
        lineEdit_value_seconds = new QLineEdit(groupBox);
        lineEdit_value_seconds->setObjectName(QString::fromUtf8("lineEdit_value_seconds"));
        lineEdit_value_seconds->setGeometry(QRect(730, 110, 113, 31));
        lineEdit_value_seconds->setAutoFillBackground(false);
        textEdit_function_mode = new QTextEdit(groupBox);
        textEdit_function_mode->setObjectName(QString::fromUtf8("textEdit_function_mode"));
        textEdit_function_mode->setGeometry(QRect(473, 110, 231, 31));
        Boutton_lancer = new QPushButton(groupBox);
        Boutton_lancer->setObjectName(QString::fromUtf8("Boutton_lancer"));
        Boutton_lancer->setEnabled(false);
        Boutton_lancer->setGeometry(QRect(510, 280, 98, 27));
        Boutton_lancer->setCursor(QCursor(Qt::PointingHandCursor));
        Boutton_lancer->setMouseTracking(false);
        Boutton_lancer->setStyleSheet(QString::fromUtf8(""));
        boutton_arreter = new QPushButton(groupBox);
        boutton_arreter->setObjectName(QString::fromUtf8("boutton_arreter"));
        boutton_arreter->setEnabled(false);
        boutton_arreter->setGeometry(QRect(720, 280, 98, 27));
        boutton_arreter->setCursor(QCursor(Qt::PointingHandCursor));
        checkBox_airpad_off = new QCheckBox(groupBox);
        checkBox_airpad_off->setObjectName(QString::fromUtf8("checkBox_airpad_off"));
        checkBox_airpad_off->setGeometry(QRect(740, 200, 97, 31));
        checkBox_airpad_on = new QCheckBox(groupBox);
        checkBox_airpad_on->setObjectName(QString::fromUtf8("checkBox_airpad_on"));
        checkBox_airpad_on->setGeometry(QRect(620, 200, 97, 31));
        textEdit_airpad = new QTextEdit(groupBox);
        textEdit_airpad->setObjectName(QString::fromUtf8("textEdit_airpad"));
        textEdit_airpad->setEnabled(false);
        textEdit_airpad->setGeometry(QRect(490, 200, 71, 31));
        textEdit_mode = new QTextEdit(groupBox);
        textEdit_mode->setObjectName(QString::fromUtf8("textEdit_mode"));
        textEdit_mode->setEnabled(false);
        textEdit_mode->setGeometry(QRect(490, 40, 81, 31));
        textEdit_mode->setMouseTracking(false);
        textEdit_mode->setAcceptDrops(false);
        textEdit_mode->setTabChangesFocus(false);
        textEdit_mode->setUndoRedoEnabled(false);
        checkBox_closure = new QCheckBox(groupBox);
        checkBox_closure->setObjectName(QString::fromUtf8("checkBox_closure"));
        checkBox_closure->setGeometry(QRect(600, 40, 97, 31));
        checkBox_monitoring = new QCheckBox(groupBox);
        checkBox_monitoring->setObjectName(QString::fromUtf8("checkBox_monitoring"));
        checkBox_monitoring->setGeometry(QRect(730, 40, 121, 31));

        verticalLayout_6->addWidget(groupBox);

        tabWidget->addTab(tab, QString());
        widget = new QWidget();
        widget->setObjectName(QString::fromUtf8("widget"));
        verticalLayout_2 = new QVBoxLayout(widget);
        verticalLayout_2->setSpacing(3);
        verticalLayout_2->setContentsMargins(5, 5, 5, 5);
        verticalLayout_2->setObjectName(QString::fromUtf8("verticalLayout_2"));
        tabWidget->addTab(widget, QString());

        gridLayout_6->addWidget(tabWidget, 0, 0, 1, 1);

        ATLAS_BCAM->setCentralWidget(centralwidget);
        menubar = new QMenuBar(ATLAS_BCAM);
        menubar->setObjectName(QString::fromUtf8("menubar"));
        menubar->setGeometry(QRect(0, 0, 910, 25));
        menuFichier = new QMenu(menubar);
        menuFichier->setObjectName(QString::fromUtf8("menuFichier"));
        menuAide = new QMenu(menubar);
        menuAide->setObjectName(QString::fromUtf8("menuAide"));
        ATLAS_BCAM->setMenuBar(menubar);
        statusBar = new QStatusBar(ATLAS_BCAM);
        statusBar->setObjectName(QString::fromUtf8("statusBar"));
        ATLAS_BCAM->setStatusBar(statusBar);

        menubar->addAction(menuFichier->menuAction());
        menubar->addAction(menuAide->menuAction());
        menuFichier->addAction(actionCharger);
        menuFichier->addAction(action_Quitter);
        menuAide->addAction(actionAbout_Qt);
        menuAide->addAction(action_Aide);

        retranslateUi(ATLAS_BCAM);

        tabWidget->setCurrentIndex(0);


        QMetaObject::connectSlotsByName(ATLAS_BCAM);
    } // setupUi

    void retranslateUi(QMainWindow *ATLAS_BCAM)
    {
        ATLAS_BCAM->setWindowTitle(QApplication::translate("ATLAS_BCAM", "ADEPO", 0, QApplication::UnicodeUTF8));
        actionCharger->setText(QApplication::translate("ATLAS_BCAM", "INPUT FILE", 0, QApplication::UnicodeUTF8));
#ifndef QT_NO_TOOLTIP
        actionCharger->setToolTip(QApplication::translate("ATLAS_BCAM", "INPUT FOLDER", 0, QApplication::UnicodeUTF8));
#endif // QT_NO_TOOLTIP
#ifndef QT_NO_STATUSTIP
        actionCharger->setStatusTip(QApplication::translate("ATLAS_BCAM", "Ouverture du projet", 0, QApplication::UnicodeUTF8));
#endif // QT_NO_STATUSTIP
        actionAbout_Qt->setText(QApplication::translate("ATLAS_BCAM", "About &Qt", 0, QApplication::UnicodeUTF8));
        action_Aide->setText(QApplication::translate("ATLAS_BCAM", "&Aide ATLAS_BCAM", 0, QApplication::UnicodeUTF8));
        action_Quitter->setText(QApplication::translate("ATLAS_BCAM", "&Quitter", 0, QApplication::UnicodeUTF8));
#ifndef QT_NO_STATUSTIP
        action_Quitter->setStatusTip(QApplication::translate("ATLAS_BCAM", "Quitter l'application", 0, QApplication::UnicodeUTF8));
#endif // QT_NO_STATUSTIP
        groupBox->setTitle(QString());
        QTableWidgetItem *___qtablewidgetitem = tableWidget_liste_bcams->horizontalHeaderItem(0);
        ___qtablewidgetitem->setText(QApplication::translate("ATLAS_BCAM", "BCAM NAME", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem1 = tableWidget_liste_bcams->horizontalHeaderItem(1);
        ___qtablewidgetitem1->setText(QApplication::translate("ATLAS_BCAM", "DETECTOR ID", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem2 = tableWidget_liste_bcams->horizontalHeaderItem(2);
        ___qtablewidgetitem2->setText(QApplication::translate("ATLAS_BCAM", "PORT DRIVER", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem3 = tableWidget_liste_bcams->horizontalHeaderItem(3);
        ___qtablewidgetitem3->setText(QApplication::translate("ATLAS_BCAM", "PORT MUX", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem4 = tableWidget_liste_bcams->horizontalHeaderItem(4);
        ___qtablewidgetitem4->setText(QApplication::translate("ATLAS_BCAM", "TYPE", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem5 = tableWidget_liste_bcams->horizontalHeaderItem(5);
        ___qtablewidgetitem5->setText(QApplication::translate("ATLAS_BCAM", "ITEM MEASURED", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem6 = tableWidget_liste_detectors->horizontalHeaderItem(0);
        ___qtablewidgetitem6->setText(QApplication::translate("ATLAS_BCAM", "DETECTOR ID", 0, QApplication::UnicodeUTF8));
        QTableWidgetItem *___qtablewidgetitem7 = tableWidget_liste_detectors->horizontalHeaderItem(1);
        ___qtablewidgetitem7->setText(QApplication::translate("ATLAS_BCAM", "DETECTOR NAME", 0, QApplication::UnicodeUTF8));
        textEdit_function_mode->setHtml(QApplication::translate("ATLAS_BCAM", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:'Ubuntu'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
"<p align=\"justify\" style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><br /></p></body></html>", 0, QApplication::UnicodeUTF8));
        Boutton_lancer->setText(QApplication::translate("ATLAS_BCAM", "Lancer", 0, QApplication::UnicodeUTF8));
        boutton_arreter->setText(QApplication::translate("ATLAS_BCAM", "STOP", 0, QApplication::UnicodeUTF8));
        checkBox_airpad_off->setText(QApplication::translate("ATLAS_BCAM", "OFF", 0, QApplication::UnicodeUTF8));
        checkBox_airpad_on->setText(QApplication::translate("ATLAS_BCAM", "ON", 0, QApplication::UnicodeUTF8));
        textEdit_airpad->setHtml(QApplication::translate("ATLAS_BCAM", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:'Ubuntu'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
"<p align=\"justify\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">AIRPAD :</p></body></html>", 0, QApplication::UnicodeUTF8));
        textEdit_mode->setHtml(QApplication::translate("ATLAS_BCAM", "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n"
"<html><head><meta name=\"qrichtext\" content=\"1\" /><style type=\"text/css\">\n"
"p, li { white-space: pre-wrap; }\n"
"</style></head><body style=\" font-family:'Ubuntu'; font-size:11pt; font-weight:400; font-style:normal;\">\n"
"<p align=\"justify\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">MODE :</p></body></html>", 0, QApplication::UnicodeUTF8));
        checkBox_closure->setText(QApplication::translate("ATLAS_BCAM", "CLOSURE", 0, QApplication::UnicodeUTF8));
        checkBox_monitoring->setText(QApplication::translate("ATLAS_BCAM", "MONITORING", 0, QApplication::UnicodeUTF8));
        tabWidget->setTabText(tabWidget->indexOf(tab), QApplication::translate("ATLAS_BCAM", "&Configuration", 0, QApplication::UnicodeUTF8));
        tabWidget->setTabText(tabWidget->indexOf(widget), QApplication::translate("ATLAS_BCAM", "&Delta", 0, QApplication::UnicodeUTF8));
        menuFichier->setTitle(QApplication::translate("ATLAS_BCAM", "&Fichier", 0, QApplication::UnicodeUTF8));
        menuAide->setTitle(QApplication::translate("ATLAS_BCAM", "Aide", 0, QApplication::UnicodeUTF8));
    } // retranslateUi

};

namespace Ui {
    class ATLAS_BCAM: public Ui_ATLAS_BCAM {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_ATLAS_BCAM_H
