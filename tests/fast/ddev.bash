# mkwp checks Docker and DDEV once the options are valid, and asks DDEV
# whether the name or the directory is already taken by a project.

test_rejects_an_invalid_option_when_ddev_is_missing() {
	ddev_is_missing
	run_mkwp -m not-an-email site
	assert_rejected 6 'Invalid email address: not-an-email'
	assert_no_files_created
}

test_stops_when_ddev_is_missing() {
	ddev_is_missing
	run_mkwp -m test@example.com site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_no_files_created
}

test_stops_when_docker_is_not_running() {
	run_mkwp -m test@example.com site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}

test_rejects_a_name_ddev_already_has_a_project_for() {
	ddev_has_project site "$mkwp_dir/elsewhere"
	run_mkwp -m test@example.com site
	assert_rejected 16 "A project named 'site' already exists in DDEV."
	assert_nothing_created
}

# DDEV can have a project registered in a directory that no longer exists. A
# directory that does exist is rejected before DDEV is asked.
test_rejects_a_directory_ddev_already_has_a_project_in() {
	ddev_has_project other "$mkwp_dir/site"
	run_mkwp -m test@example.com site
	assert_rejected 15 "A DDEV project already exists in the directory $mkwp_dir/site."
	assert_nothing_created
}
