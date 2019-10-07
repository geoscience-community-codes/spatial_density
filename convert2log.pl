# convert2log.pl


######################################################################
#  This file convert2log.pl 
#  is part of the spatial density package from Geoscience Community Codes 
#
#    convert2log.pl is free software: you can redistribute it and/or modify
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
# 
#    Copyright (C) 2014
#    Laura Connor lconnor@usf.edu; ljconnor@gmail.com
######################################################################

# Helper script for plot_spd.gmt.pl
#
# This routine has been updated so that it does not try to compute log of 0.
# 
# Also, a cutoff value is accepted on the commandline. The code will not
# compute the log of any value below the cutoff value.
#
# Last updated: October, 2019
###################################################################
# 
# This script prints out the log of each spatial density value > 0.
# If a cutoff value is spcified on the commandline after the
# file name then values less than the cuttof will be given the
# value of the cutoff. This helps with smoothing out the gmt contouring
# of very small values.
my $cutoff = $ARGV[1];
use File::Slurp;
my @Lines = read_file("$ARGV[0]", chomp => 1); # will chomp() each line
foreach my $line (@Lines){
	($east, $north, $sd) = split " ", $line;
	if ($sd > 0) { $log_sd = log($sd)/log(10);}
	if ($log_sd < $cutoff) {$log_sd = $cutoff}
        my $text = sprintf("%0.2f", $log_sd);
	print "$east $north $text\n";
