# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
#
# Fixture test of soxin-guard. Every fixture is built at run time in a
# temporary directory, so none of the material it plants is ever committed.
# All names in it are made up.

set -euo pipefail

work=$(mktemp -d)
denied_word=zanzibar-fixture
failures=0
cases=0

# A clean repository: public inputs only, and hosts/ under examples/.
base() {
  local dir
  dir=$(mktemp -d "$work/repo.XXXXXX")
  mkdir -p "$dir/examples/fleet/hosts/example-host"
  echo '{ kind = "nixos"; system = "x86_64-linux"; }' >"$dir/examples/fleet/hosts/example-host/host.nix"
  cat >"$dir/flake.nix" <<'NIX'
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  inputs.tools.url = "git+https://codeberg.org/example/tools";
  outputs = _: { };
}
NIX
  cat >"$dir/flake.lock" <<'JSON'
{
  "nodes": {
    "nixpkgs": {
      "locked": { "owner": "NixOS", "repo": "nixpkgs", "rev": "0000000000000000000000000000000000000000", "type": "github" },
      "original": { "owner": "NixOS", "ref": "nixos-26.05", "repo": "nixpkgs", "type": "github" }
    },
    "tools": {
      "locked": { "rev": "0000000000000000000000000000000000000000", "type": "git", "url": "https://codeberg.org/example/tools" },
      "original": { "type": "git", "url": "https://codeberg.org/example/tools" }
    },
    "root": { "inputs": { "nixpkgs": "nixpkgs", "tools": "tools" } }
  },
  "root": "root",
  "version": 7
}
JSON
  echo "A made-up repository." >"$dir/README.md"
  echo "$dir"
}

# Replace one input in a fixture's flake.nix.
input_url() {
  sed -i "s|git+https://codeberg.org/example/tools|$2|" "$1/flake.nix"
}

# Replace the "tools" node of a fixture's flake.lock.
lock_node() {
  python3 - "$1/flake.lock" "$2" <<'PY'
import json, sys
path, node = sys.argv[1], json.loads(sys.argv[2])
lock = json.load(open(path))
lock["nodes"]["tools"] = {"locked": node, "original": node}
json.dump(lock, open(path, "w"))
PY
}

expect() {
  local want=$1 name=$2
  shift 2
  cases=$((cases + 1))
  local status=0
  "$@" >"$work/out" 2>&1 || status=$?
  if { [ "$want" = pass ] && [ "$status" -ne 0 ]; } || { [ "$want" = fail ] && [ "$status" -eq 0 ]; }; then
    echo "FAIL: $name: expected the guard to $want, it exited $status"
    sed 's/^/    /' "$work/out"
    failures=$((failures + 1))
  else
    echo "ok: $name ($want, exit $status)"
  fi
  if grep -qi "$denied_word" "$work/out"; then
    echo "FAIL: $name: the guard printed a denylist word"
    failures=$((failures + 1))
  fi
}

# --- clean repositories pass -------------------------------------------------

r=$(base)
expect pass "clean repository" soxin-guard "$r"

r=$(base)
echo "nothing private here" >"$r/notes.txt"
echo "$denied_word" >"$work/denylist"
expect pass "clean repository with a denylist" soxin-guard --denylist "$work/denylist" "$r"

# --- inputs that are not publicly fetchable ----------------------------------

r=$(base)
input_url "$r" "git+ssh://git@git.example.invalid/example/tools.git"
expect fail "git+ssh input" soxin-guard "$r"

r=$(base)
input_url "$r" "git+file:///srv/example/tools"
expect fail "git+file input" soxin-guard "$r"

r=$(base)
input_url "$r" "path:/srv/example/tools"
expect fail "path input" soxin-guard "$r"

r=$(base)
input_url "$r" "git+https://git.example.invalid/example/tools"
expect fail "input on a forge that is not public" soxin-guard "$r"

r=$(base)
input_url "$r" "gitlab:example/tools?host=gitlab.example.invalid"
expect fail "gitlab input on a private instance" soxin-guard "$r"

r=$(base)
input_url "$r" "tools"
expect fail "indirect input" soxin-guard "$r"

r=$(base)
lock_node "$r" '{"type": "path", "path": "/srv/example/tools"}'
expect fail "locked path input" soxin-guard "$r"

r=$(base)
lock_node "$r" '{"type": "git", "url": "ssh://git@git.example.invalid/example/tools.git"}'
expect fail "locked ssh input" soxin-guard "$r"

r=$(base)
lock_node "$r" '{"type": "git", "url": "file:///srv/example/tools"}'
expect fail "locked file input" soxin-guard "$r"

r=$(base)
lock_node "$r" '{"type": "tarball", "url": "https://files.example.invalid/tools.tar.gz"}'
expect fail "locked tarball on a host that is not public" soxin-guard "$r"

r=$(base)
lock_node "$r" '{"type": "tarball", "url": "https://files.example.invalid/tools.tar.gz"}'
expect pass "a host allowed on the command line" soxin-guard --allow-host files.example.invalid "$r"

# --- secrets files ------------------------------------------------------------

r=$(base)
echo "data: x" >"$r/examples/fleet/secrets.sops.yaml"
expect fail "*.sops.* file" soxin-guard "$r"

r=$(base)
echo "creation_rules: []" >"$r/.sops.yaml"
expect fail ".sops.yaml" soxin-guard "$r"

r=$(base)
mkdir -p "$r/keys"
echo "x" >"$r/keys/id_ed25519"
expect fail "ssh private key file name" soxin-guard "$r"

r=$(base)
{
  printf '%s%s\n' "-----BEGIN OPENSSH " "PRIVATE KEY-----"
  echo "AAAA"
} >"$r/notes.txt"
expect fail "private key in an innocent file" soxin-guard "$r"

r=$(base)
printf 'password: %s%s\n' 'ENC[AES256' '_GCM,data:AAAA,iv:AAAA,tag:AAAA,type:str]' >"$r/config.yaml"
expect fail "sops-encrypted value" soxin-guard "$r"

r=$(base)
printf '%s%s\n' "AGE-SECRET" "-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ" >"$r/notes.txt"
expect fail "age secret key" soxin-guard "$r"

# --- hosts/ outside the examples ------------------------------------------------

r=$(base)
mkdir -p "$r/hosts/example-real"
echo "{ }" >"$r/hosts/example-real/host.nix"
expect fail "top-level hosts/" soxin-guard "$r"

r=$(base)
mkdir -p "$r/modules/hosts"
echo "{ }" >"$r/modules/hosts/default.nix"
expect fail "nested hosts/" soxin-guard "$r"

# --- denylist from outside the repository ---------------------------------------

r=$(base)
echo "deploys to ${denied_word^^}.example.invalid" >"$r/notes.txt"
expect pass "a denied word passes without a denylist" soxin-guard "$r"
expect fail "denylist file (--denylist)" soxin-guard --denylist "$work/denylist" "$r"
expect fail "denylist file (SOXIN_GUARD_DENYLIST)" env SOXIN_GUARD_DENYLIST="$work/denylist" soxin-guard "$r"
expect fail "denylist words (SOXIN_GUARD_DENYLIST_WORDS)" env SOXIN_GUARD_DENYLIST_WORDS="other-word,$denied_word" soxin-guard "$r"

r=$(base)
echo "x" >"$r/$denied_word.txt"
expect fail "denied word in a file name" soxin-guard --denylist "$work/denylist" "$r"

r=$(base)
printf '%s\n!%s-project\n' "$denied_word" "$denied_word" >"$work/denylist-with-exception"
echo "uses github:example/$denied_word-project" >"$r/notes.txt"
expect pass "a denied word inside an exception" soxin-guard --denylist "$work/denylist-with-exception" "$r"
echo "and $denied_word on its own" >>"$r/notes.txt"
expect fail "a denied word outside an exception" soxin-guard --denylist "$work/denylist-with-exception" "$r"

r=$(base)
echo "$denied_word" >"$r/denylist"
expect fail "denylist inside the repository is refused" soxin-guard --denylist "$r/denylist" "$r"

r=$(base)
expect fail "--require-denylist without a denylist" soxin-guard --require-denylist "$r"

# --- history ------------------------------------------------------------------

r=$(base)
export HOME=$work GIT_AUTHOR_NAME=Alice GIT_AUTHOR_EMAIL=alice@example.com GIT_COMMITTER_NAME=Alice GIT_COMMITTER_EMAIL=alice@example.com
git -C "$r" init -q -b main
git -C "$r" add -A
git -C "$r" commit -q -m "initial"
echo "$denied_word" >"$r/notes.txt"
git -C "$r" add -A
git -C "$r" commit -q -m "add notes"
git -C "$r" rm -q notes.txt
git -C "$r" commit -q -m "remove notes"
expect pass "word removed from the tree" soxin-guard --denylist "$work/denylist" "$r"
expect fail "word still in the history" soxin-guard --denylist "$work/denylist" --history HEAD "$r"

r=$(base)
git -C "$r" init -q -b main
git -C "$r" add -A
git -C "$r" commit -q -m "deploy to $denied_word"
expect fail "word in a commit message" soxin-guard --denylist "$work/denylist" --history HEAD "$r"

echo "$cases cases, $failures failure(s)"
[ "$failures" -eq 0 ]
