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

my $cutoff = $ARGV[1];
use File::Slurp;
my @Lines = read_file("$ARGV[0]", chomp => 1); # will chomp() each line
foreach my $line (@Lines){
	($east, $north, $sd) = split " ", $line;
	if ($sd > 0) { $log_sd = log($sd)/log(10);}
	if ($log_sd < $cutoff) {$log_sd = $cutoff}
        my $text = sprintf("%0.2f", $log_sd);
	print "$east $north $text\n";

}
