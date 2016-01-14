while (<>) {
	($east, $north, $sd) = split (" ");
	$log_sd = ($sd>0) ? log($sd)/log(10) : 0;
	print "$east $north $log_sd\n";

}
