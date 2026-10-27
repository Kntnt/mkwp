# A site built from a blueprint whose second WP-CLI command fails, since it
# asks for an option that doesn't exist. mkwp must stop there, and not open
# the site. The build is expected to fail, so it's run here and not with
# make_site, and what mkwp did is kept in files for the tests to read.

fixtures="$run_dir/fixtures/wp-cli-failure"

setup_file() {

	mkdir -p "$fixtures"

	cat > "$fixtures/blueprint.json" <<- 'EOT'
	{
		"wp_cli": [
			["option", "update", "blogdescription", "Before the failure"],
			["option", "get", "mkwp_no_such_option"],
			["option", "update", "blogdescription", "After the failure"]
		]
	}
	EOT

	local name
	name=$(site_name wp-cli-failure)
	echo "$name" >> "$e2e_registry"
	note "  building $name, which is meant to fail"

	run_mkwp -d "$sites_dir" -m "$site_email" -u "$site_user" -p "$site_password" -B "$fixtures/blueprint.json" "$name"
	echo "$status" > "$fixtures/status"
	printf '%s\n' "$output" > "$fixtures/stderr"
	cp "$run_dir/stdout" "$fixtures/stdout"

}

test_stops_with_a_message_that_names_the_failing_command() {
	assert_equal 38 "$(< "$fixtures/status")"
	assert_equal "The WP-CLI command .wp_cli[1] in the blueprint $fixtures/blueprint.json failed with exit status 1: wp option get mkwp_no_such_option" "$(tail -n 1 "$fixtures/stderr")"
}

test_runs_no_command_after_the_failing_one() {
	assert_equal 'Before the failure' "$(site_wp wp-cli-failure option get blogdescription)"
}

test_does_not_open_the_site() {
	! grep -q 'You should now see your new WordPress site' "$fixtures/stdout" || fail "mkwp opened the site and told the user to look at it."
}
