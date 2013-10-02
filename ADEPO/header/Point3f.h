#ifndef POINT3F_H
#define POINT3F_H


class Point3f
{
    public:

        //constructeurs et destructeurs
        Point3f();
        Point3f(float X,float Y,float Z);
        virtual ~Point3f();
        Point3f(const Point3f& copie);

        //setter et getter
        float Get_X() const { return m_X; }
        void Set_X(float val) { m_X = val; }
        float Get_Y() const { return m_Y; }
        void Set_Y(float val) { m_Y = val; }
        float Get_Z() const { return m_Z; }
        void Set_Z(float val) { m_Z = val; }

        //methodes
        void Affiche();
        bool Est_egal(Point3f pt);

    protected:
    private:
        float m_X;
        float m_Y;
        float m_Z;
};

#endif // POINT3F_H
