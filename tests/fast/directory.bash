# A target directory mkwp can't use is rejected before mkwp checks Docker and
# DDEV, so here Docker is not running.

test_rejects_a_site_directory_that_already_exists() {
	mkdir "$mkwp_dir/site"
	run_mkwp -m test@example.com site
	assert_rejected 13 "$mkwp_dir/site already exists"
	assert_nothing_created
}

test_rejects_a_home_directory_that_does_not_exist() {
	run_mkwp -m test@example.com -d "$mkwp_dir/missing" site
	assert_rejected 14 "Cannot create $mkwp_dir/missing/site"
	assert_nothing_created
}
