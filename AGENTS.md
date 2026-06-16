# OMP Marketplace Development Guide

This repository is OMP-specific. Keep it free of non-OMP runtime files, non-OMP hook configuration, plugin-bundled agents, and compatibility fallbacks.

## Layout

- `.claude-plugin/marketplace.json` is the marketplace catalog path used by OMP. Its content must remain OMP-specific and point at top-level plugin directories.
- `coding-assistant/package.json` contains package metadata for the skills-only OMP plugin.
- `coding-assistant/plugin.json` is the OMP plugin manifest.
- `coding-assistant/skills/**` contains shared skills with OMP tool names and OMP skill invocation wording.
- `tests/**` contains marketplace-level Bats metadata tests that validate all cataloged plugins.

## Versioning

For a release, keep each plugin's versions identical across:

- `<plugin>/package.json`
- `<plugin>/plugin.json`
- `.claude-plugin/marketplace.json` plugin entry

Plugin versions are per-plugin; do not force unrelated plugins to share a version.


## Verification

From repository root, run:

```bash
bats tests
```


