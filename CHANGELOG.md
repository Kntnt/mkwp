# Changelog

All notable changes to this project are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/) and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/Kntnt/mkwp/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.5.0
[1.4.1]: https://github.com/Kntnt/mkwp/releases/tag/v1.4.1
[1.4.0]: https://github.com/Kntnt/mkwp/releases/tag/1.4.0
