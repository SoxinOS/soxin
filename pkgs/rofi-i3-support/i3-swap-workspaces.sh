#!/usr/bin/env bash
#
# vim:ft=sh:tabstop=4:shiftwidth=4:softtabstop=4:noexpandtab
#
# Copyright (c) 2021 Wael Nasreddine <wael.nasreddine@gmail.com>
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

set -euo pipefail

source @out_dir@/lib/list-workspaces.sh

if [[ -z "${*}" ]]; then
	# get the list of workspaces that are not empty
	listWorkspaces
	exit 0
fi

# record the target workspace, and its output
readonly target_workspace="$1"
readonly target_output="$(@i3-msg_bin@ -t get_workspaces | @jq_bin@ -r ".[] | select(.name == \"$target_workspace\") | .output")"

# figure out the source workspace and the output name
readonly source_workspace="$(@i3-msg_bin@ -t get_workspaces | @jq_bin@ -r ".[] | select(.visible == true and .focused == true) | .name")"
readonly source_output="$(@i3-msg_bin@ -t get_workspaces | @jq_bin@ -r ".[] | select(.visible == true and .focused == true) | .output")"

# if the target_output is empty then the workspace does not exist so just
# switch to it to create it on the same output. Or if both workspaces are on
# the same output then just switch to it
if [[ -z "${target_output:-}" ]] || [[ "${source_output}" == "${target_output}" ]]; then
	@i3-msg_bin@ workspace "$target_workspace" >/dev/null
	exit 0
fi

# swap them now
@i3-msg_bin@ move workspace to output "$target_output" >/dev/null
@i3-msg_bin@ workspace "$target_workspace" >/dev/null
@i3-msg_bin@ move workspace to output "$source_output" >/dev/null
