# Read Me First

### OVERVIEW 
This is the C version of spatial_density.pl, which calculates a spatial density or spatial intensity grid (ASCII format) based on a gaussian kernel function using a SAMSE bandwith calculated using the 'ks' package, written by Tarn Duong <tarn.duong at gmail.com> which is a package using the statistical programming language R. 

spatial_density.c (sd) was developed on a linux system (although, the C code is basic and should also run on Windows) and uses a configuration file, spatial_density.conf (default name)

Please, first edit this config file with information about your vent locations and then attempt to run the code. The configuration file is specified on the command line. You may change it's name.

### INSTALL THESE DEPENDENCIES FIRST

#### C COMPILER
A C-code compiler is necessary to compile the code. gcc is free and available for all linux systems; usually installed by the root user. Make sure you have the complete gcc suite of program compilers installed including, 
-  gcc, gcc++

To check if this compiler is installed on your system type:
>gcc -v

#### A garbage collector for C and C++
An improved memory management library is used, The Boehm–Demers–Weiser garbage collector, often known as Boehm GC or simply called, gc. On opensuse, this library is called gc-devel and libgc1. The library is most easily installed via a package manager for your system. For information see: https://www.hboehm.info/gc/index.html

#### R DEPENDENCIES
The R package 'ks' is required.
This package calculates the kernel smoothing bandwith using the SAMSE method by Tarn Duong <tarn.duong at gmail.com>. The 'ks' package will be downloaded, compiled (gcc needs to be installed for this), and installed. The 'ks' package also has some dependencies: R version (≥ 1.4.0), KernSmooth (≥ 2.22), misc3d (≥ 0.4-0), mvtnorm (≥ 1.0-0), rgl (≥ 0.66). The dependent packages are downloaded, compiled and installed automatically.

Additional system libraries MIGHT be required for the 'ks' package. Please watch the screen output for clues and install as necessary. I have installed these packages in OPENSUSE to get the 'rgl' package to compile: libpng16-16/-devel, libpng12-0, libpng16-compat-devel, libX11-6/-devel, libx11-data, libX11-6-32bit, libglut3, freeglut-devel, Mesa/-devel, Mesa-32bit, libGLw-devel, Mesa-libGL1/-devel

The 'ks' package is installed from within a running session of R. Start an R session:
>R

then follow with:

>install.packages("ks", repos="http://cran.r-project.org")

you can choose to let R create/install into a local directory, if you do not have root/admin access.

### Compile the C Code
To compile the code type:
>gcc -Wall -o sd -lm -lgc spatial_density.c


### ADDITIONAL DEPENDENCIES
These next three programs could be installed by the root or admin user or installed locally. Usually if a program is available from a linked linux repository, it is easier to install into the system by a root user, but, it is possible to install these programs locally. Most linux distributions have pre-compiled packages for these programs; check your distribution's packages. 

One way to check if a system package is installed is to use the search command from a package manager (i.e., zypper, yum, apt, etc). For example, OPENSUSE uses the package manager, zypper. To check for the existence of a package installed with zypper, type:
>zypper se package-name

Installed packages will be identified by an 'i' or '+'.

Otherwise, see the corresponding websites for more information:
-  gmt (version 5 or 6, http://gmt.soest.hawaii.edu/projects/gmt/wiki/Installing )
-  Proj (executables, libraries, devel packages, https://proj.org/index.html )
-  R Statistical Programming Environment (R-base, R-devel, etc, https://www.r-project.org )


#### USAGE
To run the compiled spatial density code type:
>./sd spatial_density.conf


### GMT plotting DEPENDENCIES
The PERL script plot_spd.gmt.pl will grid and contour the spatial density output grid file. This plotting package depends
on GMT (which depends on gdal, netcdf, Proj)

The plotting scripts also depends on 2 additional perl packages which can be installed with cpan:
Geo::Coordinates::UTM 
File::Slurp

### TROUBLESHOOTING FAILURE TO GET OUTPUT
If there is no file output then check the file: R-samse.Rout. 
The R-samse file is an R script and the R-samse.Rout file 
provides information about the SAMSE bandwith calculated using 'R'.
Also, check the logfile and the bandwidth.dat file; the bandwidth.dat should not be all zeros. This indicated a problem with executing the 'ks' package.

### PLOTTING CONTOURS AND CREATING IMAGES
The plotting script, plot_spd.gmt.pl, depends on the same spatial_density.conf configuration file.

There are 4 plotting options:
  * Option 0:  No plot.
  * Option 1:  Quartile plot (WGS84/latlon)
  * Option 2:  Log(output) plot (WGS84/lat/lon
  * Option 3:  Quartile plot (UTM/meters)
  * Option 4:  Log(output) plot (UTM/meters)
  
The quartile plots contour the 5%, 16%, 33%, 50%, 67%, 84%, 95%, and 99% contours of spatial density. GMT version 5 needs to be installed in order to run this script. It depends on the same configuration file as the spatial density calculator (above). If the map size is too large or too small, increase (make map smaller) or decrease (make map larger) the MAP_SCALING number in the spatial_density.conf file. This plotting script is called directly from the spatial density.pl script. You can also run just the plotting script directly from the command line using two additional command parameters as follows: 
>perl plot_spd.gmt.pl spatial_density.conf <your spatial denstiy output file>

### TEST 
To run a test example, COPY the sd executable and perl scripts (plot_spd.gmt.pl, convert2log.pl) into the test directory:
>cp sd *.pl test

and then execute in the test directory directory:
./sd nejapa_spatial_density.conf

Spatial density contour plots should be the result. Look for EPS, PNG and PDF images. A colorblind-friendly palette is used for the plots. 

This is just a guide as all linux distributions operate differently. Any questions can be directed to Laura Connor (lconnor@usf.edu) or Charles Connor (cbconnor@usf.edu).
