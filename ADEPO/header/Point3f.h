#ifndef POINT3F_H
#define POINT3F_H


class Point3f
{
    public:

        //constructeurs et destructeurs
        Point3f();
        Point3f(double X,double Y,double Z);
        virtual ~Point3f();
        Point3f(const Point3f& copie);

        //setter et getter
        double Get_X() const { return m_X; }
        void Set_X(double val) { m_X = val; }
        double Get_Y() const { return m_Y; }
        void Set_Y(double val) { m_Y = val; }
        double Get_Z() const { return m_Z; }
        void Set_Z(double val) { m_Z = val; }

        //methodes
        void Affiche();
        bool Est_egal(Point3f pt);

    protected:
    private:
        double m_X;
        double m_Y;
        double m_Z;
};

#endif // POINT3F_H
