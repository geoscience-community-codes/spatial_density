# plot_spd.gmt.pl

######################################################################
#  This file plot_spd.gmt.pl
#  is part of the spatial density package from Geoscience Community Codes 
#
#    plot_spd.gmt.pl is free software: you can redistribute it and/or modify
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
#    Copyright (C) 2010
#    Laura Connor
######################################################################

# This perl script uses GMT (Generic Mapping Tools) and Proj4
# to contour the spatial density grid values from spatial_density.pl
# and produce map images (PNG and PDF and ESP formats). 
#
# This script is called directly from spatial_density.pl
# and reads parameter options from the config file:
# spatial_density.conf (default) 
#
# This script uses the perl package Geo::Proj4 which
# can be downloaded and installed using the program:
# cpan
#
# This script expects 2 commandline parameters:
# 	config_file 
# 	spatial_density_grid_file (format = X(m)  Y(m)  Z)
# 
# See USAGE statement below.
#
# Laura Connor (lconnor@usf.edu; ljconnor@gmail.com) 
# Last updated: October, 2019
# ###############################################################

use Geo::Proj4;

my $args = @ARGV;
if ($args < 1) {
  print qq(USAGE: perl $0 <yourfile.conf> <XYZ_spatial_density_file>\n\n);
  exit;
}
open (LOG, ">>logfile") || die ("$!");
print STDERR "Logging run info to: logfile\n";
open (CONF, "<$ARGV[0]") || die ("$!");
my %P;
my $key;
my $value;
while (<CONF>) {
  if ($_ =~ /^#/ || $_ =~ /^\n/) {}
  else { ($key, $value) = split "=",$_;
  	chomp($value);
	 $P{$key} = $value;
     print STDERR qq($key $value\n);
  }
}
close CONF;

my $in = $ARGV[1];
my $events = $P{EVENT_FILE};
my $aoi = $P{AOI_FILE};
my $utm_west = $P{WEST};
my $utm_east = $P{EAST};
my $utm_south = $P{SOUTH};
my $utm_north = $P{NORTH};
my $utm_zone = $P{UTM_ZONE};
my $grid_spacing = $P{GRID_SPACING};
my $plot = $P{PLOT};
my $plot_dir = $P{PLOT_DIR};
my $map_scale = $P{MAP_SCALE};
my $scale = qq(1:$map_scale).qq(m);
my $res = 300;
my $title = qq($P{MAP_TITLE});
my $float = "";

if ($plot == 0) {
	print STDERR qq(Done!\n);
	exit(0);
}

my $contours = qq(contours);
my $cpt = qq(colors.cpt);

open(CONTOURS, ">$contours") || die("can't open $contours: $!");
open(CPT, ">$cpt") || die("cannot open $cpt: $!");
print LOG "\n Plotting spatial density contours .....\n";
my $ct=0;
my $data_sum = 0;

if ($plot == 1 or $plot == 3) { #Spatial density quartiles (5% 16% 33% 50% 67% 84% 95% 99%
	print LOG qq(Opening $in\n);
	open(IN, "<$in") || die("can't open $in: $!");
	while (<IN>) {
		 ($e, $n, $data[$ct]) = split " ", $_;
		 $data_sum += $data[$ct++];
	}
	@data_s = sort{$b <=> $a} @data;
	 my $num = @data_s;
	 print LOG qq(Sorted $num items.\n);

	my $sum = 0;
	$ct = 0;

	while ($sum < ($data_sum*.05) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q05 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.16) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q15 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.33) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q33 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.5) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q5 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.67) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q67 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.84) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q84 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.95) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q95 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.99) ) {
		$sum += $data_s[$ct++];
	}
	print LOG qq($data_s[$ct-1]\n);
	printf CONTOURS qq($data_s[$ct-1]\n);
	$q99 = $data_s[$ct-1];

	print CPT qq(#\tcpt file created by: $0\n);
	print CPT qq(#Color_MODEL = RGB\n);
	print CPT qq(#\n);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q99, qq(255/255/204), $q95, qq(255/255/204);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q95, qq(255/237/160), $q84, qq(255/237/160);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q84, qq(254/217/118), $q67, qq(254/217/118);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q67, qq(254/178/76), $q5, qq(254/178/76);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q5, qq(253/141/60), $q33, qq(253/141/60);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q33, qq(252/78/42), $q15, qq(252/78/42);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q15, qq(227/26/28), $q05, qq(227/26/28);
	printf CPT qq(%e\t%s\n), $q05, qq(177/0/38\t1\t177/0/38);
	printf CPT qq(%s\n),qq(B\t255/255/255);
	printf CPT qq(%s\n), qq(F\t0/0/0);
	printf CPT qq(%s\n), qq(N\t128/128/128);
}

elsif ($plot == 2 or $plot == 4) { #Log(spatial density)

	print LOG qq(opening $in; writing to $in.log\n);
	system qq(perl convert2log.pl $in > $in.log);

	$in = qq($in.log);
	sleep(2);
	
	print LOG qq(-1\n);
	print CONTOURS qq(-1 A\n);
	print LOG qq(-2\n);
	print CONTOURS qq(-2 A\n);
	print LOG qq(-3 a\n);
	print CONTOURS qq(-3 A\n);
	print LOG qq(-4\n);
	print CONTOURS qq(-4 A\n);
	print LOG qq(-5\n);
	print CONTOURS qq(-5 A\n);
	print LOG qq(-6\n);
	print CONTOURS qq(-6 A\n);
	print LOG qq(-7\n);
	print CONTOURS qq(-7 A\n);
	print LOG qq(-8\n);
	print CONTOURS qq(-8 A\n);
	
	printf CPT qq(%s\n\n), qq(# Spatial Density colormap\n# COLOR_MODEL = RGB);
	print CPT qq(#\tcpt file created by: $0\n);
	print CPT qq(#Color_MODEL = RGB\n);
	print CPT qq(#\n);
	printf CPT qq(%e\t%s\t%e\t%s\n), -8, qq(255/255/204), -7, qq(255/255/204);
	printf CPT qq(%e\t%s\t%e\t%s\n), -7, qq(255/237/160), -6, qq(255/237/160);
	printf CPT qq(%e\t%s\t%e\t%s\n), -6, qq(254/217/118), -5, qq(254/217/118);
	printf CPT qq(%e\t%s\t%e\t%s\n), -5, qq(254/178/76), -4, qq(254/178/76);
	printf CPT qq(%e\t%s\t%e\t%s\n), -4, qq(253/141/60), -3, qq(253/141/60);
	printf CPT qq(%e\t%s\t%e\t%s\n), -3, qq(252/78/42), -2, qq(252/78/42);
	printf CPT qq(%e\t%s\t%e\t%s\n), -2, qq(227/26/28), -1, qq(227/26/28);
	printf CPT qq(%e\t%s\n), -1, qq(177/0/38\t0\t177/0/38);
	printf CPT qq(%s\n),qq(B\t255/255/255);
	printf CPT qq(%s\n), qq(F\t0/0/0);
	printf CPT qq(%s\n), qq(N\t128/128/128);
}

close CONTOURS; 
close IN;
close CPT;

if ($plot == 1 or $plot == 2) { # Longitude/Latitude
	
	# Convert to  long / lat
	my $proj = Geo::Proj4->new(proj => qq(utm), ellps => qq(WGS84), datum => qq(WGS84), zone => $utm_zone );
	my ($south, $west) = $proj->inverse($utm_west, $utm_south);
	my ($north, $east) = $proj->inverse($utm_east, $utm_north); 
	# .009259259 degree spacing for 100m
	# .008333 degree for 90m
	my $gs = (0.000092222 * $grid_spacing/4);

	print STDERR qq(WEST $west\nEAST $east\nSOUTH $south\nNORTH $north\n);
	system qq(proj -I +datum=WGS84 +ellps=WGS84 +proj=utm +zone=$utm_zone -f %.6f $in > $in.ll);
	$in .= qq(.ll);
	system qq(proj -I +datum=WGS84 +ellps=WGS84 +proj=utm +zone=$utm_zone -f %.6f $events > $events.ll);
	
	$out = qq($in.eps);
	`gmt surface \`gmt gmtinfo -I- $in \` $in  -Gsurface.grd -I$gs -V`;
	`gmt makecpt -C$cpt -W -V > grid.cpt `;
	`gmt gmtset --FORMAT_GEO_MAP=-ddd.xx`;
	`gmt grdimage surface.grd -R -Cgrid.cpt -Jm$scale -E$res -X1i -Y1i  -V -K -P > $out`;
	`gmt grdcontour surface.grd -Ccontours -S2 -Gn1 -W.5p,0 -Jm -R -V -K -O >> $out`;
#	`gmt pscoast -R -Jm  -Df  -W.5p,100 -N1/1,255/255/255 -O -K -V >> $out`;
	$events .= qq(.ll);
	`gmt psxy $events -Jm -Sc.1c -R -Gwhite -W.25p,0 -N -O -K -V >> $out`;
	
	my $tick_sp = 1 * $P{TICK_SCALE};
	
	`gmt psbasemap --FONT_ANNOT_PRIMARY=8p --MAP_FRAME_TYPE=plain --FORMAT_GEO_MAP=-ddd.xx -Jm -R -Bxa$tick_sp -Bya$tick_sp -BWSne+t"$title" -V -O -K >> $out`;
	
	if ($plot == 2) {
	  $float = "%.0f";
	  $sc_title = "Log of spatial density";
	  $unit = " ";
	}
	else {
	  $float = "%0.1e";
	  $sc_title = "Spatial Density";
	  $unit = "vents / km\@+2\@+";
	}
	`gmt psscale --FORMAT_FLOAT_MAP=$float --FONT_ANNOT_PRIMARY=7p --FONT_LABEL=7p -DjBR+w4c/0.2c+o0.6/1c+ma -Li -Bx+l"$sc_title" -By+l"$unit" -R -Jm -Cgrid.cpt -O -V >> $out`;
}

elsif ($plot == 3 or $plot ==4) { # UTM meters
	$gs = $grid_spacing;
	$out = qq($in.eps);
	`gmt xyz2grd \`gmt gmtinfo -I- $in \` $in -I$gs -Gsurface.grd -V`;
	`gmt makecpt -C$cpt -W -V > grid.cpt `;	
	`gmt grdimage surface.grd -R -Cgrid.cpt -Jx$scale -E$res -X1i -Y1i -V -K -P > $out`;
	`gmt grdcontour surface.grd -Ccontours -S2 -Gn1 -W.5p,0 -Jx -R -V -K -O >> $out`;
	`gmt psxy $events -Jx -Sc.1c -R -Gwhite -W.25p,0 -N -O -K -V >> $out`;
	
	if (length($aoi) > 3) {
		`gmt psxy $aoi -Jm -Ss.1i -R -G0 -O -K -V >> $out`;
		`gmt pstext $aoi -Jm -R -D0/-.14 -G0 -O -K -V >> $out`;
	}

	my $tick_sp = 10000 * $P{TICK_SCALE};
	`gmt psbasemap --FONT_ANNOT_PRIMARY=7p --MAP_FRAME_TYPE=plain -Jx -R -Bxa$tick_sp -Bya$tick_sp -BWSne+t"$title" -V -O -K >> $out`;

if ($plot == 4) {
	  $float = "%.0f";
	  $sc_title = "Log of spatial density";
	  $unit = " ";
	}
	else {
	  $float = "%0.1e";
	  $sc_title = "Spatial Density";
	  $unit = "vents / \@~D\@~x\@~D\@~y";
	}

	`gmt psscale --FORMAT_FLOAT_MAP=$float --FONT_ANNOT_PRIMARY=6p --FONT_LABEL=6p -DjTR+w4.5c/0.2c+o0.6/1c+ma -Li -Bx+l"$sc_title" -By+l"$unit" -Cgrid.cpt -R -Jx -O -V >> $out`;
}
`gmt psconvert $out -A -Tg -V`; # Plot PNG image
`gmt psconvert $out -A -Tf -V`; # Plot PDF image

