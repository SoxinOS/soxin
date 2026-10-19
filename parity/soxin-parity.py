# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
"""soxin-parity: compare the derivations of hosts built two ways.

For every host it evaluates the derivation of an output attribute in a
baseline flake and in a target flake, runs nix-diff on the pair, and breaks
the result down into differences: an environment variable, an input, a
source, the builder, the arguments or the platform of one derivation. A
difference that only follows from a changed store path below it is not
counted, so each difference listed is a cause, not a consequence.

Differences the fleet has accepted are listed in a TOML file given with
--accepted (it belongs to the fleet, not to Soxin):

    [[difference]]
    hosts = ["example-server"]   # optional; every host when left out
    derivation = "etc"           # name of the derivation, without hash; glob
    what = "env"                 # env, input, source, builder, arguments,
                                 # platform or structure; optional
    key = "NIX_PATH"             # env variable, input or source name; glob,
                                 # optional
    changed = "^nix-path ="      # optional regular expression every changed
                                 # line (store hashes masked) must match
    reordered = true             # optional: only lines that moved, none
                                 # added or removed
    reason = "why it is accepted"

It prints a summary per host and exits 1 when any host has a difference that
is not accepted, 0 otherwise, and 2 on usage or evaluation errors.
"""

import argparse
import difflib
import fnmatch
import json
import os
import re
import subprocess
import sys
import tomllib

STORE_HASH = re.compile(r"/nix/store/[0-9a-z]{32}-")
OUTPUT_TYPES = ["nixosConfigurations", "darwinConfigurations", "homeConfigurations"]
OUTPUT_ATTRS = {
    "nixosConfigurations": "config.system.build.toplevel",
    "darwinConfigurations": "config.system.build.toplevel",
    "homeConfigurations": "activationPackage",
}


def mask(text):
    """Replace store hashes, which change whenever anything below changes."""
    return STORE_HASH.sub("/nix/store/<hash>-", text)


def drv_name(path):
    name = os.path.basename(path)
    name = re.sub(r"^[0-9a-z]{32}-", "", name)
    return name.removesuffix(".drv")


def readable(text):
    """JSON (structured attributes, generated JSON files) one value per line,
    so a line diff shows which value changed."""
    stripped = text.strip()
    if not stripped.startswith(("{", "[")):
        return text
    try:
        value = json.loads(stripped)
    except ValueError:
        return text
    return json.dumps(value, indent=1, sort_keys=True)


class Difference:
    def __init__(self, chain, what, key, old, new):
        self.chain = chain
        self.what = what
        self.key = key
        self.old = readable(old)
        self.new = readable(new)
        self.accepted_by = None

    @property
    def derivation(self):
        return self.chain[-1] if self.chain else ""

    def changed(self):
        """Lines only in the old text and lines only in the new one, compared
        with store hashes masked, so a line that only points at a rebuilt
        store path does not count."""
        old = self.old.splitlines()
        new = self.new.splitlines()
        old_masked = {mask(line) for line in old}
        new_masked = {mask(line) for line in new}
        removed = [line for line in old if mask(line) not in new_masked]
        added = [line for line in new if mask(line) not in old_masked]
        return removed, added

    def changed_lines(self):
        removed, added = self.changed()
        return removed + added

    def describe(self, width, limit=40):
        where = " > ".join(self.chain)
        head = f"{self.derivation}: {self.what}" + (f" {self.key}" if self.key else "")
        lines = [head, f"      in {where}"]
        removed, added = self.changed()
        if removed or added:
            body = [f"- {line}" for line in removed] + [f"+ {line}" for line in added]
        else:
            # Same lines in another order: show where they moved.
            old = [mask(line) for line in self.old.splitlines()]
            new = [mask(line) for line in self.new.splitlines()]
            body = ["(same lines, another order)"] + [
                line
                for line in difflib.unified_diff(old, new, lineterm="", n=1)
                if not line.startswith(("---", "+++"))
            ]
        if len(body) > limit:
            body = body[:limit] + [f"... {len(body) - limit} more line(s)"]
        lines += [f"      {line[:width]}" for line in body]
        return lines


def text_sides(segments):
    """Old and new text of a nix-diff text diff (a list of segments)."""
    old, new = [], []
    for segment in segments or []:
        kind, content = segment.get("type"), segment.get("content", "")
        if kind in ("Both", "Old"):
            old.append(content)
        if kind in ("Both", "New"):
            new.append(content)
    return "".join(old), "".join(new)


def changed_set(changed):
    """`before` and `now` of a nix-diff Changed value, as sorted strings."""
    if not changed:
        return "", ""
    before = changed.get("before", [])
    now = changed.get("now", [])
    if isinstance(before, dict):
        before = [f"{k}={v}" for k, v in sorted(before.items())]
        now = [f"{k}={v}" for k, v in sorted(now.items())]
    return "\n".join(map(str, before)), "\n".join(map(str, now))


def differences(diff, chain):
    """The causes in a nix-diff JSON derivation diff."""
    found = []
    tag = diff.get("tag")
    if tag in ("DerivationsAreTheSame", "AlreadyCompared", "OnlyAlreadyComparedBelow"):
        return found
    if tag in ("NamesDontMatch", "OutputsDontMatch"):
        before, now = changed_set(diff.get("outputStructure"))
        found.append(Difference(chain, "structure", tag, before, now))
        return found

    for field, what in (("platformDiff", "platform"), ("builderDiff", "builder")):
        value = diff.get(field)
        if value:
            before, now = changed_set(value) if isinstance(value, dict) else ("", json.dumps(value))
            found.append(Difference(chain, what, "", before, now))

    arguments = diff.get("argumentsDiff")
    if arguments:
        old, new = text_sides(arguments) if isinstance(arguments, list) else changed_set(arguments)
        if mask(old) != mask(new):
            found.append(Difference(chain, "arguments", "", old, new))

    sources = diff.get("sourcesDiff") or {}
    if sources.get("extraSrcNames"):
        before, now = changed_set(sources["extraSrcNames"])
        found.append(Difference(chain, "source", "", before, now))
    for source in sources.get("srcFilesDiff") or []:
        name = source.get("srcName", "")
        if "srcContentDiff" in source:
            old, new = text_sides(source["srcContentDiff"])
        else:
            old, new = changed_set(source.get("srcFileDiff"))
        if mask(old) != mask(new):
            found.append(Difference(chain, "source", name, old, new))

    inputs = diff.get("inputsDiff") or {}
    if inputs.get("inputExtraNames"):
        before, now = changed_set(inputs["inputExtraNames"])
        found.append(Difference(chain, "input", "", before, now))
    for entry in inputs.get("inputDerivationDiffs") or []:
        entry_tag = entry.get("tag")
        name = entry.get("drvName", "")
        if entry_tag == "OneDerivationDiff":
            found += differences(entry["drvDiff"], chain + [name])
        elif entry_tag == "SomeDerivationsDiff":
            before, now = changed_set(entry.get("extraPartsDiff"))
            found.append(Difference(chain, "input", name, before, now))

    env = diff.get("envDiff") or {}
    if env.get("tag") == "EnvironmentDiff":
        extra = env.get("extraEnvDiff")
        if extra and (extra.get("before") or extra.get("now")):
            for key in sorted(set(extra.get("before", {})) | set(extra.get("now", {}))):
                found.append(
                    Difference(chain, "env", key, str(extra.get("before", {}).get(key, "")), str(extra.get("now", {}).get(key, "")))
                )
        for entry in env.get("envContentDiff") or []:
            old, new = text_sides(entry.get("envValueDiff"))
            if mask(old) != mask(new):
                found.append(Difference(chain, "env", entry.get("envKey", ""), old, new))
    return found


def load_accepted(path):
    if not path:
        return []
    with open(path, "rb") as f:
        data = tomllib.load(f)
    entries = data.get("difference", [])
    for number, entry in enumerate(entries, 1):
        if "derivation" not in entry or "reason" not in entry:
            raise SystemExit(f"soxin-parity: {path}: difference #{number} needs a derivation and a reason")
        entry["_number"] = number
        if "changed" in entry:
            entry["_changed"] = re.compile(entry["changed"])
    return entries


def accepts(entry, host, difference):
    if "hosts" in entry and host not in entry["hosts"]:
        return False
    if not fnmatch.fnmatchcase(difference.derivation, entry["derivation"]):
        return False
    if "what" in entry and entry["what"] != difference.what:
        return False
    if "key" in entry and not fnmatch.fnmatchcase(difference.key, entry["key"]):
        return False
    if entry.get("reordered"):
        old = sorted(mask(line) for line in difference.old.splitlines())
        new = sorted(mask(line) for line in difference.new.splitlines())
        if old != new:
            return False
    if "_changed" in entry:
        lines = [mask(line) for line in difference.changed_lines()]
        if not lines or not all(entry["_changed"].search(line) for line in lines):
            return False
    return True


def nix(args, nix_args):
    # Flags such as --override-input belong after the subcommand.
    result = subprocess.run(["nix", args[0], *nix_args, *args[1:]], capture_output=True, text=True)
    if result.returncode != 0:
        sys.stderr.write(result.stderr)
        raise SystemExit(f"soxin-parity: nix {' '.join(args)} failed")
    return result.stdout


class Side:
    def __init__(self, name, ref, overrides, drvs):
        self.name = name
        self.ref = ref
        self.args = ["--log-format", "raw", "--quiet"]
        for input_name, input_ref in overrides:
            self.args += ["--override-input", input_name, input_ref]
        self.drvs = drvs
        self.names = {}

    def output_names(self, output):
        if output not in self.names:
            text = nix(["eval", "--json", f"{self.ref}#{output}", "--apply", "builtins.attrNames"], self.args) if self.ref else "[]"
            self.names[output] = json.loads(text)
        return self.names[output]

    def attribute(self, host):
        for output in OUTPUT_TYPES:
            if host in self.output_names(output):
                return f"{output}.{host}.{OUTPUT_ATTRS[output]}"
        raise SystemExit(f"soxin-parity: {self.name}: {self.ref} has no host {host} in {', '.join(OUTPUT_TYPES)}")

    def drv(self, host, attribute):
        if host in self.drvs:
            path = self.drvs[host]
            if not path.endswith(".drv"):
                path = subprocess.run(["nix-store", "-q", "--deriver", os.path.realpath(path)], check=True, capture_output=True, text=True).stdout.strip()
            return path
        if not self.ref:
            raise SystemExit(f"soxin-parity: no {self.name} flake and no {self.name} derivation for {host}")
        attribute = attribute or self.attribute(host)
        return nix(["eval", "--raw", f"{self.ref}#{attribute}.drvPath"], self.args).strip()


def parse_pairs(values, option):
    pairs = {}
    for value in values:
        name, sep, rest = value.partition("=")
        if not sep or not name or not rest:
            raise SystemExit(f"soxin-parity: {option} expects NAME=VALUE, got {value!r}")
        pairs[name] = rest
    return pairs


def main(argv=None):
    parser = argparse.ArgumentParser(prog="soxin-parity", description=__doc__.split("\n\n")[0])
    parser.add_argument("--baseline", metavar="FLAKE", help="the flake the hosts are compared against")
    parser.add_argument("--target", metavar="FLAKE", help="the flake whose hosts are checked")
    parser.add_argument("--hosts", action="append", default=[], metavar="A,B", help="hosts to compare, separated by commas")
    parser.add_argument(
        "--host",
        action="append",
        default=[],
        metavar="NAME[=ATTR]",
        help="a host, optionally with the output attribute to compare (default: its toplevel or activation package)",
    )
    parser.add_argument("--baseline-override-input", nargs=2, action="append", default=[], metavar=("INPUT", "FLAKE"))
    parser.add_argument("--target-override-input", nargs=2, action="append", default=[], metavar=("INPUT", "FLAKE"))
    parser.add_argument(
        "--baseline-drv",
        action="append",
        default=[],
        metavar="NAME=PATH",
        help="take a host's baseline from a derivation or a built store path (e.g. /run/current-system) instead of a flake",
    )
    parser.add_argument("--target-drv", action="append", default=[], metavar="NAME=PATH")
    parser.add_argument("--accepted", metavar="FILE", help="the fleet's accepted differences (TOML)")
    parser.add_argument("--width", type=int, default=160, help="cut changed lines at this width (default: 160)")
    parser.add_argument("--nix-diff", default="nix-diff", help=argparse.SUPPRESS)
    args = parser.parse_args(argv)

    hosts = {}
    for value in args.hosts:
        for name in filter(None, (h.strip() for h in value.split(","))):
            hosts.setdefault(name, None)
    for value in args.host:
        name, _, attribute = value.partition("=")
        hosts[name] = attribute or None
    if not hosts:
        parser.error("no hosts given (--hosts or --host)")

    accepted = load_accepted(args.accepted)
    baseline = Side("baseline", args.baseline, args.baseline_override_input, parse_pairs(args.baseline_drv, "--baseline-drv"))
    target = Side("target", args.target, args.target_override_input, parse_pairs(args.target_drv, "--target-drv"))

    failed = []
    used = set()
    for host, attribute in hosts.items():
        before = baseline.drv(host, attribute)
        after = target.drv(host, attribute)
        print(f"== {host}")
        print(f"   baseline {before}")
        print(f"   target   {after}")
        if before == after:
            print(f"   {host}: identical")
            continue
        result = subprocess.run([args.nix_diff, "--json", "--environment", before, after], capture_output=True, text=True)
        if result.returncode not in (0, 1) or not result.stdout.strip():
            sys.stderr.write(result.stderr)
            raise SystemExit(f"soxin-parity: nix-diff failed for {host}")
        found = differences(json.loads(result.stdout), [drv_name(after)])
        for difference in found:
            for entry in accepted:
                if accepts(entry, host, difference):
                    difference.accepted_by = entry
                    used.add(entry["_number"])
                    break
        open_ = [d for d in found if d.accepted_by is None]
        taken = [d for d in found if d.accepted_by is not None]
        for difference in taken:
            entry = difference.accepted_by
            print(f"   accepted (#{entry['_number']}: {entry['reason']}): {difference.derivation}: {difference.what} {difference.key}".rstrip())
        for difference in open_:
            lines = difference.describe(args.width)
            print(f"   DIFFERS: {lines[0]}")
            for line in lines[1:]:
                print(f"   {line}")
        if not found:
            print(f"   DIFFERS: the derivations differ but no cause was found; run nix-diff {before} {after}")
            failed.append(host)
        elif open_:
            failed.append(host)
            print(f"   {host}: {len(open_)} difference(s), {len(taken)} accepted")
        else:
            print(f"   {host}: only accepted differences ({len(taken)})")

    unused = [e for e in accepted if e["_number"] not in used]
    for entry in unused:
        print(f"note: accepted difference #{entry['_number']} ({entry['derivation']}) matched nothing")

    print()
    if failed:
        print(f"soxin-parity: {len(failed)} of {len(hosts)} host(s) differ: {', '.join(failed)}")
        return 1
    print(f"soxin-parity: {len(hosts)} host(s) at parity")
    return 0


if __name__ == "__main__":
    sys.exit(main())
