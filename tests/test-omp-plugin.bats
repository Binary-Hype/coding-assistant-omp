#!/usr/bin/env bats

load helpers

setup() {
  setup_base
}

teardown() {
  teardown_base
}

@test "repository root is the standalone coding-assistant plugin" {
  run node -e '
    const fs = require("fs");
    const path = require("path");
    const root = process.argv[1];

    if (fs.existsSync(path.join(root, ".claude-plugin/marketplace.json"))) throw new Error("marketplace catalog must not exist");
    if (fs.existsSync(path.join(root, "coding-assistant"))) throw new Error("coding-assistant wrapper directory must not exist");
    if (!fs.existsSync(path.join(root, "plugin.json"))) throw new Error("missing root plugin.json");
    if (!fs.existsSync(path.join(root, "package.json"))) throw new Error("missing root package.json");

    const manifest = JSON.parse(fs.readFileSync(path.join(root, "plugin.json"), "utf8"));
    const pkg = JSON.parse(fs.readFileSync(path.join(root, "package.json"), "utf8"));
    if (manifest.name !== "coding-assistant") throw new Error(`unexpected plugin name: ${manifest.name}`);
    if (pkg.name !== "coding-assistant") throw new Error(`unexpected package name: ${pkg.name}`);
    if (pkg.omp?.name !== "coding-assistant") throw new Error(`unexpected omp name: ${pkg.omp?.name}`);
  ' "$REPO_ROOT"

  [ "$status" -eq 0 ]
}

@test "standalone package and plugin manifests agree" {
  run node -e '
    const fs = require("fs");
    const path = require("path");
    const root = process.argv[1];
    const repository = "https://github.com/Binary-Hype/omp-marketplace";
    const pkg = JSON.parse(fs.readFileSync(path.join(root, "package.json"), "utf8"));
    const manifest = JSON.parse(fs.readFileSync(path.join(root, "plugin.json"), "utf8"));

    if (pkg.version !== "1.2.1") throw new Error(`unexpected package version: ${pkg.version}`);
    if (manifest.version !== "1.2.1") throw new Error(`unexpected plugin version: ${manifest.version}`);
    if (pkg.version !== manifest.version) throw new Error("package and plugin versions differ");
    if (typeof pkg.description !== "string" || pkg.description.length === 0) throw new Error("missing package description");
    if (typeof manifest.description !== "string" || manifest.description.length === 0) throw new Error("missing plugin description");
    if (pkg.omp?.description !== pkg.description) throw new Error("omp.description must equal package description");
    if (pkg.license !== "GPL-3.0") throw new Error(`unexpected package license: ${pkg.license}`);
    if (manifest.license !== "GPL-3.0") throw new Error(`unexpected plugin license: ${manifest.license}`);
    if (pkg.homepage !== repository || pkg.repository !== repository) throw new Error("unexpected package repository/homepage");
    if (manifest.homepage !== repository || manifest.repository !== repository) throw new Error("unexpected plugin repository/homepage");
    if (!Array.isArray(pkg.keywords) || pkg.keywords.length === 0) throw new Error("missing package keywords");
    if (!Array.isArray(manifest.keywords) || manifest.keywords.length === 0) throw new Error("missing plugin keywords");
    if (pkg.private === true) throw new Error("package must not be private");
    if (pkg.omp?.extensions !== undefined) throw new Error("omp.extensions must be absent");

    const expectedFiles = ["LICENSE", "README.md", "plugin.json", "skills"];
    const actualFiles = [...(pkg.files || [])].sort();
    if (JSON.stringify(actualFiles) !== JSON.stringify(expectedFiles)) throw new Error(`unexpected package files: ${actualFiles.join(", ")}`);
  ' "$REPO_ROOT"

  [ "$status" -eq 0 ]
}

@test "plugin exposes only standalone skills surface" {
  run node -e '
    const fs = require("fs");
    const path = require("path");
    const root = process.argv[1];
    const expectedSkills = [
      "api-design",
      "commit-message",
      "database-reviewer",
      "dependency-auditor",
      "grill-me",
      "humanizer",
      "merge-conflict-resolver",
      "promote-prs",
      "quality-check",
      "test-generator",
    ];

    const skillsRoot = path.join(root, "skills");
    if (!fs.existsSync(skillsRoot)) throw new Error("missing root skills directory");
    const actualSkills = fs.readdirSync(skillsRoot)
      .filter((entryName) => fs.statSync(path.join(skillsRoot, entryName)).isDirectory())
      .sort();
    if (JSON.stringify(actualSkills) !== JSON.stringify(expectedSkills)) throw new Error(`unexpected skills ${actualSkills.join(", ")}`);

    for (const skill of expectedSkills) {
      const skillFile = path.join(skillsRoot, skill, "SKILL.md");
      if (!fs.existsSync(skillFile)) throw new Error(`missing ${skill}/SKILL.md`);
    }

    for (const absentSurface of ["commands", "hooks", "tools", "themes", "mcp.json"]) {
      if (fs.existsSync(path.join(root, absentSurface))) throw new Error(`unused plugin surface exists: ${absentSurface}`);
    }
  ' "$REPO_ROOT"

  [ "$status" -eq 0 ]
}

@test "README advertises standalone plugin install" {
  run node -e '
    const fs = require("fs");
    const path = require("path");
    const root = process.argv[1];
    const readme = fs.readFileSync(path.join(root, "README.md"), "utf8");

    for (const required of [
      "Standalone OMP plugin for Binary Hype coding-assistant skills.",
      "omp install github:Binary-Hype/omp-marketplace",
      "omp install coding-assistant",
      "omp install ./path/to/omp-marketplace",
      "Skills are invoked with singular `/skill:<name>` syntax:",
    ]) {
      if (!readme.includes(required)) throw new Error(`README missing required text: ${required}`);
    }

    for (const forbidden of [
      "omp marketplace add",
      "coding-assistant@binary-hype-omp",
      "name@marketplace",
      "binary-hype-omp",
      "Marketplace-loaded",
      ".claude-plugin",
      "claude-plugins",
      "core-safety",
      "safety hook",
      "Safety configuration",
      "denylist",
      "OMP_SECURITY_CACHE_DIR",
      "hooks/pre",
    ]) {
      if (readme.includes(forbidden)) throw new Error(`README contains forbidden text: ${forbidden}`);
    }
  ' "$REPO_ROOT"

  [ "$status" -eq 0 ]
}

@test "skill docs use OMP skill invocation syntax" {
  run node -e '
    const fs = require("fs");
    const path = require("path");
    const root = process.argv[1];
    const expectedSkills = [
      "api-design",
      "commit-message",
      "database-reviewer",
      "dependency-auditor",
      "grill-me",
      "humanizer",
      "merge-conflict-resolver",
      "promote-prs",
      "quality-check",
      "test-generator",
    ];
    const skillsRoot = path.join(root, "skills");
    const markdownFiles = [];

    function walk(dir) {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          walk(full);
        } else if (entry.name.endsWith(".md")) {
          markdownFiles.push(full);
        }
      }
    }

    walk(skillsRoot);

    const legacyInvocation = new RegExp(`/(${expectedSkills.join("|")})(?=$|[^A-Za-z0-9_-])`);
    const forbiddenTerms = ["claude-plugins", "binary-hype-omp", "omp-marketplace", "model=\"sonnet\"", "model=\"haiku\""];
    for (const file of markdownFiles) {
      const text = fs.readFileSync(file, "utf8");
      const relative = path.relative(root, file);
      if (text.includes("/skills:")) throw new Error(`${relative} contains /skills:`);
      if (legacyInvocation.test(text)) throw new Error(`${relative} contains legacy direct invocation`);
      for (const forbidden of forbiddenTerms) {
        if (text.includes(forbidden)) throw new Error(`${relative} contains forbidden term: ${forbidden}`);
      }
    }

    const commitSkill = fs.readFileSync(path.join(skillsRoot, "commit-message/SKILL.md"), "utf8");
    const contract = "When `/skill:commit-message` injects this skill body, treat the injection itself as a direct user request: create a commit message for the repository'\''s already-staged changes.";
    if (!commitSkill.includes(contract)) throw new Error("commit-message invocation contract missing");
  ' "$REPO_ROOT"

  [ "$status" -eq 0 ]
}
