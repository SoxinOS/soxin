# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
"""soxin-guard: fail when a repository carries private material.

It fails on:

* flake inputs that are not publicly fetchable: path:, git+file:, git+ssh:,
  ssh:, indirect (registry) references, and anything not on a public forge;
* secrets files: *.sops.* files, private keys, age and sops encrypted payloads
  and other well-known secret file names;
* a hosts/ directory outside the examples directory;
* words of a denylist supplied from outside the repository, in file names,
  file contents and, with --history, in commit messages and patches.

The denylist comes from --denylist FILE, from the file named by
SOXIN_GUARD_DENYLIST, or from the words in SOXIN_GUARD_DENYLIST_WORDS
(separated by newlines or commas). An entry starting with ! is an exception:
a phrase that contains a denied word but is allowed, such as a public project
named like a private host. A denylist file inside the repository is refused. Findings never print a denylist word, only its position in the list,
so the guard can run in public CI logs.

Exit status: 0 when clean, 1 on findings, 2 on usage errors.
"""

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
from urllib.parse import parse_qs, urlsplit

PUBLIC_HOSTS = {
    "github.com",
    "gitlab.com",
    "codeberg.org",
    "git.sr.ht",
    "hg.sr.ht",
    "bitbucket.org",
    "flakehub.com",
    "api.flakehub.com",
    "channels.nixos.org",
    "releases.nixos.org",
}

# Forges a shorthand flake reference (github:owner/repo) points at by default.
FORGE_TYPES = {"github", "gitlab", "sourcehut"}

# Input types whose "url" must be an https URL on a public forge.
URL_TYPES = {"git", "tarball", "file", "hg", "mercurial"}

SECRET_NAMES = [
    "*.sops",
    "*.sops.*",
    "secrets.yaml",
    "secrets.yml",
    "secrets.json",
    "secrets.env",
    "*.age",
    "*.pem",
    "*.key",
    "*.p12",
    "*.pfx",
    "*.jks",
    "*.keystore",
    "*.kdbx",
    "*.gpg",
    "id_rsa",
    "id_dsa",
    "id_ecdsa",
    "id_ed25519",
    "id_ecdsa_sk",
    "id_ed25519_sk",
    ".env",
    ".env.*",
    ".netrc",
    ".pgpass",
    "keys.txt",
]

# Built from pieces so the guard's own source does not match itself.
SECRET_CONTENTS = [
    ("private key", re.compile("-----BEGIN [A-Z0-9 ]*" + "PRIVATE KEY" + "( BLOCK)?-----")),
    ("age secret key", re.compile("AGE-" + "SECRET-KEY-1")),
    ("sops encrypted value", re.compile(r"ENC\[" + "AES256_GCM,")),
    ("age encrypted file", re.compile("age-encryption" + r"\.org/v1")),
]

SKIP_DIRS = {".git", ".direnv"}


class Report:
    def __init__(self):
        self.findings = []
        self.words = []

    def add(self, where, what):
        self.findings.append((where, what))

    def mask(self, text):
        """Replace denylist words with their number, so none is ever printed."""
        for index, word in enumerate(self.words, 1):
            text = re.sub(re.escape(word), f"<denylist #{index}>", text, flags=re.IGNORECASE)
        return text

    def print(self):
        for where, what in self.findings:
            print(f"soxin-guard: {self.mask(where)}: {self.mask(what)}", file=sys.stderr)


def repository_files(root):
    """Relative paths of the files to scan, without following symlinks."""
    # .git is a directory in a clone and a file in a worktree.
    if os.path.exists(os.path.join(root, ".git")):
        out = subprocess.run(
            ["git", "-C", root, "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            check=True,
            capture_output=True,
        ).stdout
        paths = [p.decode() for p in out.split(b"\0") if p]
        paths = [p for p in paths if p.split("/")[0] not in SKIP_DIRS]
        return sorted(p for p in paths if os.path.lexists(os.path.join(root, p)))

    paths = []
    for directory, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SKIP_DIRS)
        for name in filenames:
            if name in SKIP_DIRS:
                continue
            paths.append(os.path.relpath(os.path.join(directory, name), root))
    return sorted(paths)


def repository_dirs(files):
    dirs = set()
    for path in files:
        parts = path.split("/")[:-1]
        for i in range(1, len(parts) + 1):
            dirs.add("/".join(parts[:i]))
    return sorted(dirs)


def read(root, path):
    full = os.path.join(root, path)
    if os.path.islink(full) or not os.path.isfile(full):
        return b""
    with open(full, "rb") as f:
        return f.read()


def public_host(host, allowed):
    return host is not None and host.lower() in allowed


def check_url(url, allowed):
    """Why a URL is not publicly fetchable, or None."""
    scheme, _, rest = url.partition(":")
    scheme = scheme.lower()
    if scheme.startswith("git+") or scheme.startswith("hg+") or scheme.startswith("tarball+") or scheme.startswith("file+"):
        scheme = scheme.split("+", 1)[1]
    if scheme != "https":
        return f"uses {scheme or 'no'} scheme, only https on a public forge is publicly fetchable"
    host = urlsplit("https:" + rest).hostname
    if not public_host(host, allowed):
        return f"is hosted on {host}, which is not a known public forge"
    return None


def check_flakeref(ref, allowed):
    """Why a flake reference string is not publicly fetchable, or None."""
    if ref.startswith(("/", ".", "~")):
        return "is a local path"
    if ":" not in ref:
        return "is an indirect (registry) reference"
    scheme, _, rest = ref.partition(":")
    scheme = scheme.lower()
    if scheme in FORGE_TYPES:
        query = parse_qs(urlsplit("x://h/" + rest).query)
        host = query.get("host", [None])[0]
        if host is not None and not public_host(host, allowed):
            return f"is hosted on {host}, which is not a known public forge"
        return None
    if scheme == "flake":
        return "is an indirect (registry) reference"
    if scheme in ("path", "file", "git+file", "ssh", "git+ssh", "sftp", "hg+file"):
        return f"uses {scheme}:, which is not publicly fetchable"
    return check_url(ref, allowed)


def check_lock_ref(ref, allowed):
    kind = ref.get("type")
    if kind in FORGE_TYPES:
        host = ref.get("host")
        if host is not None and not public_host(host, allowed):
            return f"is hosted on {host}, which is not a known public forge"
        return None
    if kind in URL_TYPES:
        return check_url(ref.get("url", ""), allowed)
    if kind == "path":
        return "is a path: input, which is not publicly fetchable"
    if kind == "indirect":
        return "is an indirect (registry) input"
    return f"has input type {kind!r}, which the guard does not know to be public"


FLAKE_URL = re.compile(r'\burl\s*=\s*"([^"]*)"')
FLAKE_TYPE = re.compile(r'\btype\s*=\s*"([^"]*)"')
FLAKE_SCP = re.compile(r"\b[\w.-]+@[\w.-]+:[\w./-]+")


def check_inputs(root, files, allowed, report):
    for path in files:
        name = os.path.basename(path)
        if name == "flake.lock":
            try:
                lock = json.loads(read(root, path))
            except ValueError as e:
                report.add(path, f"is not valid JSON ({e})")
                continue
            for node_name, node in sorted(lock.get("nodes", {}).items()):
                for field in ("locked", "original"):
                    ref = node.get(field)
                    if ref is None:
                        continue
                    why = check_lock_ref(ref, allowed)
                    if why:
                        report.add(path, f"input node {node_name!r} ({field}) {why}")
        elif name == "flake.nix":
            text = read(root, path).decode("utf-8", "replace")
            for number, line in enumerate(text.splitlines(), 1):
                for match in FLAKE_URL.finditer(line):
                    why = check_flakeref(match.group(1), allowed)
                    if why:
                        report.add(f"{path}:{number}", f"input url {match.group(1)!r} {why}")
                for match in FLAKE_TYPE.finditer(line):
                    if match.group(1) in ("path", "indirect"):
                        report.add(f"{path}:{number}", f"input of type {match.group(1)!r} is not publicly fetchable")
                for match in FLAKE_SCP.finditer(line):
                    report.add(f"{path}:{number}", f"{match.group(0)!r} looks like an ssh remote, which is not publicly fetchable")


def check_secrets(root, files, report):
    for path in files:
        name = os.path.basename(path).lower()
        for pattern in SECRET_NAMES:
            if fnmatch.fnmatchcase(name, pattern):
                report.add(path, f"is a secrets file (matches {pattern})")
                break
        text = read(root, path).decode("latin-1")
        for label, pattern in SECRET_CONTENTS:
            match = pattern.search(text)
            if match:
                number = text.count("\n", 0, match.start()) + 1
                report.add(f"{path}:{number}", f"contains a {label}")


def check_hosts(files, examples, report):
    for directory in repository_dirs(files):
        parts = directory.split("/")
        if parts[-1] != "hosts":
            continue
        if parts[0] == examples:
            continue
        report.add(directory, f"is a hosts/ directory outside {examples}/; real hosts belong in a private fleet")


class Denylist:
    """Denied words, and exceptions: phrases that contain a denied word but
    are allowed (e.g. a public project named like a private host)."""

    def __init__(self, entries):
        self.words = []
        self.exceptions = []
        for entry in entries:
            entry = entry.lower()
            target = self.exceptions if entry.startswith("!") else self.words
            entry = entry.lstrip("!").strip()
            # Keep the order, so an entry's number is stable.
            if entry and entry not in target:
                target.append(entry)

    def __bool__(self):
        return bool(self.words)

    def hits(self, text):
        """(entry number, line number) of each denied word in text."""
        lowered = text.lower()
        for exception in self.exceptions:
            lowered = lowered.replace(exception, " " * len(exception))
        for index, word in enumerate(self.words, 1):
            position = lowered.find(word)
            if position >= 0:
                yield index, lowered.count("\n", 0, position) + 1


def load_denylist(paths, root):
    """Entries are one per line (# starts a comment); a leading ! marks an exception."""
    entries = []
    for path in paths:
        real = os.path.realpath(path)
        if os.path.commonpath([real, os.path.realpath(root)]) == os.path.realpath(root):
            raise SystemExit(f"soxin-guard: the denylist {path} is inside the repository; keep it outside so it is never committed")
        with open(real, encoding="utf-8") as f:
            for line in f:
                entries.append(line.split("#", 1)[0].strip())
    entries += re.split(r"[\n,]", os.environ.get("SOXIN_GUARD_DENYLIST_WORDS", ""))
    return Denylist(e.strip() for e in entries)


def check_denylist(root, files, words, report):
    for path in files:
        for index, _ in words.hits(path):
            report.add(path, f"its path contains denylist entry #{index}")
        text = read(root, path).decode("latin-1")
        for index, number in words.hits(text):
            report.add(f"{path}:{number}", f"contains denylist entry #{index}")


def check_history(root, revisions, words, report):
    """Messages, authors, and what the commits of a revision range add.

    Removed lines are skipped: they were already in the history before the
    range, and removing them is what fixing a leak looks like.
    """
    log = subprocess.run(
        ["git", "-C", root, "log", "--format=%x1e%H%n%an <%ae>%n%cn <%ce>%n%B", "--no-ext-diff", "--no-color", "-p", revisions],
        check=True,
        capture_output=True,
    ).stdout.decode("utf-8", "replace")
    for entry in log.split("\x1e")[1:]:
        commit = entry[:12]
        header, _, patch = entry.partition("\ndiff --git ")
        added = [header]
        for line in patch.splitlines():
            if line.startswith("+++ b/") or line.startswith("rename to "):
                name = line.split(" ", 1)[1].removeprefix("b/")
                added.append(name)
                base = os.path.basename(name).lower()
                for pattern in SECRET_NAMES:
                    if fnmatch.fnmatchcase(base, pattern):
                        report.add(f"commit {commit}", f"adds secrets file {name} (matches {pattern})")
                        break
            elif line.startswith("+") and not line.startswith("+++ "):
                added.append(line[1:])
        for index, _ in words.hits("\n".join(added)):
            report.add(f"commit {commit}", f"adds denylist entry #{index} (message, author, file name or added line)")


def main(argv=None):
    parser = argparse.ArgumentParser(prog="soxin-guard", description=__doc__.split("\n\n")[0])
    parser.add_argument("root", nargs="?", default=".", help="the repository to check (default: .)")
    parser.add_argument("--denylist", action="append", default=[], metavar="FILE", help="a file of denied words, one per line, outside the repository")
    parser.add_argument("--require-denylist", action="store_true", help="fail when no denylist word was supplied")
    parser.add_argument("--allow-host", action="append", default=[], metavar="HOST", help="another host to treat as a public forge")
    parser.add_argument("--examples-dir", default="examples", help="the top-level directory hosts/ may live under (default: examples)")
    parser.add_argument("--history", metavar="RANGE", help="also check the commits of a git revision range, e.g. origin/main..HEAD")
    args = parser.parse_args(argv)

    root = args.root
    if not os.path.isdir(root):
        parser.error(f"{root} is not a directory")

    denylists = list(args.denylist)
    if os.environ.get("SOXIN_GUARD_DENYLIST"):
        denylists.append(os.environ["SOXIN_GUARD_DENYLIST"])
    words = load_denylist(denylists, root)
    if not words:
        if args.require_denylist:
            print("soxin-guard: no denylist supplied and --require-denylist is set", file=sys.stderr)
            return 2
        print("soxin-guard: no denylist supplied; checking inputs, secrets and hosts only", file=sys.stderr)

    allowed = PUBLIC_HOSTS | {h.lower() for h in args.allow_host}
    files = repository_files(root)
    report = Report()
    report.words = words.words
    check_inputs(root, files, allowed, report)
    check_secrets(root, files, report)
    check_hosts(files, args.examples_dir, report)
    if words:
        check_denylist(root, files, words, report)
        if args.history:
            check_history(root, args.history, words, report)

    if report.findings:
        report.print()
        print(f"soxin-guard: {len(report.findings)} finding(s) in {len(files)} file(s)", file=sys.stderr)
        return 1
    print(f"soxin-guard: {len(files)} file(s) clean", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
