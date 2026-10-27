#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -r "$tmp_dir"' EXIT
upstream_dir="$tmp_dir/upstream"
stage_dir="$tmp_dir/ponytail"

git clone --depth 1 --branch main https://github.com/DietrichGebert/ponytail.git "$upstream_dir"
commit="$(git -C "$upstream_dir" rev-parse HEAD)"
version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("version", "unknown"))' "$upstream_dir/.codex-plugin/plugin.json")"
mkdir -p "$stage_dir"
for path in skills hooks assets .codex-plugin .claude-plugin; do
  if [ -e "$upstream_dir/$path" ]; then cp -R "$upstream_dir/$path" "$stage_dir/"; fi
done
for path in README.md LICENSE; do
  [ -e "$upstream_dir/$path" ] && cp "$upstream_dir/$path" "$stage_dir/"
done
printf 'source_repo=https://github.com/DietrichGebert/ponytail\nsource_ref=main\nsource_commit=%s\nsource_version=%s\nsynced_at=%s\n' "$commit" "$version" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$stage_dir/UPSTREAM_VERSION"
# Temporary compatibility layer: only used when upstream lacks native Codex metadata.
# Remove this layer once upstream supports Codex; never modify upstream Skills or Hooks.
if [ ! -f "$stage_dir/.codex-plugin/plugin.json" ]; then
  mkdir -p "$stage_dir/.codex-plugin"
  cat > "$stage_dir/.codex-plugin/plugin.json" <<'JSON'
{"name":"ponytail","description":"Temporary Codex compatibility layer; remove when upstream provides native Codex support.","skills":"../skills/"}
JSON
fi
python3 - "$stage_dir" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[1])
for manifest in (root/'.codex-plugin/plugin.json', root/'.claude-plugin/plugin.json'):
    if manifest.exists(): json.loads(manifest.read_text())
if not (root/'skills').is_dir(): raise SystemExit('upstream skills directory missing')
if not (root/'.codex-plugin/plugin.json').is_file(): raise SystemExit('Codex manifest missing')
if not (root/'.claude-plugin/plugin.json').is_file(): raise SystemExit('Claude manifest missing')
PY
if [ -e "$repo_root/plugins/ponytail" ]; then rm -r "$repo_root/plugins/ponytail"; fi
mv "$stage_dir" "$repo_root/plugins/ponytail"
printf '%s\n' "Synchronized Ponytail $version ($commit)."
