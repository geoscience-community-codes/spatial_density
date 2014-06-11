spatial_density
===============

This perl script calculates a spatial density grid (ASCII format) based on a gaussian kernel function using a SAMSE bandwith calculated using R. This program requires a configuration file usually specified as spatial_density.conf
The filename is specified on the command line. To run the script type:
perl spatial_density.pl spatial_density.conf

The script depends on a number of perl modules:
PDL :: Lite
PDL::Basic
PDL::MatrixOps
PDL::LinearAlgebra

These modules can all be downloaded and installed using the perl installation program, cpan

For this script, The PDL::LinearAlgebra depends on the blas and lapack libraries and their corresponding devel packages. Please install these first. Then install the R-base and R-devel packages. If using opensuse these can be installed using YAST. It is also convenient to install perl-PDL with YAST. Then only the PDL::LinearAlgebra module need be installed with cpan. 

The R package 'ks' is also required. This is usually installed from within R (as root) using:
install.packages()

Then just select a download site and the the 'ks' package. It will be downloaded, compiled, and installed. Additional dependencies may be required for this package depending on your linux distribution. Please watch the commandline output for clues and install as necessary.

TROUBLESHOOTING
If there is no output data then check the file: R-samse.Rout
The R-samse file is an R script and the R-samse.Rout 
provides information about
the SAMSE bandwith calculated using 'R'.
