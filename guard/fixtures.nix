# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Proves the guard fails when it should: builds made-up repositories, each with
# one kind of private material, and expects the guard to reject every one of
# them while it accepts a clean one.
{
  runCommandLocal,
  git,
  guard,
  python3,
}:

runCommandLocal "soxin-guard-fixtures"
  {
    nativeBuildInputs = [
      git
      guard
      python3
    ];
  }
  ''
    bash ${./fixtures.sh}
    touch $out
  ''
