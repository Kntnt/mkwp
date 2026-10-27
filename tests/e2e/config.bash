# Sites built with the personal settings, and the blueprint, that the
# configuration files give, and with none of them on the command line but
# what a test needs to take precedence.
#
# mkwp runs with a home directory of this file's own, so the ~/.mkwp written
# here, which names a blueprint, is never read by another test file, nor is it
# the user's own. The file given with -c is in a directory of its own, next to
# the blueprint it names by a relative path, and mkwp runs from another
# directory.

fixtures="$run_dir/fixtures/config"
mkwp_home="$run_dir/home-config"

# The personal settings in ~/.mkwp.
home_email=home@example.com
home_user=home-user
home_password=home-password-123

# The personal settings that take precedence over those in ~/.mkwp.
client_email=client@example.com
stdin_email=stdin@example.com
command_line_password=command-line-password-123

setup_file() {

	mkdir -p "$mkwp_home/blueprints" "$fixtures/client"

	echo '{"site": {"title": "Home Blueprint"}, "plugins": ["hello-dolly"]}' > "$mkwp_home/blueprints/home.json"
	echo '{"site": {"title": "Client Blueprint"}}' > "$fixtures/client/client.json"

	cat > "$mkwp_home/.mkwp" <<- EOT
	# Personal settings
	email = $home_email
	user = $home_user
	password = $home_password
	directory = $sites_dir

	# The blueprint to use unless another one is given
	blueprint = ~/blueprints/home.json
	EOT

	cat > "$fixtures/client/client.mkwp" <<- EOT
	# The client's settings
	email = $client_email
	blueprint = ./client.json
	EOT

	# The file given with -c names a blueprint by a path relative to itself,
	# and is given by a path relative to the directory mkwp runs from.
	build_site config-client -c "../${fixtures#"$run_dir/"}/client/client.mkwp" -p "$command_line_password"

	# The configuration read from standard input names a blueprint too.
	build_site config-plain --no-blueprint -c - <<- EOT
	email = $stdin_email
	blueprint = ../${fixtures#"$run_dir/"}/client/client.json
	EOT

}

# Usage: build_site <label> <arg>...
# Builds the site <label> with mkwp and nothing but <arg>... on the command
# line. Fails the test if mkwp fails. See make_site.
build_site() {

	local name
	name=$(site_name "$1")
	shift

	echo "$name" >> "$e2e_registry"
	note "  building $name"

	run_mkwp "$@" "$name"
	(( status == 0 )) || fail "mkwp exited with status $status while building $name. The end of its output:\n$(tail -n 40 "$run_dir/stdout" | without_colours)\n$output"

}

test_creates_the_sites_in_the_directory_from_home_config() {
	[[ -f "$sites_dir/$(site_name config-client)/.ddev/config.yaml" ]] || fail "The site config-client is not in $sites_dir."
	[[ -f "$sites_dir/$(site_name config-plain)/.ddev/config.yaml" ]] || fail "The site config-plain is not in $sites_dir."
}

test_uses_the_blueprint_the_c_file_names_relative_to_itself_over_the_one_in_home_config() {
	assert_equal 'Client Blueprint' "$(site_wp config-client option get blogname)"
	assert_equal '' "$(site_wp config-client plugin list --field=name)"
}

test_takes_the_email_from_the_c_file_and_the_user_from_home_config() {
	assert_equal administrator "$(site_wp config-client user get "$home_user" --field=roles)"
	assert_equal "$client_email" "$(site_wp config-client user get "$home_user" --field=user_email)"
}

test_takes_the_password_from_the_command_line() {
	site_wp config-client user check-password "$home_user" "$command_line_password" || fail "The password from the command line was not accepted."
}

test_builds_a_plain_site_with_no_blueprint_although_config_files_name_one() {
	local name
	name=$(site_name config-plain)
	assert_equal "${name^}" "$(site_wp config-plain option get blogname)"
	assert_equal '' "$(site_wp config-plain plugin list --field=name)"
}

test_takes_personal_settings_from_standard_input_and_home_config_with_no_blueprint() {
	assert_equal administrator "$(site_wp config-plain user get "$home_user" --field=roles)"
	assert_equal "$stdin_email" "$(site_wp config-plain user get "$home_user" --field=user_email)"
	site_wp config-plain user check-password "$home_user" "$home_password" || fail "The password from ~/.mkwp was not accepted."
}
