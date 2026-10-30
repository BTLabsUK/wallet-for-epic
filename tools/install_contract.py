# SPDX-License-Identifier: Apache-2.0
"""The install contract (tools/install-contract.json, docs/install-contract.md).

Each frozen item names something an existing install depends on (a folder, a file, a store key,
an app id, an update address) and probes: exact text that must still be in a file of the repo.
A change to the code that drops a probe's text fails here, naming the item.

The items are sealed: the newest entry of "changes" records the sha256 of the items. Editing an
item (to follow a code change) without adding a change record fails too, and a change record
needs the migration, its test and who approved it. So nothing an install depends on changes
without someone writing down how existing installs get there.

Usage: python3 -I tools/install_contract.py [--hash]   (from the repository root)
  --hash   print the sha256 of the items as they are now, for a new change record
"""
import hashlib
import json
import os
import sys

CONTRACT = "tools/install-contract.json"
DOC = "docs/install-contract.md"
CHANGE_FIELDS = ("date", "items_sha256", "change", "migration", "migration_test", "approved_by")


def items_sha256(items):
    canon = json.dumps(items, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(canon.encode("utf-8")).hexdigest()


def main(argv):
    root = os.getcwd()
    with open(os.path.join(root, CONTRACT), encoding="utf-8") as f:
        contract = json.load(f)
    items = contract.get("items")
    if not isinstance(items, list) or not items:
        print(f"{CONTRACT}: no items", file=sys.stderr)
        return 1
    sealed = items_sha256(items)
    if argv[1:] == ["--hash"]:
        print(sealed)
        return 0

    errors = []
    seen = set()
    for it in items:
        iid = it.get("id", "?")
        if iid in seen:
            errors.append(f"item {iid}: listed twice")
        seen.add(iid)
        for field in ("id", "platforms", "what", "value", "probes"):
            if not it.get(field):
                errors.append(f"item {iid}: no {field}")
        for p in it.get("probes") or []:
            path = os.path.join(root, p.get("file", ""))
            try:
                with open(path, encoding="utf-8") as f:
                    text = f.read()
            except OSError:
                errors.append(f"item {iid} ({it.get('value')}): {p.get('file')} is gone")
                continue
            if p.get("contains", "") not in text:
                errors.append(
                    f"item {iid} ({it.get('value')}): {p['file']} no longer contains\n"
                    f"      {p['contains']}"
                )

    changes = contract.get("changes") or []
    for i, c in enumerate(changes):
        for field in CHANGE_FIELDS:
            if not str(c.get(field, "")).strip():
                errors.append(f"changes[{i}]: no {field}")
        test = c.get("migration_test", "")
        if test and not os.path.isfile(os.path.join(root, test)):
            errors.append(f"changes[{i}]: migration_test {test} does not exist")
    if not changes or changes[-1].get("items_sha256") != sealed:
        errors.append(
            "the items changed without a change record: add one at the end of \"changes\" with\n"
            f"      items_sha256 \"{sealed}\", the change, the migration that moves existing\n"
            "      installs (copy, check, then switch), its test (migration_test) and approved_by"
        )

    if errors:
        print("install contract broken: an existing install depends on this.", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(
            f"Put the code back, or change it the proper way ({DOC}): a tested migration for\n"
            f"existing installs, the owner's explicit yes, and the item plus a change record in {CONTRACT}\n"
            "in the same commit.",
            file=sys.stderr,
        )
        return 1
    probes = sum(len(it["probes"]) for it in items)
    print(f"install contract kept: {len(items)} items, {probes} probes")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
