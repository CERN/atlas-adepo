#ifndef RESULT_H
#define RESULT_H

#include "ctime"
#include "eigen-eigen-ffa86ffb5570/Eigen/Eigen"

class result
{
public:
    result() {
        mean = Eigen::MatrixXd(1,3);
        std = Eigen::MatrixXd(1,3);
    }
    ~result() {};

    void toString() {
        std::cout << name << " "
                  << mean(0,0) << " " << mean(0,1) << " " << mean(0,2) << " "
                  << std(0,0) << " " << std(0,1) << " " << std(0,2) << " "
                  << dx << " " << dy << " " << dz << std::endl;
    }

    std::string name;
    tm *ltm;
    Eigen::MatrixXd mean;
    Eigen::MatrixXd std;
    float dx, dy, dz;
};

#endif // RESULT_H
