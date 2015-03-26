<?php

function startsWith($haystack, $needle) {
    // search backwards starting from haystack length characters from the end
    return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}

$files = array_filter(glob('Archive/*.txt'),'is_file');

$first = array_search($argv[1], $files);
$last = array_search($argv[2], $files);

$files = array_slice($files, $first, $last-$first+1);

$headerWritten = false;

foreach($files as $file) {
    $content = file_get_contents($file);

    $lines = preg_split ('/$\R?^/m', $content);

    $record = null;
    $header = null;
    $sequence = 1;

    foreach($lines as $line) {
    	if (startsWith($line, "CAM")) {
	       $parts = preg_split("/[\s,]+/", trim($line));

            if ($record === null) {
                $record = $parts[1];
                $header = "datetime";
            }

            $record .= ', '.$parts[0];
            $header .= ', cam-'.$sequence.'-name';

            $record .= ', '.$parts[2];
            $header .= ', cam-'.$sequence.'-avgX';

            $record .= ', '.$parts[3];
            $header .= ', cam-'.$sequence.'-avgY';

            $record .= ', '.$parts[4];
            $header .= ', cam-'.$sequence.'-avgZ';


            $record .= ', '.$parts[5];
            $header .= ', cam-'.$sequence.'-stdX';

            $record .= ', '.$parts[6];
            $header .= ', cam-'.$sequence.'-stdY';

            $record .= ', '.$parts[7];
            $header .= ', cam-'.$sequence.'-stdZ';

            $sequence++;
        }	
    }

    if (!$headerWritten) {
        print($header."\n");
        $headerWritten = true;
    } 

    print($record."\n");
}

?>
