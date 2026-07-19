# Changelog

All notable changes to this project are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/) and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- `ddev config` now passes `--project-name=NAME`, so a `--dirname` that diverges from NAME no longer breaks the scaffold. Previously DDEV registered the project under the directory's name while wp-config.php still hardcoded the database host to `ddev-NAME-db`, so the site died with a database-connection error before it was created.

## [1.8.0] – 2026-07-19

### Changed

- The short flag for `--dirname` was renamed from `-n` to `-D`, to be consistent with the other short flags. The long form `--dirname` is unchanged.

## [1.7.0] – 2026-07-19

### Added

- The help output (`-h` / `--help`) now shows the mkwp version number on its first line.

## [1.6.0] – 2026-07-19

### Added

- New `-R` / `--redis` option (or `redis = true` in a configuration file) that adds a Redis service to the site via the official `ddev/ddev-redis` add-on and enables it as WordPress object cache backend: the Redis Object Cache plugin is installed and activated, `WP_REDIS_HOST` is set, and the `object-cache.php` drop-in is enabled.
- New `--destroy` mode (`mkwp --destroy NAME`) that deletes the DDEV project, including its database, and removes the site directory, after asking for confirmation.
- Pretty permalinks (`/%postname%/`) are enabled on the new site instead of WordPress's default plain permalinks.
- The site timezone is set automatically for a number of well-known locales (e.g. `Europe/Stockholm` for `sv_SE`).
- `WP_ENVIRONMENT_TYPE` is defined as `local` in `wp-config.php`.

### Changed

- The site is now fully provisioned in a single `ddev start`: all DDEV customizations (PHP settings, host commands, cron and the optional Redis service) are written before the first start, eliminating the `ddev restart` that previously followed the cron setup.
- WordPress cron is now scheduled through the official `ddev/ddev-cron` add-on instead of a hand-rolled Dockerfile, cron file and post-start hook. This also removes the fragile `sed` editing of `.ddev/config.yaml`, which required GNU sed and broke on stock macOS.
- WordPress core is downloaded with `--skip-content`, skipping the default themes and plugins that were previously downloaded, synced and then deleted. The default theme (when `-T` is omitted) is instead resolved from core's `WP_DEFAULT_THEME` constant and installed explicitly.
- The waiting loops for Mutagen file synchronization were replaced by explicit `ddev mutagen sync` calls.
- Themes and plugins given as wordpress.org slugs or zip URLs are now installed in a single WP-CLI call instead of one call per item.
- Duplicate removal in the theme and plugin lists now preserves the original list order.
- `WP_MEMORY_LIMIT` was raised from 64M to 128M.

### Fixed

- Option values containing spaces (e.g. `-t "My Test Site"`) were truncated at the first space due to missing quoting in the argument parser. Paths containing spaces broke the script for the same reason; all expansions are now properly quoted and the script passes shellcheck.
- The script now aborts with an error message as soon as a step fails (`set -e` with an ERR trap), instead of continuing through the remaining steps and reporting success.
- Validating the configuration file given with `-c` no longer touches it, which previously updated its modification time and could even create it.
- The email validation no longer rejects valid addresses such as `user+tag@example.com`.
- The NAME validation now matches what DDEV actually accepts as a project name — letters, digits and hyphens, starting with a letter — so a name like `www.example.com` is rejected early with a clear message pointing to `-n`/`--dirname`, instead of failing inside `ddev config`.

## [1.5.0] – 2026-07-19

### Added

- New `-n` / `--dirname` option to name the directory the site is created
  in, underneath the home directory (`-d` / `--directory`), independently
  of NAME. This lets the directory reflect e.g. a full production host
  (`www.example.com`) while the DDEV project name and local domain remain
  a plain hostname label. When omitted, the directory is named after NAME
  as before. The option is also accepted in configuration files, with the
  same precedence as the other options.

## [1.4.1] - 2026-06-11

### Fixed

- On PHP 8.5, the bundled default theme is detected correctly again. A
  deprecation notice that WP-CLI prints to stdout was being mistaken for the
  theme name, which made mkwp delete the bundled themes and leave the site
  without a theme — a blank page (white screen of death) — when no theme was
  given with `-T`.

## [1.4.0] - 2026-06-11

### Added

- New `-W` / `--wp` option to choose which WordPress version to install. It
  accepts a major (`6`), a major and minor (`6.9`), or a full version
  (`6.9.4`); any omitted parts are resolved to the highest available
  release. The core auto-update policy adapts to how precisely the version
  is given — a full version disables core auto-updates, while a less precise
  one enables patch-level updates only.
- DDEV host commands `enter` (open a shell) and `here` (run a command) that
  operate in the host's current directory inside the container.

### Changed

- The default PHP version is now 8.5 (previously 8.3), and PHP 8.4 and 8.5
  are now accepted values.

### Fixed

- Corrected the indentation written to `.ddev/config.yaml` when adding the
  post-start cron hook.
- The README now matches the `--help` output exactly: `NAME` is shown as a
  required argument, every help line fits within 79 columns, and several
  spelling errors in the help text were corrected.

[Unreleased]: https://github.com/Kntnt/mkwp/compare/v1.8.0...HEAD
[1.8.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.8.0
[1.7.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.7.0
[1.6.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.6.0
[1.5.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.5.0
[1.4.1]: https://github.com/Kntnt/mkwp/releases/tag/v1.4.1
[1.4.0]: https://github.com/Kntnt/mkwp/releases/tag/1.4.0
