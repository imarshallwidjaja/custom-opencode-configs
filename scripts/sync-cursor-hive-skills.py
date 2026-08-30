#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

PACKAGE_PATH = 'packages/opencode-hive/package.json'
SKILLS_ROOT = Path('.apm/cursor/skills')
VENDOR_DIRECTORY = Path('vendor/oc-arkive/cursor-skills')
VENDORED_SKILLS = (
    'brainstorming',
    'systematic-debugging',
    'test-driven-development',
    'verification',
)
WRITING_PLANS_CALL = 'skill({ name: "writing-plans" })'
SKILL_CALL_PATTERN = re.compile(r'skill\(\{\s*name:\s*"([^"]+)"\s*\}\)')
COMPANION_FILE_REWRITES = (
    (
        'See `root-cause-tracing.md` in this directory for the complete backward tracing technique.',
        'Do not stop at the first contract, parsing, type, null, or schema error. Treat it as a possible downstream symptom. Find the first unintended side effect or hidden write. Identify the canonical source of truth and competing sources. Audit hidden writers: lifecycle hooks, observers, restore, retries, and background work. Fix at the first unintended write, not only the final error.',
    ),
    (
        'These techniques are part of systematic debugging and available in this directory:\n'
        '\n'
        '- **`root-cause-tracing.md`** - Trace bugs backward through call stack to find original trigger\n'
        '- **`defense-in-depth.md`** - Add validation at multiple layers after finding root cause\n'
        '- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling',
        'These techniques are part of systematic debugging:\n'
        '\n'
        '- **Defense in depth** - Add validation at multiple layers after finding the root cause\n'
        '- **Condition-based waiting** - Replace arbitrary timeouts with condition polling',
    ),
)
COMPANION_RESIDUE = (
    'available in this directory',
    'in this directory',
    'root-cause-tracing.md',
    'defense-in-depth.md',
    'condition-based-waiting.md',
    'root-cause-finder',
)


def git_environment():
    environment = {
        name: value for name, value in os.environ.items() if not name.startswith('GIT_')
    }
    environment['GIT_NO_REPLACE_OBJECTS'] = '1'
    return environment


def git_object(repository: Path, object_name: str) -> bytes:
    result = subprocess.run(
        ['git', '-C', str(repository), 'show', object_name],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=git_environment(),
        check=False,
    )
    if result.returncode != 0:
        message = result.stderr.decode('utf-8', errors='replace').strip()
        raise ValueError(f'cannot read Git object {object_name}: {message}')
    return result.stdout


def resolve_commit(repository: Path, ref: str) -> str:
    result = subprocess.run(
        ['git', '-C', str(repository), 'rev-parse', '--verify', f'{ref}^{{commit}}'],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        env=git_environment(),
        check=False,
    )
    if result.returncode != 0:
        message = result.stderr.strip()
        raise ValueError(f'cannot resolve ref {ref!r} to a commit: {message}')
    commit = result.stdout.strip()
    if not re.fullmatch(r'[0-9a-f]{40}', commit):
        raise ValueError(f'Git returned a non-immutable commit ID: {commit!r}')
    return commit


def decode_git_text(content: bytes, label: str) -> str:
    try:
        return content.decode('utf-8').replace('\r\n', '\n').replace('\r', '\n')
    except UnicodeDecodeError as error:
        raise ValueError(f'{label} is not valid UTF-8: {error}') from error


def normalize_skill_text(content: bytes, label: str) -> str:
    text = decode_git_text(content, label)
    if not text.endswith('\n'):
        text += '\n'
    return text


def transform_skill(text: str) -> str:
    text = text.replace('\\`', '`')
    text = text.replace(WRITING_PLANS_CALL, 'the planning-prompt or implementation-brief command')
    text = SKILL_CALL_PATTERN.sub(lambda match: f'the {match.group(1)} skill', text)
    for old, new in COMPANION_FILE_REWRITES:
        text = text.replace(old, new)
    return text


def load_package_metadata(content: bytes):
    text = decode_git_text(content, PACKAGE_PATH)
    try:
        package = json.loads(text)
    except json.JSONDecodeError as error:
        raise ValueError(f'{PACKAGE_PATH} is not valid JSON: {error}') from error
    version = package.get('version')
    repository = package.get('repository')
    upstream = repository.get('url') if isinstance(repository, dict) else repository
    if not isinstance(version, str) or not version:
        raise ValueError(f'{PACKAGE_PATH} has no string version')
    if not isinstance(upstream, str) or not upstream:
        raise ValueError(f'{PACKAGE_PATH} has no repository URL')
    return version, upstream


def require_safe_path(repository_root: Path, path: Path, *, directory: bool) -> None:
    try:
        relative = path.relative_to(repository_root)
    except ValueError as error:
        raise ValueError(f'unsafe output path outside repository root: {path}') from error

    current = repository_root
    components = [repository_root]
    for part in relative.parts:
        current = current / part
        components.append(current)

    for index, component in enumerate(components):
        if component.is_symlink():
            raise ValueError(f'unsafe output path contains symlink: {component}')
        if not component.exists():
            continue
        is_leaf = index == len(components) - 1
        if not is_leaf or directory:
            if not component.is_dir():
                raise ValueError(f'unsafe output path component is not a directory: {component}')
        elif not component.is_file():
            raise ValueError(f'unsafe output destination is not a regular file: {component}')

    resolved_root = repository_root.resolve(strict=True)
    resolved_path = path.resolve(strict=False)
    try:
        resolved_path.relative_to(resolved_root)
    except ValueError as error:
        raise ValueError(f'unsafe output path resolves outside repository root: {path}') from error


def atomic_write(repository_root: Path, output_directory: Path, path: Path, content: bytes) -> None:
    require_safe_path(repository_root, output_directory, directory=True)
    require_safe_path(repository_root, path, directory=False)
    try:
        path.resolve(strict=False).relative_to(output_directory.resolve(strict=True))
    except ValueError as error:
        raise ValueError(f'unsafe output path outside vendor directory: {path}') from error
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode='wb',
            dir=output_directory,
            prefix=f'.{path.name}.',
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            temporary.write(content)
        require_safe_path(repository_root, output_directory, directory=True)
        require_safe_path(repository_root, path, directory=False)
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def source_path_for(name: str) -> str:
    return f'packages/opencode-hive/skills/{name}/SKILL.md'


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Sync provenance-pinned Agent Hive skills into the Cursor shared set.'
    )
    parser.add_argument('--source-repo', required=True, type=Path)
    parser.add_argument('--ref', required=True)
    args = parser.parse_args()

    try:
        commit = resolve_commit(args.source_repo, args.ref)
        version, upstream = load_package_metadata(
            git_object(args.source_repo, f'{commit}:{PACKAGE_PATH}')
        )
        installed = {}
        skills_provenance = {}
        for name in VENDORED_SKILLS:
            source_path = source_path_for(name)
            normalized = normalize_skill_text(
                git_object(args.source_repo, f'{commit}:{source_path}'),
                source_path,
            )
            transformed = transform_skill(normalized)
            if 'skill(' in transformed or 'writing-plans' in transformed:
                raise ValueError(
                    f'{name} still contains OpenCode skill-call residue after the Cursor-runtime rewrite'
                )
            leftover = [marker for marker in COMPANION_RESIDUE if marker in transformed]
            if leftover:
                raise ValueError(
                    f'{name} still names missing companion files or directory-local techniques: {leftover}'
                )
            installed_bytes = transformed.encode('utf-8')
            installed[name] = installed_bytes
            skills_provenance[name] = {
                'sourcePath': source_path,
                'sourceSha256': hashlib.sha256(normalized.encode('utf-8')).hexdigest(),
                'installedSha256': hashlib.sha256(installed_bytes).hexdigest(),
            }
    except ValueError as error:
        print(f'Cursor Hive skills sync failed: {error}', file=sys.stderr)
        return 1

    try:
        repository_root = Path(__file__).resolve().parent.parent
        for name, content in installed.items():
            skill_directory = repository_root / SKILLS_ROOT / name
            require_safe_path(repository_root, skill_directory, directory=True)
            skill_directory.mkdir(parents=True, exist_ok=True)
            require_safe_path(repository_root, skill_directory, directory=True)
            skill_path = skill_directory / 'SKILL.md'
            require_safe_path(repository_root, skill_path, directory=False)
            atomic_write(repository_root, skill_directory, skill_path, content)

        output_directory = repository_root / VENDOR_DIRECTORY
        require_safe_path(repository_root, output_directory, directory=True)
        output_directory.mkdir(parents=True, exist_ok=True)
        require_safe_path(repository_root, output_directory, directory=True)
        provenance_path = output_directory / 'provenance.json'
        require_safe_path(repository_root, provenance_path, directory=False)
        provenance = {
            'schemaVersion': 1,
            'upstreamRepository': upstream,
            'commit': commit,
            'packageVersion': version,
            'skills': skills_provenance,
        }
        provenance_bytes = (json.dumps(provenance, indent=2) + '\n').encode('utf-8')
        atomic_write(repository_root, output_directory, provenance_path, provenance_bytes)
    except (OSError, ValueError) as error:
        print(f'Cursor Hive skills sync failed: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
