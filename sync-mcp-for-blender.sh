#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

git clone --depth 1 https://github.com/ahujasid/mcp-for-blender.git "$tmp_dir/upstream"
rm -rf "$repo_root/plugins/mcp-for-blender"
cp -R "$tmp_dir/upstream/integrations/codex/plugins/mcp-for-blender" "$repo_root/plugins/"
cp "$tmp_dir/upstream/integrations/codex/.agents/plugins/marketplace.json" "$repo_root/.agents/plugins/marketplace.json"
printf '%s\n' "Synchronized mcp-for-blender from upstream."
