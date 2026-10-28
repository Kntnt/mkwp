# A blueprint's database is checked with the rest of the blueprint, before
# mkwp checks Docker and DDEV, so here Docker is not running. A database that
# passes every check gets mkwp as far as that, and no further.

# A database is a local path, so it needs no ./ in front, unlike a source.
test_finds_a_dump_given_as_a_path() {
	write_blueprint '{"database": "dumps/site.sql.gz"}'
	mkdir "$sandbox/blueprint/dumps"
	echo 'SELECT 1;' | gzip > "$sandbox/blueprint/dumps/site.sql.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

# The name of a snapshot tells the server it was taken from, so it needs no
# server. One from an older DDEV is compressed with gzip, and has .gz at the
# end of its name, but not .sql.gz.
test_finds_a_snapshot_given_as_a_path() {
	write_blueprint '{"database": "snapshots/site_20250911151318-mariadb_10.11.gz"}'
	mkdir "$sandbox/blueprint/snapshots"
	echo snapshot | gzip > "$sandbox/blueprint/snapshots/site_20250911151318-mariadb_10.11.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_rejects_a_dump_that_does_not_exist() {
	write_blueprint '{"database": "./site.sql"}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.sql\" in .database doesn't exist"
	assert_nothing_created
}

test_rejects_a_dump_that_is_a_directory() {
	write_blueprint '{"database": "./site.sql"}'
	mkdir "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.sql\" in .database is a directory, not a .sql or .sql.gz file"
	assert_nothing_created
}

test_rejects_a_dump_that_can_not_be_read() {
	write_blueprint '{"database": "./site.sql"}'
	echo 'SELECT 1;' > "$sandbox/blueprint/site.sql"
	chmod a-r "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.sql\" in .database can't be read"
	assert_nothing_created
}

# DDEV takes a file whose name ends in .gz, but not in .sql.gz, for gzipped
# SQL, and imports it as it is.
test_rejects_a_dump_that_is_neither_plain_nor_gzipped_sql() {
	write_blueprint '{"database": "./site.gz"}'
	echo 'SELECT 1;' | gzip > "$sandbox/blueprint/site.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.gz\" in .database is neither a dump, whose name ends with .sql or .sql.gz, nor a DDEV snapshot, whose name ends with the server it was taken from, as in site-mariadb_11.8.zst"
	assert_nothing_created
}

test_rejects_a_snapshot_that_does_not_exist() {
	write_blueprint '{"database": "./site-mariadb_11.8.zst"}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site-mariadb_11.8.zst\" in .database doesn't exist"
	assert_nothing_created
}

test_rejects_a_snapshot_that_is_a_directory() {
	write_blueprint '{"database": "./site-mariadb_11.8.zst"}'
	mkdir "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site-mariadb_11.8.zst\" in .database is a directory, not a DDEV snapshot"
	assert_nothing_created
}

# DDEV tells the server that a snapshot was taken from by its name alone, and
# can't restore a snapshot that has lost it. Nor can mkwp tell it from a dump.
test_rejects_a_snapshot_without_the_name_ddev_gives_it() {
	write_blueprint '{"database": "./site.zst"}'
	echo snapshot > "$sandbox/blueprint/site.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site.zst\" in .database is neither a dump, whose name ends with .sql or .sql.gz, nor a DDEV snapshot, whose name ends with the server it was taken from, as in site-mariadb_11.8.zst"
	assert_nothing_created
}

test_rejects_a_server_of_another_type() {
	write_blueprint '{"site": {"db_server": "postgres:16"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 46 "Invalid blueprint $blueprint: \"postgres:16\" in .site.db_server is not a valid MariaDB or MySQL server, given as mariadb:<version> or mysql:<version>"
	assert_nothing_created
}

test_rejects_a_server_without_a_version() {
	write_blueprint '{"site": {"db_server": "mariadb"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 46 "Invalid blueprint $blueprint: \"mariadb\" in .site.db_server is not a valid MariaDB or MySQL server, given as mariadb:<version> or mysql:<version>"
	assert_nothing_created
}

test_finds_a_dump_and_a_server_that_are_valid() {
	write_blueprint '{"site": {"db_server": "mysql:8.0"}, "database": "./site.sql.gz"}'
	echo 'SELECT 1;' | gzip > "$sandbox/blueprint/site.sql.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

test_finds_a_snapshot_and_a_server_that_match() {
	write_blueprint '{"database": "./site-mariadb_11.8.zst", "site": {"db_server": "mariadb:11.8"}}'
	echo snapshot > "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_accepted
}

# The database is read after the site, whatever their order in the blueprint.
test_rejects_a_snapshot_taken_from_another_server() {
	write_blueprint '{"database": "./site-mariadb_11.8.zst", "site": {"db_server": "mariadb:11.4"}}'
	echo snapshot > "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 50 "Invalid blueprint $blueprint: \"./site-mariadb_11.8.zst\" in .database was taken from mariadb:11.8, not from mariadb:11.4 in .site.db_server. A snapshot can only be restored into the server it was taken from."
	assert_nothing_created
}

test_rejects_a_snapshot_taken_from_another_server_than_the_one_given_with_the_option() {
	write_blueprint '{"database": "./site-mariadb_11.8.zst"}'
	echo snapshot > "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com --db-server=mariadb:11.4 -B "$blueprint" site
	assert_rejected 50 "The snapshot $sandbox/blueprint/site-mariadb_11.8.zst was taken from mariadb:11.8, not from mariadb:11.4 given with --db-server. A snapshot can only be restored into the server it was taken from."
	assert_nothing_created
}

# Before mkwp 2.1.0, the database was an object, with the path in dump or
# snapshot, and the server in server.

test_rejects_a_database_with_neither_a_dump_nor_a_snapshot() {
	write_blueprint '{"database": {"server": "mariadb:11.4"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 52 "Invalid blueprint $blueprint: .database has no \"dump\" or \"snapshot\""
	assert_nothing_created
}

test_rejects_a_database_with_both_a_dump_and_a_snapshot() {
	write_blueprint '{"database": {"dump": "./site.sql", "snapshot": "./site-mariadb_11.8.zst", "server": "mariadb:11.8"}}'
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 49 "Invalid blueprint $blueprint: .database has both \"dump\" and \"snapshot\", but may only have one of them"
	assert_nothing_created
}

# The name of a snapshot tells the server, so the object needs none either.
test_finds_a_snapshot_in_a_database_object_without_a_server() {
	write_blueprint '{"database": {"snapshot": "./site-mariadb_11.8.zst"}}'
	echo snapshot > "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 "The object form of .database in the blueprint $blueprint is deprecated, and mkwp 3.0.0 won't accept it. Use \"database\": \"./site-mariadb_11.8.zst\" instead.
Error: Check that a Docker provider is installed and running and that DDEV is properly installed"
	assert_nothing_created
}

# In the object, the key says what the file must be.
test_rejects_a_snapshot_as_the_dump_of_a_database_object() {
	write_blueprint '{"database": {"dump": "./site-mariadb_11.8.zst"}}'
	echo snapshot > "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 35 "Invalid blueprint $blueprint: \"./site-mariadb_11.8.zst\" in .database.dump is not a .sql or .sql.gz file"
	assert_nothing_created
}

test_rejects_a_snapshot_taken_from_another_server_than_the_one_in_a_database_object() {
	write_blueprint '{"database": {"snapshot": "./site-mariadb_11.8.zst", "server": "mariadb:11.4"}}'
	echo snapshot > "$sandbox/blueprint/site-mariadb_11.8.zst"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 50 "Invalid blueprint $blueprint: \"./site-mariadb_11.8.zst\" in .database.snapshot was taken from mariadb:11.8, not from mariadb:11.4 in .database.server. A snapshot can only be restored into the server it was taken from."
	assert_nothing_created
}

test_rejects_a_server_of_another_type_in_a_database_object() {
	write_blueprint '{"database": {"dump": "./site.sql", "server": "postgres:16"}}'
	echo 'SELECT 1;' > "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 46 "Invalid blueprint $blueprint: \"postgres:16\" in .database.server is not a valid MariaDB or MySQL server, given as mariadb:<version> or mysql:<version>"
	assert_nothing_created
}

# The server in the object counts as the one in the site.
test_rejects_a_server_in_a_database_object_that_is_not_the_one_in_the_site() {
	write_blueprint '{"database": {"dump": "./site.sql", "server": "mariadb:11.4"}, "site": {"db_server": "mariadb:11.8"}}'
	echo 'SELECT 1;' > "$sandbox/blueprint/site.sql"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 55 "Invalid blueprint $blueprint: \"mariadb:11.4\" in .database.server is not \"mariadb:11.8\" in .site.db_server. Give the server only in .site.db_server."
	assert_nothing_created
}

# The object still works, with a warning that says what to write instead, and
# mkwp goes on.
test_accepts_a_database_object_with_a_warning() {
	write_blueprint '{"database": {"dump": "dumps/site.sql.gz", "server": "mysql:8.0"}}'
	mkdir "$sandbox/blueprint/dumps"
	echo 'SELECT 1;' | gzip > "$sandbox/blueprint/dumps/site.sql.gz"
	run_mkwp -m test@example.com -B "$blueprint" site
	assert_rejected 1 "The object form of .database in the blueprint $blueprint is deprecated, and mkwp 3.0.0 won't accept it. Use \"database\": \"dumps/site.sql.gz\" instead, and put the server in .site.db_server, as in \"site\": {\"db_server\": \"mysql:8.0\"}.
Error: Check that a Docker provider is installed and running and that DDEV is properly installed"
	assert_nothing_created
}
