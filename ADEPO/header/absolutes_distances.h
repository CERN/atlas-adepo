#ifndef ABSOLUTES_DISTANCES_H
#define ABSOLUTES_DISTANCES_H

#include <iostream>
#include "Point3f.h"

class absolutes_distances
{
public:
    absolutes_distances(std::string bcam, std::string prism, Point3f distances) : mBCAM(bcam), mPrism(prism), mDistances(distances) {};
    virtual ~absolutes_distances() {};

   //setter et getter
    std::string getBCAM() const {return mBCAM;}
    std::string getPrism() const {return mPrism;}
    std::string getName() const { return getBCAM()+"_"+getPrism(); }

    Point3f getDistances() const {return mDistances;}

    //methodes
    void print() {
        std::cout<<"*******************************************//ABSOLUTES_DISTANCES*******************************************"<<std::endl;
        std::cout<<"La distance est entre  : "<<getBCAM()<<" "<<getPrism()<<std::endl;
        std::cout<<"Les valeurs des distances : \n"<<std::endl;
        getDistances().print();
    }

protected:
private:
    std::string mBCAM;
    std::string mPrism;
    Point3f mDistances;
};

#endif // ABSOLUTES_DISTANCES_H
