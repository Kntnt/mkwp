# mkwp - make wordpress
Bash script to quickly and easily create local WordPress sites.

```
NAME
	mkwp - make wordpress

SYNOPSIS
	mkwp [OPTION]... [NAME]

DESCRIPTION
	Makes a local WordPress site with the domain name.ddev.site where
	name is the domain name provided as the argument [NAME].

	If a flag is not specified on the command line, the corresponding option
	is in the first place set to a value read from the configuration file
	specified with -c or --config, in the second place to a value read
	from the configuration file ~/.mkwp, and in the third place to
	a default value.

	If the configuration file ~/.mkwp is missing, an empty one will be
	created.

	A configuration files should be formatted so that each line starting
	with the name of a long format flag, excluding leading double dashes
	(e.g. email instead of --email), followed by an equal sign, where
	the corresponding flag has not been specified on the command line,
	the flag is specified with the option set to the value following
	the equal sign. White space may be used around the equal sign.
	Examples:

		title = WordPress Tets Site
		php=8.3

OPTIONS
	-t <title>
	--title=<title>
		The title of the WordPress site. If omitted, [NAME] will be used.

	-d <path>
	--directory=<path>
		The home directory of the website. If omitted, current directory
		will be used as home directory.

	-m <email>
	--email=<email>
		The email address of the first user created in WordPress. If
		If omitted, the current username is used as local-part and
		the hostname as domain.

	-u <username>
	--user=<username>
		The username of the first user created in WordPress. If omitted,
		the local-part of the email address will be used.

	-p <password>
	--password=<password>
		The password of the first user created in WordPress. Must at
		least be 12 characters long. If omitted, a 16 character random
		password is generated.

	-l <locale>
	--language=<locale>
		The language of the WordPress site. If omitted, en_US will be
		used.

	-T <themes>
	--themes=<themes>
		Comma spearared list of themes to install. For a theme hosted on
		WordPress.org, enter its slug or URL to its zip-file. For a theme
		hosted in a remote Git repository, enter its remote URL. For a
		theme hosted locally, enter the path to the zip file. The last listed
		theme is activated. If omitted, WordPress's current default theme
		will be used.

	-P <plugins>
	--plugins=<plugins>
		Comma spearared list of plugins to install. For a plugin hosted on
		WordPress.org, enter its slug or URL to its zip-file. For a plugin
		hosted in a remote Git repository, enter its remote URL. For a plugin
		hosted locally, enter the path to the zip file.

	-M <plugins>
	--mu-plugins=<plugins>
		Comma spearared list of mu-plugins to install. For each plugin,
		provide the plugin's URL from where it can be downloaded as
		php-file (e.g. https://raw.githubusercontent.com/Kntnt/kntnt-
		adminbar-sanitizer/master/kntnt-adminbar-sanitizer.php).
		If omitted, no mu-plugins will be installed.

	-V <version>
	--php=<version>
		Version of PHP to be used. If omitted, PHP 7.4 will be used.

	-c <file>
	--config=<file>
		Reads configuration from a file with the path <file>.
		See description above for deatils.

	-h
	--help
		Display this help and exit.

DEPENDENCY
	This command requires that a Docker provider is installed and running
	on your system and that DDEV is properly installed and in your path.
```
