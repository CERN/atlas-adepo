#ifndef POINT3F_H
#define POINT3F_H


class Point3f
{
    public:

        //constructeurs et destructeurs
        Point3f();
<<<<<<< HEAD
        Point3f(float X,float Y,float Z);
=======
        Point3f(double X,double Y,double Z);
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
        virtual ~Point3f();
        Point3f(const Point3f& copie);

        //setter et getter
<<<<<<< HEAD
        float Get_X() const { return m_X; }
        void Set_X(float val) { m_X = val; }
        float Get_Y() const { return m_Y; }
        void Set_Y(float val) { m_Y = val; }
        float Get_Z() const { return m_Z; }
        void Set_Z(float val) { m_Z = val; }
=======
        double Get_X() const { return m_X; }
        void Set_X(double val) { m_X = val; }
        double Get_Y() const { return m_Y; }
        void Set_Y(double val) { m_Y = val; }
        double Get_Z() const { return m_Z; }
        void Set_Z(double val) { m_Z = val; }
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518

        //methodes
        void Affiche();
        bool Est_egal(Point3f pt);

    protected:
    private:
<<<<<<< HEAD
        float m_X;
        float m_Y;
        float m_Z;
=======
        double m_X;
        double m_Y;
        double m_Z;
>>>>>>> 149068ee3d8f20229540571d3a3e0dc42df9b518
};

#endif // POINT3F_H
