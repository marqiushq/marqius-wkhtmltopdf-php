<?php
/*
 * marqius/wkhtmltopdf: marqius-wkhtmltopdf for PHP's wkhtmltopdf libraries.
 * marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial and a
 * free Community licence for personal, teaching and open-source use:
 * https://marqius.com/licence/marqius-wkhtmltopdf
 */

namespace Marqius\Wkhtmltopdf;

use Illuminate\Support\ServiceProvider;

/**
 * Lets laravel-snappy use marqius-wkhtmltopdf with no setting. Laravel finds this provider by
 * itself (package discovery), and it only acts when laravel-snappy makes a PDF or a picture.
 *
 * Where laravel-snappy would run its default program (/usr/local/bin/wkhtmltopdf, or
 * wkhtmltoimage for pictures), or a program that is not there, it runs marqius-wkhtmltopdf
 * instead. A path you set to a program that is there is kept.
 *
 * To turn it off, list "marqius/wkhtmltopdf" under extra.laravel.dont-discover in your
 * application's composer.json.
 */
final class LaravelServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->afterResolving('snappy.pdf', static function ($pdf) {
            self::point($pdf, '/usr/local/bin/wkhtmltopdf', 'path');
        });
        $this->app->afterResolving('snappy.image', static function ($image) {
            self::point($image, '/usr/local/bin/wkhtmltoimage', 'imagePath');
        });
    }

    /**
     * Gives a Snappy generator this package's program, unless it was given a program that is there.
     *
     * @param object $generator laravel-snappy's Knp\Snappy\Pdf or Knp\Snappy\Image
     * @param string $default   laravel-snappy's own default path for it
     * @param string $method    Binary::path or Binary::imagePath
     *
     * @internal
     */
    public static function point($generator, string $default, string $method)
    {
        if (!is_object($generator) || !method_exists($generator, 'getBinary') || !method_exists($generator, 'setBinary')) {
            return;
        }
        // laravel-snappy's README has paths with spaces put in double quotes
        $set = trim((string) $generator->getBinary(), " \t\"'");
        if ($set === '' || $set === $default || !is_file($set)) {
            $generator->setBinary(Binary::$method());
        }
    }
}
