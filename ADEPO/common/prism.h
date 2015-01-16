#ifndef PRISM_H
#define PRISM_H

#include <iostream>
#include <QString>
#include <QStringList>

class Prism
{
public:
    // possible names: PR005 PR005* PR005+ PR005*+ PR005+* PR005(20,180), 20MABNDM000020, 20MABNDM000020+, etc and combinations...
    Prism(QString name, int numChip) : mNumChip(numChip), left(20), right(343), top(1), bottom(243),
            separate(false), adjust(false) {

        QString s = name;
        QStringList list = s.split("(");
        s = list.size() == 1 ? s : list.at(0);
        if (list.size() > 1) {
            list = list.at(1).left(list.at(1).length()-1).split(",");
            left = list.at(0).toInt();
            right = list.at(1).toInt();
        }

        prism = s.startsWith("PR");

        mName = s.left(prism ? 5 : 14);
        s = s.mid(prism ? 5 : 14);

        // * (flash separate), + (search), *+ and +* are also allowed
        separate = s.contains("*");
        adjust = s.contains("+");

//        std::cout << mName << " " << left << " " << right << " " << separate << " " << adjust << std::endl;
    };
    virtual ~Prism() {};

    QString getName() const { return mName; }
    bool isPrism() const { return prism; }

    int getNumChip() const { return mNumChip; }
    int getLeft() const { return left; }
    int getRight() const { return right; }
    int getTop() const { return top; }
    int getBottom() const { return bottom; }

    bool flashSeparate() const { return separate; }
    bool flashAdjust() const { return adjust; }

private:
    QString mName;
    bool prism;
    int mNumChip;
    int left;
    int right;
    int top;
    int bottom;
    bool separate;
    bool adjust;
};

#endif // PRISM_H
