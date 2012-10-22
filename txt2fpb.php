#!/usr/bin/php -q
<?
/*

txt2fpb

This script is a complete rewrite of my old script_convert.php for Magna Carta.
No old code was used.

One day, I looked at the script and realized -- it was so sloppy I no longer
had ANY idea what the hell it was doing. Sure it worked, but it would be a cold
day in hell before anyone learned anything from it.

This script just converts the .txt script package for Magna Carta that I
released back into useable game files.

Version:   1.2a
Author:    Derrick Sobodash <derrick@sobodash.com>
Copyright: (c) 2003, 2004, 2012 Derrick Sobodash
Web site:  https://github.com/sobodash/magnacarta/
License:   BSD License <http://opensource.org/licenses/bsd-license.php>

*/

echo ("txt2fpb 1.2a (cli)\nCopyright (c) 2003, 2012 Derrick Sobodash\n");
set_time_limit(6000000);

if ($argc < 3) {
	DisplayOptions();
	die;
}
else {
	$path = $argv[1];
	$out_path = $argv[2];
}

// Simple routine to read in a directory listing and split it to an array
$mydir=""; $outdir="";

if ($handle = opendir($path)) {
	while (false !== ($file = readdir($handle))) { 
		$mydir .= $path . "/$file\n";
		$outdir .= $out_path . "/" . substr($file, 0, strlen($file)-4) . "\n";
	}
	closedir($handle);
}

$filelist = split("\n", $mydir); $out_list = split("\n", $outdir);
$i=0; unset($mydir); @mkdir($out_path);

for ($z=2; $z < (count($filelist)-1); $z++) {
	print "Loading $filelist[$z]...\n";

	$fd = fopen($filelist[$z], "rb");
	$file = fread($fd, filesize($filelist[$z]));
	fclose($fd);
	print "Converting text to FPB string library...\n";
	$line_array = split("\r\n\r\n", $file);

	// Account for files with UNIX line breaks
	if (count($line_array) < 1)
		$line_array = split("\n\n", $file);
	
	unset ($file);
	$header = pack("V*", (count($line_array)));
	$sub_off = 0;
	
	for ($i=0; $i < count($line_array); $i++) {
		$header .= pack("V*", $i);
		$header .= pack("V*", $sub_off);
		$header .= pack("V*", (strlen($line_array[$i])+1));
		$sub_off += strlen($line_array[$i])+1;
	}
	
	$header .= pack("V*", $sub_off);
	unset($sub_off); $body = "";
	for ($i=0; $i < count($line_array); $i++)
		$body .= $line_array[$i] . chr(0);

	print "Writing $out_list[$z]...\n";
	$fo = fopen($out_list[$z], "w");
	fputs($fo, ($header . $body));
	fclose($fo);
}

echo ("All done!\n\n");

function DisplayOptions() {
	echo ("Builds a new set of FPB files for Magna Carta from a folder of plain text\n  usage: fpb2txt [input_path] [output_path]\n\n");
}

?>
