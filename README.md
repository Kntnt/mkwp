# mkwp - make wordpress
Bash script to quickly and easily create local WordPress sites.

```
NAME
	mkwp 1.8.0 - make wordpress

SYNOPSIS
	mkwp [OPTION]... NAME
	mkwp --destroy NAME

DESCRIPTION
	Makes a local WordPress site with the domain name.ddev.site where
	name is the domain name provided as the argument [NAME].

	If a flag is not specified on the command line, the corresponding
	option is in the first place set to a value read from the configuration
	file specified with -c or --config, in the second place to a value read
	from the configuration file ~/.mkwp, and in the third place to a
	default value.

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

DEPENDENCY
	This command requires that a Docker provider is installed and running
	on your system and that DDEV is properly installed and in your path.
```

## Release configuration

The version number lives in these places, which must stay in sync:

- `mkwp` — the `# mkwp X.Y.Z by …` header comment at the top of the script.
- `mkwp` — the `readonly mkwp_version='X.Y.Z'` constant.
- `README.md` — the `mkwp X.Y.Z - make wordpress` line in the embedded help text above.
- `CHANGELOG.md` — the latest release heading.

There is no archive build; releases ship release notes only.
