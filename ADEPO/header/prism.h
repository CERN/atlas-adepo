#ifndef PRISM_H
#define PRISM_H

#include <iostream>

class Prism
{
public:
    Prism(std::string name, int numChip) : mName(name), mNumChip(numChip) {};
    virtual ~Prism() {};

    std::string getName() const { return mName; }
    bool isPrism() const { return mName.length() == 5 && mName[0] == 'P' && mName[1] == 'R'; }

    int getNumChip() const { return mNumChip; }

private:
    std::string mName;
    int mNumChip;
};

#endif // PRISM_H
