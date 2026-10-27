# A site built without a blueprint. WordPress 6.9 is asked for, since the
# default theme depends on the version.

setup_file() {
	make_site plain -W 6.9
}

test_activates_the_default_theme_of_its_wordpress_version() {
	assert_equal twentytwentyfive "$(site_wp plain theme list --status=active --field=name)"
}

test_makes_the_given_user_an_administrator_with_the_given_email() {
	assert_equal administrator "$(site_wp plain user get "$site_user" --field=roles)"
	assert_equal "$site_email" "$(site_wp plain user get "$site_user" --field=user_email)"
}

test_lets_the_given_user_log_in_with_the_given_password() {
	site_wp plain user check-password "$site_user" "$site_password" || fail "The password was not accepted."
}

test_rejects_another_site_with_the_same_name() {
	run_mkwp -m "$site_email" "$(site_name plain)"
	assert_rejected 16 "A project named '$(site_name plain)' already exists in DDEV."
	assert_no_files_created
}
