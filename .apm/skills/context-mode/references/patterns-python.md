# Python Patterns For `context-mode`

Use Python when the task is easier with the standard library's text, CSV, JSON, or diff tooling.

## Good fits

- CSV or log analysis
- text extraction
- filesystem scans with lightweight grouping
- comparing source files or config files

## Pattern: analyze CSV data

```python
import csv
from collections import defaultdict

with open('data/transactions.csv') as f:
    rows = list(csv.DictReader(f))

print(f"Rows: {len(rows)}")

totals = defaultdict(float)
for row in rows:
    totals[row['category']] += float(row.get('amount', 0) or 0)

for category, total in sorted(totals.items(), key=lambda item: -item[1]):
    print(f"{category}: {total:.2f}")
```

## Pattern: summarize logs

```python
import re
from collections import Counter

levels = Counter()
pattern = re.compile(r'\b(DEBUG|INFO|WARN|ERROR|FATAL)\b')

with open('app.log') as f:
    for line in f:
        match = pattern.search(line)
        if match:
            levels[match.group(1)] += 1

for level, count in levels.most_common():
    print(f"{level}: {count}")
```

## Pattern: compare files

```python
import difflib

with open('old.txt') as f:
    old_lines = f.readlines()
with open('new.txt') as f:
    new_lines = f.readlines()

for line in difflib.unified_diff(old_lines, new_lines, fromfile='old.txt', tofile='new.txt', lineterm=''):
    print(line)
```

## Pattern: find duplicate files

```python
import hashlib
import os
from collections import defaultdict

hashes = defaultdict(list)

for root, dirs, files in os.walk('src'):
    dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'node_modules']
    for name in files:
        path = os.path.join(root, name)
        with open(path, 'rb') as f:
            hashes[hashlib.md5(f.read()).hexdigest()].append(path)

for digest, paths in hashes.items():
    if len(paths) > 1:
        print(digest)
        for path in paths:
            print(f"  {path}")
```

## Rules of thumb

- stay in the standard library
- print counts and grouped findings, not raw dumps
- skip hidden and generated directories when walking trees
- use Python when the shell version would be hard to read
