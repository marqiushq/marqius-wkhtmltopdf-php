<?php
/*
 * marqius/wkhtmltopdf: marqius-wkhtmltopdf for PHP's wkhtmltopdf libraries.
 * marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial:
 * https://marqius.com/licence/marqius-wkhtmltopdf
 */

namespace Marqius\Wkhtmltopdf;

/**
 * The paths to give a wkhtmltopdf library such as Snappy, laravel-snappy, phpwkhtmltopdf,
 * KnpSnappyBundle or CakePdf, where it asks for its binary:
 *
 *     $snappy = new \Knp\Snappy\Pdf(\Marqius\Wkhtmltopdf\Binary::path());
 *
 * This package carries the SHA-256 published with its release of marqius-wkhtmltopdf. The program
 * for this machine is fetched from marqius.com when Composer installs the package (if you let
 * Composer run it) or else on the first call here, and is used only if it matches.
 */
final class Binary
{
    const BASE = 'https://marqius.com/download/marqius-wkhtmltopdf';

    /** The release of marqius-wkhtmltopdf this package carries, such as "0.12.10". */
    public static function version(): string
    {
        return self::release()['version'];
    }

    /** The installed program's path, as wkhtmltopdf: give it where a library asks for wkhtmltopdf. */
    public static function path(): string
    {
        return self::named('wkhtmltopdf');
    }

    /** Its path as wkhtmltoimage, for pictures (Snappy's Image, for instance). */
    public static function imagePath(): string
    {
        return self::named('wkhtmltoimage');
    }

    /** The program under its own name, marqius-wkhtmltopdf: help, licence, compare and install. */
    public static function program(): string
    {
        return self::install();
    }

    /**
     * Fetches the program for this machine when it is not here yet, checks it against the SHA-256
     * this package carries, and returns its path.
     *
     * @param callable|null $say      receives one line about what was done (Composer's output)
     * @param string|null   $cacheDir a folder to keep the download in and take it from again
     * @param callable|null $download fetches a URL into a file: function (string $url, string $to): void
     */
    public static function install(?callable $say = null, ?string $cacheDir = null, ?callable $download = null): string
    {
        $release = self::release();
        $version = $release['version'];
        $platform = self::platform();
        if (!isset($release['sha256'][$platform])) {
            throw new \RuntimeException("marqius-wkhtmltopdf $version has no build for $platform. Write to hello@marqius.com.");
        }
        $sha = $release['sha256'][$platform];
        // One folder per platform, so that a vendor/ folder can be shared (by a Mac and the Linux
        // container it is mounted in, say) and each machine fetches its own build. Its path stays the
        // same from one release to the next; its file `release` says which release is in it.
        $dir = self::buildDir() . DIRECTORY_SEPARATOR . basename($platform, '.exe');
        $exe = self::windows() ? 'marqius-wkhtmltopdf.exe' : 'marqius-wkhtmltopdf';
        $bin = $dir . DIRECTORY_SEPARATOR . $exe;
        $stamp = $dir . DIRECTORY_SEPARATOR . 'release';
        $want = "$version $sha";
        if (self::current($bin, $stamp, $want)) {
            return $bin;
        }

        if (!is_dir($dir) && !@mkdir($dir, 0777, true) && !is_dir($dir)) {
            throw new \RuntimeException(self::cannotWrite($dir));
        }
        $lock = @fopen($dir . DIRECTORY_SEPARATOR . '.lock', 'c');
        if ($lock === false) {
            throw new \RuntimeException(self::cannotWrite($dir));
        }
        flock($lock, LOCK_EX);
        try {
            // another process may have fetched it while this one waited
            if (self::current($bin, $stamp, $want)) {
                return $bin;
            }
            $file = 'marqius-wkhtmltopdf-' . $platform;
            $part = $dir . DIRECTORY_SEPARATOR . '.' . $exe . '.' . getmypid() . '.part';
            $cached = $cacheDir !== null ? rtrim($cacheDir, '/\\') . DIRECTORY_SEPARATOR . $version . DIRECTORY_SEPARATOR . $file : null;
            $from = 'cache';
            if ($cached === null || !is_file($cached) || hash_file('sha256', $cached) !== $sha || !@copy($cached, $part)) {
                $base = rtrim(getenv('MARQIUS_DOWNLOAD') ?: self::BASE, '/');
                $url = "$base/$version/$file";
                $from = $url;
                self::fetch($url, $part, $download);
                $got = hash_file('sha256', $part);
                if ($got !== $sha) {
                    @unlink($part);
                    throw new \RuntimeException("$url does not match the SHA-256 published with marqius-wkhtmltopdf $version ($sha; it has $got), so it was not used.");
                }
                if ($cached !== null && (is_dir(dirname($cached)) || @mkdir(dirname($cached), 0777, true))) {
                    @copy($part, $cached);
                }
            }
            @chmod($part, 0755);
            // the folder holds no release while its program is replaced
            if (is_file($stamp)) {
                @unlink($stamp);
            }
            if (is_file($bin)) {
                @unlink($bin);
            }
            if (!@rename($part, $bin)) {
                @unlink($part);
                throw new \RuntimeException(self::cannotWrite($dir));
            }
            self::names($dir, $bin);
            file_put_contents($stamp, $want . "\n");
            if ($say !== null) {
                $say("marqius-wkhtmltopdf $version for " . basename($platform, ".exe") . ", checked against its published SHA-256" . ($from === 'cache' ? ' (from the download cache)' : ''));
            }
            return $bin;
        } finally {
            flock($lock, LOCK_UN);
            fclose($lock);
        }
    }

    /** The folder the programs are kept in, inside this package: build/PLATFORM. */
    public static function buildDir(): string
    {
        return dirname(__DIR__) . DIRECTORY_SEPARATOR . 'build';
    }

    /** "linux-x86_64", "linux-arm64", "macos-arm64" or "windows-x86_64.exe": the build for this machine. */
    public static function platform(): string
    {
        $machine = strtolower(php_uname('m'));
        $arch = in_array($machine, ['x86_64', 'amd64', 'x64'], true) ? 'x86_64' : (in_array($machine, ['aarch64', 'arm64', 'armv8', 'armv8l'], true) ? 'arm64' : $machine);
        $os = PHP_OS_FAMILY;
        if ($os === 'Linux' && ($arch === 'x86_64' || $arch === 'arm64')) {
            return "linux-$arch";
        }
        if ($os === 'Darwin' && ($arch === 'arm64' || self::rosetta())) {
            return 'macos-arm64';
        }
        if ($os === 'Windows' && $arch === 'x86_64') {
            return 'windows-x86_64.exe';
        }
        $what = $os === 'Darwin' ? 'Intel Macs' : "$os on $machine";
        throw new \RuntimeException("marqius-wkhtmltopdf has no build for $what yet: it runs on Linux (x86-64 and ARM64), Apple silicon Macs and Windows (x86-64). Write to hello@marqius.com.");
    }

    private static function named(string $name): string
    {
        $bin = self::install();
        if (self::windows()) {
            $path = dirname($bin) . DIRECTORY_SEPARATOR . $name . '.exe';
            if (!is_file($path)) {
                self::names(dirname($bin), $bin);
            }
            return $path;
        }
        // a few lines of sh in this package that start the program as $name
        $path = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'bin' . DIRECTORY_SEPARATOR . $name;
        if (!is_executable($path)) {
            @chmod($path, 0755);
        }
        return $path;
    }

    private static function current(string $bin, string $stamp, string $want): bool
    {
        return is_file($bin) && is_file($stamp) && trim((string) @file_get_contents($stamp)) === $want;
    }

    /** The names libraries run, beside the program: hard links on Windows; sh in bin/ elsewhere. */
    private static function names(string $dir, string $bin)
    {
        if (self::windows()) {
            foreach (['wkhtmltopdf.exe', 'wkhtmltoimage.exe'] as $name) {
                $to = $dir . DIRECTORY_SEPARATOR . $name;
                if (is_file($to)) {
                    @unlink($to);
                }
                if (!@link($bin, $to) && !@copy($bin, $to)) {
                    throw new \RuntimeException(self::cannotWrite($dir));
                }
            }
            return;
        }
        foreach (['marqius-wkhtmltopdf', 'wkhtmltopdf', 'wkhtmltoimage'] as $name) {
            $path = dirname(__DIR__) . DIRECTORY_SEPARATOR . 'bin' . DIRECTORY_SEPARATOR . $name;
            if (is_file($path) && !is_executable($path)) {
                @chmod($path, 0755);
            }
        }
    }

    private static function fetch(string $url, string $to, ?callable $download)
    {
        if (strpos($url, 'file://') === 0) {
            if (!@copy(substr($url, 7), $to)) {
                throw new \RuntimeException("cannot read $url");
            }
            return;
        }
        if ($download !== null) {
            $download($url, $to);
            return;
        }
        $agent = 'marqius/wkhtmltopdf (Composer package; PHP ' . PHP_VERSION . ')';
        if (function_exists('curl_init')) {
            $out = @fopen($to, 'wb');
            if ($out === false) {
                throw new \RuntimeException(self::cannotWrite(dirname($to)));
            }
            $curl = curl_init($url);
            curl_setopt_array($curl, [
                CURLOPT_FILE => $out,
                CURLOPT_FOLLOWLOCATION => true,
                CURLOPT_FAILONERROR => true,
                CURLOPT_CONNECTTIMEOUT => 30,
                CURLOPT_TIMEOUT => 600,
                CURLOPT_USERAGENT => $agent,
            ]);
            $ok = curl_exec($curl);
            $error = curl_error($curl);
            if (PHP_VERSION_ID < 80000) {
                curl_close($curl); // a no-op since PHP 8.0, and deprecated since 8.5
            }
            fclose($out);
            if ($ok !== true) {
                @unlink($to);
                throw new \RuntimeException("cannot download $url: $error");
            }
            return;
        }
        $http = ['timeout' => 600, 'user_agent' => $agent, 'follow_location' => 1];
        $proxy = getenv('https_proxy') ?: getenv('HTTPS_PROXY');
        if ($proxy) {
            $http['proxy'] = preg_replace('{^https?://}', 'tcp://', $proxy);
            $http['request_fulluri'] = true;
        }
        $in = @fopen($url, 'rb', false, stream_context_create(['http' => $http]));
        $out = $in === false ? false : @fopen($to, 'wb');
        if ($in === false || $out === false || stream_copy_to_stream($in, $out) === false) {
            $error = error_get_last();
            @unlink($to);
            throw new \RuntimeException("cannot download $url" . ($error ? ': ' . $error['message'] : ''));
        }
        fclose($in);
        fclose($out);
    }

    private static function release(): array
    {
        static $release = null;
        if ($release === null) {
            $release = require __DIR__ . DIRECTORY_SEPARATOR . 'release.php';
        }
        return $release;
    }

    private static function windows(): bool
    {
        return PHP_OS_FAMILY === 'Windows';
    }

    /** A Mac with Apple silicon, running this PHP for Intel under Rosetta 2. */
    private static function rosetta(): bool
    {
        return function_exists('shell_exec') && trim((string) @shell_exec('sysctl -in sysctl.proc_translated 2>/dev/null')) === '1';
    }

    private static function cannotWrite(string $dir): string
    {
        return "marqius-wkhtmltopdf cannot be fetched into $dir: that folder cannot be written. Run `composer install`, or `php vendor/bin/marqius-wkhtmltopdf --version`, once as the user who owns vendor/.";
    }
}
