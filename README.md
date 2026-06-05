# Binary Hype OMP Marketplace

OMP-specific marketplace for Binary Hype OMP plugins.

## Quick start
Install the marketplace once, then install the plugins you need:

```bash
omp marketplace add Binary-Hype/omp-marketplace
omp install coding-assistant@binary-hype-omp
```

## Included plugins

### coding-assistant

A lean OMP coding assistant focused on code quality, security, and correctness.

Plugin surfaces:

- Skills invoked as `/skill:<name>`:
  - `/skill:api-design`
  - `/skill:commit-message`
  - `/skill:database-reviewer`
  - `/skill:dependency-auditor`
  - `/skill:grill-me`
  - `/skill:humanizer`
  - `/skill:merge-conflict-resolver`
  - `/skill:promote-prs`
  - `/skill:quality-check`
  - `/skill:test-generator`
- Pre-tool-call safety extension: `hooks/pre/core-safety.ts`

The safety hook blocks access to configured secret files, prevents commits with staged credential-looking content, blocks unsafe `op` CLI commands, rejects `write` payloads larger than 800 lines, and requires approval for destructive `bash` commands such as `rm -rf`, `git clean -fdx`, `git reset --hard`, `find . -delete`, recursive `chmod`/`chown`, disk erase commands, and `curl | sh`.


## Safety configuration

The hook loads deny/allow patterns from:

- Global: `~/.omp/agent/security/denylist.json`
- Project: `.omp/security/denylist.json`

Each file may be either an array of deny patterns or an object with `deny` and `allow` arrays plus optional bash rule tuning:

```json
{
  "deny": ["*.secret", "production.env"],
  "allow": [".env.example"],
  "bash": {
    "disabledRuleIds": [],
    "approvalRuleIds": ["recursive-delete", "git-clean"],
    "blockedRuleIds": []
  }
}
```

Built-in destructive bash rules require approval by default. `disabledRuleIds` disables a built-in rule, `approvalRuleIds` limits approval checks to listed rule IDs, and `blockedRuleIds` escalates listed rules to hard blocks.

Runtime cache overrides use `OMP_SECURITY_CACHE_DIR`; when unset, the hook uses `/tmp/omp-security-${uid}`.

## Repository metadata

Public source: <https://github.com/Binary-Hype/omp-marketplace>
