{
	Measure probability of getting more than a threshold number
	of 1's on a mixed selection of die rolls.
}
program p;

uses
	utils;

const
	trials=1000000;
	
var
	i,j:longint;
	count,hits,threshold:longint;
	
begin
	write('threshold? ');
	readln(threshold);
	hits:=0;
	for i:=1 to trials do begin
		count:=0;
		for j:=1 to 6 do if random_0_to_1<=1/6 then inc(count);
		for j:=1 to 3 do if random_0_to_1<=1/8 then inc(count);
		for j:=1 to 2 do if random_0_to_1<=1/10 then inc(count);
		if count>=threshold then inc(hits);
	end;
	writeln('probability = ',hits/trials*100:1:3,' % = 1 in ',trials/hits:1:1);
end.

{
	Test efficiency of string-writing routines. Using writestr to
	append to a long string by writing the long string to itself,
	followed by the new string, we get:

	num_writes time (us)
1 2.0
2 2.4
4 5.0
8 13.3
16 21.6
32 47.6
64 99.0
128 456.8
256 792.8
512 1169.2
1024 2313.9
2048 8222.5
4096 35824.0
8192 165384.2

}
program p;

uses
	utils;
	
const
	num_trials=100;
	
var
	lsp:long_string_ptr;
	i,j,num_writes,k,kk:integer;
	st,et:longint;
	s:short_string;
	
begin
	new(lsp);

	num_writes:=1;
	while num_writes<=10000 do begin
		st:=getmicrosecondtime;

		for j:=1 to num_trials do begin
			lsp^:='';
			for i:=1 to num_writes do begin
				writestr(s,i:1,' ');
				string_append(lsp^,s);
			end;
		end;

		et:=getmicrosecondtime;
		writeln(num_writes:1,' ',(et-st)/num_trials:1:1);
		num_writes:=num_writes*2;
	end;


	dispose(lsp);
end.

{
	Comparison of quick-sort and bubble-sort. 04-FEB-2010
}
program p;

uses
	utils;
	
const
	num_elements=10000000;
	num_trials=1;
	
var
	list,list_copy:array [1..num_elements] of integer;
	n,m:integer;
	st,et:longint;
	
procedure swap(a,b:integer);
var m_saved:integer;
begin
	m_saved:=list[a];
	list[a]:=list[b];
	list[b]:=m_saved;
end;

function greater(a,b:integer):boolean;
begin
	greater:=list[a]>list[b];
end;

begin
	for n:=1 to num_elements do 
		list[n]:=round(random_0_to_1*num_elements);
	list_copy:=list;
	
	st:=getmicrosecondtime;
	
	for m:=1 to num_trials do begin
		list:=list_copy;
		quick_sort(1,num_elements,swap,greater);
	end;
	
	et:=getmicrosecondtime;
	
	writeln('quick_sort: ',
		(et-st)/num_trials:1:1,' us for ',
		num_elements,' elements, ',num_trials, ' trials.');

	st:=getmicrosecondtime;

	for m:=1 to num_trials do begin
		list:=list_copy;
		bubble_sort(1,num_elements,swap,greater);
	end;
	
	et:=getmicrosecondtime;
	
	writeln('bubble_sort: ',
		(et-st)/num_trials:1:1,' us for ',
		num_elements,' elements, ',num_trials, ' trials.');

end.

{
	Benchmark Test of Matrix Inverter, 09-MAY-06, updated 12-MAR-09.
}
program p;

const
	num_repetitions=10000;
	num_random=100;
	
uses utils;

type
	matrix_ptr=^matrix_type;
	
var
	A,B,C:matrix_ptr=nil;
	i,j,k,l,n:integer;
	s:long_string;
	show_matrices:boolean;
	
begin
	track_ptrs:=false;
	show_matrices:=false;
	fsr:=6;
	fsd:=3;
	
	n:=1;
	repeat;
		error_string:='';
		writeln('Calculating for n=',n:1,'...');
		A:=new(matrix_ptr,n,n);
		B:=new(matrix_ptr,n,n);
		C:=new(matrix_ptr,n,n);
		start_timer('start inversions',CurrentRoutineName);
		for l:=1 to num_random do begin
			for j:=1 to n do
				for i:=1 to n do 
					A^[j,i]:=5*random_0_to_1-2.5;
			for k:=1 to round(num_repetitions/num_random) do
				matrix_inverse(A^,B^);
		end;
		mark_time('end inversions',CurrentRoutineName);
		writeln('Done.');

		if show_matrices then begin
			s:='';
			write_matrix(s,A^);
			s:=s+eol;		
			write_matrix(s,B^);		
			s:=s+eol;		
			matrix_product(A^,B^,C^);
			for j:=1 to n do begin
				for i:=1 to n do begin
					if C^[j,i]<small_real then C^[j,i]:=0;
				end;
			end;
			write_matrix(s,C^);
			writeln(s);
		end;
		
		dispose(C);
		dispose(B);
		dispose(A);

		writeln('Inverted ',num_repetitions:1,' times.');
		report_time_marks;
		write('n? ');readln(n);
	until n=0;
end.
{
	Tests rasnik analysis calls from Pascal.
}
program p;

uses
	utils,images,rasnik;
	
var
	name:short_string;
	ip:image_ptr_type;
	rp:rasnik_ptr_type;
	pp:rasnik_pattern_ptr_type;
	
begin
	name:='../Images/Rasnik_bad_bounds.daq';

	writeln('Reading image "',name,'".');
	ip:=read_daq_file(name);

	with ip^ do begin
		writeln('Size = ',sizeof(intensity):1);
		writeln('Width = ',i_size:1);
		writeln('Height = ',j_size:1);
	end;
	with ip^.analysis_bounds do begin
		writeln('Bounds = (',left:1,' ',top:1,' ',right:1,' ',bottom:1,')');
	end;
	rp:=rasnik_analyze_image(ip,0,2,0,0,120,10);
	writeln(string_from_rasnik(rp));
	dispose_rasnik(rp);

	with ip^.analysis_bounds do begin
		left:=180;
		top:=4;
		bottom:=240;
		right:=340;
		writeln('Bounds = (',left:1,' ',top:1,' ',right:1,' ',bottom:1,')');
	end;
	rp:=rasnik_analyze_image(ip,0,2,0,0,120,10);
	writeln(string_from_rasnik(rp));
	dispose_rasnik(rp);

	dispose_image(ip);
end.


{
	Demonstrates our simplex fitting routine on a simple two-minimum
	multi-dimensional error function. 01-MAR-09
}
program p;

uses
	utils;	

const
	num_parameters=10;
	random_scale=1;
	

function disturb:real;
begin disturb:=random_scale*(random_0_to_1-0.5); end;

function error(v:simplex_vertex_type):real;
var
	sum1,sum2:real;
	i:integer;
begin
	sum1:=0;
	for i:=1 to v.n do sum1:=sum1+sqr(v[i]-i);
	sum2:=0;
	for i:=1 to v.n do sum2:=sum2+sqr(v[i]+i);
	error:=sum1*sum2;
end;

var 
	i,j:integer;
	simplex:simplex_type(num_parameters);
	done:boolean;
	
begin
	fsd:=3;
	fsr:=6;

	with simplex do begin
		for i:=1 to n do vertices[1,i]:=disturb;
		construct_size:=random_scale/10;
		done_counter:=0;
		max_done_counter:=5;
	end;
	simplex_construct(simplex,error);	
	
	done:=false;
	i:=0;
	while not done do begin
		inc(i);
		simplex_step(simplex,error);
		done:=(simplex.done_counter>simplex.max_done_counter);
		if (i mod 100 = 0) or done then begin
			write(i:5,' ');
			for j:=1 to simplex.n do write(simplex.vertices[1,j]:fsr:fsd,' ');
			writeln(error(simplex.vertices[1]):fsr:fsd,' ',
			simplex_size(simplex):fsr);
		end;
	end;
end.

{
	This program implements a cyclic redundancey check.
}
program p;

const
	n=5;
	
var 
	data:string[255];
	bit:boolean;
	register:array[0..n] of boolean;
	polynomial:array[0..n] of boolean;
	index:integer;
	saved:boolean;
	
begin
	polynomial[0]:=true;
	polynomial[1]:=false;
	polynomial[2]:=true;
	polynomial[3]:=false;
	polynomial[4]:=false;
	polynomial[5]:=true;
	
	for index:=1 to n do register[index]:=false;
	
	write('Data: ');
	readln(data);
	
	while length(data)>0 do begin
		register[0]:=data[1]='1';
 
		write(data,' ');

		saved:=register[n];
		for index:=n downto 1 do
			register[index]:=register[index-1] xor (saved and polynomial[index-1]);

		for index:=n downto 1 do 
			if register[index] then write('1') else write('0');
		writeln;

		delete(data,1,1);
	end;
end.

{
	Compare xyz_matrix_inverse and matrix_inverse, 03-MAY-06
	
	This test shows up the fact that the determinant calculated by
	matrix_inverse is sometimes of the wrong sine, even though the
	inverse matrices always agree exactly.
}
program p;

uses utils;

const
	n=num_xyz_dimensions;

var
	A,B:matrix_ptr;
	M,P:xyz_matrix_type;
	i,j,num_rows,num_columns:integer;
	s:long_string;
	
begin
	track_ptrs:=false;
	fsr:=9;
	fsd:=6;
		
	A:=new_matrix(n,n);
	for j:=1 to n do begin
		for i:=1 to n do begin
			if (i=j) or (random_0_to_1>0.8) then 
				A^[j,i]:=5*random_0_to_1-2.5
			else 
				A^[j,i]:=0;	
			M[j,i]:=A^[j,i];
		end;
	end;		
	
	B:=matrix_inverse(A);

	write_matrix(s,A);
	writeln(s);		

	writeln('Rank(A) = ',matrix_rank:1);
	writeln('Determinant(A) = ',matrix_determinant:1:3);
	write_matrix(s,B);
	writeln(s);
	
	P:=xyz_matrix_inverse(M);
	writeln('Rank(A) = ',matrix_rank:1);
	writeln('Determinant(A) = ',matrix_determinant:1:3);
	for j:=1 to n do begin
		for i:=1 to n do begin
			write(P[j,i]:fsr:fsd,' ');
		end;
		writeln;
	end;		
		
	
	dispose_matrix(B);
	dispose_matrix(A);
	
end.

{
	Self-Consistency Test of Matrix Inverter, 03-MAY-06.
	Updated 08-MAY-06: matrix inverse takes only square matrices.
	
	Here we make sure that the inverter works, by multiplying its
	output by its input, and looking to see if we get a unit matrix.
	We can give it asymmetrical matrices too, and see if the way it
	handles over- and under-determined sets of linear equations works
	as advertised in the matrix_inverse comments.
}
program p;

uses utils;

var
	A,B,C:matrix_ptr;
	i,j,num_rows:integer;
	s:long_string;
	
begin
	track_ptrs:=false;
	fsr:=6;
	fsd:=3;
	
	write('num_rows? ');readln(num_rows);
	
	A:=new_matrix(num_rows,num_rows);
	for j:=1 to num_rows do begin
		for i:=1 to num_rows do begin
			A^[j,i]:=5*random_0_to_1-2.5;
		end;
	end;		

	write_matrix(s,A);
	writeln(s);		
	
	B:=matrix_inverse(A);

	write_matrix(s,B);
	writeln(s);
	
	C:=matrix_product(B,A);
	for j:=1 to C^.num_rows do begin
		for i:=1 to C^.num_rows do begin
			if abs(C^[j,i])<0.0001 then
				C^[j,i]:=0;
		end;
	end;		
	write_matrix(s,C);
	writeln(s);

	dispose_matrix(C);	
	dispose_matrix(B);
	dispose_matrix(A);
	
	writeln('Rank(A) = ',matrix_rank:1);
	writeln('Determinant(A) = ',matrix_determinant:1:3);
end.

{
	Long Guide Tube station location calculator. 03-MAY-12 Here is an
	application of our simplex fitter to the arrangement of lenses, masks, and
	ccds in our long guide tube. We have six stations along the tube. At either
	end there are two image sensors. Thease are stations 1 and 6. Stations 2 and
	5 are lenses only. Stations 3 and 4 each contain two masks facing in
	opposite directions and a lens. The lens on 3 focuses an image of a mask on
	4 onto one of the sensors on 1. The lense on 2 focuses an image of a mask on
	3 onto the second sensor on 1. The other side is the same. We want the
	arrangement to give perfect focus of the masks, to be symmetric about the
	mid- point of the tube, and for stations 1 and 6 to be a particular distance
	apart.
}
program p;

uses
	utils;
	
const
	num_parameters=5;
	max_num_shrinks=5;
	f2=709.5;
	f3=918.5;
	f4=930.8;
	f5=737.4;
	sep=7124;
	
	
function error(v:simplex_vertex_type):real;
var
	sum:real;
begin
	sum:=
		0.1*sqr(v[1]+v[2]+v[3]+v[4]+v[5]-sep) +
		sqr(v[1]-v[5]) +
		sqr(v[2]-v[4]) +
		sqr(1/(1/f2-1/v[1])-v[2]) +
		sqr(1/(1/f3-1/(v[1]+v[2]))-v[3]) +
		sqr(1/(1/f4-1/(v[4]+v[5]))-v[3]) +
		sqr(1/(1/f5-1/v[4])-v[5]);
	error:=sqrt(sum/7);
end;

var 
	simplex:simplex_type(num_parameters);
	done:boolean;
	i:integer;
	sum:real;
	
begin
	fsd:=3;
	fsr:=6;

	with simplex do begin
		vertices[1,1]:=1000+50*random_0_to_1;
		vertices[1,2]:=1000+50*random_0_to_1;
		vertices[1,3]:=1000+50*random_0_to_1;
		vertices[1,4]:=1000+50*random_0_to_1;
		vertices[1,5]:=1000+50*random_0_to_1;
		construct_size:=100;
		done_counter:=0;
		max_done_counter:=10;
	end;
	simplex_construct(simplex,error);	
	done:=false;
	i:=0;
	while not done do begin
		if (i mod 10 = 0) or done then begin
			with simplex do begin
				writeln(i:5,' ',
					vertices[1,1]:fsr:fsd,' ',
					vertices[1,2]:fsr:fsd,' ',
					vertices[1,3]:fsr:fsd,' ',
					vertices[1,4]:fsr:fsd,' ',
					vertices[1,5]:fsr:fsd,' ',
					error(simplex.vertices[1]):fsr:fsd);
			end;
		end;
		inc(i);
		simplex_step(simplex,error);
		done:=(simplex.done_counter>=simplex.max_done_counter);
	end;
	sum:=0;
	writeln(0.0:fsr:fsd);
	for i:=1 to 5 do begin
		sum:=sum+simplex.vertices[1,i];
		writeln(sum:fsr:fsd);
	end;
end.

{
	Crystal Diode Response 03-MAY-12. We integrate exp(a*sin(x)) numerically so as
	to obtain the rectification response of a crystal diode.
}
program p;

const
	dt=0.001;
	pi=3.141592654;
	a_scale=1.1;
	a_min=0.0001;
	a_max=10.000000;
	vT=0.0271;
	fsd=10;
	fsr=1;
	
var 
	i:integer;
	integral:real;
	a,y,t:real;
	
begin
	a:=a_min;
	while a<=a_max do begin
		integral:=0;
		t:=0;
		while t<=1.0 do begin
			integral:=integral+exp(a*sin(2*pi*t)/vT)*dt;
			t:=t+dt;
		end;
		y:=vT*ln(integral);
		
		
		writeln(a:fsr:fsd,' ',y:fsr:fsd);
		a:=a_scale*a;
	end;
end.

