# marqius-wkhtmltopdf: wkhtmltopdf for PHP, Snappy, Laravel, Symfony and CakePHP

**marqius-wkhtmltopdf is the maintained drop-in replacement for wkhtmltopdf, as a Composer package.** `composer require` it, give your library its path in one line, and Snappy, laravel-snappy, phpwkhtmltopdf, KnpSnappyBundle or CakePdf keep making PDFs from your HTML. It replaces the abandoned `h4cc/wkhtmltopdf-amd64` package, and runs on Linux (x86-64 and ARM64, including Debian 13 and Ubuntu 24.04), Apple silicon Macs and Windows (x86-64).

## How do I install wkhtmltopdf with Composer?

<!-- install -->
```bash
composer require marqius/wkhtmltopdf
```

Composer asks whether to trust `marqius/wkhtmltopdf`. Answer `y`, and it fetches the program for your machine while it installs the package, checked against the SHA-256 published with the release. In CI or a Docker build, allow it first with `composer config allow-plugins.marqius/wkhtmltopdf true`. Without that, the program is fetched the first time your library runs it.

It installs nothing under the name `wkhtmltopdf` on your system: your library gets the program's path from `Marqius\Wkhtmltopdf\Binary::path()`, as below.

## How do I use wkhtmltopdf with Snappy?

Give Snappy the path:

<!-- example: snappy -->
```php
$snappy = new Knp\Snappy\Pdf(Marqius\Wkhtmltopdf\Binary::path());
$snappy->generateFromHtml('<h1>Invoice 42</h1>', 'invoice.pdf');
```

Pictures work the same way: `new Knp\Snappy\Image(Marqius\Wkhtmltopdf\Binary::imagePath())`.

## How do I use it with laravel-snappy in Laravel?

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

## How do I use it with phpwkhtmltopdf?

<!-- example: phpwkhtmltopdf -->
```php
$pdf = new mikehaertl\wkhtmlto\Pdf(['binary' => Marqius\Wkhtmltopdf\Binary::path()]);
$pdf->addPage('<html><h1>Invoice 42</h1></html>')->saveAs('invoice.pdf');
```

**On Windows, until marqius-wkhtmltopdf 0.12.14,** give phpwkhtmltopdf its `useExec` option, as below. With phpwkhtmltopdf's default settings on Windows, the program stops before it writes the PDF.

<!-- example: phpwkhtmltopdf windows -->
```php
$pdf = new mikehaertl\wkhtmlto\Pdf(['binary' => Marqius\Wkhtmltopdf\Binary::path(), 'commandOptions' => ['useExec' => true]]);
$pdf->addPage('<html><h1>Invoice 42</h1></html>')->saveAs('invoice.pdf');
```

## How do I use it with KnpSnappyBundle in Symfony?

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

## How do I use it with CakePdf in CakePHP?

In `config/bootstrap.php`, or before you make a PDF:

<!-- example: cakepdf -->
```php
Cake\Core\Configure::write('CakePdf.engine', ['className' => 'CakePdf.WkHtmlToPdf', 'binary' => Marqius\Wkhtmltopdf\Binary::path()]);
(new CakePdf\Pdf\CakePdf())->write('invoice.pdf', true, '<h1>Invoice 42</h1>');
```

## What replaces h4cc/wkhtmltopdf-amd64?

marqius-wkhtmltopdf does. Run `composer remove h4cc/wkhtmltopdf-amd64`, then `composer require marqius/wkhtmltopdf`, and replace the old path in your settings with `Marqius\Wkhtmltopdf\Binary::path()`.

## Why does Snappy say "The exit status code '127' says something went wrong"?

Exit status 127 means the program Snappy runs was not found. Install this package and give Snappy `Marqius\Wkhtmltopdf\Binary::path()`, as shown above.

## Why does wkhtmltopdf fail with "libssl.so.1.1: cannot open shared object file"?

Your wkhtmltopdf was built for an older system. It needs OpenSSL 1.1, which Debian 13 and Ubuntu 24.04 no longer include. marqius-wkhtmltopdf needs no system libraries, so it runs there as it is.

## Which systems does marqius-wkhtmltopdf run on?

It runs on:

- Linux on x86-64 and ARM64;
- Macs with Apple silicon;
- Windows on x86-64.

The package fetches the right program for each. It needs no X server, Qt or system libraries. In a slim or Alpine image without fonts, the program says so and prints the one line that installs them.

## Is marqius-wkhtmltopdf free?

You can try it free for 30 days. Personal, teaching and open-source use is free with a [Community licence](https://marqius.com/wkhtmltopdf-buy/#community): sign in with Google and your free key is waiting in your account.

Anything done by or for a business, including internal tools and client work, needs Starter or above once the trial ends. Starter is $290 USD a year for organisations of up to 10 people, and Business $990 USD a year, plus applicable taxes.

Your PDFs never stop. Without a licence after the trial, each page carries one line, "Prepared by Marqius, Purchase Licence". [Plans and licences](https://marqius.com/licence/marqius-wkhtmltopdf) · [Licence terms](https://marqius.com/wkhtmltopdf/licence-agreement/)

## How do I add my licence key?

Set the `MARQIUS_LICENCE` environment variable to your licence; that is the way for containers and CI. Or save it as `licence.txt` and run `vendor/bin/marqius-wkhtmltopdf licence add licence.txt`. `vendor/bin/marqius-wkhtmltopdf licence` shows the trial's days left, or the licence in force.

## Do these libraries pass their own tests?

Yes. Snappy, laravel-snappy, phpwkhtmltopdf, KnpSnappyBundle and CakePdf pass their own test suites with marqius-wkhtmltopdf. The results are public: [wkhtmltopdf library tests](https://github.com/marqiushq/wkhtmltopdf-library-tests).

Before each version of this package is published, [its workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-php/blob/main/.github/workflows/release.yml) installs it with Composer and runs the examples on this page on Linux (x86-64 and ARM64), macOS and Windows.

## How do I update it?

Each version of this package carries the marqius-wkhtmltopdf release with the same number. To move to the newest:

```bash
composer update marqius/wkhtmltopdf
```

## What else does the program do?

`vendor/bin/marqius-wkhtmltopdf` runs it under its own name:

- `vendor/bin/marqius-wkhtmltopdf help snappy` shows each library's setting;
- `vendor/bin/marqius-wkhtmltopdf compare old.pdf new.pdf` lists every difference between a PDF made by wkhtmltopdf and one made by marqius-wkhtmltopdf;
- `vendor/bin/marqius-wkhtmltopdf install` gives it the names `wkhtmltopdf` and `wkhtmltoimage` for everything on a server, with the rights to write to `/usr/local/bin`.

This package's own PHP files are under the MIT licence: [LICENSE.md](LICENSE.md).
