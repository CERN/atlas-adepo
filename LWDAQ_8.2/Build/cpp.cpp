/*
	c.cpp
*/

#include <stdio.h>
#include <string.h>
#include <iostream>
#include <fstream>
#include <cstdlib>

using namespace std;

struct xy_point_type{
	double x;
	double y;
};

struct rasnik_type {	
	unsigned char valid;
	char padding[7];
	xy_point_type mask_point;
	double magx;
	double magy;
	double rot;
	double error;
	int mask_orientation;
	int reference_code;
	xy_point_type reference_point;
	double square_size;
	double pixel_size;
};

struct ij_point_type {
  int i;
  int j;
};

struct ij_rectangle_type {
  int top;
  int left;
  int bottom;
  int right;
};

struct rasnik_square_type {
  xy_point_type center_pp;
  double center_intensity;
  double center_whiteness;
  int pivot_correlation;
  int x_code;
  int y_code;
  ij_rectangle_type display_outline;
  unsigned char is_a_valid_square;
  unsigned char is_a_code_square;
  unsigned char is_a_pivot_square;
  char padding[13];
};

struct rasnik_pattern_type {
  unsigned char valid;
  char padding[7];
  xy_point_type origin;
  double rotation;
  double pattern_x_width;
  double pattern_y_width;
  double image_x_width;
  double image_y_width;
  double error;
  int extent;
  int mask_orientation;
  int x_code_direction;
  int y_code_direction;
  ij_point_type analysis_center_cp;
  double analysis_width;
  char *squares;
  char more_padding[4];
};

// Declare external routines in Pascal libraries. We use
// the "C" directive to stop the compiler from adding
// two-level namespace characters to the beginning of the
// external name of each routine.
extern "C" void Analysis_Init();
extern "C" void Hello_World();
extern "C" rasnik_type* Rasnik_Analyze_File(const char *string,
	int orientation_code,
	int reference_code,
	double reference_x,
	double reference_y,
	double square_size_um,
	double pixel_size_um);
extern "C" void Dispose_Rasnik(rasnik_type *rp);
extern "C" rasnik_pattern_type* New_Rasnik_Pattern(void);
extern "C" void Dispose_Rasnik_Pattern(rasnik_pattern_type *pp);

int main (int argc, char **argv, char **envp)
{	
	printf("Main: Hello.\n");
	
	printf("Main: Initialize Pascal library.\n");
	Analysis_Init();
	Hello_World();
	
	// Check that the rasnik_type defined fields have
	// sizes that match the Pascal rasnik_type.
	printf("Main: Check length of data types.\n");
	cout<<"sizeof(rasnik_type) = "<<sizeof(rasnik_type)<<endl;
	cout<<"sizeof(rasnik_pattern_type) = "<<sizeof(rasnik_pattern_type)<<endl;
	cout<<"sizeof(rasnik_square_type) = "<<sizeof(rasnik_square_type)<<endl;


	printf("Main: Analyze rasnik file.\n");

	// A pointer to a rasnik_type.
	rasnik_type *rp;

	// Prompt the user to enter a file name.
	string file_name;
	cout<<"Enter file name, 0 for default: ";
	cin>>file_name;
	if (file_name == "0") {
		file_name="Rasnik.daq";
	}
	
	// We pass the file name to the rasnik analysis. We specify the 
	// rasnik mask and image sensor parameters with numbers.
	cout<<"Opening "<<file_name<<endl;
	rp = Rasnik_Analyze_File(file_name.c_str(),0,2,0,0,170,12);
	
	// Here we look at the fields of the rasnik_type pointed
	// to by rp, and write them to the screen.
	cout<<"Main: Display analysis results."<<endl;
	cout<<"Valid "<<(int)rp->valid<<endl;
	cout<<"Maskpoint x "<<rp->mask_point.x<<" y "<<rp->mask_point.y<<endl;
	cout<<"Mag x "<<rp->magx<<" y "<<rp->magy<<endl;
	cout<<"Rot "<<rp->rot<<endl;
	cout<<"Error "<<rp->error<<endl;
	cout<<"Mask orientation "<<rp->mask_orientation<<endl;
	cout<<"Reference code "<<rp->reference_code<<endl;
	cout<<"Reference point x "<<rp->reference_point.x<<" y "<<rp->reference_point.y<<endl;
	cout<<"Square size "<<rp->square_size<<endl;
	cout<<"Pixel size "<<rp->pixel_size<<endl;
	
	// Dispose of the rasnik_type.
	Dispose_Rasnik(rp);

	// Obtaining a pointer to a new rasnik_pattern_type
	rasnik_pattern_type *pp;
	pp = New_Rasnik_Pattern();

	// Printing out values from rasnik_pattern_type
	cout<<"Main: Values from new, empty rasnik_pattern_type: "<<endl;
	cout<<"Valid "<<(int)pp->valid<<endl;
	cout<<"Origin x "<<pp->origin.x<<" y "<<pp->origin.y<<endl;
	cout<<"Rotation "<<pp->rotation<<endl;
	cout<<"pattern_x_width "<<pp->pattern_x_width<<endl;
	cout<<"pattern_y_width "<<pp->pattern_y_width<<endl;
	cout<<"image_x_width "<<pp->image_x_width<<endl;
	cout<<"image_y_width "<<pp->image_y_width<<endl;
	cout<<"error "<<pp->error<<endl;
	cout<<"extent "<<pp->extent<<endl;
	cout<<"mask_orientation "<<pp->mask_orientation<<endl;
	cout<<"x_code_direction "<<pp->x_code_direction<<endl;
	cout<<"y_code_direction "<<pp->y_code_direction<<endl;
	cout<<"analysis_center_cp i "<<pp->analysis_center_cp.i<<" j "<<pp->analysis_center_cp.j<<endl;
	cout<<"analysis_width "<<pp->analysis_width<<endl;

	// Dispose of the rasnik pattern pointer.
	Dispose_Rasnik_Pattern(pp);
	
    return 0;
}
