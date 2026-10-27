# Helpers for the fast suite, which needs neither Docker nor DDEV.
#
# Each test gets a sandbox of its own, with its own home directory, so mkwp
# reads and creates a ~/.mkwp there and never the user's own, and its own work
# directory, where mkwp is run and would create the site. The real DDEV and
# Docker are hidden from mkwp's PATH. In their place is a stand-in for DDEV
# that behaves as DDEV does when Docker is not running, and that records each
# command it is given, so a test can tell whether DDEV was asked to create
# anything. A test that needs another situation sets it up with the helpers
# below.
# =============================================================================

# Usage: setup_test
# Gives the test a sandbox of its own, in which Docker is not running.
setup_test() {

	sandbox=$(mktemp -d "$run_dir/test.XXXXXX")
	mkwp_home="$sandbox/home"
	mkwp_dir="$sandbox/work"
	mkdir "$mkwp_home" "$mkwp_dir" "$sandbox/bin"

	mkwp_path=$PATH
	hide ddev docker
	mkwp_path="$sandbox/bin:$mkwp_path"

	docker_is_not_running

}

# Usage: hide <tool>...
# Makes each <tool> missing from the PATH mkwp runs with, while every other
# command stays where it was. Each directory on that PATH that holds one of
# them is replaced by a directory of links to everything else in it.
hide() {

	local dirs dir tool path=
	IFS=: read -r -a dirs <<< "$mkwp_path"

	for dir in "${dirs[@]}"; do
		for tool in "$@"; do
			if [[ -e "$dir/$tool" ]]; then
				dir=$(mirror_without "$dir" "$@")
				break
			fi
		done
		path+=${path:+:}$dir
	done

	# A tool that slipped through could be the real DDEV, run with the
	# sandbox's home directory, so make sure.
	for tool in "$@"; do
		[[ -z $(PATH=$path type -P "$tool") ]] || fail "Couldn't hide $tool from mkwp."
	done

	mkwp_path=$path

}

# Usage: mirror_without <directory> <tool>...
# Echoes the path of a directory of links to everything in <directory> but
# each <tool>. It is made once per run, since a directory such as Homebrew's
# can hold thousands of commands.
mirror_without() {

	local dir=$1
	shift

	local mirror
	mirror="$run_dir/path/$(printf '%s\n' "$dir" "$@" | cksum | tr ' ' -)"

	if [[ ! -d $mirror ]]; then
		mkdir -p "$mirror"
		ln -s "$dir"/* "$mirror"
		for tool in "$@"; do
			rm -f "$mirror/$tool"
		done
	fi

	echo "$mirror"

}

# Usage: stand_in_for_ddev <script>
# Puts a stand-in for DDEV on mkwp's PATH that records each command it is given
# in $sandbox/ddev.log and then runs <script>, in which $* is the command.
stand_in_for_ddev() {

	cat > "$sandbox/bin/ddev" <<- EOT
	#!/usr/bin/env bash
	echo "\$*" >> '$sandbox/ddev.log'
	$1
	EOT
	chmod +x "$sandbox/bin/ddev"

}

# Usage: docker_is_not_running
# Makes DDEV fail every command, as it does when Docker is not running.
docker_is_not_running() {
	stand_in_for_ddev 'exit 1'
}

# Usage: ddev_is_missing
# Takes DDEV off mkwp's PATH.
ddev_is_missing() {
	hide ddev
}

# Usage: ddev_has_project <name> <directory>
# Makes Docker run and DDEV list one project, named <name> and placed in
# <directory>, as `ddev list -j` does. DDEV fails any other command.
ddev_has_project() {

	stand_in_for_ddev "case \"\$*\" in
		'debug dockercheck') exit 0 ;;
		'list -j') echo '{\"level\":\"info\",\"raw\":[{\"approot\":\"$2\",\"name\":\"$1\",\"status\":\"stopped\"}]}' ;;
		*) exit 1 ;;
	esac"

}

# Usage: write_blueprint <json>
# Writes <json> to a blueprint file in a directory of its own, outside the work
# directory, and sets blueprint to the file's path. A test puts the files the
# blueprint refers to in the same directory.
write_blueprint() {

	mkdir -p "$sandbox/blueprint"
	blueprint="$sandbox/blueprint/blueprint.json"
	printf '%s\n' "$1" > "$blueprint"

}

# Usage: write_zip <zip-file> <name>
# Writes a zip file at <zip-file> that holds a theme or plugin in a directory
# named <name>.
write_zip() {

	local dir
	dir=$(mktemp -d "$sandbox/zip.XXXXXX")
	mkdir "$dir/$2"
	echo '<?php' > "$dir/$2/$2.php"
	(cd "$dir" && zip -qr - "$2") > "$1"
	rm -rf "$dir"

}

# Usage: assert_nothing_created
# Asserts that mkwp created nothing in the work directory, where it would have
# put the site, and that DDEV was asked for nothing but whether Docker runs and
# which projects it has.
assert_nothing_created() {

	assert_no_files_created

	local asked
	asked=$(grep -vxE 'debug dockercheck|list -j' "$sandbox/ddev.log" 2> /dev/null || true)
	[[ -z $asked ]] || fail "DDEV was asked to:\n$asked"

}
