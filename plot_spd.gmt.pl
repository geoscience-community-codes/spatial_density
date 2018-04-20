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
	printf CPT qq(%e\t%s\t%e\t%s\n), $q99, qq(255\t255\t255), $q95, qq(255\t255\t255\tU;99th);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q95, qq(255\t255\t255), $q84, qq(0\t85\t170\tU;95th);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q84, qq(0\t85\t170), $q67, qq(0\t170\t85\tU;84th);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q67, qq(0\t170\t85), $q5, qq(0\t255\t0\tU;67th);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q5, qq(0\t255\t0), $q33, qq(255\t255\t0\tU;50th);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q33, qq(255\t255\t0), $q15, qq(255\t195\t0\tU;33rd);
	printf CPT qq(%e\t%s\t%e\t%s\n), $q15, qq(255\t195\t0), $q05, qq(255\t165\t0\tU;15th);
	printf CPT qq(%e\t%s\n), $q05, qq(255\t165\t0\t1\t255\t0\t0\tU;5th);
	printf CPT qq(%s\n),qq(B\t255\t255\t255);
	printf CPT qq(%s\n), qq(F\t0\t0\t0);
	printf CPT qq(%s\n), qq(N\t128\t128\t128);
	

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
# print LOG qq(-9 a\n);
# print CONTOURS qq(-9\n);
#	print LOG qq(-10 a\n);
# print CONTOURS qq(-10\n);
#	print LOG qq(-11 a\n);
#	print CONTOURS qq(-11\n);
#	print LOG qq(-12 a\n);
#	print CONTOURS qq(-12\n);
	
	printf CPT qq(%s\n\n), qq(# Spatial Density colormap\n# COLOR_MODEL = RGB);

	# printf CPT "%.6f\t%s\t%.5f\t%s\n", $q99, "230\t230\t255", $q95, "230\t230\t255";
	# printf CPT "%.5f\t%s\t%.5f\t%s\n", $q95, "0\t100\t200", $q84, "0\t100\t200";
	# printf CPT "%.5f\t%s\t%.5f\t%s\n", $q84, "0\t170\t170", $q67, "0\t170\t170";
	# printf CPT "%.5f\t%s\t%.5f\t%s\n", $q67, "0\t255\t0", $q5, "0\t255\t0";
	# printf CPT "%.5f\t%s\t%.5f\t%s\n", $q5, "255\t255\t0", $q33, "255\t255\t0";
	# printf CPT "%.5f\t%s\t%.5f\t%s\n", $q33, "255\t210\t0", $q15, "255\t210\t0";
	# printf CPT "%.5f\t%s\t%.5f\t%s\n", $q15, "255\t165\t0", $q05, "255\t165\t0";
	# printf CPT "%.5f\t%s\n\n", $q05, "235\t0\t0\t1\t235\t0\t0";


	# print CPT "0 255 225 255 $q95 255 255 255\n";
	# print CPT "$q95 255 255 255 $q84 0 85 170\n";
	# print CPT "$q84 0 85 170 $q67 0 170 85\n";
	# print CPT "$q67 0 170 85 $q5 0 255 0\n";
	# print CPT "$q5 0 255 0 $q33 255 255 0\n";
	# print CPT "$q33 255 255 0 $q15 255 195 0\n";
	# print CPT "$q15 255 195 0 $q05 255 165 0\n";
	# print CPT "$q05 255 165 0 1 255 0 0\n\n";
	# print CPT "B 255 255 255\n";
	# print CPT "F 255 0 0\n";
	# print CPT "N 255 255 255\n";

	print CPT qq(#\tcpt file created by: $0\n);
	print CPT qq(#Color_MODEL = RGB\n);
	print CPT qq(#\n);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -8, qq(230\t230\t255), -7, qq(230\t230\t255\t;-8);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -7, qq(0\t100\t200), -6, qq(0\t100\t200\t;-7);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -6, qq(0\t170\t170), -5, qq(0\t170\t170\t;-6);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -5, qq(0\t255\t0), -4, qq(0\t255\t0\t;-5);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -4, qq(255\t255\t0), -3, qq(255\t255\t0\t;-4);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -3, qq(255\t210\t0), -2, qq(255\t210\t0\t;-3);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), -2, qq(255\t165\t0), -1, qq(255\t165\t0\t;-2);
	printf CPT qq(%.1e\t%s\n\n), -1, qq(235\t0\t0\t0\t235\t0\t0\t;-1);
	printf CPT qq(%s\n),qq(B\t255\t255\t255);
	printf CPT qq(%s\n), qq(F\t0\t0\t0);
	printf CPT qq(%s\n), qq(N\t128\t128\t128);
	
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
	`gmt makecpt -C$cpt -V > grid.cpt `;
	`gmt gmtset --FORMAT_GEO_MAP=-ddd.xx`;
	`gmt grdimage surface.grd -R -Cgrid.cpt -Jm$scale -E$res -X1i -Y1i  -V -K -P > $out`;
	`gmt grdcontour surface.grd -Ccontours -S2 -Gn1 -W.5p,0 -Jm -R -V -K -O >> $out`;
#	`gmt pscoast -R -Jm  -Df  -W.5p,100 -N1/1,255/255/255 -O -K -V >> $out`;
	$events .= qq(.ll);
	`gmt psxy $events -Jm -Sc.1c -R -Gwhite -W.25p,0 -N -O -K -V >> $out`;
	
	my $tick_sp = 1 * $P{TICK_SCALE};
	
	`gmt psbasemap --FONT_ANNOT_PRIMARY=8p --MAP_FRAME_TYPE=plain -Jm -R -Bxa$tick_sp -Bya$tick_sp -BWSne+t"$title" -V -O -K >> $out`;
	
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
	`gmt makecpt -C$cpt -V > grid.cpt `;	
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
`gmt psconvert $out -A -Tg -V`;
`gmt psconvert $out -A -Tf -V`;
exit(0);

# NOT IMPLEMENTED YET >>>
	# Only add DEM if grd file exists
	unless (-e $grd) {
		# Only process intensity file if it does not exist
		unless ( -e $int) {
			`gmt grdgradient $grd -G$int -R$west/$east/$south/$north -E-80/20/.5/.2/.2/100 -Nt0.5 -V `;
		}
		`gmt grdimage $grd -C$cpt -Jm$scale -I$int -R$west/$east/$south/$north -E$res -Ba50000 -BWSen -P -K > $out`;
	}	
