# A site built from a blueprint with WP-CLI commands in wp_cli. One argument
# holds characters a shell would act on, and two commands set the same option.
# A plugin is marked to be activated, and a command deactivates it, which can
# only stick if the commands run after the activation step.

fixtures="$run_dir/fixtures/wp-cli"

setup_file() {

	mkdir -p "$fixtures"

	cat > "$fixtures/blueprint.json" <<- 'EOT'
	{
		"plugins": [{"source": "hello-dolly", "activate": true}],
		"wp_cli": [
			["option", "update", "blogdescription", "Set by a WP-CLI command"],
			["option", "update", "mkwp_argument", "It's \"quoted\", with  two spaces, $5; `whoami` $(id) ${HOME} * and \\ a backslash"],
			["option", "update", "mkwp_order", "first"],
			["option", "update", "mkwp_order", "second"],
			["plugin", "deactivate", "hello-dolly"]
		]
	}
	EOT

	make_site wp-cli -B "$fixtures/blueprint.json"

}

test_sets_an_option_with_a_command() {
	assert_equal 'Set by a WP-CLI command' "$(site_wp wp-cli option get blogdescription)"
}

test_passes_an_argument_on_exactly_as_written() {
	local expected
	IFS= read -r expected <<- 'EOT'
	It's "quoted", with  two spaces, $5; `whoami` $(id) ${HOME} * and \ a backslash
	EOT
	assert_equal "$expected" "$(site_wp wp-cli option get mkwp_argument)"
}

test_runs_the_commands_in_the_given_order() {
	assert_equal second "$(site_wp wp-cli option get mkwp_order)"
}

test_runs_the_commands_after_the_activation() {
	assert_equal inactive "$(site_wp wp-cli plugin get hello-dolly --field=status)"
}
