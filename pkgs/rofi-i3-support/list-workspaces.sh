#!/usr/bin/env bash
#
# vim:ft=sh:tabstop=4:shiftwidth=4:softtabstop=4:noexpandtab
#
# Copyright (c) 2010-2020 Wael Nasreddine <wael.nasreddine@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.
#

containsElement () {
	local e match="$1"
	shift
	for e; do [[ "$e" == "$match" ]] && return 0; done
	return 1
}

function listWorkspaces() {
	local all_workspaces current_workspace dir elem elem file profile_name story story_name workspaces

	# get the list of non-focused workspaces
	all_workspaces=( $(@i3-msg_bin@ -t get_workspaces | @jq_bin@ -r '.[] | select(.focused == false) | .name') )

	# get the list of available profiles
	for file in $(find "${HOME}/.zsh/profiles" -iregex '.*/[a-z]*\.zsh' | sort); do
		elem="$(basename "${file}" .zsh)"
		if ! containsElement "${elem}" "${all_workspaces[@]}"; then
			all_workspaces=("${all_workspaces[@]}" "${elem}")
		fi
	done

	# get the list of available stories
	if [[ "$(swm story list --name-only | wc -l)" -gt 0 ]]; then
		for story in $(swm story list --name-only); do
			profile_name="$(echo "${story}" | cut -d/ -f1)"
			story_name="$(echo "${story}" | cut -d/ -f2-)"
			elem="${profile_name}@${story_name}"
			if ! containsElement "${elem}" "${all_workspaces[@]}"; then
				all_workspaces+=("${elem}")
			fi
		done
	fi


	# sort the workspaces by putting first the non-story workspaces followed by the story workspaces
	workspaces=( $(printf "%s\n" "${all_workspaces[@]}" | grep -v '@' | sort) )
	if [[ "$(swm story list --name-only | wc -l)" -gt 0 ]]; then
		workspaces+=( $(printf "%s\n" "${all_workspaces[@]}" | grep '@' | sort) )
	fi

	# compute the current workspace
	current_workspace="$( @i3-msg_bin@ -t get_workspaces | @jq_bin@ -r '.[] | select(.focused == true) | .name' )"

	for elem in "${workspaces[@]}"; do
		if [[ "${elem}" == "${current_workspace}" ]]; then
			continue
		fi

		echo "${elem}"
	done
}
