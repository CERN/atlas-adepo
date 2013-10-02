/****************************************************************************
** Meta object code from reading C++ file 'atlas_bcam.h'
**
** Created: Wed Oct 2 10:36:25 2013
**      by: The Qt Meta Object Compiler version 63 (Qt 4.8.1)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../ADEPO/header/atlas_bcam.h"
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'atlas_bcam.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 63
#error "This file was generated using the moc from 4.8.1. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

QT_BEGIN_MOC_NAMESPACE
static const uint qt_meta_data_ATLAS_BCAM[] = {

 // content:
       6,       // revision
       0,       // classname
       0,    0, // classinfo
       9,   14, // methods
       0,    0, // properties
       0,    0, // enums/sets
       0,    0, // constructors
       0,       // flags
       0,       // signalCount

 // slots: signature, parameters, type, tag, flags
      12,   11,   11,   11, 0x0a,
      30,   11,   11,   11, 0x0a,
      47,   11,   11,   11, 0x0a,
      79,   65,   11,   11, 0x0a,
     108,   11,   11,   11, 0x0a,
     129,   11,   11,   11, 0x0a,
     148,   11,   11,   11, 0x0a,
     159,   11,   11,   11, 0x0a,
     178,   11,   11,   11, 0x0a,

       0        // eod
};

static const char qt_meta_stringdata_ATLAS_BCAM[] = {
    "ATLAS_BCAM\0\0save_time_value()\0"
    "ouvrirDialogue()\0aide_atlas_bcam()\0"
    "ligne,colonne\0affiche_liste_BCAMs(int,int)\0"
    "lancer_acquisition()\0stop_acquisition()\0"
    "get_mode()\0get_airpad_state()\0"
    "startCalcul()\0"
};

void ATLAS_BCAM::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    if (_c == QMetaObject::InvokeMetaMethod) {
        Q_ASSERT(staticMetaObject.cast(_o));
        ATLAS_BCAM *_t = static_cast<ATLAS_BCAM *>(_o);
        switch (_id) {
        case 0: _t->save_time_value(); break;
        case 1: _t->ouvrirDialogue(); break;
        case 2: _t->aide_atlas_bcam(); break;
        case 3: _t->affiche_liste_BCAMs((*reinterpret_cast< int(*)>(_a[1])),(*reinterpret_cast< int(*)>(_a[2]))); break;
        case 4: _t->lancer_acquisition(); break;
        case 5: _t->stop_acquisition(); break;
        case 6: _t->get_mode(); break;
        case 7: _t->get_airpad_state(); break;
        case 8: _t->startCalcul(); break;
        default: ;
        }
    }
}

const QMetaObjectExtraData ATLAS_BCAM::staticMetaObjectExtraData = {
    0,  qt_static_metacall 
};

const QMetaObject ATLAS_BCAM::staticMetaObject = {
    { &QMainWindow::staticMetaObject, qt_meta_stringdata_ATLAS_BCAM,
      qt_meta_data_ATLAS_BCAM, &staticMetaObjectExtraData }
};

#ifdef Q_NO_DATA_RELOCATION
const QMetaObject &ATLAS_BCAM::getStaticMetaObject() { return staticMetaObject; }
#endif //Q_NO_DATA_RELOCATION

const QMetaObject *ATLAS_BCAM::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->metaObject : &staticMetaObject;
}

void *ATLAS_BCAM::qt_metacast(const char *_clname)
{
    if (!_clname) return 0;
    if (!strcmp(_clname, qt_meta_stringdata_ATLAS_BCAM))
        return static_cast<void*>(const_cast< ATLAS_BCAM*>(this));
    return QMainWindow::qt_metacast(_clname);
}

int ATLAS_BCAM::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QMainWindow::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 9)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 9;
    }
    return _id;
}
QT_END_MOC_NAMESPACE
