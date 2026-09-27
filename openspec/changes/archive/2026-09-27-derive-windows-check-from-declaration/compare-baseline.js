import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

const [baseline, candidate, manifest = resolve(import.meta.dir, "baseline.md")] = process.argv.slice(2);
if (!baseline || !candidate) {
  console.error("usage: bun compare-baseline.js BASELINE CANDIDATE [BASELINE_MD]");
  process.exit(1);
}

const hashes = Object.fromEntries(
  [...readFileSync(manifest, "utf8").matchAll(/^\| (\S+)\s+\| ([0-9a-f]{64}) \|$/gm)].map(
    ([, file, hash]) => [file, hash],
  ),
);
const names = Object.keys(hashes).sort();
assert.equal(names.length, 19, "the manifest must list all 19 output files");
const files = (directory) => readdirSync(directory).sort();
const file = (directory, name) => readFileSync(resolve(directory, name));
const text = (directory, name) => file(directory, name).toString("utf8");
const sha256 = (bytes) => createHash("sha256").update(bytes).digest("hex");
assert.deepEqual(files(baseline), names, "baseline file set");
assert.deepEqual(files(candidate), names, "candidate file set: no new or missing files");
for (const name of names) {
  assert.equal(sha256(file(baseline, name)), hashes[name], `baseline hash: ${name}`);
}
const changed = names.filter((name) => !file(baseline, name).equals(file(candidate, name)));
if (resolve(baseline) === resolve(candidate)) {
  assert.deepEqual(changed, []);
  console.log("baseline self-comparison: 19 identical files; zero differences");
  process.exit(0);
}
assert.deepEqual(changed, ["configuration.winget", "zen-catppuccin.json"]);
for (const name of names.filter((name) => !changed.includes(name))) {
  assert.equal(sha256(file(candidate, name)), hashes[name], `unchanged file: ${name}`);
}

const oldTheme = JSON.parse(text(baseline, "zen-catppuccin.json"));
for (const asset of Object.values(oldTheme.files)) {
  assert.ok(asset.sri, "baseline theme asset must have SRI");
  delete asset.sri;
}
assert.deepEqual(JSON.parse(text(candidate, "zen-catppuccin.json")), oldTheme);
const oldDoc = Bun.YAML.parse(text(baseline, "configuration.winget"));
const newDoc = Bun.YAML.parse(text(candidate, "configuration.winget"));
const oldResources = new Map(oldDoc.resources.map((resource) => [resource.name, resource]));
const newResources = new Map(newDoc.resources.map((resource) => [resource.name, resource]));
const oldZen = oldResources.get("zen catppuccin theme");
const newZen = newResources.get("zen catppuccin theme");
for (const key of ["testScript", "setScript"]) {
  const original = oldZen.properties[key];
  const expected = original.replace(/,"sri":"sha256-[A-Za-z0-9+/=]+"/g, "");
  assert.notEqual(expected, original, `Zen ${key} changes`);
  assert.equal(newZen.properties[key], expected, `Zen ${key}: only SRI removal`);
  oldZen.properties[key] = expected;
}
const oldFork = oldResources.get("fork wslgit");
const newFork = newResources.get("fork wslgit");
const zedMerge = oldResources.get("zed settings").properties.setScript.split("\n\n")[0];
assert.ok(zedMerge.startsWith("function Merge-Object(") && zedMerge.endsWith("\n}"));
const branch = [
  "  $gitPath = Join-Path $root 'bin\\git.exe'",
  "  if ($null -eq $settings.PSObject.Properties['GitInstancePath']) {",
  "    $settings | Add-Member -NotePropertyName GitInstancePath -NotePropertyValue $gitPath",
  "  } else {",
  "    $settings.GitInstancePath = $gitPath",
  "  }",
].join("\n");
const mergeCall = "  Merge-Object $settings ([PSCustomObject]@{ GitInstancePath = (Join-Path $root 'bin\\git.exe') })";
const originalFork = oldFork.properties.setScript;
assert.ok(originalFork.includes(branch), "baseline Fork branch");
const expectedFork = `${zedMerge}\n\n${originalFork.replace(branch, mergeCall)}`;
assert.equal(newFork.properties.setScript, expectedFork, "Fork: only shared merge and call");
oldFork.properties.setScript = expectedFork;
assert.deepEqual(newDoc, oldDoc, "all other parsed YAML data remains equal");
console.log("19 files: 17 byte-identical; Zen SRI removal and Fork merge only; no YAML semantic drift");
