# Helpers for the end-to-end suite, which builds real sites with Docker and
# DDEV.
#
# mkwp runs with a home directory of the run's own, so it reads and creates a
# ~/.mkwp there and never the user's own. DDEV and Docker keep their state in
# the user's real home directory, so mkwp reaches DDEV through a stand-in that
# runs the real DDEV with the real HOME.
#
# DDEV runs non-interactively, so it never waits for an answer, nor for a
# password to add a hostname it can't resolve to the hosts file. `ddev launch`
# prints the site's address instead of opening it in a browser.
#
# Each site is named after the run's prefix, mkwp-e2e- and a random part, so it
# can't be mistaken for a project of the user's or of another run. A site is
# registered before mkwp starts to build it, and destroy_sites destroys every
# registered site with mkwp --destroy. tests/run-e2e calls it after each test
# file, and when the run ends, however it ends.
# =============================================================================

# The user each site is built with.
site_user=admin
site_email=admin@example.com
site_password=correct-horse-battery-staple

# Usage: require_docker_and_ddev
# Exits with status 2 unless DDEV is on PATH and Docker is running.
require_docker_and_ddev() {

	if ! command -v ddev > /dev/null || ! ddev debug dockercheck &> /dev/null < /dev/null; then
		echo "The end-to-end suite needs DDEV on PATH and a running Docker provider." >&2
		exit 2
	fi

}

# Usage: prepare_e2e
# Sets the run's prefix and the environment mkwp runs in, puts the stand-in for
# DDEV on mkwp's PATH, and makes DDEV run non-interactively.
prepare_e2e() {

	e2e_prefix="mkwp-e2e-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 6 || true)"
	e2e_registry="$run_dir/registry"
	sites_dir="$run_dir/sites"

	mkwp_home="$run_dir/home"
	mkwp_dir="$run_dir/work"
	mkwp_path="$run_dir/bin:$PATH"
	mkdir "$mkwp_home" "$mkwp_dir" "$sites_dir" "$run_dir/bin"
	touch "$e2e_registry"

	cat > "$run_dir/bin/ddev" <<- EOT
	#!/usr/bin/env bash
	HOME=$(printf '%q' "$HOME") exec $(printf '%q' "$(command -v ddev)") "\$@"
	EOT
	chmod +x "$run_dir/bin/ddev"

	export DDEV_NONINTERACTIVE=true DDEV_LAUNCH_PRINT_URL=true

}

# Usage: site_name <label>
# Echoes the name of the run's site <label>.
site_name() {
	echo "$e2e_prefix-$1"
}

# Usage: make_site <label> [<option>...]
# Builds the site <label> with mkwp, with the site user and any <option>..., in
# the run's sites directory. Fails the test if mkwp fails.
make_site() {

	local name
	name=$(site_name "$1")
	shift

	echo "$name" >> "$e2e_registry"
	note "  building $name"

	run_mkwp -d "$sites_dir" -m "$site_email" -u "$site_user" -p "$site_password" "$@" "$name"
	(( status == 0 )) || fail "mkwp exited with status $status while building $name. The end of its output:\n$(tail -n 40 "$run_dir/stdout" | without_colours)\n$output"

}

# Usage: site_wp <label> <arg>...
# Runs `ddev wp <arg>...` in the site <label>.
site_wp() {

	local dir
	dir="$sites_dir/$(site_name "$1")"
	shift

	(cd "$dir" && ddev wp "$@") | without_php_deprecations

}

# Usage: without_php_deprecations
# Copies stdin to stdout without PHP's deprecation notices. Under PHP 8.5, the
# WP-CLI that DDEV ships prints them to stdout, each after an empty line, ahead
# of what it was asked for.
without_php_deprecations() {

	awk '
		/^$/ && !held { held = 1; next }
		/^Deprecated: .* on line [0-9]+$/ { held = 0; next }
		held { print ""; held = 0 }
		{ print }
		END { if (held) print "" }
	'

}

# Usage: destroy_sites
# Destroys each registered site that DDEV has, with mkwp --destroy, and then
# forgets them all. Only a name with the run's prefix is ever destroyed.
destroy_sites() {

	local names name
	mapfile -t names < "$e2e_registry"

	for name in "${names[@]}"; do
		[[ $name == "$e2e_prefix"-* ]] || continue
		if ddev describe "$name" -j &> /dev/null < /dev/null; then
			echo "  destroying $name"
			run_mkwp --destroy "$name" <<< "$name"
			(( status == 0 )) || echo "  mkwp --destroy $name exited with status $status: $output" >&2
		fi
	done

	: > "$e2e_registry"

}

# Usage: report_leftovers
# Reports each DDEV project and Docker container named after the run's prefix,
# and returns non-zero if there is one.
report_leftovers() {

	local left
	left=$(
		ddev list -j < /dev/null 2> /dev/null | grep -oE "\"name\":\"$e2e_prefix-[^\"]*\"" | sed -E 's/.*:"(.*)"/DDEV project: \1/'
		docker ps -a --format '{{.Names}}' 2> /dev/null | grep -F -- "$e2e_prefix" | sed 's/^/Docker container: /'
	)

	if [[ $left ]]; then
		echo "Left behind:" >&2
		echo "$left" >&2
		return 1
	fi

}
