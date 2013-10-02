more off
clear all
clf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% contrainte sur la distance

l=[x_134 y_134 z_134 x_279 y_279 z_279 x_03 y_03 z_03 x_04 y_04 z_04];	%vecteur des observations

n=length(l);    	%nombres d'observations
r=6;				%nombre d'equations de contraintes
sigma0=0.3;		% sigma a priori
sigma_coord=0.3;	% sigma sur les coordonnees calculees

kll=sigma_coord^2*eye(n,n);

Qll=kll/sigma0^2;

P=inv(Qll);

D_03_04=dist_absolue_03_04_avt;	    %distance vraie
D_03_134=dist_absolue_03_134_avt;	%distance vraie
D_03_279=dist_absolue_03_279_avt;	%distance vraie
D_279_04=dist_absolue_279_04_avt;	%distance vraie
D_134_04=dist_absolue_134_04_avt;	%distance vraie
D_134_279=dist_absolue_134_279_avt;	%distance vraie

 %ecart de fermeture

w=[sqrt((x_03-x_04)^2+(y_03-y_04)^2+(z_03-z_04)^2)-D_03_04;
   sqrt((x_03-x_134)^2+(y_03-y_134)^2+(z_03-z_134)^2)-D_03_134;
   sqrt((x_03-x_279)^2+(y_03-y_279)^2+(z_03-z_279)^2)-D_03_279;
   sqrt((x_279-x_04)^2+(y_279-y_04)^2+(z_279-z_04)^2)-D_279_04;
   sqrt((x_134-x_04)^2+(y_134-y_04)^2+(z_134-z_04)^2)-D_134_04;
   sqrt((x_134-x_279)^2+(y_134-y_279)^2+(z_134-z_279)^2)-D_134_279];
   
%~ w=[sqrt((x_134-x_279)^2+(y_134-y_279)^2+(z_134-z_279)^2)-D_134_279];

%~ disp('---------------UNIT mm')
%~ disp('---------------ecart entre les observations et les distances absolues')
ecart_avant=w*1e3;

frac_03_04=1/sqrt((x_03-x_04)^2+(y_03-y_04)^2+(z_03-z_04)^2);
frac_03_134=1/sqrt((x_03-x_134)^2+(y_03-y_134)^2+(z_03-z_134)^2);
frac_03_279=1/sqrt((x_03-x_279)^2+(y_03-y_279)^2+(z_03-z_279)^2);
frac_279_04=1/sqrt((x_279-x_04)^2+(y_279-y_04)^2+(z_279-z_04)^2);
frac_134_04=1/sqrt((x_134-x_04)^2+(y_134-y_04)^2+(z_134-z_04)^2);
frac_134_279=1/sqrt((x_134-x_279)^2+(y_134-y_279)^2+(z_134-z_279)^2);


%matrice des derivees
G=[0 0 0 0 0 0 (x_03-x_04)*frac_03_04 (y_03-y_04)*frac_03_04 (z_03-z_04)*frac_03_04 (-x_03+x_04)*frac_03_04 (-y_03+y_04)*frac_03_04 (-z_03+z_04)*frac_03_04;
   (-x_03+x_134)*frac_03_134 (-y_03+y_134)*frac_03_134 (-z_03+z_134)*frac_03_134 0 0 0 (x_03-x_134)*frac_03_134 (y_03-y_134)*frac_03_134 (z_03-z_134)*frac_03_134 0 0 0;
   0 0 0 (-x_03+x_279)*frac_03_279 (-y_03+y_279)*frac_03_279 (-z_03+z_279)*frac_03_279 (x_03-x_279)*frac_03_279 (y_03-y_279)*frac_03_279 (z_03-z_279)*frac_03_279 0 0 0;
   0 0 0 (x_279-x_04)*frac_279_04 (y_279-y_04)*frac_279_04 (z_279-z_04)*frac_279_04 0 0 0 (-x_279+x_04)*frac_279_04 (-y_279+y_04)*frac_279_04 (-z_279+z_04)*frac_279_04;
   (x_134-x_04)*frac_134_04 (y_134-y_04)*frac_134_04 (z_134-z_04)*frac_134_04 0 0 0 0 0 0 (-x_134+x_04)*frac_134_04 (-y_134+y_04)*frac_134_04 (-z_134+z_04)*frac_134_04;
   (x_134-x_279)*frac_134_279 (y_134-y_279)*frac_134_279 (z_134-z_279)*frac_134_279 (-x_134+x_279)*frac_134_279 (-y_134+y_279)*frac_134_279 (-z_134+z_279)*frac_134_279 0 0 0 0 0 0];

vect_x_moy=[x_03 x_04 x_134 x_279];
vect_y_moy=[y_03 y_04 y_134 y_279];
x_moy=mean(vect_x_moy);
y_moy=mean(vect_y_moy);

figure(2)
	hold on
	plot((x_03-x_moy)*1e3, (y_03-y_moy)*1e3, '*r','linewidth',3)
	plot((x_04-x_moy)*1e3, (y_04-y_moy)*1e3, '*b','linewidth',3)
	plot((x_134-x_moy)*1e3, (y_134-y_moy)*1e3, '*g','linewidth',3)
	plot((x_279-x_moy)*1e3, (y_279-y_moy)*1e3, '*k','linewidth',3)
for j=1:3
	S=inv(P)*G'*inv(G*inv(P)*G');
	v_estime=S*w; % estimation du vecteur des residus
	l_estime=l-v_estime'; % estimation des observations
	sigma_estime=sqrt(v_estime'*P*v_estime/(n-r));  % sigma estime
	
	for i=1:12
		if(abs(v_estime(i,1)) > sigma0)
		{
			P(i,i)=sigma0*sigma0*4/(v_estime(i,1)^2);
		}

		else
			P(i,i)=1;
		end
	end
end
vect_x_estime_moy=[l_estime(1,7) l_estime(1,10) l_estime(1,1) l_estime(1,4)];
vect_y_estime_moy=[l_estime(1,8) l_estime(1,11) l_estime(1,2) l_estime(1,5)];
x_estime_moy=mean(vect_x_estime_moy);
y_estime_moy=mean(vect_y_estime_moy);

	plot((l_estime(1,7)-x_estime_moy)*1e3, (l_estime(1,8)-y_estime_moy)*1e3, 'xr','linewidth',3)
	plot((l_estime(1,10)-x_estime_moy)*1e3,(l_estime(1,11)-y_estime_moy)*1e3, 'xb','linewidth',3)
	plot((l_estime(1,1)-x_estime_moy)*1e3,(l_estime(1,2)-y_estime_moy)*1e3, 'xg','linewidth',3)
	plot((l_estime(1,4)-x_estime_moy)*1e3,(l_estime(1,5)-y_estime_moy)*1e3, 'xk','linewidth',3)
%~ disp('----------------ecart entre les observations initiales et les observations ajustees en mm')
1e3*(l-l_estime)';	% ecart avec les observations

ecart_apres=[sqrt((l_estime(7)-l_estime(10))^2+(l_estime(8)-l_estime(11))^2+(l_estime(9)-l_estime(12))^2)-D_03_04;
             sqrt((l_estime(7)-l_estime(1))^2+(l_estime(8)-l_estime(2))^2+(l_estime(9)-l_estime(3))^2)-D_03_134;
             sqrt((l_estime(7)-l_estime(4))^2+(l_estime(8)-l_estime(5))^2+(l_estime(9)-l_estime(6))^2)-D_03_279;
             sqrt((l_estime(4)-l_estime(10))^2+(l_estime(5)-l_estime(11))^2+(l_estime(6)-l_estime(12))^2)-D_279_04;
             sqrt((l_estime(1)-l_estime(10))^2+(l_estime(2)-l_estime(11))^2+(l_estime(3)-l_estime(12))^2)-D_134_04;
             sqrt((l_estime(1)-l_estime(4))^2+(l_estime(2)-l_estime(5))^2+(l_estime(3)-l_estime(6))^2)-D_134_279];


