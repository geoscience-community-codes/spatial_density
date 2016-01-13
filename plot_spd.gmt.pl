use Geo::Proj4;

my $args = @ARGV;
if ($args < 1) {
  print qq(USAGE: perl $0 <yourfile.conf> <XYZ_spatial_density_file>\n\n);
  exit;
}

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

$in = $ARGV[1];
$events = $P{EVENT_FILE};
$aoi = $P{AOI_FILE};
$utm_west = $P{WEST};
$utm_east = $P{EAST};
$utm_south = $P{SOUTH};
$utm_north = $P{NORTH};
$utm_zone = $P{UTM_ZONE};
$grid_spacing = $P{GRID_SPACING};
$plot = $P{PLOT};
$map_scale = $P{MAP_SCALE};
$scale = qq(1:$map_scale).qq(m);
$res = 300;
$psscaleX = 12;
$psscaleY = 10;

if ($plot == 0) {
	print STDERR qq(Done!\n);
	exit(0);
}


$contours = qq(contours);
$cpt = qq(colors.cpt);

open(CONTOURS, ">$contours") || die("can't open $contours: $!");
open(CPT, ">$cpt") || die("cannot open $cpt: $!");

$ct=0;
$data_sum = 0;

if ($plot == 1 or $plot == 3) {
print STDERR qq(Opening $in\n);
	open(IN, "<$in") || die("can't open $in: $!");
	while (<IN>) {
		 ($e, $n, $data[$ct]) = split " ", $_;
		 $data_sum += $data[$ct++];
	}
	@data_s = sort{$b <=> $a} @data;
	 $num = @data_s;
	 print STDERR qq(Sorted $num items.\n);

	my $sum = 0;
	$ct = 0;

	while ($sum < ($data_sum*.05) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q05 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.16) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q15 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.33) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q33 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.5) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q5 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.67) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q67 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.84) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q84 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.95) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
	$q95 = $data_s[$ct-1];

	while ( $sum < ($data_sum*.99) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	print CONTOURS qq($data_s[$ct-1] \n);
    $q99 = $data_s[$ct-1];

    print CPT qq(#\tcpt file created by: $0\n);
	print CPT qq(#Color_MODEL = RGB\n);
	print CPT qq(#\n);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q99, qq(255\t255\t255), $q95, qq(255\t255\t255\t;99th);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q95, qq(255\t255\t255), $q84, qq(0\t85\t170\t;95th);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q84, qq(0\t85\t170), $q67, qq(0\t170\t85\t;84th);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q67, qq(0\t170\t85), $q5, qq(0\t255\t0\t;67th);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q5, qq(0\t255\t0), $q33, qq(255\t255\t0\t;50th);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q33, qq(255\t255\t0), $q15, qq(255\t195\t0\t;33rd);
	printf CPT qq(%g\t%s\t%g\t%s\n), $q15, qq(255\t195\t0), $q05, qq(255\t165\t0\t;15th);
	printf CPT qq(%g\t%s\n\n), $q05, qq(255\t165\t0\t1\t255\t0\t0\t;5th);
	printf CPT qq(%s\n),qq(B\t255\t255\t255);
	printf CPT qq(%s\n), qq(F\t0\t0\t0);
	printf CPT qq(%s\n), qq(N\t128\t128\t128);
}

elsif ($plot == 2 or $plot == 4) {
	print STDERR qq(opening $in; writing to $in.log\n);
	system qq(perl convert2log.pl $in > $in.log);

	$in = qq($in.log);
	sleep(2);
	open(IN, "<$in") || die("can't open $in: $!");
	while (<IN>) {
	 ($e, $n, $data[$ct]) = split " ", $_;
	 $data_sum += $data[$ct++];
	}
	@data_s = sort{$b <=> $a} @data;
	 $num = @data_s;
	 print STDERR qq("Sorted $num items.\n);

	my $sum = 0;
	$ct = 0;

	while ($sum < ($data_sum*.05) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q05 = $data_s[$ct-1];
	print CONTOURS qq(-2\n);
	$q05 = -2;

	while ( $sum < ($data_sum*.16) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q15 = $data_s[$ct-1];
	print CONTOURS qq(-3\n);
	$q15 = -3;

	while ( $sum < ($data_sum*.33) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q33 = $data_s[$ct-1];
	print CONTOURS qq(-4\n);
	$q33 = -4;

	while ( $sum < ($data_sum*.5) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q5 = $data_s[$ct-1];
	print CONTOURS qq(-5\n);
	$q5 = -5;

	while ( $sum < ($data_sum*.67) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q67 = $data_s[$ct-1];
	print CONTOURS qq(-6\n);
	$q67 = -6;

	while ( $sum < ($data_sum*.84) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q84 = $data_s[$ct-1];
	print CONTOURS qq(-7\n);
	$q84 = -7;

	while ( $sum < ($data_sum*.95) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.5f\n", $data_s[$ct-1];
	$q95 = $data_s[$ct-1];
	print CONTOURS qq(-8\n);
	$q95 = -8;

	while ( $sum < ($data_sum*.99) ) {
		$sum += $data_s[$ct++];
	}
	print qq($data_s[$ct-1] a\n);
	#printf CONTOURS "%.6f\n", $data_s[$ct-1];
	$q99 = $data_s[$ct-1];
	print CONTOURS qq(-9\n);
	$q99 = -9;

	printf CPT qq(%s\n\n), qq(# Spatial Density colormap\n# COLOR_MODEL = RGB);

	#printf CPT "%.6f\t%s\t%.5f\t%s\n", $q99, "230\t230\t255", $q95, "230\t230\t255";
	#printf CPT "%.5f\t%s\t%.5f\t%s\n", $q95, "0\t100\t200", $q84, "0\t100\t200";
	#printf CPT "%.5f\t%s\t%.5f\t%s\n", $q84, "0\t170\t170", $q67, "0\t170\t170";
	#printf CPT "%.5f\t%s\t%.5f\t%s\n", $q67, "0\t255\t0", $q5, "0\t255\t0";
	#printf CPT "%.5f\t%s\t%.5f\t%s\n", $q5, "255\t255\t0", $q33, "255\t255\t0";
	#printf CPT "%.5f\t%s\t%.5f\t%s\n", $q33, "255\t210\t0", $q15, "255\t210\t0";
	#printf CPT "%.5f\t%s\t%.5f\t%s\n", $q15, "255\t165\t0", $q05, "255\t165\t0";
	#printf CPT "%.5f\t%s\n\n", $q05, "235\t0\t0\t1\t235\t0\t0";


	#print CPT "0 255 225 255 $q95 255 255 255\n";
	#print CPT "$q95 255 255 255 $q84 0 85 170\n";
	#print CPT "$q84 0 85 170 $q67 0 170 85\n";
	#print CPT "$q67 0 170 85 $q5 0 255 0\n";
	#print CPT "$q5 0 255 0 $q33 255 255 0\n";
	#print CPT "$q33 255 255 0 $q15 255 195 0\n";
	#print CPT "$q15 255 195 0 $q05 255 165 0\n";
	#print CPT "$q05 255 165 0 1 255 0 0\n\n";
	#print CPT "B 255 255 255\n";
	#print CPT "F 255 0 0\n";
	#print CPT "N 255 255 255\n";

	print CPT qq(#\tcpt file created by: $0\n);
	print CPT qq(#Color_MODEL = RGB\n);
	print CPT qq(#\n);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q99, qq(230\t230\t255), $q95, qq(230\t230\t255\t;-2);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q95, qq(0\t100\t200), $q84, qq(0\t100\t200\t;-3);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q84, qq(0\t170\t170), $q67, qq(0\t170\t170\t;-4);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q67, qq(0\t255\t0), $q5, qq(0\t255\t0\t;-5);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q5, qq(255\t255\t0), $q33, qq(255\t255\t0\t;-6);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q33, qq(255\t210\t0), $q15, qq(255\t210\t0\t;-7);
	printf CPT qq(%.1e\t%s\t%.1e\t%s\n), $q15, qq(255\t165\t0), $q05, qq(255\t165\t0\t;-8);
	printf CPT qq(%.1e\t%s\n\n), $q05, qq(235\t0\t0\t0\t235\t0\t0\t;-9);
	printf CPT qq(%s\n),qq(B\t255\t255\t255);
	printf CPT qq(%s\n), qq(F\t0\t0\t0);
	printf CPT qq(%s\n), qq(N\t128\t128\t128);
}

close CONTOURS; 
close IN;
close CPT;

if ($plot == 1 or $plot == 2) {
	
	# Convert to  long / lat
	my $proj = Geo::Proj4->new(proj => qq(utm), ellps => qq(WGS84), datum => qq(WGS84), zone => $utm_zone );
	my ($south, $west) = $proj->inverse($utm_west, $utm_south);
	my ($north, $east) = $proj->inverse($utm_east, $utm_north); 
	# .009259259 degree spacing for 100m
	# .008333 degree for 90m
	
	my $gs = 0.000092222 * $grid_spacing;
	my $gs = (0.000092222 * $grid_spacing/4);
#$west = -123.0;
#$east = -120.6;
#$south = 40.0;
#$north = 41.55;
	print STDERR qq(WEST $west\nEAST $east\nSOUTH $south\nNORTH $north\n);
	system qq(proj -I +datum=WGS84 +ellps=WGS84 +proj=utm +zone=$utm_zone -f %.6f $in > $in.ll);
	$in .= qq(.ll);
	system qq(proj -I +datum=WGS84 +ellps=WGS84 +proj=utm +zone=$utm_zone -f %.6f $events > $events.ll);
	
	$out = qq($in.eps);
	`gmt surface \`gmt gmtinfo -I- $in \` $in  -Gsurface.grd -I$gs -V`;
	`gmt makecpt -C$cpt -V > grid.cpt `;
	`gmt grdimage surface.grd -R$west/$east/$south/$north -Cgrid.cpt -Jm$scale -E$res -X1i -Y1i  -V -K -P > $out`;
	`gmt grdcontour surface.grd -Ccontours -A- -S2 -Gn1 -W.5p,0 -Jm -R -V -K -O >> $out`;
	`gmt pscoast -R -Jm  -Dh  -W.5p,100 -N1/1,255/255/255 -O -K -V >> $out`;
	$events .= qq(.ll);
	`gmt psxy $events -Jm -Sc.1c -R -Gwhite -W.25p,0 -N -O -K -V >> $out`;
	
	if (length($aoi) > 3) {
		`gmt psxy $aoi -Jm -Ss.1i -R -G0 -O -K -V >> $out`;
		`gmt pstext $aoi -Jm -R -D0/-.14 -G0 -O -K -V >> $out`;
	}
	`gmt psbasemap --FORMAT_FLOAT_MAP=%0.1f -Jm -R -Bxa0.5 -Bya0.5 -BWSne -V -O -K >> $out`;
	`gmt psscale -D$psscaleX/$psscaleY/2i/.2c -Cgrid.cpt -L  -O -V >> $out`;

}

elsif ($plot == 3 or $plot ==4) {
	$gs = $grid_spacing;
	$out = qq($in.eps);
	`gmt xyz2grd \`gmt gmtinfo -I- $in \` $in -I$gs -Gsurface.grd -V`;
	`gmt makecpt -C$cpt -V > grid.cpt `;	
	`gmt grdimage surface.grd -R$utm_west/$utm_east/$utm_south/$utm_north -Cgrid.cpt -Jx$scale -E$res -X1i -Y1i -V -K -P > $out`;
	`gmt grdcontour surface.grd -Ccontours -A- -S2 -Gn1 -W.5p,0 -Jx -R -V -K -O >> $out`;
	`gmt psxy $events -Jx -Sc.1c -R -Gwhite -W.25p,0 -N -O -K -V >> $out`;
	
	if (length($aoi) > 3) {
		`gmt psxy $aoi -Jm -Ss.1i -R -G0 -O -K -V >> $out`;
		`gmt pstext $aoi -Jm -R -D0/-.14 -G0 -O -K -V >> $out`;
	}
	#-B option.  Correct syntax:
#-B[p|s][x|y|z]<intervals>[+l<label>][+p<prefix>][+u<unit>] -B[<axes>][+b][+g<fill>][+o<lon>/<lat>][+t<title>] OR
#-B[p|s][x|y|z][a|f|g]<tick>[m][l|p] -B[p|s][x|y|z][+l<label>][+p<prefix>][+u<unit>] -B[<axes>][+b][+g<fill>][+o<lon>/<lat>][+t<title>] 

	`gmt psbasemap --FORMAT_FLOAT_OUT=%0f -Jx -R -Bxa20000 -Bya20000 -BWSne -V -O -K >> $out`;

	`gmt psscale -D$psscaleX/$psscaleY/2i/.2c  -L -Cgrid.cpt -O -V >> $out`;
}

`gmt ps2raster $out -A -Tg -V`;
`gmt ps2raster $out -A -Tf -V`;
exit(0);
	# Only add DEM if grd file exists
	unless (-e $grd) {
		# Only process intensity file if it does not exist
		unless ( -e $int) {
			`gmt grdgradient $grd -G$int -R$west/$east/$south/$north -E-80/20/.5/.2/.2/100 -Nt0.5 -V `;
		}
		`gmt grdimage $grd -C$cpt -Jm$scale -I$int -R$west/$east/$south/$north -E$res -Ba50000 -BWSen -P -K > $out`;
	}	
