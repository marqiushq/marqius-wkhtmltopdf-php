# marqius-wkhtmltopdf for PHP

**marqius-wkhtmltopdf** is the maintained drop-in replacement for wkhtmltopdf. This Composer package brings it to your project for Snappy, laravel-snappy, phpwkhtmltopdf, KnpSnappyBundle and CakePdf: keep your library, your HTML templates and your PDF calls, and point the library at it with one line. It runs on Linux (x86-64 and ARM64), Apple silicon Macs and Windows (x86-64), and needs no X server, Qt or system libraries.

<!-- install -->
```bash
composer require marqius/wkhtmltopdf
```

Composer asks whether to trust `marqius/wkhtmltopdf`. Answer `y`, and it fetches the program for your machine while it installs the package, checked against the SHA-256 published with the release. In CI or a Docker build, allow it first with `composer config allow-plugins.marqius/wkhtmltopdf true`. Without that, the program is fetched the first time your library runs it.

On a server or in a container without fonts, such as a slim or Alpine image, the program says so and prints the one line that installs them for that system.

## Point your library at it

`Marqius\Wkhtmltopdf\Binary::path()` gives the installed program's path: give it to your library where it asks for the wkhtmltopdf binary, and `Binary::imagePath()` where it asks for wkhtmltoimage. Each is a path inside `vendor/`; nothing is installed under the name `wkhtmltopdf` on your system.

### Snappy

<!-- example: snappy -->
```php
$snappy = new Knp\Snappy\Pdf(Marqius\Wkhtmltopdf\Binary::path());
$snappy->generateFromHtml('<h1>Invoice 42</h1>', 'invoice.pdf');
```

Pictures work the same way: `new Knp\Snappy\Image(Marqius\Wkhtmltopdf\Binary::imagePath())`.

### laravel-snappy

In `config/snappy.php` (`php artisan vendor:publish --provider="Barryvdh\Snappy\ServiceProvider"` writes it), name the binary under `pdf`, and `Binary::imagePath()` under `image`:

<!-- example: laravel-snappy config/snappy.php -->
```php
'binary' => Marqius\Wkhtmltopdf\Binary::path(),
```

Then make PDFs as before:

<!-- example: laravel-snappy -->
```php
Barryvdh\Snappy\Facades\SnappyPdf::loadHTML('<h1>Invoice 42</h1>')->save('invoice.pdf');
```

If your app caches its configuration, run `php artisan config:clear` after the change.

### phpwkhtmltopdf

<!-- example: phpwkhtmltopdf -->
```php
$pdf = new mikehaertl\wkhtmlto\Pdf(['binary' => Marqius\Wkhtmltopdf\Binary::path()]);
$pdf->addPage('<html><h1>Invoice 42</h1></html>')->saveAs('invoice.pdf');
```

### KnpSnappyBundle

In `config/packages/knp_snappy.yaml`:

<!-- example: knpsnappybundle config/packages/knp_snappy.yaml -->
```yaml
knp_snappy:
    pdf:
        binary: '%kernel.project_dir%/vendor/marqius/wkhtmltopdf/bin/wkhtmltopdf'
    image:
        binary: '%kernel.project_dir%/vendor/marqius/wkhtmltopdf/bin/wkhtmltoimage'
```

Then make PDFs as before, with the `Knp\Snappy\Pdf` service:

<!-- example: knpsnappybundle -->
```php
$pdf->generateFromHtml('<h1>Invoice 42</h1>', 'invoice.pdf');
```

On Windows, where that path cannot run, write `config/packages/knp_snappy.php` instead (it works on every system):

<!-- example: knpsnappybundle config/packages/knp_snappy.php -->
```php
<?php
return static function (Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator $container) {
    $container->extension('knp_snappy', ['pdf' => ['binary' => Marqius\Wkhtmltopdf\Binary::path()], 'image' => ['binary' => Marqius\Wkhtmltopdf\Binary::imagePath()]]);
};
```

### CakePdf

In `config/bootstrap.php`, or before you make a PDF:

<!-- example: cakepdf -->
```php
Cake\Core\Configure::write('CakePdf.engine', ['className' => 'CakePdf.WkHtmlToPdf', 'binary' => Marqius\Wkhtmltopdf\Binary::path()]);
(new CakePdf\Pdf\CakePdf())->write('invoice.pdf', true, '<h1>Invoice 42</h1>');
```

## The program itself

`vendor/bin/marqius-wkhtmltopdf` runs it under its own name: `vendor/bin/marqius-wkhtmltopdf help snappy` shows each library's setting, `vendor/bin/marqius-wkhtmltopdf compare old.pdf new.pdf` lists every difference between a PDF made by wkhtmltopdf and one made by marqius-wkhtmltopdf, and `vendor/bin/marqius-wkhtmltopdf licence` shows the trial days left.

To give it the names `wkhtmltopdf` and `wkhtmltoimage` for everything on a server, as the [one-line installer](https://marqius.com/wkhtmltopdf/download/) does, run `vendor/bin/marqius-wkhtmltopdf install` with the rights to write to `/usr/local/bin`.

## Always the latest release

Each release of this package carries one release of marqius-wkhtmltopdf, with the same version number. [A workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-php/blob/main/.github/workflows/release.yml) follows marqius.com every hour: a new release is checked against its published checksums, installed with Composer and run through Snappy, laravel-snappy, phpwkhtmltopdf, KnpSnappyBundle and CakePdf on Linux (x86-64 and ARM64), macOS (Apple silicon) and Windows, and only then published here. To move to it:

```bash
composer update marqius/wkhtmltopdf
```

## Licence

marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial counted from its first run. After the trial, without a licence, each page carries one line saying the copy is unlicensed. [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

## Before you switch

- [wkhtmltopdf parity suite](https://github.com/marqiushq/wkhtmltopdf-parity): the same HTML documents through wkhtmltopdf and marqius-wkhtmltopdf on every release, misses included.
- [The developer manual](https://marqius.com/download/developer-manual.pdf), one chapter per library, and [runnable examples](https://github.com/marqiushq/marqius-wkhtmltopdf-examples).
- Moving from `h4cc/wkhtmltopdf-amd64`? Run `composer remove h4cc/wkhtmltopdf-amd64`, then replace its path in your settings with `Marqius\Wkhtmltopdf\Binary::path()`.
