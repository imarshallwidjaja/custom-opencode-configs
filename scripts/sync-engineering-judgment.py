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

SOURCE_PATH = 'packages/opencode-hive/src/agents/engineering-judgment.ts'
PACKAGE_PATH = 'packages/opencode-hive/package.json'
VENDOR_DIRECTORY = Path('vendor/oc-arkive/engineering-judgment')
PROMPT_PATTERN = re.compile(
    r'export const ENGINEERING_JUDGMENT_PROMPT = `([^`]*)`;\n?',
    re.DOTALL,
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


def extract_prompt(source: str) -> str:
    match = PROMPT_PATTERN.fullmatch(source)
    if not match:
        raise ValueError(
            'unsupported ENGINEERING_JUDGMENT_PROMPT source shape; expected one static exported template literal'
        )
    body = match.group(1)
    if '${' in body:
        raise ValueError('unsupported interpolation in ENGINEERING_JUDGMENT_PROMPT')
    if '\\' in body:
        raise ValueError('unsupported escape sequence in ENGINEERING_JUDGMENT_PROMPT')
    if not body.startswith('## Engineering Judgment\n'):
        raise ValueError('ENGINEERING_JUDGMENT_PROMPT is missing its expected heading')
    return body.rstrip('\n') + '\n'


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


def main() -> int:
    parser = argparse.ArgumentParser(
        description='Sync the provenance-pinned oc-arkive Engineering Judgment vendor.'
    )
    parser.add_argument('--source-repo', required=True, type=Path)
    parser.add_argument('--ref', required=True)
    args = parser.parse_args()

    try:
        commit = resolve_commit(args.source_repo, args.ref)
        source = decode_git_text(
            git_object(args.source_repo, f'{commit}:{SOURCE_PATH}'),
            SOURCE_PATH,
        )
        markdown = extract_prompt(source).encode('utf-8')
        version, upstream = load_package_metadata(
            git_object(args.source_repo, f'{commit}:{PACKAGE_PATH}')
        )
    except ValueError as error:
        print(f'Engineering Judgment sync failed: {error}', file=sys.stderr)
        return 1

    try:
        repository_root = Path(__file__).resolve().parent.parent
        output_directory = repository_root / VENDOR_DIRECTORY
        require_safe_path(repository_root, output_directory, directory=True)
        output_directory.mkdir(parents=True, exist_ok=True)
        require_safe_path(repository_root, output_directory, directory=True)
        markdown_path = output_directory / 'engineering-judgment.md'
        provenance_path = output_directory / 'provenance.json'
        require_safe_path(repository_root, markdown_path, directory=False)
        require_safe_path(repository_root, provenance_path, directory=False)
        provenance = {
            'schemaVersion': 1,
            'upstreamRepository': upstream,
            'commit': commit,
            'sourcePath': SOURCE_PATH,
            'packageVersion': version,
            'sha256': hashlib.sha256(markdown).hexdigest(),
        }
        provenance_bytes = (json.dumps(provenance, indent=2) + '\n').encode('utf-8')
        atomic_write(repository_root, output_directory, markdown_path, markdown)
        atomic_write(repository_root, output_directory, provenance_path, provenance_bytes)
    except (OSError, ValueError) as error:
        print(f'Engineering Judgment sync failed: {error}', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
