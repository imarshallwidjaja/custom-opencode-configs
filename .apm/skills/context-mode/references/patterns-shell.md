# Shell Patterns For `context-mode`

Use shell inside `context-mode` when native CLI tools already do most of the work and you only need bounded output.

## Good fits

- build and test filtering
- quick git summaries
- disk usage and directory overviews
- piping command output through a small number of filters

## Pattern: capture build failures only

```shell
npm run build 2>&1 | tee /tmp/build-output.txt
EXIT_CODE=${PIPESTATUS[0]}

echo "Exit code: $EXIT_CODE"
grep -iE '(error|failed|FAIL)' /tmp/build-output.txt || true
rm -f /tmp/build-output.txt
```

## Pattern: summarize pytest failures

```shell
python -m pytest --tb=short -q 2>&1 | tee /tmp/pytest-output.txt
EXIT_CODE=${PIPESTATUS[0]}

echo "Exit code: $EXIT_CODE"
grep -E '(FAILED|ERROR)' /tmp/pytest-output.txt || true
rm -f /tmp/pytest-output.txt
```

## Pattern: inspect project size

```shell
du -sh */ 2>/dev/null | sort -rh
```

## Pattern: summarize recent git activity

```shell
echo "Recent commits: $(git log --since='30 days ago' --oneline | wc -l | xargs)"
echo "Top authors:"
git shortlog -sn --since='30 days ago' | head -10
```

## Rules of thumb

- keep shell scripts short and legible
- if the logic turns into nested parsing, switch to JavaScript or Python
- clean up temp files inside the script
- print the exact counters or failure lines you need the model to reason about
