<?php
// Fetches marqius-wkhtmltopdf for this machine for bin/wkhtmltopdf and bin/wkhtmltoimage, the
// first time they run. marqius-wkhtmltopdf is commercial software with a 30-day free trial.
require_once __DIR__ . DIRECTORY_SEPARATOR . 'Binary.php';
try {
    Marqius\Wkhtmltopdf\Binary::install(function ($line) {
        fwrite(STDERR, $line . PHP_EOL);
    });
} catch (Throwable $e) {
    fwrite(STDERR, 'marqius/wkhtmltopdf: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}
