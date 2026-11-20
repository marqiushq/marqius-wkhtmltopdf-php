<?php
/*
 * marqius/wkhtmltopdf: marqius-wkhtmltopdf for PHP's wkhtmltopdf libraries.
 * marqius-wkhtmltopdf is commercial software from Simple AI LLC, with a 30-day free trial:
 * https://marqius.com/licence/marqius-wkhtmltopdf
 */

namespace Marqius\Wkhtmltopdf;

use Composer\Composer;
use Composer\EventDispatcher\EventSubscriberInterface;
use Composer\IO\IOInterface;
use Composer\Plugin\PluginInterface;
use Composer\Script\Event;
use Composer\Script\ScriptEvents;

/**
 * Fetches marqius-wkhtmltopdf for this machine when Composer installs or updates the project,
 * through Composer's own downloader (its proxy and certificate settings apply), and keeps the
 * download in Composer's cache. Optional: when the plugin is not allowed to run, the program is
 * fetched on first use instead.
 */
final class Plugin implements PluginInterface, EventSubscriberInterface
{
    /** @var Composer */
    private $composer;

    /** @var IOInterface */
    private $io;

    public function activate(Composer $composer, IOInterface $io)
    {
        $this->composer = $composer;
        $this->io = $io;
    }

    public function deactivate(Composer $composer, IOInterface $io)
    {
    }

    public function uninstall(Composer $composer, IOInterface $io)
    {
    }

    public static function getSubscribedEvents()
    {
        return [
            ScriptEvents::POST_INSTALL_CMD => 'fetch',
            ScriptEvents::POST_UPDATE_CMD => 'fetch',
        ];
    }

    public function fetch(Event $event)
    {
        // the plugin's classes stay loaded after `composer remove marqius/wkhtmltopdf`
        if (!is_file(__DIR__ . DIRECTORY_SEPARATOR . 'release.php')) {
            return;
        }
        $io = $this->io;
        $http = $this->composer->getLoop()->getHttpDownloader();
        $cache = $this->composer->getConfig()->get('cache-dir');
        $fetched = false;
        try {
            $bin = Binary::install(
                function (string $line) use ($io, &$fetched) {
                    $io->write('<info>' . $line . '</info>');
                    $fetched = true;
                },
                $cache ? $cache . DIRECTORY_SEPARATOR . 'marqius-wkhtmltopdf' : null,
                function (string $url, string $to) use ($http) {
                    $http->copy($url, $to);
                }
            );
            if ($fetched) {
                $io->write('marqius-wkhtmltopdf is commercial software with a 30-day free trial: https://marqius.com/licence/marqius-wkhtmltopdf');
            }
            if ($io->isVerbose()) {
                $io->write('marqius-wkhtmltopdf: ' . $bin);
            }
        } catch (\Throwable $e) {
            $io->writeError('<warning>marqius/wkhtmltopdf: ' . $e->getMessage() . ' It will be fetched again on first use.</warning>');
        }
    }
}
