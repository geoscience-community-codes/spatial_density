# Read Me First

### OVERVIEW 
This perl script calculates a spatial density or spatial intensity grid (ASCII format) based on a gaussian kernel function using a SAMSE bandwith calculated using the 'ks' package, written by Tarn Duong <tarn.duong at gmail.com> which is a package using the statistical programming language R. 

### USAGE  
spatial_density.pl runs on linux systems and uses a configuration file: spatial_density.conf (default name)
Please edit this config file first with information about your vent locations and then attempt to run the script. The configuration file is specified on the command line. To run the script type:

>perl spatial_density.pl spatial_density.conf

Successfull script execution depends on first installing some perl packages, R packages, and some additional programs and libraries. One way to check if a system package is installed is to use the search command from a package manager (i.e., zypper, yum, apt, etc). For example, OPENSUSE uses the package manager, zypper. To check for the existence of a package installed with zypper, type:
>zypper se package-name

Installed packages will be identified by an 'i' or '+'.

#### INSTALL THESE DEPENDENCIES FIRST
A C-code and fortran code compiler are necessary to compile codes. These are usually installed by the admin or root user and available to all users. These are free and available for all linux systems. Make sure you have the complete gcc suite of program compilers installed including, 
-  gcc, gcc++, gfortran

To check if these compilers are installed on your system type:
>gcc -v

>gfortran -v

Some specialized linear algebra libraries are also needed. These libraries have been optimized for speed. These are usually installed by an admin or root user. 
-  blas, lapack, lapacke, armadillo, quadmath  

Use a package manager to check for their existence. Also have the corresponding devel packages installed.

These next three programs could be installed by the root or admin user or installed locally. Usually if a program is available from a linked linux repository, it is easier to install into the system by a root user, but, it is possible to install these programs locally. Most linux distributions have pre-compiled packages for these programs; check your distribution's packages. Otherwise, see these corresponding websites for more information:
-  gmt (version 5, http://gmt.soest.hawaii.edu/projects/gmt/wiki/Installing )
-  Proj/Proj4 (executables, libraries, devel packages, https://live.osgeo.org/en/overview/proj4_overview.html )
-  R Statistical Programming Environment (R-base, R-devel, etc, https://www.r-project.org )

The following additional dependencies can be installed locally into your home directory.

### perl script DEPENDENCIES 
The script depends on a number of perl modules:
  * PDL::Lite
  * PDL::Core
  * PDL::MatrixOps
  * PDL::Basic
  * PDL::LinearAlgebra

These modules can be downloaded and installed using the perl installation program:
>cpan

To install these modules locally (non-root):

  choose the cpan configuration option: local:lib

Once cpan is configured attempt to install each PDL module, individually. 
>cpan> install PDL::Lite

This installation might fail initally, if some dependencies are missing. Keep careful watch of the output for clues for missing system libraries or other perl packages. The failure message is usually near the end of the output. Required perl packages are often installed automatically. If a system library is needed, install this library and then retry the cpan installation. Sometimes, it is necessay to type:
>cpan> clean module-name
  
before trying to install a second time. This installation could take a long time if you have never installed any packages using cpan. A '?' at the cpan prompt gives the cpan help menu: 
>cpan> ?

### R DEPENDENCIES
The R package 'ks' is required.
This package calculates the kernel smoothing bandwith using the SAMSE method by Tarn Duong <tarn.duong at gmail.com>. The 'ks' package will be downloaded, compiled (gcc needs to be installed for this), and installed. The 'ks' package also has some dependencies: R version (≥ 1.4.0), KernSmooth (≥ 2.22), misc3d (≥ 0.4-0), mvtnorm (≥ 1.0-0), rgl (≥ 0.66). The dependent packages are downloaded, compiled and installed automatically.

Additional system libraries MIGHT be required for the 'ks' package. Please watch the screen output for clues and install as necessary. I have installed these packages in OPENSUSE to get the 'rgl' package to compile: libpng16-16/-devel, libpng12-0, libpng16-compat-devel, libX11-6/-devel, libx11-data, libX11-6-32bit, libglut3, freeglut-devel, Mesa/-devel, Mesa-32bit, libGLw-devel, Mesa-libGL1/-devel

The 'ks' package is installed from within a running session of R. Start an R session:
>R

then follow with:

>install.packages("ks", repos="http://cran.r-project.org")

then choose to let R create/install into a local directory.

### GMT plotting DEPENDENCIES
The PERL script plot_spd.gmt.pl will grid and contour the spatial density output grid file. This plotting package depends
on GMT (which depends on gdal, netcdf, Proj/Proj4)

The plotting scripts depend on 2 additional perl packages which can be installed with cpan:
Geo::Proj4 (this requires Proj4, its libs, programs, and devel files)
File::Slurp

### TROUBLESHOOTING FAILURE TO GET OUTPUT
If there is no file output then check the file: R-samse.Rout. 
The R-samse file is an R script and the R-samse.Rout file 
provides information about the SAMSE bandwith calculated using 'R'.
Also, check the logfile and the bandwidth.dat file; the bandwidth.dat should not be all zeros. This indicated a problem with executing the 'ks' package.

### PLOTTING CONTOURS AND CREATING IMAGES
The plotting script, plot_spd.gmt.pl, depends on the same spatial_density.conf configuration file.

There are 4 plotting options:
  * Option 0: No plot.
  * Option 1:  Quartile plot (WGS84/latlon)
  * Option 2:  Log(output) plot (WGS84/lat/lon
  * Option 3:  Quartile plot (UTM/meters)
  * Option 4:  Log(output) plot (UTM/meters)
  
The quartile plots contour the 5%, 16%, 33%, 50%, 67%, 84%, 95%, and 99% contours of spatial density. GMT version 5 needs to be installed in order to run this script. It depends on the same configuration file as the spatial density calculator (above). If the map size is too large or too small, increase (make map smaller) or decrease (make map larger) the MAP_SCALING number in the spatial_density.conf file. This plotting script is called directly from the spatial density.pl script. You can also run just the plotting script directly from the command line using two additional command parameters as follows: 
>perl plot_spd.gmt.pl spatial_density.conf <your spatial denstiy output file>

### TEST 
To run a test example, COPY the perl scripts (spatial_density.pl, plot_spd.pl, convert2log.pl) into the test directory:
>cp *.pl test

and then execute in the test directory directory:
>perl spatial_density.pl nejapa_spatial_density.conf

Spatial density contour plots should be the result. Look for EPS, PNG and PDF images.

This is just a guide as all linux distributions operate differently. Any questions can be directed to Laura Connor (lconnor@usf.edu) or Charles Connor (cbconnor@usf.edu).
