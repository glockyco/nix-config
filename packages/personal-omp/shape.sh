#!/usr/bin/env bash
set -euo pipefail

test -x "$OMP_WRAPPER"
test -x "$OMP_UPDATER"
test -x "$OMP_VERIFIER"

jq -e '.omp.extensions | index("./extensions/personal-commit.ts") != null' "$OMP_PLUGIN/package.json"
test "$(jq -r '.servers | keys | sort | join(",")' "$OMP_PLUGIN/lsp/lsp.json")" = markdown-oxide,marksman,roslyn-language-server,svelte
test "$(jq -r '.servers.marksman.disabled' "$OMP_PLUGIN/lsp/lsp.json")" = true

test -f "$OMP_PLUGIN/commands/opsx-propose.md"
test ! -e "$OMP_PLUGIN/lsp/commands"

command -v Microsoft.CodeAnalysis.LanguageServer
command -v markdown-oxide
command -v pyright-langserver
command -v typescript-language-server
command -v svelteserver
command -v nixd
! command -v marksman
command -v texlab
touch "$out"
