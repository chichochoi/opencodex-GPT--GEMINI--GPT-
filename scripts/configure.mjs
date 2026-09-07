import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(scriptDir, "..");
const codexHome = process.env.CODEX_HOME || path.join(os.homedir(), ".codex");
const configPath = path.join(codexHome, "config.toml");
const agentsPath = path.join(codexHome, "AGENTS.md");
const policyPath = path.join(repoRoot, "AGENTS.policy.md");
const begin = "<!-- BEGIN OPENCODEX GPT-GEMINI-GPT HARNESS -->";
const end = "<!-- END OPENCODEX GPT-GEMINI-GPT HARNESS -->";

fs.mkdirSync(codexHome, { recursive: true });

function backup(file) {
  if (!fs.existsSync(file)) return;
  const stamp = new Date().toISOString().replaceAll(":", "-");
  fs.copyFileSync(file, `${file}.harness-${stamp}.bak`);
}

function setRootTomlValue(source, key, value) {
  const lines = source.replaceAll("\r\n", "\n").split("\n");
  const firstSection = lines.findIndex((line) => /^\s*\[/.test(line));
  const limit = firstSection === -1 ? lines.length : firstSection;
  const matcher = new RegExp(`^\\s*${key}\\s*=`);
  const existing = lines.slice(0, limit).findIndex((line) => matcher.test(line));
  if (existing >= 0) lines[existing] = `${key} = ${JSON.stringify(value)}`;
  else lines.splice(limit, 0, `${key} = ${JSON.stringify(value)}`);
  return lines.join(os.EOL).replace(/(?:\r?\n)*$/, os.EOL);
}

if (!fs.existsSync(configPath)) {
  throw new Error(`${configPath} does not exist. Run 'ocx init' first.`);
}

backup(configPath);
let config = fs.readFileSync(configPath, "utf8");
config = setRootTomlValue(config, "model", "gpt-6-astra");
config = setRootTomlValue(config, "model_reasoning_effort", "low");
fs.writeFileSync(configPath, config, "utf8");

const policy = fs.readFileSync(policyPath, "utf8").trim();
let agents = fs.existsSync(agentsPath) ? fs.readFileSync(agentsPath, "utf8") : "";
backup(agentsPath);
const start = agents.indexOf(begin);
const finish = agents.indexOf(end);
if (start >= 0 && finish >= start) {
  agents = `${agents.slice(0, start)}${policy}${agents.slice(finish + end.length)}`;
} else {
  agents = `${agents.trimEnd()}${agents.trim() ? `${os.EOL}${os.EOL}` : ""}${policy}${os.EOL}`;
}
fs.writeFileSync(agentsPath, agents, "utf8");

console.log(`Configured ${configPath}`);
console.log(`Installed policy block in ${agentsPath}`);
