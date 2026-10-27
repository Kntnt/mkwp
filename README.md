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

	Your personal settings, and the blueprint to use when none is given
	with -B, can be kept in a configuration file. See CONFIGURATION
	below.

	An option given on the command line always takes precedence. If a
	site setting (title, language, PHP or WordPress version, or Redis)
	is not given there, it is in the first place set to the value in the
	blueprint, if there is one and it has the setting, and in the second
	place to a default value. If a personal setting (email, user,
	password or directory) is not given there, it is in the first place
	set to the value in the configuration file specified with -c or
	--config, in the second place to the value in the configuration
	file ~/.mkwp, and in the third place to a default value.

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
		enabled.

	-B <file>
	--blueprint=<file>
		Builds the site that the blueprint <file> describes, instead
		of the one a configuration file names, if any. See BLUEPRINT
		below.

	--no-blueprint
		Builds the site without a blueprint, even if a configuration
		file names one. Can't be given together with -B or
		--blueprint.

	--destroy
		Destroys the site [NAME]: deletes the DDEV project, including
		its database, and removes the site directory from the file
		system. Asks for confirmation before doing so. All other
		options are ignored.

	-c <file>
	--config=<file>
		Reads personal settings, and the blueprint to use, from the
		configuration file <file>, or from standard input if <file>
		is -. See CONFIGURATION below.

	-h
	--help
		Display this help and exit.

CONFIGURATION
	mkwp reads the configuration file given with -c or --config, if
	any, and the configuration file ~/.mkwp. If ~/.mkwp is missing, an
	empty one is created.

	A configuration file holds your personal settings, and may name a
	blueprint. Each line is a key, an equal sign and a value, with
	optional white space around the equal sign. Blank lines and lines
	starting with # are ignored. Any other line stops mkwp. Example:

		# Personal settings
		email = jane@example.com
		user = jane
		directory = /Users/jane/Sites
		blueprint = ~/blueprints/default.json

	The keys are:

	email
	user
	password
	directory
		The same as the options with the same names.

	blueprint
		The blueprint to build the site from when none is given with
		-B or --blueprint. A path starting with ~/ is in your home
		directory, and a relative path is relative to the directory of
		the configuration file, or to the current directory if the
		configuration is read from standard input. A blueprint named
		in the file given with -c is used instead of one named in
		~/.mkwp. Give --no-blueprint to build a site without it.

	Before mkwp 2.0.0, a configuration file could also hold the site
	settings name, dirname, title, language, themes, plugins,
	mu-plugins, php, wp and redis. Now they stop mkwp. Give name
	and dirname on the command line, and the others in a blueprint
	or as options.

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
		given in each item of themes, plugins, mu_plugins and
		files. mkwp ignores it.

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
		have it. If no theme has it, the last theme is activated.
		Themes and plugins given with -T and -P are installed after
		the blueprint's, and the last theme given with -T is activated
		instead of the blueprint's.

	mu_plugins
		An array of the mu-plugins to install. An item is the URL of a
		PHP file, or an object with the URL in source, and with note.

	files
		An array of the files and directories to copy into wp-content,
		such as the media that a database refers to. An item is an
		object with a local file or directory in source, the directory
		to copy it into in target, and note. A relative source is
		relative to the blueprint's directory. The target is relative
		to wp-content, as in "uploads/2024/01", and is created if it's
		missing. It must not be absolute or start with ~, and its ..
		parts must not lead out of wp-content. A file keeps its name,
		and replaces a file with the same name. A directory's contents
		are merged with what the target already has. Example:

			"files": [
			  { "source": "./media", "target": "uploads" },
			  { "source": "./fonts/brand.woff2", "target": "fonts" }
			]

	database
		Not supported yet. A blueprint with this key is rejected.

	wp_cli
		An array of WP-CLI commands, which are run in the given order at
		the end of the build. A command is an array of the arguments to
		wp, without wp itself, such as
		["option", "update", "blogdescription", "Just another site"].
		Each argument reaches WP-CLI exactly as written, since no shell
		is involved, so nothing needs quoting. A command gets no input,
		so give --yes to a command that asks for confirmation. If a
		command fails, mkwp stops without opening the site.

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
		- The files are copied into wp-content.
		- The theme to activate, and the plugins with
		  "activate": true, are activated.
		- Redis is enabled as object cache, if it is used.
		- The WP-CLI commands in wp_cli are run, in order.
		- The site is opened in the browser.

DEPENDENCY
	This command requires that a Docker provider is installed and running
	on your system and that DDEV is properly installed and in your path.
	A blueprint also requires jq, and a blueprint with a local zip file
	requires unzip.
```

## Blueprints

A blueprint is a JSON file that describes a site, and `mkwp --blueprint=<file> NAME` builds that site. The format, the rules for sources and the order in which a site is built are described under BLUEPRINT in the usage above, which also has an example.

A relative path in a blueprint is relative to the blueprint's own directory, so a blueprint and the zip files and other files it refers to can be kept together in a directory of their own. That directory can be a Git repository, private if it holds commercial plugins or code of your own, and can be cloned anywhere.

To build every site from a blueprint of yours unless you say otherwise, name it in `~/.mkwp`, as in `blueprint = ~/blueprints/default.json`. A blueprint named in a configuration file given with `-c`, such as one for a client, is used instead, and a blueprint given with `--blueprint` is used before either. `--no-blueprint` builds a plain site. The configuration files hold only your personal settings and that blueprint; everything that describes the site belongs in the blueprint. See CONFIGURATION in the usage above.

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
