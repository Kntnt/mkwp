# A blueprint is checked in full before mkwp checks Docker and DDEV, so here
# Docker is not running. A blueprint that passes every check gets mkwp as far
# as that, and no further.

test_stops_when_jq_is_missing() {
	write_blueprint '{}'
	hide jq
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 27 'mkwp needs jq to read a blueprint. Install jq and try again.'
	assert_nothing_created
}

test_needs_no_jq_without_a_blueprint() {
	hide jq
	run_mkwp -m test@example.com site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_a_blueprint_that_does_not_exist() {
	run_mkwp -m test@example.com -B "$sandbox/missing.json" site
	assert_rejected 28 "Couldn't read the blueprint $sandbox/missing.json"
	assert_nothing_created
}

test_rejects_invalid_json() {
	write_blueprint '{"site": {"title": "Test",}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 29 "Invalid JSON in the blueprint $blueprint: Expected another key-value pair at line 1, column 27"
	assert_nothing_created
}

test_rejects_a_blueprint_with_more_than_one_json_value() {
	write_blueprint '{} {}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 29 "Invalid JSON in the blueprint $blueprint: it must hold one JSON object, but holds 2 values"
	assert_nothing_created
}

test_rejects_an_unknown_key() {
	write_blueprint '{"site": {"title": "Test"}, "theme": ["twentytwentyfive"]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 30 "Invalid blueprint $blueprint: .theme is not a known key"
	assert_nothing_created
}

test_rejects_an_unknown_key_in_an_item() {
	write_blueprint '{"plugins": ["query-monitor", {"source": "akismet", "notes": "Spam"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 30 "Invalid blueprint $blueprint: .plugins[1].notes is not a known key"
	assert_nothing_created
}

test_rejects_a_blueprint_that_is_not_an_object() {
	write_blueprint '["twentytwentyfive"]'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 31 "Invalid blueprint $blueprint: the top level must be an object, not an array"
	assert_nothing_created
}

test_rejects_a_value_of_the_wrong_type() {
	write_blueprint '{"site": {"php": 8.4}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 31 "Invalid blueprint $blueprint: .site.php must be a string, not a number"
	assert_nothing_created
}

test_rejects_an_item_that_is_neither_a_string_nor_an_object() {
	write_blueprint '{"themes": [["twentytwentyfive"]]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 31 "Invalid blueprint $blueprint: .themes[0] must be a string or an object, not an array"
	assert_nothing_created
}

test_rejects_an_item_without_a_source() {
	write_blueprint '{"plugins": [{"activate": true}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 32 "Invalid blueprint $blueprint: .plugins[0] has no \"source\""
	assert_nothing_created
}

test_accepts_schema_and_notes_on_every_item() {
	write_blueprint '{
		"$schema": "https://example.com/blueprint.schema.json",
		"note": "A note on the blueprint",
		"site": {"title": "Test", "language": "sv_SE", "php": "8.4", "wp": "6.9", "redis": true},
		"themes": ["twentytwentyfive", {"source": "twentytwentyfour", "activate": true, "note": "A note on a theme"}],
		"plugins": ["query-monitor", {"source": "akismet", "activate": false, "note": "A note on a plugin"}],
		"mu_plugins": ["https://example.com/one.php", {"source": "https://example.com/two.php", "note": "A note on an mu-plugin"}]
	}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_an_invalid_title() {
	write_blueprint '{"site": {"title": "Two\tcolumns"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 33 $'Invalid blueprint '"$blueprint"$': "Two\tcolumns" in .site.title is not a valid title'
	assert_nothing_created
}

test_rejects_an_invalid_language() {
	write_blueprint '{"site": {"language": "swedish"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 33 "Invalid blueprint $blueprint: \"swedish\" in .site.language is not a valid language code"
	assert_nothing_created
}

test_rejects_an_unsupported_php_version() {
	write_blueprint '{"site": {"php": "9.1"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 33 "Invalid blueprint $blueprint: \"9.1\" in .site.php is not a valid PHP version"
	assert_nothing_created
}

test_rejects_an_invalid_wordpress_version() {
	write_blueprint '{"site": {"wp": "latest"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 33 "Invalid blueprint $blueprint: \"latest\" in .site.wp is not a valid WordPress version"
	assert_nothing_created
}

test_rejects_a_source_that_is_not_a_slug_and_not_a_local_path() {
	write_blueprint '{"plugins": ["plugins/commercial.zip"]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 34 "Invalid blueprint $blueprint: \"plugins/commercial.zip\" in .plugins[0] is not a WordPress.org slug. A local path must start with ./, ../, / or ~/."
	assert_nothing_created
}

test_rejects_an_empty_source() {
	write_blueprint '{"themes": [{"source": ""}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 34 "Invalid blueprint $blueprint: \"\" in .themes[0] is not a WordPress.org slug. A local path must start with ./, ../, / or ~/."
	assert_nothing_created
}

test_rejects_an_mu_plugin_that_is_not_the_url_of_a_php_file() {
	write_blueprint '{"mu_plugins": ["https://example.com/mu-plugin.zip"]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 34 "Invalid blueprint $blueprint: \"https://example.com/mu-plugin.zip\" in .mu_plugins[0] is not the URL of a PHP file"
	assert_nothing_created
}

test_finds_a_relative_source_in_the_blueprint_directory() {
	write_blueprint '{"plugins": ["./plugin.zip"], "themes": ["../theme.zip"]}'
	write_zip "$sandbox/blueprint/plugin.zip" plugin
	write_zip "$sandbox/theme.zip" theme
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_finds_a_source_in_the_home_directory() {
	write_blueprint '{"plugins": ["~/plugin.zip"]}'
	write_zip "$mkwp_home/plugin.zip" plugin
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_a_local_source_that_does_not_exist() {
	write_blueprint '{"plugins": ["./plugin.zip"]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./plugin.zip\" in .plugins[0] doesn't exist"
	assert_nothing_created
}

test_does_not_look_for_a_relative_source_in_the_current_directory() {
	write_blueprint '{"plugins": ["./plugin.zip"]}'
	write_zip "$mkwp_dir/plugin.zip" plugin
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./plugin.zip\" in .plugins[0] doesn't exist"
	assert_nothing_created
}

test_rejects_a_local_source_that_is_a_directory() {
	write_blueprint '{"themes": ["./theme"]}'
	mkdir "$sandbox/blueprint/theme"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./theme\" in .themes[0] is a directory, not a zip file"
	assert_nothing_created
}

test_rejects_a_local_source_that_can_not_be_read() {
	write_blueprint '{"plugins": ["./plugin.zip"]}'
	write_zip "$sandbox/blueprint/plugin.zip" plugin
	chmod a-r "$sandbox/blueprint/plugin.zip"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./plugin.zip\" in .plugins[0] can't be read"
	assert_nothing_created
}

test_rejects_a_local_source_that_is_not_a_zip_file() {
	write_blueprint '{"plugins": ["./plugin.zip"]}'
	echo 'Not a zip file' > "$sandbox/blueprint/plugin.zip"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./plugin.zip\" in .plugins[0] is not a zip file"
	assert_nothing_created
}

test_stops_when_unzip_is_missing_for_a_local_source() {
	write_blueprint '{"plugins": ["./plugin.zip"]}'
	write_zip "$sandbox/blueprint/plugin.zip" plugin
	hide unzip
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 27 "mkwp needs unzip to read \"./plugin.zip\" in the blueprint $blueprint. Install unzip and try again."
	assert_nothing_created
}

test_rejects_two_activated_themes() {
	write_blueprint '{"themes": [{"source": "twentytwentyfour", "activate": true}, "twentytwentythree", {"source": "twentytwentyfive", "activate": true}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 36 "Invalid blueprint $blueprint: .themes has more than one theme with \"activate\": true"
	assert_nothing_created
}

# An invalid value is only reported if it's the one used, which shows which
# value takes precedence.
test_lets_an_option_take_precedence_over_the_blueprint() {
	write_blueprint '{"site": {"php": "8.4"}}'
	run_mkwp -m test@example.com -V 9.1 -B "$blueprint" site
	assert_rejected 9 'Invalid PHP version: 9.1'
	assert_nothing_created
}

test_lets_the_blueprint_take_precedence_over_a_configuration_file() {
	write_blueprint '{"site": {"php": "8.4"}}'
	echo 'php = 9.1' > "$sandbox/config"
	run_mkwp -m test@example.com -c "$sandbox/config" -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_an_invalid_site_setting_even_when_the_command_line_replaces_it() {
	write_blueprint '{"site": {"php": "9.1"}}'
	run_mkwp -m test@example.com -V 8.4 -B "$blueprint" site
	assert_rejected 33 "Invalid blueprint $blueprint: \"9.1\" in .site.php is not a valid PHP version"
	assert_nothing_created
}
