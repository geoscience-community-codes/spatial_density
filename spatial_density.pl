
######################################################################
# This file is part of spatial_density.pl.
#
#    spatial_density.pl is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    spatial_density.pl is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with spatial_density.pl.
#    If not, see <http://www.gnu.org/licenses/>.
######################################################################

# This program requires a configuration file
# usually specified as spatial_density.conf
# The filename is specified on the command line.
# The code is run as: perl spatial_density.pl spatial_density.conf

# The code outputs an X Y Z file formatted as:
# easting northing density_value

# If using opensuse linux, install package perl-PDL using YAST
# then install the perl Linear::Algebra module using cpan
# The Linear::Algebra module requires the blas and lapack libraries
# and their corresponding devel packages to be installed
# (also found as packages in YAST)

# Required: the perl module PDL :: Lite 
#           the perl module PDL::Basic
#           the perl module PDL::MatrixOps
#           the perl module PDL::LinearAlgebra 
# these modules can all be downloaded and installed using CPAN

# If there is no output data then check the file: R-samse.Rout
# The R-samse file is an R script and the R-samse.Rout file
# provides information about
# the SAMSE bandwidth calculated using 'R'

system "date";
# use PDL::Lite; # Is equivalent to the following:
 
# use PDL::Ops '';
#  use PDL::Primitive '';
#  use PDL::Ufunc '';
#  use PDL::Basic '';
#  use PDL::Slices '';
#  use PDL::Bad '';
#  use PDL::Version;

use PDL::Core '';
use PDL::Lvalue;
use PDL::MatrixOps qw(det inv );
use PDL::Basic qw(transpose);
use PDL::LinearAlgebra::Trans qw(msqrt);

# Import constants pi2, pip2, pip4 (2*pi, pi/2, pi/4).
use Math::Trig qw(pi);

# our $pi = pdl(3.1415926535897932384626433832795029);

$pi = pi;

my $args = @ARGV;
if ($args < 1) {
  print "USAGE: perl $0 <file.conf>\n\n";
  exit;
}
open (LOG, ">>logfile") || die ("$!");
print "Opening and appending run info to to: logfile\n";
print LOG "\n Parameters:\n";
open (CONF, "<$ARGV[0]") || die ("$!");
my %P;
my $key;
my $value;
while (<CONF>) {
  if ($_ =~ /^#/ || $_ =~ /^\n/) {}
  else { ($key, $value) = split "=",$_;
  	chomp($value);
	  $P{$key} = $value;
 		print STDERR "$key $value\n";
 		print LOG "$key $value\n";
  }
}
close CONF;
print LOG "\n Calculating spatial density for $P{EVENT_FILE} now ....\n";
my $west = $P{WEST}/1000.0;
my $east = $P{EAST}/1000.0;
my $south = $P{SOUTH}/1000.0;
my $north = $P{NORTH}/1000.0;

my $Grid_spacing = $P{GRID_SPACING}/1000.0;
my $in = $P{EVENT_FILE};
my $out1 = "$in.samse.xyz";
my $plot_dir = $P{PLOT_DIR};
my $plotter = "$plot_dir/plot_spd.gmt.pl";


my $band = $P{BANDWIDTH_FILE};
my $samse = $P{SAMSE};
if ($samse > 0) {
  #FIND BANDWIDTH using SAMSE bandwidth from R #######
  print "\nOptimizing Pilot Bandwidth (SAMSE)\n";
  system "touch bandwidth.dat";
  open KOP, ">R-samse" or die "Cannot create R-script";

  print KOP "library(ks)\n";
  print KOP "vents<-read.table(\"$in\")\n";
  print KOP "bd <- Hpi(x=vents,nstage=2,pilot=\"samse\",pre=\"sphere\", binned=FALSE, amise=FALSE, deriv.order=0, verbose=FALSE,optim.fun=\"nlm\")\n"; #performs samse!
  print KOP "sink(\"$band\")\n"; #designates write-to file
  print KOP "show(bd)\n"; 	#should be 2x2 matrix
  print KOP "sink()\n"; #clears sink
  close KOP;

  `R CMD BATCH R-samse`;
} 
else {
  # Use bandwidth specifiers in config file
  print "\nUsing user-specified smoothing bandwith\n";
  my $x_sm = $P{SMOOTH_X};
  my $y_sm = $P{SMOOTH_Y};
  my $trend = $P{ROTATION};
  $x_sm *= $x_sm;
  $y_sm *= $y_sm;
  if ($trend < 0) {$trend *= -$trend;}
  else {$trend *= $trend;}
  
  my @lines;
  $lines[0] = sprintf("          [,1]      [,2]\n");
  $lines[1] = sprintf("[1,] %d %d\n", $x_sm, $trend);
  $lines[2] = sprintf("[2,] %d %d\n", $trend, $y_sm);
  write_bandwidth($band, \@lines);
}
  

open BW, "<$band" or die "Cannot read bandwidth file $band: $!";
my @line = <BW>;
close BW;
my $i=0;
my @h;
foreach (@line) {
  ($h[$i++], $h[$i++], $h[$i]) = split " ";
  $h[$i-1]/=1e6; $h[$i]/=1e6;
  if ($h[$i-1] != 0) {
    $i++;
  }
}
print "$h[3] $h[4]\n$h[6] $h[7]\n";
# The bandwidth matrix via SAMSE 2-stage 
# pre-transformation 'sphering' R output
# units = square meters
#> bw_samse_vents <- Hpi(x=vents, nstage=2, pilot="samse", pre="sphere", binned=FALSE, amise=FALSE, deriv.order=0, verbose=FALSE,optim.fun="nlm")

#> show(bw_samse_vents)
#         [,1]     [,2]
#[1,] 17702123 -8106069
#[2,] -8106069 19934123

#units = square kilometers
my $H = pdl [
        [ $h[3], $h[4]],
        [$h[6], $h[7]]
];
###############################################################

print LOG "Bandwidth Matrix (units = square kilometers):$H\n";
# The input file of event locations

# Creat output files
open(OUT1, ">$out1") or die("can't open $out1: $!");

# Create array of vent locations
my @vent;
# Load vent locations
my $num_vents = load_file($in, \@vent);
# Calculate spatial density
my $spd = $num_vents;

if ($P{SPD} == 2) { #Calculate spatial intensity
  print LOG "Calculating spatial intensity.\n";
  print STDERR "Calculating spatial intensity.\n";
  $spd = 1; 
}
else {
  print LOG "Calculating spatial density; grid should sum to 1.\n";
  print LOG "Number of vents = $spd\n";
  print STDERR "Calculating spatial density; grid should sum to 1.\n";
  print LOG "Number of vents = $spd\n";
}

# Calculate necessary constants for 
# the Gaussian kernel fuctions:
# square root of the bandwidth matrix
my $sqrtH = msqrt($H);
print LOG "Square Root Matrix:$sqrtH";

# determinant of the bandwidth matrix
my $detH = det($H);
print LOG "Determinant: $detH\n";

my $sqrt_detH = sqrt($detH);
print LOG "sqrt(Determinant): $sqrt_detH\n";

# inverse of the square root matrix
our $sqrtHi = inv($sqrtH);

# our $sqrtHi = inv($H);
print LOG "Inverse of Square Root Matrix:$sqrtHi";

# gaussian constant
#This is to calculate spatial density
# that is dedive by the number of vents.
our $Const = 2.0 * $pi * $sqrt_detH * $spd;
print STDERR "Const: $Const = $sqrt_detH * $spd * 2 * $pi\n";
print LOG "Const: $Const = $sqrt_detH * $spd * 2 * $pi\n";

# Create the spatial intensity grid 
# my @pdf;
my $grid_total = 0;
my $X;
my $Y;
#my $ct = 0;
$X = $west - $Grid_spacing;
do {
    $X += $Grid_spacing;
    $Y = $south - $Grid_spacing;
    do {
      $Y += $Grid_spacing;
      my $pdf = gauss($X, $Y, \@vent, $num_vents);
      # $pdf[$ct]{LAMBDA} = gauss($X, $Y, \@vent, $num_vents);
      # $pdf[$ct]{EAST} = $X;
      # $pdf[$ct]{NORTH} = $Y;
      # print OUT1 "$X $Y $pdf[$ct]{LAMBDA}\n";
      my $XX = $X * 1000.0;
      my $YY = $Y * 1000.0; 
      $pdf *= $Grid_spacing**2;
      if ($pdf > 1.0) {
        print STDERR "$XX \t $YY \t $pdf\n";
      }
      print OUT1 "$XX $YY $pdf\n";
      # $ct++;
      $grid_total += $pdf;
    } while ($Y < $north);
} while ($X < $east);
close OUT1;
close LOG;

print STDERR "Grid totals $grid_total. Finished Calculations.\n";
system "date";
print STDERR "Now plotting ....\n";
$cmd = sprintf ("%s", "perl $plotter $ARGV[0] $out1");
print "$cmd\n";
system "$cmd";

##################################################################
# Function gauss($$$$)
# INPUTS: 
# (1) IN X (meters) current grid location
# (2) IN Y (meters) current grid location
# (3) IN reference to array of volcanic vent locations (meters)
# (4) IN number of vent locations
#
# The funstion uses the following runtime constants:
# (1) $sqrtHi: this is the inverse of the square root 
#     of the (2 x 2)bandwidth matrix
# (2) $Const: this is 2*pi*determinant(H)
# OUTPUTS:
# (1) lambda (i.e. spatial intensity at the current grid location)
####################################################################
sub gauss() {

  my $sum = 0.0; 
  my $x = $_[0];
  my $y = $_[1];
  my $vents = $_[2];
  my $num_vents = $_[3];
  #my $h = 10;
  for (my $i = 0; $i < $num_vents; $i++) { # For each event
      # Get distance from event to grid point
      my $dx = ($x - $vents->[$i]->{EAST});
      my $dy = ($y - $vents->[$i]->{NORTH});
      # my $dist = sqrt($dx * $dx + $dy * $dy);
      #$sum += exp(-0.5 * ($dist/$h)*($dist/$h));
      # convert to matrix
      my $dxdy = pdl [[$dx], [$dy]];
      
      $dxdy = $sqrtHi x $dxdy;
      
      my $Tdxdy = transpose($dxdy);
      
      my $dist = $Tdxdy x $dxdy;
      
      $sum += exp(-0.5 * $dist->sclr);
  }
  my $lambda = $sum/$Const;
  # my $lambda = $sum/(2.0 * $pi * $h * $h * $num_vents);
  return $lambda;
}

#############################################
# INPUTS: 
# (1) IN File name of vent locations
# (2) IN/OUT array of vent locations
# OUTPUTS: 
# (1) Number of data lines in the file
#############################################
sub load_file() {
  
  my $in = $_[0];
  # Open input file of vent locations and create aray
  open(INFO, $in) or die("can't open $in: $!"); 
  my $i = 0;
  while (<INFO>) {
    if (!($_ =~ m/^#/)) {
      chomp;
     ($_[1]->[$i]{EAST}, $_[1]->[$i]{NORTH}) = split " ", $_;
     # Store vent location in km
     $_[1]->[$i]{EAST} /= 1000.0;
     $_[1]->[$i]{NORTH} /= 1000.0;
     print LOG "$i $_[1]->[$i]{EAST}, $_[1]->[$i]{NORTH}\n";
     $i++;    
    }
  }
  close INFO;
 print LOG "Loaded $i vents from $in\n";
 return $i;
}

sub write_bandwidth() {
  
	my $in = $_[0];
	my $lines = $_[1];
	open(BW, ">$in") or die("Cannot read bandwidth file $in: $!");
	
	foreach my $line (@$lines) {
	  print STDERR $line;
	  print BW $line;
	}
	close BW;
	return;
}	
