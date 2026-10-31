#!/usr/bin/env python3
"""Install the profile's pinned TUI plugin entry into an OpenCode tui.json.

Usage: merge-tui-plugin.py plan|apply <source-tui.json> <target-config-dir>

The source is a regular file holding exactly one exact name@version plugin pin.
Only entries for that package are managed: an existing entry for the same
package, or the known local Magic Compact checkout entry, is replaced in place
(tuple options are kept) and later duplicates are dropped. Every other key and
plugin entry is preserved. The merge edits the plugin array OpenCode reads: a
top-level "plugin" wins over one nested under "tui", and a nested array is
used only when the top level has none. A target that is not a strict JSON
object with a valid plugin array is refused before anything is written.
`plan` never writes.
"""

import json
import math
import os
import posixpath
import re
import stat
import sys
import tempfile
from urllib.parse import unquote, urlparse

TARGET_NAME = "tui.json"
# OpenCode also accepts tui.jsonc; this helper does not parse JSONC.
JSONC_NAME = "tui.jsonc"
# Observed local-checkout entry that the published package replaces.
LEGACY_LOCAL_SUFFIX = "/magic-compact/packages/opencode-plugin/src/tui.ts"
EXACT_PIN = re.compile(
    r"(?P<name>(?:@[a-z0-9][a-z0-9._~-]*/)?[a-z0-9][a-z0-9._~-]*)"
    r"@(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)"
    r"(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?"
)
WINDOWS_DRIVE = re.compile(r"[A-Za-z]:[\\/]")
ACTION_VERBS = {
    "create": ("create", "Created"),
    "update": ("update", "Updated"),
    "unchanged": ("leave unchanged", "Left unchanged"),
}


class Refusal(Exception):
    pass


def reject_constant(name):
    raise ValueError(f"{name} is not a JSON number")


def finite_float(text):
    value = float(text)
    if not math.isfinite(value):
        raise ValueError(f"{text} is outside the finite number range")
    return value


def same_options(left, right):
    """Compare JSON options by value, keeping booleans distinct from numbers."""
    if type(left) is not type(right):
        return type(left) in (int, float) and type(right) in (int, float) and left == right
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(same_options(left[key], right[key]) for key in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(same_options(a, b) for a, b in zip(left, right))
    return left == right


def npm_package_name(spec):
    """Return the npm package name of a registry spec, or None for paths and URLs."""
    if not spec or ":" in spec or spec.startswith(("/", ".", "~")):
        return None
    version_at = spec.find("@", 1) if spec.startswith("@") else spec.find("@")
    return spec if version_at < 0 else spec[:version_at]


def local_path(spec, base_dir):
    """Return a normalized slash-separated path for a path-like spec, or None.

    Like OpenCode, file URLs, absolute paths, and Windows drive paths are taken
    as they are, and "."-relative paths resolve against the declaring config's
    directory. Backslashes are read as separators.
    """
    if spec.startswith("file://"):
        path = unquote(urlparse(spec).path)
    elif spec.startswith(("/", "\\")) or WINDOWS_DRIVE.match(spec):
        path = spec
    elif spec.startswith("."):
        path = posixpath.join(base_dir, spec.replace("\\", "/"))
    else:
        return None
    return posixpath.normpath(path.replace("\\", "/"))


def read_json_file(path, missing_ok):
    """Return (raw, data) for a regular strict-JSON file, or (None, None) when missing_ok."""
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        if missing_ok:
            return None, None
        raise Refusal(f"{path} does not exist")
    except OSError as exc:
        raise Refusal(f"cannot inspect {path}: {exc}")
    if stat.S_ISLNK(info.st_mode) or not stat.S_ISREG(info.st_mode):
        raise Refusal(f"{path} is a symlink or not a regular file; resolve it manually")
    try:
        with open(path, encoding="utf-8") as handle:
            raw = handle.read()
    except (OSError, UnicodeDecodeError) as exc:
        raise Refusal(f"cannot read {path}: {exc}")
    try:
        data = json.loads(raw, parse_constant=reject_constant, parse_float=finite_float)
    except ValueError as exc:
        raise Refusal(
            f"{path} is not strict JSON ({exc}); comments, trailing commas, NaN, and Infinity are not supported"
        )
    return raw, data


def load_source(path):
    try:
        raw, data = read_json_file(path, missing_ok=False)
    except Refusal as exc:
        raise Refusal(f"source {exc}") from None
    plugins = data.get("plugin") if isinstance(data, dict) else None
    if not isinstance(plugins, list) or len(plugins) != 1 or not isinstance(plugins[0], str):
        raise Refusal(f"source {path} must hold exactly one string plugin entry")
    spec = plugins[0]
    pin = EXACT_PIN.fullmatch(spec)
    if not pin:
        raise Refusal(f"source {path} plugin entry must be an exact name@version pin, got {spec!r}")
    return raw, spec, pin["name"]


def entry_spec(entry, index, path):
    if isinstance(entry, str) and entry:
        return entry
    if (
        isinstance(entry, list)
        and len(entry) == 2
        and isinstance(entry[0], str)
        and entry[0]
        and isinstance(entry[1], dict)
    ):
        return entry[0]
    raise Refusal(f"{path} plugin[{index}] is not a plugin name or a [name, options] pair")


def is_managed(spec, name, base_dir):
    if npm_package_name(spec) == name:
        return True
    resolved = local_path(spec, base_dir)
    return resolved is not None and resolved.endswith(LEGACY_LOCAL_SUFFIX)


def read_target(path):
    """Return the parsed target object, or None when it does not exist."""
    raw, data = read_json_file(path, missing_ok=True)
    if raw is None:
        return None
    if not isinstance(data, dict):
        raise Refusal(f"{path} must contain a JSON object")
    return data


def plugin_holder(data, path):
    """Return the object whose "plugin" array OpenCode uses, and that array.

    OpenCode reads an object-valued "tui" key as {...tui, ...outer}.
    """
    nested = data.get("tui")
    if "plugin" not in data and isinstance(nested, dict) and "plugin" in nested:
        holder, label = nested, "tui.plugin"
    else:
        holder, label = data, "plugin"
    plugins = holder.get("plugin", [])
    if not isinstance(plugins, list):
        raise Refusal(f"{path} {label} must be an array")
    return holder, plugins


def merge_plugins(plugins, spec, name, path):
    """Put one managed entry where the first managed entry was, keeping its options."""
    base_dir = os.path.dirname(path)
    managed = [
        index for index, entry in enumerate(plugins) if is_managed(entry_spec(entry, index, path), name, base_dir)
    ]
    options = None
    for index in managed:
        entry = plugins[index]
        if isinstance(entry, list):
            if options is None:
                options = entry[1]
            elif not same_options(options, entry[1]):
                raise Refusal(f"{path} has {name} entries with different options; keep one and rerun")
    replacement = [spec, options] if options is not None else spec
    merged = []
    for index, entry in enumerate(plugins):
        if index not in managed:
            merged.append(entry)
        elif index == managed[0]:
            merged.append(replacement)
    if not managed:
        merged.append(replacement)
    replaced = [entry_spec(plugins[index], index, path) for index in managed]
    return merged, replaced


def plan(source_path, target_dir):
    source_raw, spec, name = load_source(source_path)
    target = os.path.join(target_dir, TARGET_NAME)
    jsonc = os.path.join(target_dir, JSONC_NAME)
    if os.path.lexists(jsonc):
        raise Refusal(f"{jsonc} exists; merge {spec} into it manually or remove it before installing")
    data = read_target(target)
    if data is None:
        return target, "create", source_raw, f"with {spec}"
    holder, plugins = plugin_holder(data, target)
    merged, replaced = merge_plugins(plugins, spec, name, target)
    if merged == plugins:
        return target, "unchanged", None, f"({spec} is already installed)"
    holder["plugin"] = merged
    content = json.dumps(data, indent=2, ensure_ascii=False, allow_nan=False) + "\n"
    if replaced:
        detail = "replacing " + ", ".join(repr(item) for item in replaced) + f" with {spec}"
    else:
        detail = f"adding {spec}"
    return target, "update", content, detail


def write_atomically(target, content):
    try:
        mode = stat.S_IMODE(os.stat(target).st_mode)
    except FileNotFoundError:
        mode = 0o644
    directory = os.path.dirname(target)
    handle, temp_path = tempfile.mkstemp(prefix=".tui.json.", dir=directory)
    try:
        with os.fdopen(handle, "w", encoding="utf-8") as stream:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp_path, mode)
        os.replace(temp_path, target)
    except BaseException:
        if os.path.lexists(temp_path):
            os.unlink(temp_path)
        raise


def main(argv):
    if len(argv) != 4 or argv[1] not in ("plan", "apply"):
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    mode, source_path, target_dir = argv[1], argv[2], argv[3]
    try:
        target, action, content, detail = plan(source_path, target_dir)
        planned, done = ACTION_VERBS[action]
        if mode == "plan":
            print(f"Would {planned} {target} {detail}")
            return 0
        if action != "unchanged":
            write_atomically(target, content)
        print(f"{done} {target} {detail}")
    except Refusal as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    except OSError as exc:
        print(f"ERROR: cannot write {os.path.join(target_dir, TARGET_NAME)}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
