# A site built from a blueprint and from options on the command line, which
# take precedence over the blueprint. A relative path given with -P is relative
# to the directory mkwp is run from. The blueprint names one database server,
# and the option another.

fixtures="$run_dir/fixtures/blueprint-options"

# The database server given with --db-server.
option_db_server='mariadb:11.4'

setup_file() {

	mkdir -p "$fixtures"
	make_zip "$fixtures/mkwp-zip-theme.zip" theme mkwp-zip-theme 1.0.0
	make_zip "$fixtures/mkwp-zip-plugin.zip" plugin mkwp-zip-plugin 1.0.0
	make_zip "$fixtures/mkwp-option-plugin.zip" plugin mkwp-option-plugin 1.0.0
	make_repository "$fixtures/mkwp-option-theme.git" theme mkwp-option-theme 1.0.0

	cat > "$fixtures/blueprint.json" <<- 'EOT'
	{
		"site": {"title": "Blueprint Site", "db_server": "mariadb:11.8"},
		"themes": [{"source": "./mkwp-zip-theme.zip", "activate": true}],
		"plugins": [{"source": "./mkwp-zip-plugin.zip", "activate": true}]
	}
	EOT

	make_site blueprint-options -B "$fixtures/blueprint.json" \
		-t 'Title From The Command Line' \
		--db-server="$option_db_server" \
		-T "file://$fixtures/mkwp-option-theme.git" \
		-P "../${fixtures#"$run_dir/"}/mkwp-option-plugin.zip"

}

test_has_the_title_from_the_command_line() {
	assert_equal 'Title From The Command Line' "$(site_wp blueprint-options option get blogname)"
}

test_has_the_database_server_from_the_command_line() {
	assert_equal "$option_db_server" "$(site_db_server blueprint-options)"
}

test_activates_the_last_theme_given_with_the_option_instead_of_the_marked_one() {
	assert_equal mkwp-option-theme "$(site_wp blueprint-options theme list --status=active --field=name)"
	assert_equal inactive "$(site_wp blueprint-options theme get mkwp-zip-theme --field=status)"
}

test_installs_a_plugin_given_with_the_option_without_activating_it() {
	assert_equal inactive "$(site_wp blueprint-options plugin get mkwp-option-plugin --field=status)"
}

test_installs_and_activates_the_plugin_from_the_blueprint() {
	assert_equal active "$(site_wp blueprint-options plugin get mkwp-zip-plugin --field=status)"
}
