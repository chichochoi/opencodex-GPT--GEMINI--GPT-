import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (relative) => fs.readFileSync(path.join(root, relative), "utf8");
const executableFiles = ["scripts/install.ps1", "scripts/install.sh", "scripts/configure.mjs"];

test("pins the exact orchestrator and worker models", () => {
  const content = executableFiles.map(read).join("\n");
  assert.match(content, /gpt-6-astra/);
  assert.match(content, /google-antigravity\/gemini-3\.8-flash/);
});

test("executable setup never configures a Gemini API-key provider", () => {
  const content = executableFiles.map(read).join("\n");
  assert.doesNotMatch(content, /ocx\s+(?:provider\s+add|login|account\s+add-key)\s+(?:google|google-vertex)(?:\s|$)/i);
  assert.doesNotMatch(content, /GEMINI_API_KEY|GOOGLE_API_KEY/);
});

test("requires GPT review and corrected re-delegation", () => {
  const policy = read("AGENTS.policy.md");
  assert.match(policy, /review every Gemini result/i);
  assert.match(policy, /smaller corrected task/i);
});

test("installers clear fallback and enable v2", () => {
  for (const file of ["scripts/install.ps1", "scripts/install.sh"]) {
    const content = read(file);
    assert.match(content, /ocx agent fallback clear/);
    assert.match(content, /ocx v2 on/);
    assert.match(content, /agentTaskRecovery/);
  }
});

test("repository contains no machine-specific home path", () => {
  const files = [
    "README.md",
    "AGENTS.policy.md",
    "scripts/install.ps1",
    "scripts/install.sh",
    "scripts/configure.mjs"
  ];
  const content = files.filter((file) => fs.existsSync(path.join(root, file))).map(read).join("\n");
  assert.doesNotMatch(content, /C:\\Users\\user/i);
});

test("configuration preserves existing content and is idempotent", () => {
  const temp = fs.mkdtempSync(path.join(os.tmpdir(), "ocx-harness-"));
  const config = path.join(temp, "config.toml");
  const agents = path.join(temp, "AGENTS.md");
  fs.writeFileSync(config, 'model = "old-model"\ncustom_root = true\n\n[features]\nweb_search = true\n');
  fs.writeFileSync(agents, "# Existing policy\n\nKeep this text.\n");

  const run = () => spawnSync(process.execPath, [path.join(root, "scripts/configure.mjs")], {
    env: { ...process.env, CODEX_HOME: temp },
    encoding: "utf8"
  });
  const first = run();
  assert.equal(first.status, 0, first.stderr);
  const second = run();
  assert.equal(second.status, 0, second.stderr);

  const configured = fs.readFileSync(config, "utf8");
  const policy = fs.readFileSync(agents, "utf8");
  assert.match(configured, /^model = "gpt-6-astra"/m);
  assert.match(configured, /^model_reasoning_effort = "low"/m);
  assert.match(configured, /^custom_root = true$/m);
  assert.match(configured, /^\[features\]$/m);
  assert.match(configured, /^web_search = true$/m);
  assert.match(policy, /Keep this text\./);
  assert.equal(policy.match(/BEGIN OPENCODEX GPT-GEMINI-GPT HARNESS/g)?.length, 1);
});
