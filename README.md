# Read Me First

### OVERVIEW: 
This perl script calculates a spatial density or spatial intensity grid (ASCII format) based on a gaussian kernel function using a SAMSE bandwith calculated using the 'ks' package, written by Tarn Duong <tarn.duong at gmail.com> which is a package using the statistical programming language R. 

### USAGE:  
This spatial density program requires a configuration file: spatial_density.conf (default)
Please edit this file first and then attempt to run the script.
The filename is specified on the command line. To run the script type:
perl spatial_density.pl spatial_density.conf

### DEPENDENCIES:  
The script depends on a number of perl modules:
PDL::Lite
PDL::Core
PDL::MatrixOps
PDL::Basic
PDL::LinearAlgebra

These modules can be downloaded and installed using the perl installation program, 'cpan'.
To install these modules locally (non-root):
choose the cpan configuration option: local:lib

>install PDL::Lite 
etc...

This installation could take a long time if you have never installed any packages using cpan.

#### INSTALL THESE DEPENDENCIES FIRST
The PDL::LinearAlgebra package has some library dependencies (these are the opensuse package names):
gcc/g++/gfortran ('C' compiler and any associated dependencies)
blas3/-devel
lapack/lapacke
lapack-devel/lapacke-devel
atlas/-devel (or armadillo/-devel)

After installing the perl packages, install the 'R' system (these are the opensuse package names):
R-base/-devel

The R package 'ks' is required.
This package calculates the kernel smoothing bandwith using the SAMSE method by Tarn Duong <tarn.duong at gmail.com>. Install this package from within R (locally, non-root):

>install.packages("ks", repos="http://cran.r-project.org")

then choose to let R create/install into a local directory

The 'ks' package will be downloaded, compiled (gcc needs to be installed), and installed. The 'ks' package also has some dependencies: R version (≥ 1.4.0), KernSmooth (≥ 2.22), misc3d (≥ 0.4-0), mvtnorm (≥ 1.0-0), rgl (≥ 0.66). This are downloaded, compiled and installed automatically.

Additional packages may be required for the R-installation. Please watch the commandline output for clues and install as necessary. I have installed these packages to get the 'rgl' package to compile: 
libpng16-16/-devel
libpng12-0
libpng16-compat-devel
libX11-6/-devel
libx11-data
libX11-6-32bit
libglut3
freeglut-devel
Mesa/-devel
Mesa-32bit
libGLw-devel
Mesa-libGL1/-devel

### TROUBLESHOOTING:  
If there is no file output then check the file: R-samse.Rout
The R-samse file is an R script and the R-samse.Rout 
provides information about the SAMSE bandwith calculated using 'R'.
Also, check the logfile. Check the bandwidth.dat file; the bandwidth should not be all zeros. This indicated a problem with the ks package.

### PLOT CONTOURS:  
The PERL script plot_spd.gmt.pl will grid and contour the spatial density output grid file. This plotting package depends
on gmt (which depends on gdal, netcdf, proj4)

The plotting scripts depend on 2 additional perl packages which can be installed with cpan:
Geo::Proj4 (first install Proj4, its libs, programs, and devel files)
File::Slurp

This script has 4 plotting options:
Option 0: No plot.
Option 1:  Quartile plot (WGS84/latlon)
Option 2:  Log(output) plot (WGS84/lat/lon
Option 3:  Quartile plot (UTM/meters)
Option 4:  Log(output) plot (UTM/meters)
The quartile plots contour the 5%, 16%, 33%, 50%, 67%, 84%, 95%, and 99% contours of spatial density. GMT version 5 needs to be installed in order to run this script. It depends on the same configuration file as the spatial density calculator (above). If the map size is too large or too small, increase (make map smaller) or decrease (make map larger) the MAP_SCALING number in the spatial_density.conf file. This plotting script is called directly from the spatial density.pl script. You can also run just the plotting script directly from the command line using two additional command parameters: 

>perl plot_spd.gmt.pl spatial_density.conf <your spatial denstiy output file>

### TEST 
To run a test example, copy the perl scripts (spatial_density.pl, plot_spd.pl, convert2log.pl) into the test directory
and then run in that directory:

>perl spatial_density.pl nejapa_spatial_density.conf

Spatial density contour plots should be the result. Look for EPS, PNG and PDF images.
