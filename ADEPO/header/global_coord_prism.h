#ifndef GLOBAL_COORD_PRISM_H
#define GLOBAL_COORD_PRISM_H

class global_coord_prism
{
public:
    global_coord_prism(BCAM* bcam, Point3f coordPrismMountSys, float airpad) :
        mBCAM(bcam), mCoordPrismMountSys(coordPrismMountSys), mAirpad(airpad) {};
    virtual ~global_coord_prism() {};

    //getter setter
    BCAM* getBCAM() const {return mBCAM; }
    Prism getPrism() const {return mBCAM->getPrism(); }
    std::string getName() const { return getBCAM()->getName()+"_"+getPrism().getName(); }
    Point3f getCoordPrismMountSys() const {return mCoordPrismMountSys; }

    float getAirpad() { return mAirpad; }

    //methodes
    void print() {
        std::cout<<"*******************************************global coordinates of prism*******************************************"<<std::endl;
        std::cout<<"Objet BCAM : "<<getBCAM()->getName()<<std::endl;
        std::cout<<"Objet Prism : "<<getPrism().getName()<<std::endl;
        std::cout<<"Coordonnées du prisme dans le systeme global : "<<std::endl;
        getCoordPrismMountSys().print();
    }

protected:
private:
    BCAM* mBCAM;
    Point3f mCoordPrismMountSys;
    float mAirpad;
};

#endif // GLOBAL_COORD_PRISM_H
