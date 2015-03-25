#ifndef DELAYED_SPIN_BOX
#define DELAYED_SPIN_BOX

#include <QSpinBox>
#include <QTimer>

class DelayedSpinBox : public QSpinBox {
    public:
        DelayedSpinBox(QWidget * parent = 0) : QSpinBox(parent) {
            timer = new QTimer(this);
            timer->setInterval(2000);
            timer->setSingleShot(true);

            connect(timer, &QTimer::timeout, this, &DelayedSpinBox::timeout);

            connect(this, SIGNAL(valueChanged(int)), this, SLOT(triggerValueChanged(int)));
        }

//    Q_SIGNALS:
//        void delayedValueChanged(int i);

    private slots:
        void triggerValueChanged(int i) {
            std::cout << "Spin " << i << std::endl;
        }

        void timeout() {
            std::cout << "Timeout Spin " << value() << std::endl;
//            emit delayedValueChanged(value());
        }

    private:
        QTimer *timer;
};

#endif // DELAYED_SPIN_BOX

