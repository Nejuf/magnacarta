#!/usr/bin/php -q
<?php
//
// fpb2txt v1.2a
// (c) 2003 Derrick Sobodash
//
// This dumps Magna Carta scripts
//
echo ("\ntxt2fpb v1.2a (c) 2003 Derrick Sobodash\n");
set_time_limit(6000000);

if ($argc < 3) { DisplayOptions(); die; }
else { $path = $argv[1]; $out_path = $argv[2]; }

// Simple routine to read in a directory listing and split it to an array
$mydir=""; $outdir=""; $ffiles = "";
if ($handle = opendir($path)) {
	while (false !== ($file = readdir($handle))) { 
		$mydir .= $path . "/$file\n";
		$ffiles .= "$file\n";
		$outdir .= $out_path . "/" . substr($file, 0, strlen($file)-3) . "txt\n";
	}
	closedir($handle);
}
$filelist = split("\n", $mydir); $out_list = split("\n", $outdir); $ffiles_list = split("\n", $ffiles);
$i=0; unset($mydir); @mkdir($out_path);

for ($z=2; $z < (count($filelist)-1); $z++) {
	print "Loading $filelist[$z]...\n";
	$fd = fopen($filelist[$z], "rb");

	print "Counting strings...\n";
	$count = hexdec(bin2hex(strrev(fread($fd, 4))));
	print "$count found!\n";
	
	if ($count == 0)
		print "Zero count, skipping file!\n";
	else {

		print "Skipping pointers...\n";
		fseek($fd, ($count * 12) + 8, SEEK_SET);
		
		print "Reading in file and splitting to strings... ";
		$base = fread($fd, filesize($filelist[$z]) - (($count * 12) + 8));
		//die (print strlen($base));
		$strings = split("LINE BREAK", str_replace(chr(0), "LINE BREAK", $base));
		print "done!\n";
		
		print "Building output... ";
		$output = "";
		for ($g=0; $g < count($strings) -1; $g++)
			$output .= str_replace("\$n", "\r\n", $strings[$g]) . "<>\r\n\r\n";
			//$output .= $ffiles_list[$z] . " - " . str_pad($g, 4, "0", STR_PAD_LEFT) ."<>\r\n\r\n";
			
		//die (print strlen($strings[0]));
		print "done!\n";
		
		print "Writing $out_list[$z]...\n";
		$fo = fopen($out_list[$z], "w");
		fputs($fo, $output);
		fclose($fo);
	}
}
	
echo ("All done!...\n\n");
	
function DisplayOptions() {
	echo ("Dumps Magna Carta scripts to text files\n  usage: fpb2txt [input_path] [output_path]\n\n");
}

?>
