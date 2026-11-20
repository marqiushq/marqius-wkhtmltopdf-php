#!/bin/sh
# Makes the zip Composer would download from GitHub for this package, at the version in
# src/release.sh, in OUT: for testing it as an artifact repository before Packagist has it.
#   tests/artifact.sh OUT
set -eu
pkg=$(cd "$(dirname "$0")/.." && pwd)
out=$(mkdir -p "$1" && cd "$1" && pwd)
. "$pkg/src/release.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
(cd "$pkg" && tar cf - --exclude=./vendor --exclude=./build --exclude=./composer.lock --exclude=.git .) | (cd "$tmp" && tar xf -)
cd "$tmp"
# an artifact repository reads the version from composer.json; Packagist takes it from the tag
VERSION=$version php -r '$j = json_decode(file_get_contents("composer.json"), true); $j["version"] = getenv("VERSION"); file_put_contents("composer.json", json_encode($j, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n");'
git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm "marqius-wkhtmltopdf $version"
rm -f "$out"/marqius-wkhtmltopdf-*.zip
git archive --format=zip --prefix="marqiushq-marqius-wkhtmltopdf-php-$(git rev-parse --short HEAD)/" -o "$out/marqius-wkhtmltopdf-$version.zip" HEAD
echo "$out/marqius-wkhtmltopdf-$version.zip"
