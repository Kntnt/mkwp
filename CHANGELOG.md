# Changelog

All notable changes to this project are documented here. The format
follows [Keep a Changelog](https://keepachangelog.com/) and the project
uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- New `-B` / `--blueprint` option that builds a site from a blueprint: a JSON file that describes the site's title, language, PHP and WordPress versions and Redis setting, and the themes, plugins and mu-plugins to install. A theme or plugin comes from WordPress.org, a Git repository (including a private one over SSH), a URL or a zip file next to the blueprint, and is activated if it's marked with `"activate": true`. Options on the command line take precedence over the blueprint, and the blueprint over the built-in defaults. mkwp checks the whole blueprint, and every file it refers to, before it touches Docker and DDEV, and stops with an exit status of its own for each kind of error. A blueprint needs `jq`.
- `blueprint.schema.json`, a JSON Schema for blueprints, lets an editor check and complete a blueprint.
- A blueprint's `files` key copies files and directories into `wp-content`, such as the media that a database refers to, after the themes, plugins and mu-plugins are installed. Each entry has a local `source`, relative to the blueprint's directory, and a `target`, the directory underneath `wp-content` to copy it into, which is created if it's missing. A file keeps its name, and a directory's contents are merged with what the target already has. A missing source, and a target that is absolute or leads out of `wp-content`, stop mkwp before it touches Docker and DDEV.
- A blueprint's `database` starts a site from a dump of another WordPress site, in plain or gzip-compressed SQL, and its `server` sets the database server, such as `mariadb:11.4`. The dump is imported after the themes, plugins and files are in place. Its old address is replaced by the site's, as plain text and JSON-escaped, and the database is upgraded to the installed WordPress. Its users are kept, and the user given to mkwp is made an administrator with the given email address and password. A title and a language given explicitly replace the dump's, but mkwp's defaults for a new site don't. Themes and plugins keep the state the dump gives them, unless they are marked with `"activate": true` or the theme is given with `-T`. Only dumps with the table prefix `wp_` are supported. A dump can contain secrets, such as licence keys and API credentials, and mkwp doesn't sanitize them.
- A blueprint's `database` can start a site from a DDEV snapshot in `snapshot`, such as one taken with `ddev snapshot` of another site, instead of a dump in `dump`. The snapshot can be anywhere; mkwp hands it to DDEV itself. `server` is required with a snapshot and must be the server the snapshot was taken from, which DDEV writes at the end of the snapshot's name, as in `site-mariadb_11.8.zst`, so a snapshot must keep the name DDEV gave it. The snapshot is restored where a dump would be imported, and everything after that is the same as for a dump. A `database` with both `dump` and `snapshot`, or with neither, a snapshot without `server`, a missing snapshot, and a snapshot from another server than `server` stop mkwp before it touches Docker and DDEV. A snapshot can contain secrets just as a dump can, and mkwp doesn't sanitize them.
- A blueprint's `wp_cli` key lists WP-CLI commands that mkwp runs, in order, at the end of the build: after Redis is enabled and before the site is opened. Each command is an array of the arguments to `wp`, which reach WP-CLI exactly as written, with no shell in between. If a command fails, mkwp stops with a message that names the command and its exit status, and doesn't open the site.
- A blueprint can pin a theme or plugin from WordPress.org to a `version`, and one from a Git repository to a `ref`: a tag, a branch or a commit, checked out instead of the latest tag. `version` on anything but a WordPress.org slug, and `ref` on anything but a Git repository, make mkwp stop before it touches Docker and DDEV.
- A theme or plugin in a blueprint can be a directory next to the blueprint, which is copied into the site under its own name, and an mu-plugin can be a PHP file next to the blueprint. Unpublished code can therefore be kept in a blueprint's directory as plain files.
- A configuration file can name the blueprint to build sites from when none is given on the command line, as in `blueprint = ~/blueprints/default.json`. A path that starts with `~/` is in the home directory, and a relative path is relative to the configuration file's directory, or to the current directory when the configuration is read from standard input with `-c -`. A blueprint given with `--blueprint` is used before one named in the file given with `-c`, and that one before one named in `~/.mkwp`.
- New `--no-blueprint` option that builds a site without a blueprint, even when a configuration file names one. The personal settings in the configuration files are still used.

### Changed

- **Breaking:** A configuration file, `~/.mkwp` or the file given with `-c`, now holds only the personal settings `email`, `user`, `password` and `directory`, and `blueprint`. Every other key it could hold before stops mkwp, before Docker and DDEV are touched, with a message that names the key and says where it belongs, and so does any other line that is neither blank nor a comment starting with `#`; mkwp used to ignore such lines. The command line still takes precedence over the file given with `-c`, and that file over `~/.mkwp`. Move each removed key like this:
  - `name`: give the site's name on the command line, as `mkwp my-site`. It never worked in a configuration file.
  - `dirname`: give it on the command line, so `dirname = my-site` becomes `-D my-site` or `--dirname=my-site`.
  - `title`, `language`, `php`, `wp` and `redis`: put them in a blueprint's `site`, so `title = My Site`, `language = sv_SE`, `php = 8.4`, `wp = 6.8` and `redis = true` become `"site": {"title": "My Site", "language": "sv_SE", "php": "8.4", "wp": "6.8", "redis": true}`. `redis` is `true` or `false` there, not `yes`, `no`, `1` or `0`.
  - `themes`, `plugins` and `mu-plugins`: put them in a blueprint's `themes`, `plugins` and `mu_plugins`, as arrays, so `plugins = query-monitor,https://example.com/my-plugin.zip` becomes `"plugins": ["query-monitor", "https://example.com/my-plugin.zip"]`. The last theme is still the one activated, unless another is marked with `"activate": true`. A local zip file is given by a path that starts with `./`, `../`, `/` or `~/`, and a relative path is relative to the blueprint.

  To keep these settings for every site, as `~/.mkwp` gave them before, put them in a blueprint and name it in `~/.mkwp` with `blueprint = ~/blueprints/default.json`. Each of them can still be given as an option on the command line too.
- Invalid options are now reported before Docker and DDEV are checked, so a mistyped name, email address, password or other option is reported even when Docker isn't running. The WordPress version given with `-W` or in a blueprint is looked up on WordPress.org last of all, before DDEV is touched too, so a version that no release matches, or a failed lookup, no longer leaves a half-built site behind.

### Fixed

- A relative path to a zip file given with `-T`, `-P` or `-M` is now relative to the current directory. It was looked for in the site's themes, plugins or mu-plugins directory, where it was never found.

## [1.9.0] – 2026-10-21

### Added

- Each GitHub release carries the `mkwp` file itself, with its version written in, so mkwp is installed and updated with one download from the latest release. The README's new Installation section shows how.

### Changed

- A copy of `mkwp` taken straight from the repository calls itself `unreleased`. Only the file attached to a release carries a version number.

## [1.8.2] – 2026-09-08

### Fixed

- Provisioning now stops immediately when a command fails. The main flow was wrapped in a conditional subshell, which made Bash ignore `set -e` and allowed failures such as an unsuccessful Redis add-on installation to be hidden while the script continued and reported success.
- When Redis is requested, its DDEV service must now answer `PONG` before WordPress installation begins, preventing sites from being configured with an unreachable Redis backend.

## [1.8.1] – 2026-07-20

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

[Unreleased]: https://github.com/Kntnt/mkwp/compare/v1.9.0...HEAD
[1.9.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.9.0
[1.8.2]: https://github.com/Kntnt/mkwp/releases/tag/v1.8.2
[1.8.1]: https://github.com/Kntnt/mkwp/releases/tag/v1.8.1
[1.8.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.8.0
[1.7.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.7.0
[1.6.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.6.0
[1.5.0]: https://github.com/Kntnt/mkwp/releases/tag/v1.5.0
[1.4.1]: https://github.com/Kntnt/mkwp/releases/tag/v1.4.1
[1.4.0]: https://github.com/Kntnt/mkwp/releases/tag/1.4.0
