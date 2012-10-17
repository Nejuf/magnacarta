#!/usr/bin/php -q
<?php
//
// texcvrt v0.5 for PHP web mode
// (c) 2003 Derrick Sobodash
//
// This converts all the texture files in Magna Carta to a normally
// viewable format. There's some pretty interesting ones.
//
// I never really commented when I first wrote this and I'm not
// about to start. I'm already done witht his file as all game
// textures have already been translated and re-inserted back
// into the game.
//

set_time_limit(6000);

function getmicrotime(){ 
	list($usec, $sec) = explode(" ",microtime()); 
	return ((float)$usec + (float)$sec); 
}

$start = getmicrotime();

$filelist = "";
$badfiles = "";
$mydir = "";

if ($handle = opendir('BGR')) {
	while (false !== ($file = readdir($handle))) { 
		$mydir .= "BGR/$file\n";
	}
	closedir($handle);
}

$filelist = split("\n", $mydir);

for ($i=2; $i < (count($filelist)-1); $i++) {
	$fd = fopen ($filelist[$i], "rb");
	$fddump = fread ($fd, filesize ($filelist[$i]));
	fclose ($fd);
	$bmp = substr ($fddump, 24, 2);
	$tga = substr ($fddump, (strlen($fddump)-18), 10);
	$tgatest = substr ($fddump, 14, 1);
	$tgatest2 = substr ($fddump, 58, 1);
	$tgatest3 = substr ($fddump, 42, 1);
	
	//echo ("$gif $jfif $bmp");
	if ($bmp == "BM") {
		$output = substr ($fddump, 24, strlen($fddump));
		$temp = substr($filelist[$i], 23, 4);
		$outfile = "BGR-OUT/$temp.bmp";
		$fo = fopen($outfile, "w");
		fputs($fo, $output);
		fclose($fo);
		unset ($fo, $output, $outfile, $temp);
	}
	elseif (($tga == "TRUEVISION") && ($tgatest == chr(02))) {
		$output = substr ($fddump, 12, strlen($fddump));
		$temp = substr($filelist[$i], 23, 4);
		$outfile = "BGR-OUT/$temp.tga";
		$fo = fopen($outfile, "w");
		fputs($fo, $output);
		fclose($fo);
		unset ($fo, $output, $outfile, $temp);
	}
	elseif (($tga == "TRUEVISION") && ($tgatest2 == chr(02))) {
		$output = substr ($fddump, 56, strlen($fddump));
		$temp = substr($filelist[$i], 23, 4);
		$outfile = "BGR-OUT/$temp.tga";
		$fo = fopen($outfile, "w");
		fputs($fo, $output);
		fclose($fo);
		unset ($fo, $output, $outfile, $temp);
	}
	elseif (($tga == "TRUEVISION") && ($tgatest3 == chr(02))) {
		$output = substr ($fddump, 40, strlen($fddump));
		$temp = substr($filelist[$i], 23, 4);
		$outfile = "BGR-OUT/$temp.tga";
		$fo = fopen($outfile, "w");
		fputs($fo, $output);
		fclose($fo);
		unset ($fo, $output, $outfile, $temp);
	}
	elseif ($tga == "TRUEVISION") {
		$output = substr ($fddump, 24, strlen($fddump));
		$temp = substr($filelist[$i], 23, 4);
		$outfile = "BGR-OUT/$temp.tga";
		$fo = fopen($outfile, "w");
		fputs($fo, $output);
		fclose($fo);
		unset ($fo, $output, $outfile, $temp);
	}
	else {
		$output = $fddump;
		$temp = substr($filelist[$i], 23, 4);
		$outfile = "BGR-FAIL/$temp.unk";
		$fo = fopen($outfile, "w");
		fputs($fo, $output);
		fclose($fo);
		unset ($fo, $output, $outfile, $temp);
		$badfiles .= "$filelist[$i]\n";
	}
	unset ($fd, $fddump, $gif, $jfif, $bmp);
}

$outfile = "badfiles.txt";
$fo = fopen($outfile, "w");
fputs($fo, $badfiles);
fclose($fo);
unset ($fo, $output, $outfile);

$end = getmicrotime();
$total = $end - $start;
$total = substr($total,0,5);

echo ("All done! Converting the files took $total seconds.\n\n");

?>
