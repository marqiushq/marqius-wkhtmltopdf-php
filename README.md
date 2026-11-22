# wkhtmltopdf for PHP: marqius-wkhtmltopdf for Laravel, Symfony, CakePHP and Snappy

[![Packagist](https://img.shields.io/packagist/v/marqius/wkhtmltopdf)](https://packagist.org/packages/marqius/wkhtmltopdf) [![PHP](https://img.shields.io/packagist/dependency-v/marqius/wkhtmltopdf/php)](https://packagist.org/packages/marqius/wkhtmltopdf) [![Tested on Linux, macOS and Windows](https://github.com/marqiushq/marqius-wkhtmltopdf-php/actions/workflows/release.yml/badge.svg)](https://github.com/marqiushq/marqius-wkhtmltopdf-php/actions/workflows/release.yml)

**marqius-wkhtmltopdf is the maintained drop-in replacement for wkhtmltopdf, installed with Composer.** One command installs it. laravel-snappy, Snappy, KnpSnappyBundle, CakePdf and phpwkhtmltopdf then turn your HTML into PDFs as before. It prints Arabic, Hebrew, Hindi, Thai, Chinese, Japanese and Korean as well as English, on Linux, Mac and Windows.

- **One command to install.** No apt packages, no libssl 1.1, no X server, no Qt.
- **Nothing to set up in Laravel.** Install it, and laravel-snappy uses it.
- **Your templates stay as they are.** The same HTML, the same options, the same library.
- **Many languages, even on one page.** Arabic and Hebrew from right to left, Indian and Asian scripts, all as text you can search and copy.
- **Fast.** A one-page invoice takes a few milliseconds.
- **Tested in public.** Every version is tested with all five libraries on Linux, macOS and Windows before it is published.

## Make your first PDF in two minutes

**1. Install** the package and Snappy, the most used PHP library for wkhtmltopdf. Run this in your project, or in an empty folder:

<!-- quickstart -->
```bash
composer require marqius/wkhtmltopdf knplabs/knp-snappy
```

If Composer asks whether to trust `marqius/wkhtmltopdf`, answer `y`. It then fetches the program for your computer, checked against its published SHA-256. If you answer `n`, the program is fetched the first time you make a PDF.

**2. Save** this as `invoice.php`:

<!-- example: quickstart invoice.php -->
```php
<?php
require __DIR__ . '/vendor/autoload.php';

use Knp\Snappy\Pdf;
use Marqius\Wkhtmltopdf\Binary;

$pdf = new Pdf(Binary::path());
$pdf->generateFromHtml('<h1>Invoice 42</h1><p>Thank you for your order.</p>', 'invoice.pdf');
```

**3. Run** it, then open `invoice.pdf`:

<!-- run -->
```bash
php invoice.php
```

That's it. Next, connect your framework, or [print other languages](#which-languages-can-it-print).

## What do I change in my framework?

| You use | What to do |
|---|---|
| Laravel, with laravel-snappy | [Nothing](#how-do-i-use-wkhtmltopdf-in-laravel): install the package |
| Symfony, with KnpSnappyBundle | [Two lines of YAML](#how-do-i-use-wkhtmltopdf-in-symfony) |
| CakePHP, with CakePdf | [One setting](#how-do-i-use-wkhtmltopdf-in-cakephp) |
| Snappy, in any PHP code | [Give it `Binary::path()`](#how-do-i-use-wkhtmltopdf-with-snappy) |
| phpwkhtmltopdf | [One option](#how-do-i-use-wkhtmltopdf-with-phpwkhtmltopdf) |

## How do I install wkhtmltopdf with Composer?

<!-- install -->
```bash
composer require marqius/wkhtmltopdf
```

Answer `y` when Composer asks whether to trust `marqius/wkhtmltopdf`, and it fetches the program for your machine while it installs. In CI or a Docker build, allow it first, so that the program is in place before your app runs:

<!-- allow -->
```bash
composer config allow-plugins.marqius/wkhtmltopdf true
```

Nothing is installed under the name `wkhtmltopdf` on your system. Your library gets the program's path from `Marqius\Wkhtmltopdf\Binary::path()`, or `Binary::imagePath()` for pictures.

## How do I use wkhtmltopdf in Laravel?

Install the package. That's all: laravel-snappy finds marqius-wkhtmltopdf by itself, and you make PDFs as before:

<!-- example: laravel-snappy -->
```php
Barryvdh\Snappy\Facades\SnappyPdf::loadHTML('<h1>Invoice 42</h1>')->save('invoice.pdf');
```

Laravel discovers the package, and the package points laravel-snappy at marqius-wkhtmltopdf. If your settings name another wkhtmltopdf that is installed, that one is used: delete the setting to switch.

To name the program yourself, put it in `config/snappy.php` under `pdf`, and `Binary::imagePath()` under `image`. `php artisan vendor:publish --provider="Barryvdh\Snappy\ServiceProvider"` writes the file.

<!-- example: laravel-snappy config/snappy.php -->
```php
'binary' => Marqius\Wkhtmltopdf\Binary::path(),
```

If your app caches its configuration, run `php artisan config:clear` after the change.

## How do I use wkhtmltopdf in Symfony?

With KnpSnappyBundle, write this in `config/packages/knp_snappy.yaml`:

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

On Windows, where that path cannot run, write `config/packages/knp_snappy.php` instead. It works on every system:

<!-- example: knpsnappybundle config/packages/knp_snappy.php -->
```php
<?php
return static function (Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator $container) {
    $container->extension('knp_snappy', ['pdf' => ['binary' => Marqius\Wkhtmltopdf\Binary::path()], 'image' => ['binary' => Marqius\Wkhtmltopdf\Binary::imagePath()]]);
};
```

## How do I use wkhtmltopdf in CakePHP?

With CakePdf, in `config/bootstrap.php`, or before you make a PDF:

<!-- example: cakepdf -->
```php
Cake\Core\Configure::write('CakePdf.engine', ['className' => 'CakePdf.WkHtmlToPdf', 'binary' => Marqius\Wkhtmltopdf\Binary::path()]);
(new CakePdf\Pdf\CakePdf())->write('invoice.pdf', true, '<h1>Invoice 42</h1>');
```

## How do I use wkhtmltopdf with Snappy?

Give Snappy the path:

<!-- example: snappy -->
```php
$snappy = new Knp\Snappy\Pdf(Marqius\Wkhtmltopdf\Binary::path());
$snappy->generateFromHtml('<h1>Invoice 42</h1>', 'invoice.pdf');
```

Pictures work the same way: `new Knp\Snappy\Image(Marqius\Wkhtmltopdf\Binary::imagePath())`.

## How do I use wkhtmltopdf with phpwkhtmltopdf?

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

## Which languages can it print?

All of these, even on one page. Each one is tested on real invoices, letters and receipts, and the PDF keeps the words as text, so you can search and copy them.

| Language | On a Linux server | On a Mac or Windows |
|---|---|---|
| English, French, German, Spanish and other languages in Latin letters; Greek; Russian | Works with the fonts most servers have | Works |
| Arabic and Hebrew, from right to left | Works: the fonts are built in | Works |
| Hindi and Thai | Install `fonts-noto-core` | Works |
| Chinese, Japanese and Korean | Install `fonts-noto-cjk` | Works |

On Debian or Ubuntu, this one line installs the fonts for every language above:

<!-- fonts: debian -->
```bash
sudo apt-get update && sudo apt-get install -y fonts-noto-core fonts-noto-cjk
```

In a Dockerfile, put the same line after `RUN`, without `sudo`. On Alpine, Fedora, Red Hat or Arch, the program tells you the line for your system ([see below](#why-do-letters-show-as-boxes-or-blanks-in-my-pdf)).

Then one invoice can carry them all:

<!-- example: languages -->
```php
$html = <<<'HTML'
<!doctype html>
<meta charset="utf-8">
<h1>Invoice 42</h1>
<p lang="ar" dir="rtl">فاتورة 42</p>
<p lang="he" dir="rtl">חשבונית 42</p>
<p lang="hi">चालान 42</p>
<p lang="th">ใบแจ้งหนี้ 42</p>
<p lang="zh">发票 42</p>
<p lang="ja">請求書 42</p>
<p lang="ko">청구서 42</p>
HTML;

$pdf = new Knp\Snappy\Pdf(Marqius\Wkhtmltopdf\Binary::path());
$pdf->generateFromHtml($html, 'invoice.pdf');
```

For a page all in Arabic or Hebrew, put `dir="rtl"` on its `<html>` tag. The page then reads from the right, and its tables and lists turn to match.

## Why do letters show as boxes or blanks in my PDF?

The computer that makes the PDF has no font for them. On Linux, install the fonts [above](#which-languages-can-it-print). To see what is missing, convert your page with the program itself:

<!-- check -->
```bash
vendor/marqius/wkhtmltopdf/bin/wkhtmltopdf page.html page.pdf
```

It names each letter it could not print, then gives the one line that installs fonts for them on your system: `apt-get` on Debian and Ubuntu, `apk` on Alpine, `dnf` on Fedora and Red Hat, `pacman` on Arch.

## Why can't I search or copy Arabic, Chinese or Hindi text in my wkhtmltopdf PDF?

wkhtmltopdf often stores these scripts as shapes, not words. The public parity suite prints the same pages with both programs:

- **Arabic:** from wkhtmltopdf's invoice, 2 of its 56 words read back as written; from marqius-wkhtmltopdf's, 48.
- **Hebrew:** wkhtmltopdf splits many words into single letters (28 of 48 read back); marqius-wkhtmltopdf gives back 43.
- **Chinese:** wkhtmltopdf puts look-alike signs in place of some characters, so a search for the company's name finds nothing. marqius-wkhtmltopdf keeps the real characters.
- **Hindi and Thai:** wkhtmltopdf loses letters and splits off marks. marqius-wkhtmltopdf's text reads back clean.

The pages themselves look the same. [See every page and score](https://github.com/marqiushq/wkhtmltopdf-parity).

## Why are accented letters garbled, like Ã© for é?

Your page does not say that it is UTF-8, so wkhtmltopdf reads it as an old Western character set. marqius-wkhtmltopdf prints é, € and ü as written anyway. To make every program agree, put `<meta charset="utf-8">` at the top of your page.

## What replaces h4cc/wkhtmltopdf-amd64?

marqius-wkhtmltopdf does. Run `composer remove h4cc/wkhtmltopdf-amd64`, then `composer require marqius/wkhtmltopdf`. Replace the old path in your settings with `Marqius\Wkhtmltopdf\Binary::path()`; in Laravel, just delete it.

## Why does Snappy say "The exit status code '127' says something went wrong"?

Exit status 127 means the program Snappy runs was not found. Install this package and give Snappy `Marqius\Wkhtmltopdf\Binary::path()`, as shown above.

## Why does wkhtmltopdf fail with "libssl.so.1.1: cannot open shared object file"?

Your wkhtmltopdf was built for an older system. It needs OpenSSL 1.1, which Debian 13 and Ubuntu 24.04 no longer include. marqius-wkhtmltopdf needs no system libraries, so it runs there as it is.

## Is it faster than wkhtmltopdf?

Yes. The public parity suite converts 86 documents with both programs on the same machine. marqius-wkhtmltopdf is 35 times faster, or 5 times faster with wkhtmltopdf's 200 ms wait for scripts turned off for both. On Linux, a one-page invoice takes 5 to 7 milliseconds.

## Will my PDFs look the same as with wkhtmltopdf?

Almost always. Of the parity suite's 86 documents, 64 come out the same, and 16 differ only in small details of appearance. Each difference is listed with its reason. To check your own templates, make a PDF with each program and compare them:

```bash
vendor/bin/marqius-wkhtmltopdf compare old.pdf new.pdf
```

## Which systems does it run on?

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

Yes. The suites of laravel-snappy and phpwkhtmltopdf run the program, and every test passes with marqius-wkhtmltopdf. Snappy's, KnpSnappyBundle's and CakePdf's pass too, though they check only the library's own code. The results are public: [wkhtmltopdf library tests](https://github.com/marqiushq/wkhtmltopdf-library-tests).

Before each version of this package is published, [its workflow](https://github.com/marqiushq/marqius-wkhtmltopdf-php/blob/main/.github/workflows/release.yml) installs it with Composer and runs the examples on this page, the eight-language invoice among them, on Linux (x86-64 and ARM64), macOS and Windows.

## How do I update it?

This package follows each release of marqius-wkhtmltopdf, after testing it. To move to the newest:

```bash
composer update marqius/wkhtmltopdf
```

## What else does the program do?

`vendor/bin/marqius-wkhtmltopdf` runs it under its own name:

- `vendor/bin/marqius-wkhtmltopdf help snappy` shows each library's setting;
- `vendor/bin/marqius-wkhtmltopdf compare old.pdf new.pdf` lists every difference between a PDF made by wkhtmltopdf and one made by marqius-wkhtmltopdf;
- `vendor/bin/marqius-wkhtmltopdf install` gives it the names `wkhtmltopdf` and `wkhtmltoimage` for everything on a server, with the rights to write to `/usr/local/bin`.

## Where do I get help?

Write to hello@marqius.com, or [open an issue](https://github.com/marqiushq/marqius-wkhtmltopdf-php/issues). Send the page that prints differently from wkhtmltopdf if you can.

This package's own PHP files are under the MIT licence: [LICENSE.md](LICENSE.md).
