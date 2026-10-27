# The test runner both suites share, and the assertions their tests use.
#
# A test file is a Bash file that defines tests: functions whose names start
# with test_. It may also define setup_file, which runs once before its tests.
# Each file is sourced in a subshell of its own, so files never see each
# other's functions, and each test runs in a subshell of its own, so a test can
# neither see nor spoil what another test did. Tests run in the order they are
# defined. A test fails when a command in it fails, since tests run with
# errexit, nounset and pipefail, like mkwp itself.
#
# Tests run mkwp with run_mkwp, in the environment the suite gives it through
# mkwp_home, mkwp_path and mkwp_dir, and assert on what a user sees: the exit
# status, the message, and the site that was built.
# =============================================================================

# The repository, and the mkwp under test in it.
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)
mkwp="$repo_dir/mkwp"

# The directory that holds everything a run creates. See make_run_dir.
run_dir=

# The environment run_mkwp runs mkwp in, which each suite sets: the home
# directory, the PATH, and the directory mkwp is run from.
mkwp_home=
mkwp_path=
mkwp_dir=

# Keep the user's own environment from changing how mkwp or a test behaves.
unset MKWP_DEBUG BASH_ENV CDPATH

# Usage: make_run_dir
# Creates the directory that holds everything a run creates, and sets run_dir
# to it. The path is physical, since Docker and DDEV resolve symbolic links,
# such as /var on macOS, and mkwp compares paths with theirs.
make_run_dir() {

	local tmp=${TMPDIR:-/tmp}
	run_dir=$(mktemp -d "${tmp%/}/mkwp-tests.XXXXXX") || exit 1
	run_dir=$(cd "$run_dir" && pwd -P) || exit 1

}

# Usage: note <message>
# Shows <message> on the terminal while a test runs, since a test's own output
# is kept for its report.
note() {
	echo "$1" >&3
}

# Usage: fail <message>
# Fails the current test with <message>.
fail() {
	echo -e "$1" >&2
	exit 1
}

# Usage: run_mkwp <arg>...
# Runs mkwp with <arg>... the way a user does, from the directory mkwp_dir, with
# the home directory mkwp_home and the PATH mkwp_path. Sets status to its exit
# status and output to what it wrote to stderr, without colours. What it wrote
# to stdout is in $run_dir/stdout.
run_mkwp() {

	find "$mkwp_dir" -mindepth 1 | sort > "$run_dir/before"

	status=0
	(cd "$mkwp_dir" && HOME="$mkwp_home" PATH="$mkwp_path" exec "$mkwp" "$@") > "$run_dir/stdout" 2> "$run_dir/stderr" || status=$?
	output=$(without_colours < "$run_dir/stderr")

}

# Usage: without_colours
# Copies stdin to stdout without the escape sequences that colour terminal
# output.
without_colours() {
	sed $'s/\e\\[[0-9;]*m//g'
}

# Usage: assert_no_files_created
# Asserts that mkwp, as last run by run_mkwp, created nothing in mkwp_dir,
# which is where it creates a site unless told otherwise.
assert_no_files_created() {

	local created
	created=$(find "$mkwp_dir" -mindepth 1 | sort | comm -13 "$run_dir/before" -)
	[[ -z $created ]] || fail "mkwp created:\n$created"

}

# Usage: assert_rejected <status> <message>
# Asserts that mkwp, as last run by run_mkwp, exited with <status> and wrote
# exactly <message> to stderr.
assert_rejected() {

	[[ $status == "$1" ]] || fail "Expected exit status $1, got $status, with this message:\n$output"
	[[ $output == "$2" ]] || fail "Expected the message:\n$2\nGot:\n$output"

}

# Usage: assert_stopped_with <status> <message>
# Asserts that mkwp, as last run by run_mkwp, exited with <status>, and that
# the last thing it wrote to stderr was <message>.
assert_stopped_with() {
	[[ $status == "$1" ]] || fail "Expected exit status $1, got $status, with this output:\n$(tail -n 20 <<< "$output")"
	assert_equal "$2" "$(tail -n 1 <<< "$output")"
}

# Usage: assert_equal <expected> <actual>
# Asserts that <actual> is <expected>.
assert_equal() {
	[[ $2 == "$1" ]] || fail "Expected:\n$1\nGot:\n$2"
}

# Usage: run_isolated <function>...
# Runs each <function> in turn in one subshell with errexit, nounset and
# pipefail, and with its output in $run_dir/log. Returns non-zero as soon as one
# fails. Errexit only works if this is not called as part of a condition, so
# the caller reads the status from $? afterwards.
run_isolated() {

	(
		set -eEuo pipefail
		trap 'echo "Failed at ${BASH_SOURCE[0]#"$repo_dir/"}:$LINENO: $BASH_COMMAND" >&2' ERR
		for function in "$@"; do
			"$function"
		done
	) > "$run_dir/log" 2>&1

}

# Usage: report <status> <function>
# Reports the test or setup <function> as passed if <status> is 0 and as
# failed with its output otherwise, and records the outcome for the summary.
report() {

	local name=${2#test_}
	name=${name//_/ }

	if (( $1 == 0 )); then
		printf '  ok      %s\n' "$name"
		echo passed >> "$run_dir/results"
	else
		printf '  FAILED  %s\n' "$name"
		sed 's/^/          /' "$run_dir/log"
		echo failed >> "$run_dir/results"
	fi

}

# Usage: run_file <file>
# Runs setup_file, if <file> defines it, and then each test in <file>, preceded
# by setup_test if the suite defines it. If setup_file fails, the tests are not
# run.
run_file() {

	local file=$1

	echo "${file#"$repo_dir/"}"

	(
		# shellcheck source=/dev/null
		source "$file"

		if declare -F setup_file > /dev/null; then
			run_isolated setup_file
			local status=$?
			if (( status )); then
				report "$status" setup_file
				exit
			fi
		fi

		local setup=()
		if declare -F setup_test > /dev/null; then
			setup=(setup_test)
		fi

		local tests test
		mapfile -t tests < <(grep -oE '^test_[[:alnum:]_]+' "$file")
		for test in "${tests[@]}"; do
			run_isolated "${setup[@]}" "$test"
			report $? "$test"
		done
	) 3>&1 < /dev/null

}

# Usage: summarize
# Prints how many tests passed and failed, and returns non-zero if any failed
# or none ran.
summarize() {

	local passed failed
	passed=$(grep -cx passed "$run_dir/results" 2> /dev/null)
	failed=$(grep -cx failed "$run_dir/results" 2> /dev/null)

	echo
	echo "${passed:-0} passed, ${failed:-0} failed"

	(( ${failed:-0} == 0 && ${passed:-0} > 0 ))

}
