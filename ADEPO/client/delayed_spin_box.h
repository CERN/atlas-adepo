#ifndef DELAYED_SPIN_BOX
#define DELAYED_SPIN_BOX

#include <QSpinBox>
#include <QTimer>
#include <QDebug>
#include <QEvent>

class DelayedSpinBox : public QSpinBox {
    Q_OBJECT

    public:
        DelayedSpinBox(QWidget * parent = 0) : QSpinBox(parent) {
            timer = new QTimer(this);
            timer->setInterval(500);
            timer->setSingleShot(true);

            connect(timer, &QTimer::timeout, this, &DelayedSpinBox::timeout);
            connect(this, SIGNAL(valueChanged(int)), this, SLOT(myValueChanged(int)));
        }

    signals:
        void delayedValueChanged(int i);

    private slots:
        void myValueChanged(int i) {
            Q_UNUSED(i);
            timer->start();
        }

        void timeout() {
            emit delayedValueChanged(value());
        }

    private:
        QTimer* timer;
};

#endif // DELAYED_SPIN_BOX
