# A site built from a blueprint, with themes and plugins from WordPress.org,
# from zip files next to the blueprint and from Git repositories. The zip files
# are named with a version, unlike the directories they hold, and the Git
# repositories are bare repositories reached through file:// URLs. mkwp is run
# from another directory than the blueprint's.

fixtures="$run_dir/fixtures/blueprint"

# Kntnt's adminbar sanitizer, a single PHP file, serves as mu-plugin.
mu_plugin_url=https://raw.githubusercontent.com/Kntnt/kntnt-adminbar-sanitizer/master/kntnt-adminbar-sanitizer.php

setup_file() {

	mkdir -p "$fixtures"
	make_zip "$fixtures/mkwp-zip-theme-1.0.0.zip" theme mkwp-zip-theme 1.0.0
	make_zip "$fixtures/mkwp-zip-plugin-1.0.0.zip" plugin mkwp-zip-plugin 1.0.0
	make_repository "$fixtures/mkwp-git-theme.git" theme mkwp-git-theme 1.0.0 1.1.0 1.2.0-dev
	make_repository "$fixtures/mkwp-git-plugin.git" plugin mkwp-git-plugin 1.0.0 1.1.0 1.2.0-dev

	cat > "$fixtures/blueprint.json" <<- EOT
	{
		"\$schema": "https://raw.githubusercontent.com/Kntnt/mkwp/main/blueprint.schema.json",
		"note": "Built by the end-to-end suite",
		"site": {"title": "Blueprint Site", "language": "sv_SE", "php": "8.4", "wp": "6.8", "redis": true},
		"themes": [
			"twentytwentyfive",
			{"source": "./mkwp-zip-theme-1.0.0.zip", "activate": true, "note": "Marked, but not listed last"},
			"file://$fixtures/mkwp-git-theme.git"
		],
		"plugins": [
			{"source": "hello-dolly", "activate": true},
			{"source": "./mkwp-zip-plugin-1.0.0.zip", "activate": true},
			"file://$fixtures/mkwp-git-plugin.git"
		],
		"mu_plugins": ["$mu_plugin_url"]
	}
	EOT

	make_site blueprint -B "$fixtures/blueprint.json"

}

test_has_the_title_from_the_blueprint() {
	assert_equal 'Blueprint Site' "$(site_wp blueprint option get blogname)"
}

test_has_the_language_from_the_blueprint() {
	assert_equal sv_SE "$(site_wp blueprint eval 'echo get_locale();')"
}

test_runs_the_php_version_from_the_blueprint() {
	assert_equal 8.4 "$(site_wp blueprint eval 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')"
}

test_has_the_wordpress_version_from_the_blueprint() {
	local version
	version=$(site_wp blueprint core version)
	[[ $version == 6.8.* ]] || fail "Expected WordPress 6.8.x, got $version"
}

test_uses_redis_as_the_blueprint_asks() {
	assert_equal yes "$(site_wp blueprint eval 'echo wp_using_ext_object_cache() ? "yes" : "no";')"
}

test_installs_themes_from_wordpress_org_a_zip_file_and_git() {
	assert_equal $'mkwp-git-theme\nmkwp-zip-theme\ntwentytwentyfive' "$(site_wp blueprint theme list --field=name | sort)"
}

test_activates_the_marked_theme_although_it_is_not_listed_last() {
	assert_equal mkwp-zip-theme "$(site_wp blueprint theme list --status=active --field=name)"
}

test_checks_out_the_latest_tag_of_a_git_repository() {
	assert_equal 1.1.0 "$(site_wp blueprint theme get mkwp-git-theme --field=version)"
	assert_equal 1.1.0 "$(site_wp blueprint plugin get mkwp-git-plugin --field=version)"
}

test_activates_the_marked_plugins() {
	assert_equal $'hello-dolly\nmkwp-zip-plugin\nredis-cache' "$(site_wp blueprint plugin list --status=active --field=name | sort)"
}

test_installs_unmarked_plugins_without_activating_them() {
	assert_equal mkwp-git-plugin "$(site_wp blueprint plugin list --status=inactive --field=name)"
}

test_installs_an_mu_plugin_from_a_url() {
	assert_equal kntnt-adminbar-sanitizer "$(site_wp blueprint plugin list --status=must-use --field=name)"
}
