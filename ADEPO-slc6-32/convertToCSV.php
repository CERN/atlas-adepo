<?php

function startsWith($haystack, $needle) {
    // search backwards starting from haystack length characters from the end
    return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}

$files = array_filter(glob('Archive/*.txt'),'is_file');

$first = array_search($argv[1], $files);
$last = array_search($argv[2], $files);

$files = array_slice($files, $first, $last-$first+1);

foreach($files as $file) {
    $content = file_get_contents($file);

    $lines = preg_split ('/$\R?^/m', $content);

    $dateWritten = false;

    foreach($lines as $line) {
    	if (startsWith($line, "CAM")) {
	    $parts = preg_split("/[\s,]+/", trim($line));

            if (!$dateWritten) {
                $dateWritten = true;
                print('"'.$parts[1].'", ');
		print(", , , , , , , , , ");
            }

            print('"'.$parts[0].'", ');

            print('"'.$parts[2].'", ');
            print('"'.$parts[3].'", ');
            print('"'.$parts[4].'", ');

            print('"'.$parts[5].'", ');
            print('"'.$parts[6].'", ');
            print('"'.$parts[7].'", ');

            print(", , ,");
        }	
    }
    print("\n");
}

?>
