#!/usr/bin/php -q
<?php
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

if ($argc < 3) { DisplayOptions(); die; }
else { $path = $argv[1]; $out_path = $argv[2]; }

// Simple routine to read in a directory listing and split it to an array
$mydir=""; $outdir="";
if ($handle = opendir($path)) {
	while (false !== ($file = readdir($handle))) { 
		$mydir .= $path . "/$file\n";
		$outdir .= $out_path . "/" . substr($file, 0, strlen($file)-4) . ".fpb\n";
	}
	closedir($handle);
}
$filelist = explode("\n", $mydir); $out_list = explode("\n", $outdir);
$i=0; unset($mydir); @mkdir($out_path);

for ($z=2; $z < (count($filelist)-1); $z++) {
	unset($string_tags);

	print "Loading $filelist[$z]...\n";
	$file = trim(file_get_contents($filelist[$z]));

	print "  Parsing source files ...\n";
	$kor = fopen("./fpb/ko/" . str_replace(".txt", ".fpb", substr($filelist[$z], strlen($filelist[$z])-8, 8)), "rb");
	list($null, $kor_count) = unpack("V", fread($kor, 4));
	$lele = unpack("V*", fread($kor, 4 * 3 * $kor_count));
	print "  Harvesting string IDs ...\n";
	for($i=1; $i<count($lele); $i += 3)
		$string_tags[] = $lele[$i];

	print "  Converting text to FPB string library ...\n";
	$line_array = explode("<>", $file);
	unset($file);
	print "  Sanitizing ...\n";
	for($i=0; $i<count($line_array); $i++)
		$line_array[$i] = trim($line_array[$i]);
	unset($line_array[(count($line_array)-1)]);
	$header = pack("V*", (count($line_array)));
	$sub_off = 0;

	if(count($line_array) != count($string_tags))
	{
		echo "FATAL ERROR: The number of lines in the Korean and English files does not match! (KO=" . count($string_tags) . " EN=" . count($line_array) . ")\n";
		die;
	}

	for ($i=0; $i < count($line_array); $i++) {
		$header .= pack("V*", $string_tags[$i]);
		$header .= pack("V*", $sub_off);
		$header .= pack("V*", (strlen(str_replace("\r\n", "\$n", $line_array[$i]))+1));
		$sub_off += strlen($line_array[$i])+1;
	}
	$header .= pack("V*", $sub_off);
	unset($sub_off); $body = "";
	for ($i=0; $i < count($line_array); $i++) {
		$body .= str_replace("\r\n", "\$n", $line_array[$i]) . chr(0);
	}
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
