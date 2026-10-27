# A blueprint's database is checked with the rest of the blueprint, before
# mkwp checks Docker and DDEV, so here Docker is not running. A database that
# passes every check gets mkwp as far as that, and no further.

test_rejects_a_database_without_a_dump() {
	write_blueprint '{"database": {"server": "mariadb:11.4"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 32 "Invalid blueprint $blueprint: .database has no \"dump\""
	assert_nothing_created
}

test_rejects_a_snapshot() {
	write_blueprint '{"database": {"dump": "./site.sql", "snapshot": "./site.zst"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 30 "Invalid blueprint $blueprint: .database.snapshot is not a known key"
	assert_nothing_created
}

test_rejects_a_dump_that_does_not_exist() {
	write_blueprint '{"database": {"dump": "./site.sql"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.sql\" in .database.dump doesn't exist"
	assert_nothing_created
}

test_rejects_a_dump_that_is_a_directory() {
	write_blueprint '{"database": {"dump": "./site.sql"}}'
	mkdir "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.sql\" in .database.dump is a directory, not a .sql or .sql.gz file"
	assert_nothing_created
}

test_rejects_a_dump_that_can_not_be_read() {
	write_blueprint '{"database": {"dump": "./site.sql"}}'
	echo 'SELECT 1;' > "$sandbox/blueprint/site.sql"
	chmod a-r "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.sql\" in .database.dump can't be read"
	assert_nothing_created
}

# DDEV takes a file whose name ends in .gz, but not in .sql.gz, for gzipped
# SQL, and imports it as it is.
test_rejects_a_dump_that_is_neither_plain_nor_gzipped_sql() {
	write_blueprint '{"database": {"dump": "./site.gz"}}'
	echo 'SELECT 1;' | gzip > "$sandbox/blueprint/site.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.gz\" in .database.dump is not a .sql or .sql.gz file"
	assert_nothing_created
}

test_rejects_a_server_of_another_type() {
	write_blueprint '{"database": {"dump": "./site.sql", "server": "postgres:16"}}'
	echo 'SELECT 1;' > "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 46 "Invalid blueprint $blueprint: \"postgres:16\" in .database.server is not a MariaDB or MySQL server, given as mariadb:<version> or mysql:<version>"
	assert_nothing_created
}

test_rejects_a_server_without_a_version() {
	write_blueprint '{"database": {"dump": "./site.sql", "server": "mariadb"}}'
	echo 'SELECT 1;' > "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 46 "Invalid blueprint $blueprint: \"mariadb\" in .database.server is not a MariaDB or MySQL server, given as mariadb:<version> or mysql:<version>"
	assert_nothing_created
}

# A dump is a local path, so it needs no ./ in front, unlike a source.
test_finds_a_dump_and_a_server_that_are_valid() {
	write_blueprint '{"database": {"dump": "dumps/site.sql.gz", "server": "mysql:8.0"}}'
	mkdir "$sandbox/blueprint/dumps"
	echo 'SELECT 1;' | gzip > "$sandbox/blueprint/dumps/site.sql.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 'Error: Check that a Docker provider is installed and running and that DDEV is properly installed'
	assert_nothing_created
}
