#ifndef FLOAT_TABLE_WIDGET_ITEM_H
#define FLOAT_TABLE_WIDGET_ITEM_H

#include <QTableWidgetItem>

class FloatTableWidgetItem : public QTableWidgetItem {
    public:
        FloatTableWidgetItem(QString s) : QTableWidgetItem(s) {};

        bool operator <(const QTableWidgetItem &other) const
        {
            return text().toFloat() < other.text().toFloat();
        }
};

#endif // FLOAT_TABLE_WIDGET_ITEM_H
