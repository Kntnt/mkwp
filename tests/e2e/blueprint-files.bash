# A site built from a blueprint that copies a file into a directory underneath
# uploads, which doesn't exist until then, and merges a directory into
# mu-plugins, which mkwp has already put files in. uploads is mounted into the
# container, while mu-plugins reaches it through Mutagen. The sources are given
# relative to the blueprint, and mkwp is run from another directory.

fixtures="$run_dir/fixtures/blueprint-files"

setup_file() {

	mkdir -p "$fixtures/media" "$fixtures/mu-plugins/DISABLED"
	echo 'A file copied by mkwp' > "$fixtures/media/mkwp-file.txt"
	printf '<?php\n/*\nPlugin Name: mkwp-files-mu\n*/\n' > "$fixtures/mu-plugins/mkwp-files-mu.php"
	printf '<?php\n/*\nPlugin Name: mkwp-files-disabled\n*/\n' > "$fixtures/mu-plugins/DISABLED/mkwp-files-disabled.php"

	cat > "$fixtures/blueprint.json" <<- 'EOT'
	{
		"files": [
			{"source": "./media/mkwp-file.txt", "target": "uploads/2024/01"},
			{"source": "./mu-plugins", "target": "mu-plugins", "note": "Merged with what is there"}
		]
	}
	EOT

	make_site files -B "$fixtures/blueprint.json"

}

test_copies_a_file_into_a_new_directory_underneath_uploads() {
	assert_equal 'A file copied by mkwp' "$(site_wp files eval 'echo file_get_contents(wp_upload_dir()["basedir"] . "/2024/01/mkwp-file.txt");')"
}

test_merges_a_directory_into_mu_plugins() {
	assert_equal mkwp-files-mu "$(site_wp files plugin list --status=must-use --field=name)"
	assert_equal yes "$(site_wp files eval 'echo is_file(WPMU_PLUGIN_DIR . "/DISABLED/mkwp-files-disabled.php") ? "yes" : "no";')"
}

test_keeps_what_was_already_in_mu_plugins() {
	assert_equal yes "$(site_wp files eval 'echo is_file(WPMU_PLUGIN_DIR . "/index.php") ? "yes" : "no";')"
}
