# Sites built from the database of another site. Site A is built from a
# blueprint without a database, with every kind of source a blueprint has: two
# local theme directories, of which the one marked to be activated is listed
# first, a local zip file for each plugin, of which one is marked to be
# activated, two plugins from a local bare Git repository reached through a
# file:// URL, one at the latest tag and one at an older tag given as ref, an
# mu-plugin from a local PHP file, and a file copied into uploads. Its WP-CLI
# commands change it the way a user would change a site: it gets another user,
# a language of its own in the database, a timezone that isn't the one of its
# language, another permalink structure, and its address in JSON. Its
# database is then taken, as a dump and as a DDEV snapshot, and other sites
# are built from it.
#
# Each site in from_a is built by make_site_from_a, from the same blueprint
# but for the database, and with the same options. The tests that loop over
# from_a check each of them in the same way, whatever way the database got
# there. Site defaults is built from A's dump with nothing given explicitly.

fixtures="$run_dir/fixtures/database"

# The sites built by make_site_from_a, each named after the way A's database
# got there.
from_a=(dump snapshot)

# The user that mkwp is given for each site in from_a, who is an editor with
# another email address and password in site A.
editor='mkwp-editor'
editor_email='editor-b@example.com'
editor_password='editor-password-in-b'

# The user that mkwp is given for site defaults, who is not in site A.
new_user='mkwp-new'
new_email='new@example.com'

# The timezone of site A, which mkwp doesn't give a site of any language.
a_timezone='Atlantic/Azores'

setup_file() {

	mkdir -p "$fixtures/mu-plugins" "$fixtures/media"
	make_extension "$fixtures/themes/mkwp-theme-one" theme mkwp-theme-one 1.0.0
	make_extension "$fixtures/themes/mkwp-theme-two" theme mkwp-theme-two 1.0.0
	make_zip "$fixtures/mkwp-active.zip" plugin mkwp-active 1.0.0
	make_zip "$fixtures/mkwp-inactive.zip" plugin mkwp-inactive 1.0.0
	make_repository "$fixtures/mkwp-git-latest.git" plugin mkwp-git-latest 1.0.0 1.1.0 1.2.0-dev
	make_repository "$fixtures/mkwp-git-ref.git" plugin mkwp-git-ref 1.0.0 1.1.0
	printf '<?php\ndefine( "MKWP_MU_PLUGIN", true );\n' > "$fixtures/mu-plugins/mkwp-mu-plugin.php"
	echo 'Media of site A' > "$fixtures/media/mkwp-media.txt"

	# Site A's address, JSON-escaped in a JSON object, as a plugin may keep
	# it, written as a JSON string for the blueprint.
	local a_url json
	a_url=$(site_url a)
	json=$(jq -n --arg value "{\"home\":\"${a_url//\//\\/}\"}" '$value')

	# Site A, on an older WordPress than the sites built from it, so that
	# their database has to be upgraded.
	cat > "$fixtures/a.json" <<- EOT
	{
		"site": {"title": "Site A", "language": "sv_SE", "php": "8.4", "wp": "6.8"},
		"themes": [{"source": "./themes/mkwp-theme-two", "activate": true}, "./themes/mkwp-theme-one"],
		"plugins": [
			{"source": "./mkwp-active.zip", "activate": true},
			"./mkwp-inactive.zip",
			"file://$fixtures/mkwp-git-latest.git",
			{"source": "file://$fixtures/mkwp-git-ref.git", "ref": "v1.0.0"}
		],
		"mu_plugins": ["./mu-plugins/mkwp-mu-plugin.php"],
		"files": [{"source": "./media/mkwp-media.txt", "target": "uploads/2024/01/"}],
		"wp_cli": [
			["user", "create", "$editor", "editor@example.com", "--role=editor", "--user_pass=editor-password-in-a"],
			["option", "update", "WPLANG", "sv_SE"],
			["option", "update", "timezone_string", "$a_timezone"],
			["rewrite", "structure", "/%year%/%postname%/"],
			["option", "add", "mkwp_e2e_json", $json]
		]
	}
	EOT
	make_site a -B "$fixtures/a.json"

	local a_dir
	a_dir="$sites_dir/$(site_name a)"
	(cd "$a_dir" && ddev export-db --file="$fixtures/a.sql.gz")

	# A snapshot of site A, which has DDEV's default server, since its
	# blueprint has no database. DDEV names the snapshot after the server.
	local snapshots server
	(cd "$a_dir" && ddev snapshot --name=a)
	snapshots=("$a_dir"/.ddev/db_snapshots/a-*)
	cp "${snapshots[0]}" "$fixtures/"
	server=$(cd "$a_dir" && ddev describe -j | jq -r '.raw.database_type + ":" + .raw.database_version')

	make_site_from_a dump '{"dump": "./a.sql.gz", "server": "mariadb:11.4"}'
	make_site_from_a snapshot "{\"snapshot\": \"./${snapshots[0]##*/}\", \"server\": \"$server\"}"

	# Site defaults, with neither a title nor a language given, and with a
	# user who is not in A's database. Its blueprint marks a theme.
	cat > "$fixtures/defaults.json" <<- 'EOT'
	{
		"themes": ["./themes/mkwp-theme-two", {"source": "./themes/mkwp-theme-one", "activate": true}],
		"database": {"dump": "./a.sql.gz"}
	}
	EOT
	make_site defaults -B "$fixtures/defaults.json" -u "$new_user" -m "$new_email"

}

# Usage: make_site_from_a <label> <database>
# Builds the site <label> from a blueprint with the JSON object <database> as
# its database, and with the editor of site A as mkwp's user. The blueprint
# gives a title and a language, and lists A's themes and its zipped plugins
# without marks, but for the plugin that is inactive in A. The theme listed
# last is not the one that is active in A.
make_site_from_a() {

	cat > "$fixtures/$1.json" <<- EOT
	{
		"site": {"title": "Site B", "language": "en_GB"},
		"themes": ["./themes/mkwp-theme-two", "./themes/mkwp-theme-one"],
		"plugins": ["./mkwp-active.zip", {"source": "./mkwp-inactive.zip", "activate": true}],
		"database": $2
	}
	EOT

	make_site "$1" -B "$fixtures/$1.json" -u "$editor" -m "$editor_email" -p "$editor_password"

}

# Usage: try_site <label> [<option>...]
# Runs mkwp to build the site <label> as make_site does, but leaves it to the
# test to check how that went.
try_site() {

	local name
	name=$(site_name "$1")
	shift

	echo "$name" >> "$e2e_registry"
	note "  building $name"

	run_mkwp -d "$sites_dir" -m "$site_email" -u "$site_user" -p "$site_password" "$@" "$name"

}

# Usage: site_url <label>
# Echoes the address of the site <label>.
site_url() {
	echo "https://$(site_name "$1").ddev.site"
}

# Usage: assert_site_equal <label> <expected> <actual>
# Asserts that <actual>, found in the site <label>, is <expected>.
assert_site_equal() {
	[[ $3 == "$2" ]] || fail "In site $1, expected:\n$2\nGot:\n$3"
}

# Usage: assert_stopped_with <status> <message>
# Asserts that mkwp, as last run by run_mkwp, exited with <status>, and that
# the last thing it wrote to stderr was <message>.
assert_stopped_with() {
	[[ $status == "$1" ]] || fail "Expected exit status $1, got $status, with this output:\n$(tail -n 20 <<< "$output")"
	assert_equal "$2" "$(tail -n 1 <<< "$output")"
}

# What the tests below find in the other sites comes from site A, so first
# check that A is what its blueprint describes.
test_builds_site_a_from_every_kind_of_source() {
	assert_equal mkwp-theme-two "$(site_wp a theme list --status=active --field=name)"
	assert_equal mkwp-active "$(site_wp a plugin list --status=active --field=name)"
	assert_equal 1.1.0 "$(site_wp a plugin get mkwp-git-latest --field=version)"
	assert_equal 1.0.0 "$(site_wp a plugin get mkwp-git-ref --field=version)"
	assert_equal loaded "$(site_wp a eval 'echo defined( "MKWP_MU_PLUGIN" ) ? "loaded" : "not loaded";')"
	assert_equal 'Media of site A' "$(site_wp a eval 'echo file_get_contents(wp_upload_dir()["basedir"] . "/2024/01/mkwp-media.txt");')"
	assert_equal editor "$(site_wp a user get "$editor" --field=roles)"
	assert_equal "$a_timezone" "$(site_wp a option get timezone_string)"
}

test_replaces_the_old_address_as_plain_text_and_json_escaped() {

	local plain json site
	plain=$(site_url a)
	json=${plain//\//\\/}

	[[ $(site_wp a db search "$plain" --all-tables) ]] || fail "Site A's database doesn't have its own address."
	[[ $(site_wp a db search "$json" --all-tables) ]] || fail "Site A's database doesn't have its own address JSON-escaped."

	for site in "${from_a[@]}"; do
		assert_site_equal "$site" '' "$(site_wp "$site" db search "$plain" --all-tables)"
		assert_site_equal "$site" '' "$(site_wp "$site" db search "$json" --all-tables)"
		assert_site_equal "$site" "{\"home\":\"$(site_url "$site" | sed 's|/|\\/|g')\"}" "$(site_wp "$site" option get mkwp_e2e_json)"
	done

}

test_has_its_own_address_as_home_and_siteurl() {
	local site
	for site in "${from_a[@]}"; do
		assert_site_equal "$site" "$(site_url "$site")" "$(site_wp "$site" option get home)"
		assert_site_equal "$site" "$(site_url "$site")" "$(site_wp "$site" option get siteurl)"
	done
}

test_keeps_the_users_of_the_database() {
	local site
	for site in "${from_a[@]}" defaults; do
		assert_site_equal "$site" administrator "$(site_wp "$site" user get "$site_user" --field=roles)"
		assert_site_equal "$site" "$site_email" "$(site_wp "$site" user get "$site_user" --field=user_email)"
	done
}

test_makes_a_user_of_the_database_an_administrator_with_the_given_email_and_password() {
	local site
	for site in "${from_a[@]}"; do
		assert_site_equal "$site" administrator "$(site_wp "$site" user get "$editor" --field=roles)"
		assert_site_equal "$site" "$editor_email" "$(site_wp "$site" user get "$editor" --field=user_email)"
		site_wp "$site" user check-password "$editor" "$editor_password" || fail "In site $site, the password was not accepted."
	done
}

test_creates_a_user_who_is_not_in_the_database_as_an_administrator() {
	assert_equal administrator "$(site_wp defaults user get "$new_user" --field=roles)"
	assert_equal "$new_email" "$(site_wp defaults user get "$new_user" --field=user_email)"
	site_wp defaults user check-password "$new_user" "$site_password" || fail "The password was not accepted."
}

test_keeps_the_active_plugins_of_the_database_and_activates_the_marked_ones() {
	local site
	for site in "${from_a[@]}"; do
		assert_site_equal "$site" $'mkwp-active\nmkwp-inactive' "$(site_wp "$site" plugin list --status=active --field=name | sort)"
	done
}

test_keeps_the_active_theme_of_the_database_when_no_theme_is_marked() {
	local site
	for site in "${from_a[@]}"; do
		assert_site_equal "$site" mkwp-theme-two "$(site_wp "$site" theme list --status=active --field=name)"
	done
}

test_activates_the_marked_theme_instead_of_that_of_the_database() {
	assert_equal mkwp-theme-one "$(site_wp defaults theme list --status=active --field=name)"
}

test_replaces_the_title_and_language_of_the_database_with_those_given() {
	local site
	for site in "${from_a[@]}"; do
		assert_site_equal "$site" 'Site B' "$(site_wp "$site" option get blogname)"
		assert_site_equal "$site" en_GB "$(site_wp "$site" eval 'echo get_locale();')"
	done
}

test_keeps_the_title_and_language_of_the_database_when_none_is_given() {
	assert_equal 'Site A' "$(site_wp defaults option get blogname)"
	assert_equal sv_SE "$(site_wp defaults eval 'echo get_locale();')"
}

# WordPress falls back to English for a language whose language pack is
# missing, so a site that keeps the language of the database must get its
# language pack, and show in the same language as site A.
test_installs_the_language_of_the_database_when_none_is_given() {

	site_wp defaults language core is-installed sv_SE || fail "The language pack of sv_SE is not installed."

	local in_a
	in_a=$(site_wp a eval 'echo __( "Settings" );')
	[[ $in_a != Settings ]] || fail "Site A doesn't show in its language, so it can't tell whether site defaults does."
	assert_equal "$in_a" "$(site_wp defaults eval 'echo __( "Settings" );')"

}

# A new site gets the timezone of its language and pretty permalinks, but a
# site with a database keeps those of the database.
test_keeps_the_timezone_and_permalinks_of_the_database() {
	local site
	for site in "${from_a[@]}" defaults; do
		assert_site_equal "$site" "$a_timezone" "$(site_wp "$site" option get timezone_string)"
		assert_site_equal "$site" '/%year%/%postname%/' "$(site_wp "$site" option get permalink_structure)"
	done
}

test_upgrades_the_database_to_the_version_of_wordpress() {

	local site a_version version
	a_version=$(site_wp a option get db_version)

	for site in "${from_a[@]}" defaults; do
		version=$(site_wp "$site" eval 'global $wp_db_version; echo $wp_db_version;')
		[[ $version != "$a_version" ]] || fail "In site $site, WordPress has the database version of site A, $a_version, so nothing had to be upgraded."
		assert_site_equal "$site" "$version" "$(site_wp "$site" option get db_version)"
	done

}

test_uses_the_database_server_of_the_blueprint() {
	local site server
	for site in "${from_a[@]}"; do
		server=$(jq -r .database.server "$fixtures/$site.json")
		assert_site_equal "$site" "$server" "$(cd "$sites_dir/$(site_name "$site")" && ddev describe -j | jq -r '.raw.database_type + ":" + .raw.database_version')"
	done
}

test_stops_at_a_dump_with_another_table_prefix() {
	gunzip -c "$fixtures/a.sql.gz" | sed 's/`wp_/`xyz_/g' | gzip > "$fixtures/xyz.sql.gz"
	echo '{"database": {"dump": "./xyz.sql.gz"}}' > "$fixtures/xyz.json"
	try_site xyz -B "$fixtures/xyz.json"
	assert_stopped_with 47 "The database from $fixtures/xyz.sql.gz is not a WordPress site with the table prefix wp_, which is the only prefix mkwp supports."
}

test_stops_when_the_email_address_belongs_to_another_user_in_the_database() {
	try_site taken -B "$fixtures/defaults.json" -u "$new_user"
	assert_stopped_with 48 "The email address $site_email belongs to the user $site_user in the database from $fixtures/a.sql.gz, so it can't be given to $new_user. Give $new_user another email address, or use $site_user."
}
