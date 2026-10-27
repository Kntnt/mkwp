# A site built from a blueprint that copies files underneath uploads, into
# directories that don't exist until then: one file under a new name, and one
# into a directory, given with a trailing slash, under its own name. It also
# merges a directory into mu-plugins, which mkwp has already put files in.
# uploads is mounted into the container, while mu-plugins reaches it through
# Mutagen. The sources are given relative to the blueprint, and mkwp is run
# from another directory.

fixtures="$run_dir/fixtures/blueprint-files"

setup_file() {

	mkdir -p "$fixtures/media" "$fixtures/mu-plugins/DISABLED"
	echo 'A file copied by mkwp' > "$fixtures/media/mkwp-file.txt"
	printf '<?php\n/*\nPlugin Name: mkwp-files-mu\n*/\n' > "$fixtures/mu-plugins/mkwp-files-mu.php"
	printf '<?php\n/*\nPlugin Name: mkwp-files-disabled\n*/\n' > "$fixtures/mu-plugins/DISABLED/mkwp-files-disabled.php"

	cat > "$fixtures/blueprint.json" <<- 'EOT'
	{
		"files": [
			{"source": "./media/mkwp-file.txt", "target": "uploads/2024/01/mkwp-renamed.txt"},
			{"source": "./media/mkwp-file.txt", "target": "uploads/2024/02/"},
			{"source": "./mu-plugins", "target": "mu-plugins", "note": "Merged with what is there"}
		]
	}
	EOT

	make_site files -B "$fixtures/blueprint.json"

}

# Usage: uploads_listing <label>
# Echoes the path of each file underneath the uploads directory of the site
# <label>, relative to it, sorted.
uploads_listing() {
	# shellcheck disable=SC2016 # The code is PHP's, not the shell's
	site_wp "$1" eval '
		$base = wp_upload_dir()["basedir"];
		$files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($base, FilesystemIterator::SKIP_DOTS));
		$paths = [];
		foreach ($files as $file) { $paths[] = substr($file->getPathname(), strlen($base) + 1); }
		sort($paths);
		echo implode("\n", $paths);
	'
}

test_copies_a_file_to_the_target_path_under_a_new_name() {
	assert_equal 'A file copied by mkwp' "$(site_wp files eval 'echo file_get_contents(wp_upload_dir()["basedir"] . "/2024/01/mkwp-renamed.txt");')"
}

test_copies_a_file_into_a_target_that_ends_with_a_slash_under_its_own_name() {
	assert_equal 'A file copied by mkwp' "$(site_wp files eval 'echo file_get_contents(wp_upload_dir()["basedir"] . "/2024/02/mkwp-file.txt");')"
}

test_copies_nothing_else_into_uploads() {
	assert_equal $'2024/01/mkwp-renamed.txt\n2024/02/mkwp-file.txt' "$(uploads_listing files)"
}

test_merges_a_directory_into_mu_plugins() {
	assert_equal mkwp-files-mu "$(site_wp files plugin list --status=must-use --field=name)"
	assert_equal yes "$(site_wp files eval 'echo is_file(WPMU_PLUGIN_DIR . "/DISABLED/mkwp-files-disabled.php") ? "yes" : "no";')"
}

test_keeps_what_was_already_in_mu_plugins() {
	assert_equal yes "$(site_wp files eval 'echo is_file(WPMU_PLUGIN_DIR . "/index.php") ? "yes" : "no";')"
}
