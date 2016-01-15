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
use PDL::Lite;	
use PDL::MatrixOps qw(det inv );
use PDL::Basic qw(transpose);
use PDL::LinearAlgebra::Trans qw(msqrt);

$pi = pdl(3.1415926535897932384626433832795029);


my $args = @ARGV;
if ($args < 1) {
  print "USAGE: perl $0 <file.conf>\n\n";
  exit;
}
open (LOG, ">>logfile") || die ("$!");
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
my $west = $P{WEST};
my $east = $P{EAST};
my $south = $P{SOUTH};
my $north = $P{NORTH};

my $Grid_spacing = $P{GRID_SPACING};
my $in = $P{EVENT_FILE};
my $out1 = "$in.samse.xyz";

# SAMSE bandwidth from R
my $band = $P{BANDWIDTH_FILE};
#FIND BANDWIDTH##################
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

open BW, "<$band" or die "Cannot read bandwidth file $band: $!";
my @line = <BW>;
close BW;
my $i=0;
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
#Calculate spatial intensity
if ($P{SPD} == 2) { $spd = 1; }

# Calculate necessary constants for 
# the Gaussian kernel fuctions:
# square root of the bandwidth matrix
$sqrtH = msqrt($H);
print LOG "Square Root Matrix:$sqrtH";
# determinant of the bandwidth matrix
$detH = det($sqrtH);
print LOG "Determinant: $detH\n";
# inverse of the square root matrix
$sqrtH = inv($sqrtH);
# gaussian constant
#This is to calculate spatial density
# that is dedive by the number of vents.
$Const = 2.0 * $pi * $detH * $spd;

# Create the spatial intensity grid 
# my @pdf;
my $pdf;
my $X;
my $Y;
#my $ct = 0;
$X = $west - $Grid_spacing;
do {
    $X += $Grid_spacing;
    $Y = $south - $Grid_spacing;
    do {
      $Y += $Grid_spacing;
      $pdf = gauss($X, $Y, \@vent, $num_vents);
      #$pdf[$ct]{LAMBDA} = gauss($X, $Y, \@vent, $num_vents);
      #$pdf[$ct]{EAST} = $X;
      #$pdf[$ct]{NORTH} = $Y;
      #print OUT1 "$X $Y $pdf[$ct]{LAMBDA}\n"; 
      print OUT1 "$X $Y $pdf\n";
      $ct++;
    } while ($Y < $north);
} while ($X < $east);
close OUT1;
close LOG;
print STDERR "DOne\n";
system "date";
print STDERR "Grid calculated; now plotting ....\n";
$cmd = sprintf ("%s", "perl plot_spd.gmt.pl $ARGV[0] $out1");
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
# (1) $sqrtH: this is the inverse of the square root 
#     of the (2 x 2)bandwidth matrix
# (2) $Const: this is 2*pi*determinant(H)
# OUTPUTS:
# (1) lambda (i.e. spatial intensity at the current grid location)
####################################################################
sub gauss() {

  my $i, my $dx, my $dy, my $dist, my $dxdy, my $Tdxdy;
  my $sum = 0.0; 
  my $x = $_[0];
  my $y = $_[1];
  my $vents = $_[2];
  my $num_vents = $_[3];
  for ($i = 0; $i <= $num_vents; $i++) { # For each event
      # Change distance (vent to grid) to km
      # Get distance from event to grid point
      $dx = ($x - $vents->[$i]->{EAST})/1000.0;
      $dy = ($y - $vents->[$i]->{NORTH})/1000.0;      
      # convert to matrix
      $dxdy = pdl [[$dx], [$dy],];      
      $dxdy = $sqrtH x $dxdy;
      $Tdxdy = transpose($dxdy);
      $dist = $Tdxdy x $dxdy;
      $sum += exp(-0.5 * $dist->sclr);
  }
  my $lambda = $sum/$Const;
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
  open(INFO, $in) || die("can't open $in: $!"); 
  my $i = 0;
  while (<INFO>) {
    if (!($_ =~ m/^#/)) {
      chomp;
     ($_[1]->[$i]{EAST}, $_[1]->[$i]{NORTH}) = split " ", $_;
     $i++;    
    }
  }
  close INFO;
 print LOG "Loaded input vents: $in, $i lines\n";
 return $i;
}
