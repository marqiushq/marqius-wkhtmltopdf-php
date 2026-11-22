#!/bin/sh
# Runs this README's install line and each library's example exactly as printed, each in a new
# project that already uses the library, and checks that each one makes a real PDF.
#
#   tests/examples.sh WORK [LIBRARY ...]
#
# LIBRARY is quickstart (the README's first three steps, in an empty folder), snappy, image,
# phpwkhtmltopdf, phpwkhtmltopdf-windows, cakepdf, laravel-snappy (no setting at all),
# laravel-snappy-config (the README's line in config/snappy.php), knpsnappybundle,
# knpsnappybundle-php or languages (the README's eight-language invoice, after its fonts line on
# Debian and Ubuntu); all but phpwkhtmltopdf-windows by default. With several, each runs on its
# own, and all are reported before the script fails. PLUGIN=allow (the default) lets Composer run the package's plugin,
# which fetches the program while Composer installs; PLUGIN=prompt answers Composer's trust
# question with y; PLUGIN=off leaves the plugin blocked, so the program is fetched on first use.
# MARQIUS_COMPOSER_REPO is a Composer repository (JSON) that holds marqius/wkhtmltopdf before
# Packagist does, such as {"type":"artifact","url":"/tmp/zips"}.
set -eu
pkg=$(cd "$(dirname "$0")/.." && pwd)
work=$1
shift
libraries=${*:-quickstart snappy image phpwkhtmltopdf cakepdf laravel-snappy laravel-snappy-config knpsnappybundle knpsnappybundle-php languages}

# several libraries: run each in a process of its own, so that one failing does not hide the rest
if [ "$(echo $libraries | wc -w)" -gt 1 ]; then
    failed=
    for lib in $libraries; do
        "$0" "$work" "$lib" || failed="$failed $lib"
    done
    if [ -n "$failed" ]; then
        printf '\n== FAILED:%s (plugin: %s)\n' "$failed" "${PLUGIN:-allow}" >&2
        exit 1
    fi
    printf '\n== all passed: %s (plugin: %s)\n' "$libraries" "${PLUGIN:-allow}"
    exit 0
fi
plugin=${PLUGIN:-allow}
. "$pkg/src/release.sh"
case $(uname -s) in MINGW* | MSYS* | CYGWIN*) exe=.exe ;; *) exe= ;; esac
export COMPOSER_NO_AUDIT=1

say() { printf '\n== %s\n' "$*"; }
fail() {
    echo "FAIL $lib: $*" >&2
    exit 1
}
readme() { php "$pkg/tests/readme.php" "$1"; }
fetched() { grep -qs "^$version " vendor/marqius/wkhtmltopdf/build/*/release; }

# Composer's repository for the package, then this README's install line, as printed
install_line() {
    if [ -n "${MARQIUS_COMPOSER_REPO:-}" ]; then
        composer config repositories.marqius "$MARQIUS_COMPOSER_REPO"
    fi
    line=$(readme install)
    say "$line"
    case $plugin in
    allow)
        allow=$(readme allow)
        say "$allow"
        sh -c "$allow"
        sh -c "$line" </dev/null
        fetched || fail "the plugin did not fetch the program while Composer installed"
        ;;
    prompt)
        # Composer asks only on a terminal: give it one (with expect), and answer y
        LINE=$line expect -c 'set timeout 600
            spawn sh -c $env(LINE)
            expect "Do you trust \"marqius/wkhtmltopdf\" to execute code" { send "y\r" }
            expect eof
            exit [lindex [wait] 3]'
        grep -q '"marqius/wkhtmltopdf": true' composer.json || fail "Composer's trust question did not allow the plugin"
        fetched || fail "the plugin did not fetch the program while Composer installed"
        ;;
    off)
        sh -c "$line" </dev/null
        ! fetched || fail "the program was fetched although the plugin is blocked"
        ;;
    esac
}

# a new project that uses the library already
project() {
    dir=$work/$lib
    rm -rf "$dir"
    mkdir -p "$dir"
    cd "$dir"
    echo '{}' >composer.json
    composer require --no-interaction "$@"
}

php_example() { # the README's block, in a script that loads Composer's autoloader
    { printf '<?php\nrequire __DIR__ . "/vendor/autoload.php";\n'; readme "example: $1"; } >render.php
    cat render.php
    php render.php
}

laravel_render() { # the README's Laravel line, in the application booted as for a request
    { printf '<?php\nrequire __DIR__ . "/vendor/autoload.php";\n$app = require __DIR__ . "/bootstrap/app.php";\n$app->make(Illuminate\\Contracts\\Console\\Kernel::class)->bootstrap();\n'; readme "example: laravel-snappy"; } >render.php
    php render.php
}

# what the program says of a page's letters: the README's own line for it where the system can run
# that (Linux and macOS), the program as Binary::path() gives it on Windows
program_says() {
    if [ -z "$exe" ]; then
        line=$(readme check)
        say "$line"
        sh -c "$line" >said.txt 2>&1 || true
    else
        bin=$(php -r 'require "vendor/autoload.php"; echo Marqius\Wkhtmltopdf\Binary::path();')
        "$(cygpath -u "$bin")" page.html page.pdf >said.txt 2>&1 || true
    fi
    cat said.txt
}

check() { # a file made by the example, and its first bytes
    [ -s "$1" ] || fail "no $1"
    head -c 8 "$1" | od -An -c | tr -d ' \n' | grep -q "$2" || fail "$1 does not start with $2"
    if [ "$2" = "%PDF-" ] && command -v pdftotext >/dev/null 2>&1; then
        pdftotext "$1" - | grep -q 'Invoice 42' || fail "$1 does not read Invoice 42"
    fi
    echo "ok $lib: $1 ($(wc -c <"$1" | tr -d ' ') bytes)"
}

for lib in $libraries; do
    say "$lib (plugin: $plugin)"
    case $lib in
    snappy | image)
        project knplabs/knp-snappy
        install_line
        if [ "$lib" = snappy ]; then
            php_example snappy
            check invoice.pdf %PDF-
        else
            printf '<?php\nrequire __DIR__ . "/vendor/autoload.php";\n(new Knp\\Snappy\\Image(Marqius\\Wkhtmltopdf\\Binary::imagePath()))->generateFromHtml("<h1>Invoice 42</h1>", "invoice.jpg");\n' >render.php
            php render.php
            check invoice.jpg 377330377
        fi
        ;;
    phpwkhtmltopdf)
        project mikehaertl/phpwkhtmltopdf
        install_line
        php_example phpwkhtmltopdf
        if [ ! -s invoice.pdf ]; then
            # the README's lines made no file: print the library's own error, and try the two settings
            # its README suggests for Windows (exec in place of proc_open; proc_open without cmd.exe)
            cat >why.php <<'PHP'
<?php
require __DIR__ . "/vendor/autoload.php";
foreach (["as printed" => [], "useExec" => ["useExec" => true], "bypass_shell" => ["procOptions" => ["bypass_shell" => true]]] as $how => $options) {
    $pdf = new mikehaertl\wkhtmlto\Pdf(["binary" => Marqius\Wkhtmltopdf\Binary::path(), "commandOptions" => $options]);
    $pdf->addPage("<html><h1>Invoice 42</h1></html>");
    $ok = $pdf->saveAs("why-$how.pdf");
    echo "phpwkhtmltopdf $how: ", $ok ? "made why-$how.pdf" : "failed: " . trim($pdf->getError()), "\n    command: ", $pdf->getCommand()->getExecCommand(), "\n";
}
// the program run directly: its error output as a pipe opened "w" or "a" (phpwkhtmltopdf opens it
// "a" on Windows), with and without --quiet, without a shell and through cmd.exe as phpwkhtmltopdf does
$bin = Marqius\Wkhtmltopdf\Binary::path();
$html = sys_get_temp_dir() . DIRECTORY_SEPARATOR . "why-direct.html";
file_put_contents($html, "<h1>Invoice 42</h1>");
foreach (["array", "cmd.exe"] as $form) {
    foreach (["w", "a"] as $mode) {
        foreach ([false, true] as $quiet) {
            $out = sys_get_temp_dir() . DIRECTORY_SEPARATOR . "why-direct-$form-$mode-" . ($quiet ? "q" : "v") . ".pdf";
            $args = array_merge($quiet ? ["--quiet"] : [], [$html, $out]);
            $cmd = $form === "array" ? array_merge([$bin], $args) : implode(" ", array_map("escapeshellarg", array_merge([$bin], $args)));
            $p = proc_open($cmd, [1 => ["pipe", "w"], 2 => ["pipe", $mode]], $pipes);
            $o = @stream_get_contents($pipes[1]);
            $e = (string) @stream_get_contents($pipes[2]);
            fclose($pipes[1]);
            fclose($pipes[2]);
            $code = proc_close($p);
            printf("direct, %s, error output pipe \"%s\"%s: exit %d, %s, error output %d bytes: %s\n", $form, $mode, $quiet ? ", --quiet" : "", $code, is_file($out) && filesize($out) > 0 ? "PDF made" : "no PDF", strlen($e), substr(str_replace(["\r", "\n"], " ", trim($e)), 0, 160));
        }
    }
}
PHP
            php why.php || true
        fi
        check invoice.pdf %PDF-
        ;;
    phpwkhtmltopdf-windows)
        # the README's Windows lines for phpwkhtmltopdf (useExec), until 0.12.14 fixes its default settings there
        project mikehaertl/phpwkhtmltopdf
        install_line
        php_example "phpwkhtmltopdf windows"
        check invoice.pdf %PDF-
        ;;
    cakepdf)
        project "friendsofcake/cakepdf:^5.0"
        install_line
        php_example cakepdf
        check invoice.pdf %PDF-
        ;;
    quickstart)
        # the README's three steps, as printed, in a new folder: empty, but for Composer's settings
        # where the package comes from an artifact repository or Composer is let run its plugin
        dir=$work/$lib
        rm -rf "$dir"
        mkdir -p "$dir"
        cd "$dir"
        if [ -n "${MARQIUS_COMPOSER_REPO:-}" ]; then
            echo '{}' >composer.json
            composer config repositories.marqius "$MARQIUS_COMPOSER_REPO"
        fi
        if [ "$plugin" = allow ]; then
            [ -f composer.json ] || echo '{}' >composer.json
            sh -c "$(readme allow)"
        fi
        line=$(readme quickstart)
        say "$line"
        sh -c "$line" </dev/null
        readme "example: quickstart invoice.php" >invoice.php
        cat invoice.php
        line=$(readme run)
        say "$line"
        sh -c "$line"
        check invoice.pdf %PDF-
        ;;
    languages)
        project knplabs/knp-snappy
        install_line
        # the page in the README's example, as page.html for the program's own line
        readme "example: languages" | php -r '$s = stream_get_contents(STDIN); preg_match("{<<<.HTML.\n(.*?)\nHTML;}s", $s, $m) || exit(1); file_put_contents("page.html", $m[1] . "\n");'
        if [ -f /etc/debian_version ]; then
            # before the fonts: what the program says, and that it names Debian's Noto packages
            program_says
            if grep -q 'no font has a glyph' said.txt; then
                grep -q 'fonts-noto' said.txt || fail "the program named letters with no font, but no fonts-noto package to install"
            fi
            line=$(readme "fonts: debian")
            say "$line"
            sh -c "$line"
        fi
        php_example languages
        check invoice.pdf %PDF-
        # every word as written, where pdftotext can be had
        if ! command -v pdftotext >/dev/null 2>&1; then
            if [ -f /etc/debian_version ]; then
                sudo apt-get install -y -qq poppler-utils >/dev/null || true
            elif [ "$(uname -s)" = Darwin ]; then
                brew install -q poppler >/dev/null || true
            fi
        fi
        if command -v pdftotext >/dev/null 2>&1; then
            # UTF-8 said outright: the pdftotext that comes with Git on Windows writes Latin-1 otherwise
            pdftotext -v 2>&1 | head -n 1
            pdftotext -enc UTF-8 invoice.pdf - >text.txt
            cat text.txt
            for word in 'Invoice 42' 'فاتورة' 'חשבונית' 'चालान' 'ใบแจ้งหนี้' '发票' '請求書' '청구서'; do
                grep -qF "$word" text.txt || fail "invoice.pdf does not read $word as written"
            done
            echo "ok $lib: every word reads back as written"
        fi
        # after the fonts, or with the system's own: no letter without a font
        program_says
        ! grep -q 'no font has a glyph' said.txt || fail "letters with no font on this system"
        ;;
    laravel-snappy)
        # no setting at all: Laravel discovers the package, which points laravel-snappy at the program,
        # with laravel-snappy's own configuration, then with config/snappy.php published as it comes
        rm -rf "$work/$lib"
        composer create-project --no-interaction --no-progress laravel/laravel "$work/$lib"
        cd "$work/$lib"
        composer require --no-interaction barryvdh/laravel-snappy
        install_line
        grep -qF 'Marqius\\Wkhtmltopdf\\LaravelServiceProvider' bootstrap/cache/packages.php || fail "Laravel did not discover the package's provider"
        laravel_render
        check invoice.pdf %PDF-
        rm -f invoice.pdf
        php artisan vendor:publish --provider="Barryvdh\Snappy\ServiceProvider"
        grep -n "binary" config/snappy.php
        laravel_render
        check invoice.pdf %PDF-
        ;;
    laravel-snappy-config)
        rm -rf "$work/$lib"
        composer create-project --no-interaction --no-progress laravel/laravel "$work/$lib"
        cd "$work/$lib"
        composer require --no-interaction barryvdh/laravel-snappy
        install_line
        php artisan vendor:publish --provider="Barryvdh\Snappy\ServiceProvider"
        # the README's line in place of the published one, under pdf, and its image twin
        line=$(readme "example: laravel-snappy config/snappy.php")
        LINE=$line php -r '
            $c = file_get_contents("config/snappy.php");
            $pdf = getenv("LINE");
            $image = str_replace("Binary::path()", "Binary::imagePath()", $pdf);
            $c = preg_replace("{\x27binary\x27\s*=>\s*env\(\x27WKHTML_PDF_BINARY\x27[^\n]*}", $pdf, $c, 1, $a);
            $c = preg_replace("{\x27binary\x27\s*=>\s*env\(\x27WKHTML_IMG_BINARY\x27[^\n]*}", $image, $c, 1, $b);
            if ($a + $b !== 2) { fwrite(STDERR, "config/snappy.php has no binary lines to replace\n"); exit(1); }
            file_put_contents("config/snappy.php", $c);'
        grep -n "Binary::" config/snappy.php
        laravel_render
        check invoice.pdf %PDF-
        ;;
    knpsnappybundle | knpsnappybundle-php)
        rm -rf "$work/$lib"
        composer create-project --no-interaction --no-progress symfony/skeleton "$work/$lib"
        cd "$work/$lib"
        composer require --no-interaction knplabs/knp-snappy-bundle
        install_line
        # Flex skips the bundle's community recipe when it is not allowed to run it
        grep -q KnpSnappyBundle config/bundles.php || php -r '
            $b = file_get_contents("config/bundles.php");
            file_put_contents("config/bundles.php", str_replace("];", "    Knp\\Bundle\\SnappyBundle\\KnpSnappyBundle::class => [\"all\" => true],\n];", $b));'
        # the README's YAML, or for knpsnappybundle-php its PHP (the form for Windows)
        rm -f config/packages/knp_snappy.yaml config/packages/knp_snappy.php
        if [ "$lib" = knpsnappybundle ]; then
            readme "example: knpsnappybundle config/packages/knp_snappy.yaml" >config/packages/knp_snappy.yaml
        else
            readme "example: knpsnappybundle config/packages/knp_snappy.php" >config/packages/knp_snappy.php
        fi
        # the bundle's services are private: a public name for this test only
        printf 'services:\n    marqius_test.pdf:\n        alias: knp_snappy.pdf\n        public: true\n' >config/packages/marqius_test.yaml
        rm -rf var/cache
        # the README's line, with $pdf the bundle's Knp\Snappy\Pdf service
        { printf '<?php\nrequire __DIR__ . "/vendor/autoload.php";\n$kernel = new App\\Kernel("dev", true);\n$kernel->boot();\n$pdf = $kernel->getContainer()->get("marqius_test.pdf");\n'; readme "example: knpsnappybundle"; } >render.php
        php render.php
        check invoice.pdf %PDF-
        ;;
    *)
        fail "no such library"
        ;;
    esac
    fetched || fail "the program of release $version is not in vendor/marqius/wkhtmltopdf/build"
    if [ -z "$exe" ]; then
        vendor/marqius/wkhtmltopdf/bin/wkhtmltopdf -V | grep "compatible; marqius-wkhtmltopdf $version" || fail "bin/wkhtmltopdf -V"
    fi
    vendor/bin/marqius-wkhtmltopdf --version | grep -x "marqius-wkhtmltopdf $version" || fail "vendor/bin/marqius-wkhtmltopdf --version"
done
say "all passed: $libraries (plugin: $plugin)"
