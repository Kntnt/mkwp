# mkwp - make wordpress
Bash script to quickly and easily create local WordPress sites.

## Installation

mkwp is a single file. Download it from the latest release into a directory on your `PATH`, such as `~/bin`, and make it executable:

```bash
mkdir -p ~/bin
curl -fsSL https://github.com/Kntnt/mkwp/releases/latest/download/mkwp -o ~/bin/mkwp
chmod +x ~/bin/mkwp
```

To update mkwp, run the same commands again. To install a particular version, put `download/v<version>` in place of `latest/download` in the link, as in `https://github.com/Kntnt/mkwp/releases/download/v1.9.0/mkwp`. The first line of `mkwp --help` shows the installed version.

Install the file from a release, not from a clone of the repository. The version is written into the file when a release is built, so a copy of `mkwp` taken straight from the repository has none and calls itself `unreleased`. To build the file from a clone, run `bin/build-release-assets`: it writes `release-assets/mkwp`, with the version taken from git.

mkwp needs a running Docker provider and [DDEV](https://ddev.com/) on your `PATH`. To build a site from a blueprint, it also needs [jq](https://jqlang.org/), and `unzip` if the blueprint has local zip files. Current macOS comes with both.

## Usage

```
NAME
	mkwp <version> - make wordpress

SYNOPSIS
	mkwp [OPTION]... NAME
	mkwp --destroy NAME

DESCRIPTION
	Makes a local WordPress site with the domain name.ddev.site where
	name is the domain name provided as the argument [NAME].

	The site can be described by a blueprint, a JSON file given with
	-B or --blueprint. See BLUEPRINT below.

	If a flag is not specified on the command line, the corresponding
	option is in the first place set to the value in the blueprint, if
	there is one and it has a value for the option, in the second place
	to a value read from the configuration file specified with -c or
	--config, in the third place to a value read from the configuration
	file ~/.mkwp, and in the fourth place to a default value.

	If the configuration file ~/.mkwp is missing, an empty one will be
	created.

	A configuration file should be formatted so that each line starting
	with the name of a long format flag, excluding leading double dashes
	(e.g. email instead of --email), followed by an equal sign, where the
	corresponding flag has not been specified on the command line, the flag
	is specified with the option set to the value following the equal sign.
	White space may be used around the equal sign.
	Examples:

		title = WordPress Test Site
		php=8.5

OPTIONS
	-t <title>
	--title=<title>
		The title of the WordPress site. If omitted, [NAME] will be
		used.

	-d <path>
	--directory=<path>
		The home directory of the website. If omitted, current
		directory will be used as home directory.

	-D <dirname>
	--dirname=<dirname>
		The name of the directory the site is created in, underneath the
		home directory. If omitted, [NAME] will be used.

	-m <email>
	--email=<email>
		The email address of the first user created in WordPress. If
		omitted, the current username is used as local-part and the
		hostname as domain.

	-u <username>
	--user=<username>
		The username of the first user created in WordPress. If
		omitted, the local-part of the email address will be used.

	-p <password>
	--password=<password>
		The password of the first user created in WordPress. Must at
		least be 12 characters long. If omitted, a 16 character random
		password is generated.

	-l <locale>
	--language=<locale>
		The language of the WordPress site. If omitted, en_US will be
		used. For a number of well-known locales, the site timezone is
		set accordingly (e.g. Europe/Stockholm for sv_SE).

	-T <themes>
	--themes=<themes>
		Comma separated list of themes to install. For a theme hosted
		on WordPress.org, enter its slug or URL to its zip-file. For a
		theme hosted in a remote Git repository, enter its remote URL.
		For a theme hosted locally, enter the path to the zip file. The
		last listed theme is activated. If omitted, WordPress's current
		default theme will be used.

	-P <plugins>
	--plugins=<plugins>
		Comma separated list of plugins to install. For a plugin hosted
		on WordPress.org, enter its slug or URL to its zip-file. For a
		plugin hosted in a remote Git repository, enter its remote URL.
		For a plugin hosted locally, enter the path to the zip file.

	-M <plugins>
	--mu-plugins=<plugins>
		Comma separated list of mu-plugins to install. For each plugin,
		provide the plugin's URL from where it can be downloaded as
		php-file (e.g. https://raw.githubusercontent.com/Kntnt/kntnt-
		adminbar-sanitizer/master/kntnt-adminbar-sanitizer.php).
		If omitted, no mu-plugins will be installed.

	-V <version>
	--php=<version>
		Version of PHP to be used. If omitted, PHP 8.5 will be used.

	-W <version>
	--wp=<version>
		Version of WordPress to install, given as <major>,
		<major>.<minor> or <major>.<minor>.<patch> (e.g. 6, 6.9 or
		6.9.4). Omitted parts are resolved to the highest available
		release. If omitted entirely, the latest version is installed.
		The core auto-update policy reflects the precision: a full
		<major>.<minor>.<patch> disables auto-updates, while <major> or
		<major>.<minor> enables patch-level updates only.

	-R
	--redis
		Adds a Redis service to the site and enables it as WordPress
		object cache backend: the Redis Object Cache plugin is
		installed and activated, and its object-cache.php drop-in is
		enabled. In a configuration file, use redis = true.

	-B <file>
	--blueprint=<file>
		Builds the site that the blueprint <file> describes. See
		BLUEPRINT below.

	--destroy
		Destroys the site [NAME]: deletes the DDEV project, including
		its database, and removes the site directory from the file
		system. Asks for confirmation before doing so. All other
		options are ignored.

	-c <file>
	--config=<file>
		Reads configuration from a file with the path <file>.
		See description above for details.

	-h
	--help
		Display this help and exit.

BLUEPRINT
	A blueprint is a JSON file that describes a site. Keep it, and the
	files it refers to, in a directory of their own, which can be a Git
	repository and cloned anywhere. mkwp checks the whole blueprint, and
	every file it refers to, before it makes anything. Example:

		{
		  "$schema": "https://raw.githubusercontent.com/Kntnt/mkwp/main/blueprint.schema.json",
		  "note": "Our starting point for client sites",
		  "site": { "title": "Client Site", "language": "sv_SE", "php": "8.4", "redis": true },
		  "themes": [
		    "twentytwentyfive",
		    { "source": "./themes/client-child.zip", "activate": true }
		  ],
		  "plugins": [
		    { "source": "query-monitor", "activate": true },
		    { "source": "git@github.com:example/private-plugin.git", "activate": true },
		    { "source": "./plugins/commercial-plugin.zip", "note": "Licensed to us" }
		  ],
		  "mu_plugins": [
		    "https://raw.githubusercontent.com/Kntnt/kntnt-adminbar-sanitizer/master/kntnt-adminbar-sanitizer.php"
		  ]
		}

	A blueprint is an object with these keys, all of them optional:

	$schema
		The JSON Schema of the blueprint, which lets an editor check
		and complete it. mkwp ignores it.

	note
		A note of your own, since JSON has no comments. It may also be
		given in each item of themes, plugins and mu_plugins. mkwp
		ignores it.

	site
		An object with the settings of the site: title, language, php
		and wp, which are strings, and redis, which is true or false.
		Each is checked like the option with the same name, and is
		replaced by the option when it's given on the command line.

	themes
	plugins
		Arrays of the themes and plugins to install. An item is a
		source, as described below, or an object with the source in
		source, and with activate (true or false) and note. Each item
		with "activate": true is activated, and at most one theme may
		have it. If no theme has it, the last theme is activated,
		unless there is a database. Themes and plugins given with -T
		and -P are installed after the blueprint's, and the last theme
		given with -T is activated instead of the blueprint's.

	mu_plugins
		An array of the mu-plugins to install. An item is the URL of a
		PHP file, or an object with the URL in source, and with note.

	files
		Not supported yet. A blueprint with this key is rejected.

	database
		An object with a database to start the site from: a dump of
		another WordPress site in dump, and the database server to
		import it into in server. The dump is plain SQL in a .sql file
		or gzip-compressed SQL in a .sql.gz file, and its tables must
		have the prefix wp_. A relative path is relative to the
		blueprint's directory. The server is given as
		mariadb:<version> or mysql:<version>, e.g. mariadb:11.8, with
		a version that DDEV has. If it's omitted, DDEV's default is
		used.

		The site keeps the users, settings and active theme and
		plugins of the dump, but for what is given explicitly: the
		themes and plugins with "activate": true and the theme given
		with -T are activated, and a title and a language given
		replace those of the dump. What mkwp gives a new site by
		default, such as a title made from NAME, pretty permalinks
		and the timezone of the language, is not applied. The user
		is made an administrator with the email address and
		password given, and is created if the dump doesn't have it.
		A dump can hold secrets, such as licence keys and API
		credentials, which mkwp doesn't remove.

	wp_cli
		Not supported yet. A blueprint with this key is rejected.

	The source of a theme or plugin is one of these, recognized in this
	order:

		A local path, which starts with ./, ../, / or ~/, to a zip
		file. A relative path is relative to the blueprint's directory.
		The theme or plugin is named after the directory in the zip
		file, so the file's own name doesn't matter.

		A Git repository, whose URL ends with .git. Any URL that Git
		accepts works, including SSH, so a private repository is
		reached with your own SSH setup. The latest tag is checked out,
		or the default branch if there is no tag.

		A URL, which starts with http:// or https://, to a zip file.

		A slug on WordPress.org, which is anything else.

	A site is built in this order:

		- DDEV is configured, with the cron add-on and, if Redis is
		  used, the Redis add-on, and started.
		- WordPress is downloaded and installed.
		- The themes, plugins and mu-plugins are installed.
		- The dump is imported, if there is one. The old address is
		  replaced by the site's, also where it's JSON-escaped, the
		  database is upgraded, the user is made an administrator,
		  the title and language given are applied, and the rewrite
		  rules and the object cache are flushed.
		- The theme to activate, and the plugins with
		  "activate": true, are activated.
		- Redis is enabled as object cache, if it is used.
		- The site is opened in the browser.

DEPENDENCY
	This command requires that a Docker provider is installed and running
	on your system and that DDEV is properly installed and in your path.
	A blueprint also requires jq, and a blueprint with a local zip file
	requires unzip.
```

## Blueprints

A blueprint is a JSON file that describes a site, and `mkwp --blueprint=<file> NAME` builds that site. The format, the rules for sources and the order in which a site is built are described under BLUEPRINT in the usage above, which also has an example.

A relative path in a blueprint is relative to the blueprint's own directory, so a blueprint and the zip files it refers to can be kept together in a directory of their own. That directory can be a Git repository, private if it holds commercial plugins or code of your own, and can be cloned anywhere.

A blueprint's `database` starts the site from a dump of another site, with all the settings and content that site has. Only a dump whose tables have the prefix `wp_` can be used.

**A dump can contain secrets.** Plugins keep licence keys, API credentials and similar secrets in the database, and a dump holds them as they are. mkwp copies a dump into the new site without sanitizing it. Keep dumps only where those secrets may be, such as a private repository, and remove what doesn't belong there before you add a dump to a blueprint.

`blueprint.schema.json` in this repository is a [JSON Schema](https://json-schema.org/) for blueprints. Name it in a blueprint's `$schema` key, as the example does, and an editor such as VS Code checks the blueprint and completes its keys as you write. The schema on `main` follows the latest mkwp. For the schema of a particular version, put its tag in place of `main`, as in `https://raw.githubusercontent.com/Kntnt/mkwp/v2.0.0/blueprint.schema.json`.

## Testing

mkwp has two test suites. Both run `mkwp` the way a user does and look only at what a user sees: the exit status, the message, and the site that was built. Neither reads or changes your `~/.mkwp`.

The fast suite checks that mkwp rejects what it must reject before it touches DDEV. It needs neither Docker nor DDEV, and takes a few seconds:

```bash
tests/run-fast
```

The end-to-end suite builds real sites and checks them through `ddev wp`. It needs a running Docker provider, DDEV on your `PATH` and access to the internet, and takes a few minutes. Run it before a release:

```bash
tests/run-e2e
```

Each site it builds is named `mkwp-e2e-` followed by a random part, is created in a temporary directory, and is destroyed with `mkwp --destroy` when its test file is done, even if a test fails or you interrupt the run. It touches no other DDEV project.

To run only some of the tests, name their files, as in `tests/run-fast tests/fast/options.bash`. A test is a function whose name starts with `test_`, in a file under `tests/fast` or `tests/e2e`. The helpers the tests use are in `tests/lib`.

## Releasing

`/release` tags the release, and `bin/build-release-assets` builds the `mkwp` it attaches: the script as committed at the tag, with the tag's version written into it. The repository keeps no version number anywhere else; the tag and `CHANGELOG.md` carry it.
