# JavaScript Patterns For `context-mode`

Use JavaScript when the task involves JSON, APIs, structured aggregation, or moderate parsing logic.

## Good fits

- summarize an API response
- compare JSON config files
- inspect `package.json` or lockfiles
- reduce large test output into failures only

## Pattern: summarize JSON

```javascript
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));

console.log(`Target: ${data.compilerOptions?.target}`);
console.log(`Module: ${data.compilerOptions?.module}`);
console.log(`Strict: ${data.compilerOptions?.strict}`);
console.log(`Path aliases: ${Object.keys(data.compilerOptions?.paths || {}).length}`);
```

## Pattern: compare two configs

```javascript
const fs = require('fs');
const left = JSON.parse(fs.readFileSync('config.default.json', 'utf8'));
const right = JSON.parse(fs.readFileSync('config.local.json', 'utf8'));

function diff(a, b, prefix = '') {
  const keys = new Set([...Object.keys(a || {}), ...Object.keys(b || {})]);
  for (const key of [...keys].sort()) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (!(key in (a || {}))) console.log(`+ ${path}: ${JSON.stringify(b[key])}`);
    else if (!(key in (b || {}))) console.log(`- ${path}: ${JSON.stringify(a[key])}`);
    else if (typeof a[key] === 'object' && typeof b[key] === 'object' && a[key] && b[key]) diff(a[key], b[key], path);
    else if (JSON.stringify(a[key]) !== JSON.stringify(b[key])) console.log(`~ ${path}: ${JSON.stringify(a[key])} -> ${JSON.stringify(b[key])}`);
  }
}

diff(left, right);
```

## Pattern: extract failing tests from JSON output

```javascript
const { execSync } = require('child_process');

let output = '';
try {
  output = execSync('npx jest --json 2>/dev/null', { encoding: 'utf8', maxBuffer: 50 * 1024 * 1024 });
} catch (error) {
  output = error.stdout || '';
}

const results = JSON.parse(output);
console.log(`Passed: ${results.numPassedTests}`);
console.log(`Failed: ${results.numFailedTests}`);

for (const suite of results.testResults || []) {
  for (const assertion of suite.assertionResults || []) {
    if (assertion.status === 'failed') {
      console.log(`${suite.name} :: ${assertion.fullName}`);
    }
  }
}
```

## Rules of thumb

- prefer JavaScript for JSON-heavy work
- serialize objects instead of printing `[object Object]`
- use `try/catch` around file reads or subprocess parsing when failure is possible
- print findings, not raw blobs
