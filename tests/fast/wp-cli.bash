# The WP-CLI commands in a blueprint's wp_cli are checked with the rest of the
# blueprint, before mkwp checks Docker and DDEV, so here Docker is not running.
# A blueprint that passes every check gets mkwp as far as that, and no further.

test_accepts_wp_cli_commands() {
	write_blueprint '{"wp_cli": [["option", "update", "blogname", "A title with spaces"], ["rewrite", "flush"]]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_wp_cli_that_is_not_an_array() {
	write_blueprint '{"wp_cli": {"option": ["update", "blogname", "Title"]}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 31 "Invalid blueprint $blueprint: .wp_cli must be an array, not an object"
	assert_nothing_created
}

test_rejects_a_command_given_as_a_string() {
	write_blueprint '{"wp_cli": [["rewrite", "flush"], "option update blogname Title"]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 31 "Invalid blueprint $blueprint: .wp_cli[1] must be an array, not a string"
	assert_nothing_created
}

test_rejects_an_argument_that_is_not_a_string() {
	write_blueprint '{"wp_cli": [["option", "update", "posts_per_page", 20]]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 31 "Invalid blueprint $blueprint: .wp_cli[0][3] must be a string, not a number"
	assert_nothing_created
}

test_rejects_an_empty_command() {
	write_blueprint '{"wp_cli": [["rewrite", "flush"], []]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 39 "Invalid blueprint $blueprint: .wp_cli[1] must not be empty"
	assert_nothing_created
}
