# A site built from a blueprint whose themes, plugins and mu-plugins are
# pinned to a version or a ref, or are kept next to the blueprint as plain
# files.
#
# The plain files are two theme directories, of which the first is marked to
# be activated and the second is listed last, a plugin directory, given with a
# trailing slash, and an mu-plugin's PHP file.
#
# The Git sources are copies of one bare repository, reached through file://
# URLs, and named after the ref each is installed at, since a theme or plugin
# from Git is named after its repository. The repository holds a plugin at
# these versions:
#
#   1.0.0      tagged v1.0.0, on main
#   1.1.0-dev  untagged, on main
#   1.2.0      tagged v1.2.0, the latest tag, on main
#   1.3.0-dev  untagged, on the branch next only

fixtures="$run_dir/fixtures/blueprint-sources"

# Hello Dolly has an older release, 1.6, on WordPress.org.
pinned_version=1.6

setup_file() {

	mkdir -p "$fixtures"
	make_extension "$fixtures/themes/mkwp-dir-theme" theme mkwp-dir-theme 1.0.0
	mkdir "$fixtures/themes/mkwp-dir-theme/parts"
	echo '<!-- A part in a subdirectory -->' > "$fixtures/themes/mkwp-dir-theme/parts/header.html"
	make_extension "$fixtures/themes/mkwp-other-theme" theme mkwp-other-theme 1.0.0
	make_extension "$fixtures/plugins/mkwp-dir-plugin" plugin mkwp-dir-plugin 1.0.0
	mkdir "$fixtures/mu-plugins"
	printf '<?php\ndefine( "MKWP_MU_PLUGIN", true );\n' > "$fixtures/mu-plugins/mkwp-mu-plugin.php"

	make_ref_repository "$fixtures/mkwp-ref.git"

	local repository
	for repository in latest tag branch commit; do
		cp -R "$fixtures/mkwp-ref.git" "$fixtures/mkwp-$repository-plugin.git"
	done

	# An abbreviated hash, as one would copy it from git log
	local commit
	commit=$(fixture_git -C "$fixtures/mkwp-ref.git" rev-parse --short=12 'v1.2.0^')

	cat > "$fixtures/blueprint.json" <<- EOT
	{
		"themes": [
			{"source": "./themes/mkwp-dir-theme", "activate": true},
			"./themes/mkwp-other-theme"
		],
		"plugins": [
			{"source": "./plugins/mkwp-dir-plugin/", "activate": true},
			{"source": "hello-dolly", "version": "$pinned_version"},
			"file://$fixtures/mkwp-latest-plugin.git",
			{"source": "file://$fixtures/mkwp-tag-plugin.git", "ref": "v1.0.0"},
			{"source": "file://$fixtures/mkwp-branch-plugin.git", "ref": "next"},
			{"source": "file://$fixtures/mkwp-commit-plugin.git", "ref": "$commit"}
		],
		"mu_plugins": ["./mu-plugins/mkwp-mu-plugin.php"]
	}
	EOT

	make_site sources -B "$fixtures/blueprint.json"

}

# Usage: make_ref_repository <repository>
# Makes the bare Git repository described at the top of this file at
# <repository>.
make_ref_repository() {

	make_repository "$1" plugin mkwp-ref-plugin 1.0.0 1.1.0-dev 1.2.0

	local work
	work=$(mktemp -d "$run_dir/repository.XXXXXX")
	fixture_git clone -q "$1" "$work"
	fixture_git -C "$work" switch -qc next
	make_extension "$work" plugin mkwp-ref-plugin 1.3.0-dev
	fixture_git -C "$work" commit -qam 'Version 1.3.0-dev'
	fixture_git -C "$work" push -q origin next
	rm -rf "$work"

}

test_installs_a_plugin_from_wordpress_org_at_the_pinned_version() {
	assert_equal "$pinned_version" "$(site_wp sources plugin get hello-dolly --field=version)"
}

test_checks_out_the_latest_tag_without_a_ref() {
	assert_equal 1.2.0 "$(site_wp sources plugin get mkwp-latest-plugin --field=version)"
}

test_checks_out_an_older_tag_given_as_ref() {
	assert_equal 1.0.0 "$(site_wp sources plugin get mkwp-tag-plugin --field=version)"
}

test_checks_out_a_branch_given_as_ref() {
	assert_equal 1.3.0-dev "$(site_wp sources plugin get mkwp-branch-plugin --field=version)"
}

test_checks_out_a_commit_given_as_ref() {
	assert_equal 1.1.0-dev "$(site_wp sources plugin get mkwp-commit-plugin --field=version)"
}

test_installs_themes_from_local_directories_under_their_own_names() {
	assert_equal $'mkwp-dir-theme\nmkwp-other-theme' "$(site_wp sources theme list --field=name | sort)"
}

test_activates_the_marked_theme_from_a_local_directory() {
	assert_equal mkwp-dir-theme "$(site_wp sources theme list --status=active --field=name)"
}

test_copies_a_local_directory_with_its_subdirectories() {
	assert_equal yes "$(site_wp sources eval 'echo is_file( get_stylesheet_directory() . "/parts/header.html" ) ? "yes" : "no";')"
}

test_installs_and_activates_a_plugin_from_a_local_directory() {
	assert_equal active "$(site_wp sources plugin get mkwp-dir-plugin --field=status)"
}

test_installs_and_loads_an_mu_plugin_from_a_local_php_file() {
	assert_equal mkwp-mu-plugin "$(site_wp sources plugin list --status=must-use --field=name)"
	assert_equal loaded "$(site_wp sources eval 'echo defined( "MKWP_MU_PLUGIN" ) ? "loaded" : "not loaded";')"
}
