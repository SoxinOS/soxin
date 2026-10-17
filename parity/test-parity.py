# SPDX-FileCopyrightText: 2026 Wael Nasreddine
# SPDX-License-Identifier: MIT
"""Tests of soxin-parity's reading of nix-diff output and of accepted
differences, on a made-up nix-diff JSON document."""

import importlib.util
import os
import sys
import tempfile

spec = importlib.util.spec_from_file_location("parity", sys.argv[1])
parity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parity)

H1 = "/nix/store/" + "a" * 32
H2 = "/nix/store/" + "b" * 32


def text(old, new, both=""):
    segments = [{"type": "Both", "content": both}] if both else []
    if old:
        segments.append({"type": "Old", "content": old})
    if new:
        segments.append({"type": "New", "content": new})
    return segments


def drv(env=None, inputs=None):
    return {
        "tag": "DerivationDiff",
        "argumentsDiff": None,
        "builderDiff": None,
        "platformDiff": None,
        "sourcesDiff": {"extraSrcNames": None, "srcFilesDiff": []},
        "outputsDiff": {"extraOutputs": None, "outputHashDiff": []},
        "envDiff": {"tag": "EnvironmentDiff", "extraEnvDiff": {"before": {}, "now": {}}, "envContentDiff": env or []},
        "inputsDiff": {"inputExtraNames": None, "inputDerivationDiffs": inputs or []},
    }


# A toplevel whose `etc` input differs in nix.conf, and whose own env only
# differs by the store hash of that input (a consequence, not a cause).
document = drv(
    env=[{"envKey": "etc", "envValueDiff": text(f"{H1}-etc", f"{H2}-etc")}],
    inputs=[
        {
            "tag": "OneDerivationDiff",
            "drvName": "etc",
            "drvDiff": drv(
                env=[
                    {"envKey": "nixPath", "envValueDiff": text("nixpkgs=/old", "nixpkgs=/new")},
                    {"envKey": "zshrc", "envValueDiff": text("alias a=b\n", "", both="# head\n")},
                ]
            ),
        }
    ],
)

found = parity.differences(document, ["toplevel"])
summary = sorted((d.derivation, d.what, d.key) for d in found)
assert summary == [("etc", "env", "nixPath"), ("etc", "env", "zshrc")], summary
assert found[0].chain == ["toplevel", "etc"], found[0].chain

with tempfile.TemporaryDirectory() as work:
    path = os.path.join(work, "accepted.toml")
    with open(path, "w") as f:
        f.write(
            """
[[difference]]
derivation = "etc"
key = "nixPath"
changed = "^nixpkgs="
reason = "NIX_PATH points elsewhere"

[[difference]]
hosts = ["other"]
derivation = "etc"
key = "zshrc"
reason = "only on another host"
"""
        )
    accepted = parity.load_accepted(path)

by_key = {d.key: d for d in found}
assert parity.accepts(accepted[0], "host", by_key["nixPath"])
assert not parity.accepts(accepted[0], "host", by_key["zshrc"])
assert not parity.accepts(accepted[1], "host", by_key["zshrc"])
assert parity.accepts(accepted[1], "other", by_key["zshrc"])

# A changed line that only points at a rebuilt store path is not a change.
d = parity.Difference(["x"], "env", "k", f"a {H1}-foo\nb\n", f"a {H2}-foo\nc\n")
assert d.changed() == (["b"], ["c"]), d.changed()

print("soxin-parity: tests passed")
