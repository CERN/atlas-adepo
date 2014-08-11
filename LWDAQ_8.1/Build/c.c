/*
	c.c
*/

#include <stdio.h>
#include <string.h>

struct xy_point_type {
	double x;
	double y;
};

struct rasnik_type {	
	unsigned char valid;
	char padding[7];
	struct xy_point_type mask_point;
	double magx;
	double magy;
	double rot;
	double error;
	int mask_orientation;
	int reference_code;
	struct xy_point_type reference_point;
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
  struct xy_point_type center_pp;
  double center_intensity;
  double center_whiteness;
  int pivot_correlation;
  int x_code;
  int y_code;
  struct ij_rectangle_type display_outline;
  unsigned char is_a_valid_square;
  unsigned char is_a_code_square;
  unsigned char is_a_pivot_square;
  char padding[13];
};

struct rasnik_pattern_type {
  unsigned char valid;
  char padding[7];
  struct xy_point_type origin;
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
  struct ij_point_type analysis_center_cp;
  double analysis_width;
  char *squares;
  char more_padding[4];
};

extern void Analysis_Init();
extern void Hello_World();
extern struct rasnik_type* Rasnik_Analyze_File(const char* string,
	int orientation_code,
	int reference_code,
	double reference_x,
	double reference_y,
	double square_size_um,
	double pixel_size_um);
extern struct rasnik_type* Rasnik_Analyze_Image(char* ip,
	int orientation_code,
	int reference_code,
	double reference_x,
	double reference_y,
	double square_size_um,
	double pixel_size_um);
extern void Dispose_Rasnik(struct rasnik_type* rp);
extern struct rasnik_pattern_type* New_Rasnik_Pattern();
extern void Dispose_Rasnik_Pattern(struct rasnik_pattern_type* pp);
extern char* Read_Daq_File(const char* string);
extern char* Dispose_Image(char* ip);
extern struct rasnik_pattern_type* Rasnik_Find_Pattern(
	char* iip, char* jip, unsigned char show_fitting);
extern void Rasnik_Refine_Pattern(
	struct rasnik_pattern_type* pp,
	char* iip, char* jip, unsigned char show_fitting);
extern void Rasnik_Adjust_Pattern_Parity(char* ip, struct rasnik_pattern_type* pp);
extern void Rasnik_Identify_Pattern_Squares(char* ip, struct rasnik_pattern_type* pp);
extern void Rasnik_Identify_Code_Squares(char* ip, struct rasnik_pattern_type* pp);
extern void Rasnik_Analyze_Code(struct rasnik_pattern_type* pp, int orientation_code);
extern struct rasnik_type* Rasnik_From_Pattern(
	char* ip,
	struct rasnik_pattern_type* pp,
	int reference_code,
	double reference_x,
	double reference_y,
	double square_size_um,
	double pixel_size_um);
extern void Rasnik_Get_Square(
	struct rasnik_square_type* sp,
	char* sap, int a, int b);
extern void Rasnik_Put_Square(
	struct rasnik_square_type* sp,
	char* sap, int a, int b);
extern char* Image_Grad_J(char* ip);
extern char* Image_Grad_I(char* ip);

int main (int argc, char** argv, char** envp)
{	
	printf("Main: Hello.\n");
	
	printf("Main: Initialize Pascal library.\n");
	Analysis_Init();
	Hello_World();
	
	printf("Main: Analyze rasnik file.\n");

	// Read name of image file.
	char file_name[256];
	printf("Enter file name, 0 for default: ");
	scanf("%s",file_name);
	if (strcmp(file_name,"0")==0) {
		strcpy(file_name,"Rasnik.daq");
	
	}
	
	// Declare pointer to rasnik_type;
	struct rasnik_type* rp;
	
	// Now we call the rasnik analysis. We pass a string to 
	// it directly, giving a file name. We specify the rasnik
	// mask and image sensor parameters with numbers.
	printf("Main: Opening %s.\n",file_name);
	
	rp=Rasnik_Analyze_File(file_name,0,2,0,0,170,12);
	
	// Here we look at the fields of the rasnik_type pointed
	// to by rp, and write them to the screen.
	printf("Main: Display rasnik results.\n");
	if (rp->valid) {
		printf("Valid %i.\n",(int) rp->valid);
		printf("Maskpoint x %f y %f.\n",rp->mask_point.x,rp->mask_point.y);
		printf("Magnification x %f y %f.\n",rp->magx,rp->magy);
		printf("Rotation %f.\n",rp->rot);
		printf("Error %f.\n",rp->error);
		printf("Mask orientation %i.\n",rp->mask_orientation);
		printf("Reference code %i.\n",rp->reference_code);
		printf("Reference point x %f y %f.\n",rp->reference_point.x,rp->reference_point.y);
		printf("Square size %f.\n",rp->square_size);
		printf("Pixel size %f.\n",rp->pixel_size);
	} else {
		printf("ERROR: Rasnik analysis failed.\n");
	}
	
	// Now we call the routine that disposes of the rasnik_type.
	Dispose_Rasnik(rp);
	
	// Re-open the rasnik image file and analyze in stages.
	printf("Main: Re-Opening %s.\n",file_name);
	char* ip;
	ip=Read_Daq_File(file_name);
	
	// Create derivative images.
	char* jip;
	jip=Image_Grad_J(ip);
	char* iip;
	iip=Image_Grad_I(ip);
	
	// Find the approximate pattern, pass a zero for
	// the show_fitting parameter to turn off the drawing
	// routines that we won't use.
	struct rasnik_pattern_type* pp;
	pp=Rasnik_Find_Pattern(iip,jip,0);
	
	// Show pattern contents.
	printf("Main: Display approximate pattern.\n");
	printf("Origin x %f y %f.\n",pp->origin.x,pp->origin.y);
	printf("Square Width x %f y %f.\n",pp->pattern_x_width,pp->pattern_y_width);
	printf("Rotation %f.\n",pp->rotation);

	// Refine the pattern.
	Rasnik_Refine_Pattern(pp,iip,jip,0);
	
	// Show pattern contents.
	printf("Main: Display refined pattern.\n");
	printf("Origin x %f y %f.\n",pp->origin.x,pp->origin.y);
	printf("Square Width x %f y %f.\n",pp->pattern_x_width,pp->pattern_y_width);
	printf("Rotation %f.\n",pp->rotation);
	
	// Analyze the code squares.
	Rasnik_Adjust_Pattern_Parity(ip,pp);
	Rasnik_Identify_Pattern_Squares(ip,pp);
	Rasnik_Identify_Code_Squares(ip,pp);
	Rasnik_Analyze_Code(pp,0);
	struct xy_point_type ref;
	rp=Rasnik_From_Pattern(ip,pp,2,0,0,170,12);

	// Display results of analysis by stages.
	printf("Main: Display rasnik results.\n");
	if (rp->valid) {
		printf("Maskpoint x %f y %f.\n",rp->mask_point.x,rp->mask_point.y);
		printf("Magnification x %f y %f.\n",rp->magx,rp->magy);
		printf("Rotation %f.\n",rp->rot);
	} else {
		printf("ERROR: Rasnik analysis failed.\n");
	}

	// Extract a square and show its contents. If you specify
	// the default image, this square will be a pivot square,
	// and so have all fields filled with interesting information.
	printf("Main: Display rasnik square contents.\n");
	struct rasnik_square_type rs;
	Rasnik_Get_Square(&rs,pp->squares,0,0);
	printf("is_a_valid_square? %i\n",(int) rs.is_a_valid_square);
	printf("is_a_code_square? %i\n",(int) rs.is_a_code_square);
	printf("is_a_pivot_square? %i\n",(int) rs.is_a_pivot_square);
	printf("Center Location x %f y %f.\n",rs.center_pp.x,rs.center_pp.y);
	printf("Center Intensity %f.\n",rs.center_intensity);
	printf("Center Whiteness %f.\n",rs.center_whiteness);
	printf("Pivot Correlation %i.\n",rs.pivot_correlation);
	printf("Code x %i y %i.\n",rs.x_code,rs.y_code);

	// Dispose of pointers.
	Dispose_Image(ip);
	Dispose_Image(jip);
	Dispose_Image(iip);
	Dispose_Rasnik_Pattern(pp);
	Dispose_Rasnik(rp);
	
    return 0;
}
