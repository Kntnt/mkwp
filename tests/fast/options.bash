# Invalid options are rejected with their own message and exit status before
# mkwp checks Docker and DDEV, so here Docker is not running. The email address
# is given wherever its check comes first, since the default one, made from the
# user and host names, is not valid on every machine.

test_rejects_an_invalid_name() {
	run_mkwp www.example.com
	assert_rejected 11 'Invalid name: www.example.com. A DDEV project name must start with a letter and may otherwise only contain letters, digits and hyphens. Use -D/--dirname to name the site directory freely.'
	assert_nothing_created
}

test_rejects_an_invalid_dirname() {
	run_mkwp -D .. site
	assert_rejected 20 'Invalid dirname: ..'
	assert_nothing_created
}

test_rejects_an_invalid_title() {
	run_mkwp -t $'Two\tcolumns' site
	assert_rejected 4 $'Invalid title: Two\tcolumns'
	assert_nothing_created
}

test_rejects_an_invalid_email_address() {
	run_mkwp -m not-an-email site
	assert_rejected 6 'Invalid email address: not-an-email'
	assert_nothing_created
}

test_rejects_a_short_password() {
	run_mkwp -m test@example.com -p 'too-short' site
	assert_rejected 7 'Invalid password. Must be at least 12 characters.'
	assert_nothing_created
}

test_rejects_an_invalid_language() {
	run_mkwp -m test@example.com -l swedish site
	assert_rejected 8 'Invalid language code: swedish'
	assert_nothing_created
}

test_rejects_an_unsupported_php_version() {
	run_mkwp -m test@example.com -V 9.1 site
	assert_rejected 9 'Invalid PHP version: 9.1'
	assert_nothing_created
}

test_rejects_an_invalid_wordpress_version() {
	run_mkwp -m test@example.com -W latest site
	assert_rejected 17 'Invalid WordPress version: latest'
	assert_nothing_created
}
