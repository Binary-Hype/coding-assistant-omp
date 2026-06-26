# OMP coding-assistant Plugin Development Guide

This repository is OMP-specific. Keep it free of non-OMP runtime files, non-OMP hook configuration, plugin-bundled agents, and compatibility fallbacks.

## Layout

- `package.json` contains package metadata for the standalone skills-only OMP plugin.
- `plugin.json` is the OMP plugin manifest.
- `skills/**` contains shared skills with OMP tool names and OMP skill invocation wording.
- `tests/**` contains standalone plugin-root Bats metadata tests.

## Versioning

For a release, keep versions identical between root `package.json` and root `plugin.json`.


## Verification

From repository root, run:

```bash
bats tests
```


