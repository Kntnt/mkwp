# The files a blueprint copies into wp-content are checked with the rest of the
# blueprint, before mkwp checks Docker and DDEV, so here Docker is not running.
# A blueprint that passes every check gets mkwp as far as that, and no further.

test_accepts_a_file_and_a_directory_to_copy() {
	write_blueprint '{"files": [
		{"source": "./media/logo.png", "target": "uploads/2024/01/client-logo.png"},
		{"source": "./media/logo.png", "target": "uploads/2024/02/"},
		{"source": "./mu-plugins", "target": "mu-plugins", "note": "Our own mu-plugins"}
	]}'
	mkdir -p "$sandbox/blueprint/media" "$sandbox/blueprint/mu-plugins"
	echo 'A logo' > "$sandbox/blueprint/media/logo.png"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_accepts_a_target_that_stays_inside_wp_content() {
	write_blueprint '{"files": [
		{"source": "./media", "target": "uploads/../themes"},
		{"source": "./media", "target": "."}
	]}'
	mkdir "$sandbox/blueprint/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_finds_a_source_in_the_home_directory() {
	write_blueprint '{"files": [{"source": "~/media", "target": "uploads"}]}'
	mkdir "$mkwp_home/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_does_not_look_for_a_relative_source_in_the_current_directory() {
	write_blueprint '{"files": [{"source": "media", "target": "uploads"}]}'
	mkdir "$mkwp_dir/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"media\" in .files[0].source doesn't exist"
	assert_nothing_created
}

test_rejects_an_entry_without_a_target() {
	write_blueprint '{"files": [{"source": "./media"}]}'
	mkdir "$sandbox/blueprint/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 32 "Invalid blueprint $blueprint: .files[0] has no \"target\""
	assert_nothing_created
}

test_rejects_a_source_that_does_not_exist() {
	write_blueprint '{"files": [{"source": "./media", "target": "uploads"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./media\" in .files[0].source doesn't exist"
	assert_nothing_created
}

test_rejects_a_source_that_can_not_be_read() {
	write_blueprint '{"files": [{"source": "./media/logo.png", "target": "uploads"}]}'
	mkdir "$sandbox/blueprint/media"
	echo 'A logo' > "$sandbox/blueprint/media/logo.png"
	chmod a-r "$sandbox/blueprint/media/logo.png"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./media/logo.png\" in .files[0].source can't be read"
	assert_nothing_created
}

test_rejects_an_absolute_target() {
	write_blueprint '{"files": [{"source": "./media", "target": "/var/www/html/wp-content/uploads"}]}'
	mkdir "$sandbox/blueprint/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 37 "Invalid blueprint $blueprint: \"/var/www/html/wp-content/uploads\" in .files[0].target is not a path relative to wp-content"
	assert_nothing_created
}

test_rejects_a_target_that_escapes_wp_content() {
	write_blueprint '{"files": [{"source": "./media", "target": "uploads/2024/../../../wp-admin"}]}'
	mkdir "$sandbox/blueprint/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 38 "Invalid blueprint $blueprint: \"uploads/2024/../../../wp-admin\" in .files[0].target is outside wp-content"
	assert_nothing_created
}

test_rejects_a_target_in_the_home_directory() {
	write_blueprint '{"files": [{"source": "./media", "target": "~/uploads"}]}'
	mkdir "$sandbox/blueprint/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 37 "Invalid blueprint $blueprint: \"~/uploads\" in .files[0].target is not a path relative to wp-content"
	assert_nothing_created
}

test_rejects_an_empty_target() {
	write_blueprint '{"files": [{"source": "./media", "target": ""}]}'
	mkdir "$sandbox/blueprint/media"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 37 "Invalid blueprint $blueprint: \"\" in .files[0].target is not a path relative to wp-content"
	assert_nothing_created
}
