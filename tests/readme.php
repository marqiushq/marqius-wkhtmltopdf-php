<?php
// Prints the README's code block that follows "<!-- NAME -->", exactly as printed:
//   php tests/readme.php "example: snappy"
$readme = file_get_contents(dirname(__DIR__) . '/README.md');
$marker = '<!-- ' . $argv[1] . ' -->';
$at = strpos($readme, $marker);
if ($at === false || !preg_match('{\G\s*```[a-z]*\n(.*?)\n```}s', $readme, $m, 0, $at + strlen($marker))) {
    fwrite(STDERR, "README.md has no code block after $marker\n");
    exit(1);
}
echo $m[1], "\n";
