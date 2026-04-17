# ast-grep Rule Reference

This is a compact reference for the ast-grep rule shapes used by the packaged skill.

## Rule categories

- Atomic rules match a node directly.
- Relational rules constrain where that node sits.
- Composite rules combine multiple rules.

## Common atomic rules

### `pattern`

Matches code by syntax shape.

```yaml
pattern: console.log($ARG)
```

### `kind`

Matches a concrete tree-sitter node kind.

```yaml
kind: call_expression
```

### `regex`

Matches the node text with a Rust regular expression.

```yaml
regex: ^[a-z_][a-z0-9_]*$
```

## Common relational rules

### `inside`

Require the target node to appear inside another matched node.

```yaml
inside:
  kind: function_declaration
  stopBy: end
```

### `has`

Require the target node to contain a matched descendant.

```yaml
has:
  pattern: await $EXPR
  stopBy: end
```

### `precedes` and `follows`

Use these when order matters.

```yaml
precedes:
  pattern: return $VALUE
```

## Common composite rules

### `all`

Every rule must match.

```yaml
all:
  - kind: function_declaration
  - has:
      pattern: await $EXPR
      stopBy: end
```

### `any`

Any one rule may match.

```yaml
any:
  - pattern: console.log($$$)
  - pattern: console.warn($$$)
  - pattern: console.error($$$)
```

### `not`

Exclude matches that satisfy a sub-rule.

```yaml
not:
  has:
    pattern: try { $$$ } catch ($ERR) { $$$ }
    stopBy: end
```

## Metavariables

- `$VAR`: one named node
- `$$VAR`: one unnamed token-like node
- `$$$VAR`: zero or more sibling nodes
- `$_VAR`: non-capturing metavariable

Examples:

```yaml
pattern: function $NAME($$$ARGS) { $$$BODY }
```

```yaml
pattern: $LEFT == $RIGHT
```

## Practical defaults

- start with `pattern` when possible
- move to YAML rules when you need context or exclusions
- use `stopBy: end` as the default for deep `inside` or `has` searches
- test the rule on a minimal sample before scanning the repository

## Troubleshooting

- If the rule does not match, dump the target AST and the pattern AST.
- If the wrong nodes match, tighten the rule with `kind`, `inside`, or `has`.
- If metavariables fail, make sure they are the only content in the AST node they are meant to capture.
