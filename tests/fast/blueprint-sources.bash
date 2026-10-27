# The sources of a blueprint's themes, plugins and mu-plugins, and the version
# or ref that pins them, are checked before mkwp checks Docker and DDEV, so
# here Docker is not running. A blueprint that passes every check gets mkwp as
# far as that, and no further.

test_accepts_a_version_on_a_wordpress_org_slug() {
	write_blueprint '{"themes": [{"source": "twentytwentyfive", "version": "1.0"}], "plugins": [{"source": "hello-dolly", "version": "1.6"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_rejects_a_version_on_a_source_that_is_not_a_wordpress_org_slug() {
	write_blueprint '{"plugins": ["hello-dolly", {"source": "https://github.com/example/plugin.git", "version": "1.2.0"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 44 "Invalid blueprint $blueprint: .plugins[1] has a version, but only a slug on WordPress.org can have one"
	assert_nothing_created
}

test_accepts_a_ref_on_a_git_source() {
	write_blueprint '{"themes": [{"source": "git@github.com:example/theme.git", "ref": "v1.0.0"}], "plugins": [{"source": "file:///srv/git/plugin.git", "ref": "main"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_rejects_a_ref_on_a_source_that_is_not_a_git_repository() {
	write_blueprint '{"themes": [{"source": "twentytwentyfive", "ref": "v1.0.0"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 45 "Invalid blueprint $blueprint: .themes[0] has a ref, but only a Git repository can have one"
	assert_nothing_created
}

# A local path is recognized before a Git repository, so a path to a
# directory that ends with .git is not a Git source.
test_rejects_a_ref_on_a_local_path_that_ends_with_git() {
	write_blueprint '{"plugins": [{"source": "./plugin.git", "ref": "main"}]}'
	mkdir "$sandbox/blueprint/plugin.git"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 45 "Invalid blueprint $blueprint: .plugins[0] has a ref, but only a Git repository can have one"
	assert_nothing_created
}

test_rejects_an_empty_version() {
	write_blueprint '{"plugins": [{"source": "hello-dolly", "version": ""}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 33 "Invalid blueprint $blueprint: \"\" in .plugins[0].version is not a valid version"
	assert_nothing_created
}

# Git would take a ref that starts with a hyphen for an option.
test_rejects_a_ref_that_starts_with_a_hyphen() {
	write_blueprint '{"plugins": [{"source": "file:///srv/git/plugin.git", "ref": "--orphan"}]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 33 "Invalid blueprint $blueprint: \"--orphan\" in .plugins[0].ref is not a valid Git ref"
	assert_nothing_created
}

test_accepts_a_local_directory_as_a_theme_or_plugin() {
	write_blueprint '{"themes": [{"source": "./themes/child", "activate": true}], "plugins": ["./plugins/custom/"]}'
	mkdir -p "$sandbox/blueprint/themes/child" "$sandbox/blueprint/plugins/custom"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_rejects_a_local_directory_that_does_not_exist() {
	write_blueprint '{"themes": [{"source": "./themes/child", "activate": true}]}'
	mkdir -p "$sandbox/blueprint/themes"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./themes/child\" in .themes[0] doesn't exist"
	assert_nothing_created
}

test_accepts_a_local_php_file_as_an_mu_plugin() {
	write_blueprint '{"mu_plugins": ["./mu-plugins/custom.php", {"source": "~/shared.php", "note": "Shared by every site"}]}'
	mkdir -p "$sandbox/blueprint/mu-plugins"
	echo '<?php' > "$sandbox/blueprint/mu-plugins/custom.php"
	echo '<?php' > "$mkwp_home/shared.php"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_rejects_a_local_php_file_that_does_not_exist() {
	write_blueprint '{"mu_plugins": ["./mu-plugins/custom.php"]}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./mu-plugins/custom.php\" in .mu_plugins[0] doesn't exist"
	assert_nothing_created
}

test_rejects_a_local_mu_plugin_that_is_a_directory() {
	write_blueprint '{"mu_plugins": ["./custom.php"]}'
	mkdir "$sandbox/blueprint/custom.php"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./custom.php\" in .mu_plugins[0] is a directory, not a PHP file"
	assert_nothing_created
}

test_rejects_a_local_mu_plugin_that_is_not_a_php_file() {
	write_blueprint '{"mu_plugins": ["./mu-plugin.zip"]}'
	write_zip "$sandbox/blueprint/mu-plugin.zip" mu-plugin
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 34 "Invalid blueprint $blueprint: \"./mu-plugin.zip\" in .mu_plugins[0] is neither a local PHP file nor the URL of one"
	assert_nothing_created
}

test_rejects_a_local_directory_that_can_not_be_read() {
	write_blueprint '{"plugins": ["./custom"]}'
	mkdir "$sandbox/blueprint/custom"
	chmod a-x "$sandbox/blueprint/custom"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./custom\" in .plugins[0] can't be read"
	assert_nothing_created
}
