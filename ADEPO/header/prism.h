#ifndef PRISM_H
#define PRISM_H

#include <iostream>
#include <QString>
#include <QStringList>

class Prism
{
public:
    Prism(std::string name, int numChip) : mNumChip(numChip), left(20), right(343), top(1), bottom(243),
            separate(false), adjust(false) {

        QString s = QString::fromStdString(name);
        QStringList list = s.split("(");
        s = list.size() == 1 ? s : list.at(0);
        if (list.size() > 1) {
            list = list.at(1).right(list.at(1).length()-1).split(",");
            left = list.at(0).toInt();
            right = list.at(1).toInt();
        }

        // * (flash separate), + (search) or *+ is allowed

        if (s.endsWith("+")) {
            adjust = true;
            s = s.left(s.length()-1);
        }

        if (s.endsWith("*")) {
            separate = true;
            s = s.left(s.length()-1);
        }

        mName = s.toStdString();
        std::cout << mName << " " << left << " " << right << " " << separate << " " << adjust << std::endl;
    };
    virtual ~Prism() {};

    std::string getName() const { return mName; }
    bool isPrism() const { return mName.length() == 5 && mName[0] == 'P' && mName[1] == 'R'; }

    int getNumChip() const { return mNumChip; }
    int getLeft() const { return left; }
    int getRight() const { return right; }
    int getTop() const { return top; }
    int getBottom() const { return bottom; }

    bool flashSeparate() const { return separate; }
    bool flashAdjust() const { return adjust; }

private:
    std::string mName;
    int mNumChip;
    int left;
    int right;
    int top;
    int bottom;
    bool separate;
    bool adjust;
};

#endif // PRISM_H
