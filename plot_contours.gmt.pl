
#USAGE:  perl plot_contours.gmt.pl spatial_density.conf

use Geo::Proj4;

my $args = @ARGV;
if ($args < 1) {
  print "USAGE: perl $0 <spatial_density.conf> <XYZ_spatial_density_file>\n\n";
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
 		print STDERR "$key $value\n";
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
$map_scaling= $P{MAP_SCALING};

$out = "$in.eps";
$contours = "contours";

$cpt = "colors.cpt";
open(IN, "<$in") || die("can't open $in: $!");
open(CONTOURS, ">$contours") || die("can't open $contours: $!");
open(CPT, ">$cpt") || die("cannot open $cpt: $!");

$ct=0;
$data_sum = 0;
while (<IN>) {
 ($e, $n, $data[$ct]) = split " ", $_;
 $data_sum += $data[$ct++];
}
print "Data sums to $data_sum\n";
@data_s = sort{$b <=> $a} @data;
 $num = @data_s;
 print "Sorted $num items.\n";

my $sum = 0;
$ct = 0;

while ($sum < ($data_sum*.05) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q05 = $data_s[$ct-1];

while ( $sum < ($data_sum*.16) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q15 = $data_s[$ct-1];

while ( $sum < ($data_sum*.33) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q33 = $data_s[$ct-1];

while ( $sum < ($data_sum*.5) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q5 = $data_s[$ct-1];

while ( $sum < ($data_sum*.67) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q67 = $data_s[$ct-1];

while ( $sum < ($data_sum*.84) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q84 = $data_s[$ct-1];

while ( $sum < ($data_sum*.95) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";
$q95 = $data_s[$ct-1];

while ( $sum < ($data_sum*.99) ) {
  $sum += $data_s[$ct++];
}
print "$data_s[$ct-1] a\n";
print CONTOURS "$data_s[$ct-1] \n";


print CPT "#\tcpt file created by: $0\n";
print CPT "#Color_MODEL = RGB\n";
print CPT "#\n";
#print CPT "0 255 225 255 $q95 255 255 255\n";
print CPT "$q95 255 255 255 $q84 0 85 170\n";
print CPT "$q84 0 85 170 $q67 0 170 85\n";
print CPT "$q67 0 170 85 $q5 0 255 0\n";
print CPT "$q5 0 255 0 $q33 255 255 0\n";
print CPT "$q33 255 255 0 $q15 255 195 0\n";
print CPT "$q15 255 195 0 $q05 255 165 0\n";
print CPT "$q05 255 165 0 1 255 0 0\n\n";
print CPT "B 255 255 255\n";
print CPT "F 255 0 0\n";
print CPT "N 255 255 255\n";

close CONTOURS;
close IN;
close CPT;

# Convert long / lat to utm 
my $proj = Geo::Proj4->new(proj => "utm", ellps => "WGS84", datum => "WGS84", zone => $utm_zone );
my ($south, $west) = $proj->inverse($utm_west, $utm_south);
my ($north, $east) = $proj->inverse($utm_east, $utm_north); 
# .009259259 degree spacing for 100m
# .008333 degree for 90m
#
my $gs = (0.000092222 * $grid_spacing/4);
print stderr "WEST $west\nEAST $east\nSOUTH $south\nNORTH $north\n";
system "invproj +datum=WGS84 +ellps=WGS84 +proj=utm +zone=$utm_zone -f %.6f $in > $in.ll";
$in .= ".ll";
system "invproj +datum=WGS84 +ellps=WGS84 +proj=utm +zone=$utm_zone -f %.6f $events > $events.ll";
$events .= ".ll";
`gmt surface $in -R$west/$east/$south/$north -Gsurface.grd -I$gs -V`;
`gmt makecpt -C$cpt -V > grid.cpt `;
$scaling = "1:$map_scaling"."m";
`gmt grdimage surface.grd -R$west/$east/$south/$north -Cgrid.cpt -Jm$scaling -X1i -Y1i  -E150 -V -K -P > $out`;
`gmt grdcontour --FORMAT_FLOAT_OUT=%e surface.grd -Ccontours -A- -Gn1 -W.5p,0 -Jm -R -V -K -O >> $out`;
#`gmt pscoast -R -Jm  -Dh  -W.5p,100 -N1/1,255/255/255 -O -K -V >> $out`;
`gmt psxy $events -Jm -Sc.1c -R -Gwhite -W.25p,0 -N -O -K -V >> $out`;
#system "gmt psxy -R -Jm -St0.8c -Gblack -V -O -K << eof >> $out
#44.184500	40.520287
#eof";
#`gmt psxy $aoi -Jm -Ss.1i -R -G0 -O -K -V >> $out`;
#`gmt pstext $aoi -Jm -R -D0/-.14 -G0 -O -K -V >> $out`;
`gmt psbasemap --FORMAT_GEO_MAP=ddd.x --MAP_FRAME_TYPE=plain --FONT_ANNOT_PRIMARY=10p -Jm -R -Bxa0.05 -Bya0.05 -BWSne -V -O -K >> $out`;
`gmt psscale --FONT_ANNOT_PRIMARY=10p --FORMAT_FLOAT_OUT=%.2e -D3c/14c/4c/.2c -Cgrid.cpt -L  -O -V >> $out`;
`gmt ps2raster $out -A -Tg -V`;
