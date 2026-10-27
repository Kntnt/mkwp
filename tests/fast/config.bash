# The configuration files, ~/.mkwp and the file given with -c, hold personal
# settings and may name a blueprint. They are read and checked before mkwp
# checks Docker and DDEV, so here Docker is not running. ~/.mkwp is the one in
# the sandbox's home directory, never the user's own.

# Usage: write_home_config <line>...
# Writes each <line> to ~/.mkwp.
write_home_config() {
	printf '%s\n' "$@" > "$mkwp_home/.mkwp"
}

test_rejects_a_site_setting_in_home_config() {
	write_home_config 'title = My Site'
	run_mkwp -m test@example.com site
	assert_rejected 41 'Invalid configuration in ~/.mkwp: title on line 1 belongs in a blueprint now, as .site.title'
	assert_nothing_created
}

# Each setting a configuration file could hold before, and that belongs in a
# blueprint or on the command line now, with what mkwp says about it.
test_rejects_each_site_setting_in_a_config_file_and_says_where_it_belongs() {

	local -A belongs=(
		[name]='on the command line now, as NAME'
		[dirname]='on the command line now, as -D or --dirname'
		[title]='in a blueprint now, as .site.title'
		[language]='in a blueprint now, as .site.language'
		[php]='in a blueprint now, as .site.php'
		[wp]='in a blueprint now, as .site.wp'
		[redis]='in a blueprint now, as .site.redis'
		[themes]='in a blueprint now, as .themes'
		[plugins]='in a blueprint now, as .plugins'
		[mu-plugins]='in a blueprint now, as .mu_plugins'
	)

	local key
	for key in "${!belongs[@]}"; do
		printf '%s\n' '# Personal settings' 'email = test@example.com' "$key=value" > "$sandbox/config"
		run_mkwp -c "$sandbox/config" site
		assert_rejected 41 "Invalid configuration in $sandbox/config: $key on line 3 belongs ${belongs[$key]}"
		assert_nothing_created
	done

}

test_rejects_a_line_that_is_not_a_setting() {
	write_home_config 'email = test@example.com' '' 'emial = test@example.com'
	run_mkwp site
	assert_rejected 42 'Invalid configuration in ~/.mkwp: line 3 is neither blank, a comment nor a setting: emial = test@example.com'
	assert_nothing_created
}

test_rejects_a_setting_without_an_equal_sign() {
	printf '%s\n' 'email test@example.com' > "$sandbox/config"
	run_mkwp -c "$sandbox/config" site
	assert_rejected 42 "Invalid configuration in $sandbox/config: line 1 is neither blank, a comment nor a setting: email test@example.com"
	assert_nothing_created
}

# A configuration that is accepted, and holds a valid email address, gets mkwp
# as far as the check of Docker and DDEV.
test_accepts_blank_lines_and_comments() {
	write_home_config '# Personal settings' '' '   ' '  # Indented' 'email=test@example.com' 'user = tester' '# title = Not read'
	run_mkwp site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

# An invalid value is only reported if it's the one used, which shows which
# value takes precedence.
test_lets_a_personal_setting_on_the_command_line_take_precedence_over_config_files() {
	write_home_config 'email = from-home'
	printf '%s\n' 'email = from-config' > "$sandbox/config"
	run_mkwp -m test@example.com -c "$sandbox/config" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_lets_a_personal_setting_in_the_c_file_take_precedence_over_home_config() {
	write_home_config 'email = from-home'
	printf '%s\n' 'email = from-config' > "$sandbox/config"
	run_mkwp -c "$sandbox/config" site
	assert_rejected 6 'Invalid email address: from-config'
	assert_nothing_created
}

test_uses_a_personal_setting_in_home_config_that_the_c_file_lacks() {
	write_home_config 'email = test@example.com' 'password = short'
	printf '%s\n' 'user = tester' > "$sandbox/config"
	run_mkwp -c "$sandbox/config" site
	assert_rejected 7 'Invalid password. Must be at least 12 characters.'
	assert_nothing_created
}

test_reads_the_c_file_from_standard_input() {
	run_mkwp -c - site <<< 'email = from-standard-input'
	assert_rejected 6 'Invalid email address: from-standard-input'
	assert_nothing_created
}

# A blueprint named in a configuration file is read, which an invalid one
# shows, since mkwp reports what is wrong with it. mkwp runs from the work
# directory, which is neither the configuration file's nor the blueprint's.
test_reads_a_blueprint_relative_to_the_c_file() {
	write_blueprint '{"unknown": true}'
	printf '%s\n' 'blueprint = blueprint.json' > "$sandbox/blueprint/client.mkwp"
	run_mkwp -m test@example.com -c "$sandbox/blueprint/client.mkwp" site
	assert_rejected 30 "Invalid blueprint $sandbox/blueprint/blueprint.json: .unknown is not a known key"
	assert_nothing_created
}

test_reads_a_blueprint_relative_to_home_config() {
	mkdir "$mkwp_home/blueprints"
	echo '{"unknown": true}' > "$mkwp_home/blueprints/base.json"
	write_home_config 'blueprint = blueprints/base.json'
	run_mkwp -m test@example.com site
	assert_rejected 30 "Invalid blueprint $mkwp_home/blueprints/base.json: .unknown is not a known key"
	assert_nothing_created
}

test_reads_a_blueprint_in_the_home_directory() {
	mkdir "$mkwp_home/blueprints"
	echo '{"unknown": true}' > "$mkwp_home/blueprints/base.json"
	write_blueprint '{}'
	printf '%s\n' 'blueprint = ~/blueprints/base.json' > "$sandbox/blueprint/client.mkwp"
	run_mkwp -m test@example.com -c "$sandbox/blueprint/client.mkwp" site
	assert_rejected 30 "Invalid blueprint $mkwp_home/blueprints/base.json: .unknown is not a known key"
	assert_nothing_created
}

test_reads_a_blueprint_relative_to_the_current_directory_from_standard_input() {
	write_blueprint '{"unknown": true}'
	run_mkwp -m test@example.com -c - site <<< 'blueprint = ../blueprint/blueprint.json'
	assert_rejected 30 'Invalid blueprint ../blueprint/blueprint.json: .unknown is not a known key'
	assert_nothing_created
}

test_builds_from_a_valid_blueprint_named_in_a_config_file() {
	write_blueprint '{"site": {"title": "Client Site"}}'
	write_home_config "blueprint = $blueprint"
	run_mkwp -m test@example.com site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_a_blueprint_named_in_a_config_file_that_does_not_exist() {
	printf '%s\n' 'blueprint = ./missing.json' > "$sandbox/config"
	run_mkwp -m test@example.com -c "$sandbox/config" site
	assert_rejected 28 "Couldn't read the blueprint $sandbox/./missing.json, named in $sandbox/config"
	assert_nothing_created
}

# Only the blueprint that is used is read, so the missing ones that are not
# used are not reported, which shows which blueprint takes precedence.
test_lets_a_blueprint_on_the_command_line_take_precedence_over_config_files() {
	write_blueprint '{}'
	write_home_config "blueprint = $sandbox/home.json"
	printf '%s\n' "blueprint = $sandbox/client.json" > "$sandbox/config"
	run_mkwp -m test@example.com -c "$sandbox/config" -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_lets_a_blueprint_in_the_c_file_take_precedence_over_home_config() {
	write_home_config "blueprint = $sandbox/home.json"
	printf '%s\n' "blueprint = $sandbox/client.json" > "$sandbox/config"
	run_mkwp -m test@example.com -c "$sandbox/config" site
	assert_rejected 28 "Couldn't read the blueprint $sandbox/client.json, named in $sandbox/config"
	assert_nothing_created
}

# Without a blueprint, neither jq nor the missing blueprints are needed. The
# personal settings in the configuration files are still used, as the invalid
# password shows.
test_builds_without_the_blueprint_a_config_file_names_with_no_blueprint() {
	hide jq
	write_home_config 'email = test@example.com' "blueprint = $sandbox/home.json"
	printf '%s\n' "blueprint = $sandbox/client.json" > "$sandbox/config"
	run_mkwp --no-blueprint -c "$sandbox/config" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
	write_home_config 'email = test@example.com' 'password = short' "blueprint = $sandbox/home.json"
	run_mkwp --no-blueprint -c "$sandbox/config" site
	assert_rejected 7 'Invalid password. Must be at least 12 characters.'
	assert_nothing_created
}

test_rejects_no_blueprint_together_with_a_blueprint() {
	write_blueprint '{}'
	run_mkwp -m test@example.com --no-blueprint -B "$blueprint" site
	assert_rejected 43 '--no-blueprint and -B/--blueprint can'\''t be used together.'
	assert_nothing_created
	run_mkwp -m test@example.com --blueprint="$blueprint" --no-blueprint site
	assert_rejected 43 '--no-blueprint and -B/--blueprint can'\''t be used together.'
	assert_nothing_created
}
