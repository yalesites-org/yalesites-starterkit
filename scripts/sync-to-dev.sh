#!/usr/bin/env bash

# Import starterkit content changed in a git range onto the dev site.
# Usage: scripts/sync-to-dev.sh [--dry-run] [base-ref]   (base-ref default: HEAD^1)
# Env: SITE (default ys-starterkit.dev)

set -euo pipefail

dry_run=0
if [[ "${1:-}" == "--dry-run" ]]; then dry_run=1; shift; fi
base="${1:-HEAD^1}"
SITE="${SITE:-ys-starterkit.dev}"

cd "$(git rev-parse --show-toplevel)"

# read loops instead of mapfile: stock macOS has bash 3.2
ymls=()
while IFS= read -r l; do ymls+=("$l"); done < <(git diff --name-only --diff-filter=AM "$base..HEAD" -- 'starterkit/*.yml')
if [[ ${#ymls[@]} -eq 0 ]]; then
  echo "No starterkit yml files added or modified in $base..HEAD. Nothing to sync."
  exit 0
fi

deleted=()
while IFS= read -r l; do deleted+=("$l"); done < <(git diff --name-only --diff-filter=D "$base..HEAD" -- 'starterkit/*.yml')
if [[ ${#deleted[@]} -gt 0 ]]; then
  echo "WARNING: import cannot delete. Remove these on $SITE by hand:" >&2
  printf '  %s\n' "${deleted[@]}" >&2
fi

# Paths are relative to starterkit/ so the zip has ymls at the root.
files=()
for yml in "${ymls[@]}"; do
  files+=("${yml#starterkit/}")
  while read -r uri; do
    asset="assets/${uri#public://}"
    if [[ ! -f "starterkit/$asset" ]]; then
      echo "ERROR: $yml references missing asset starterkit/$asset" >&2
      exit 1
    fi
    files+=("$asset")
  done < <(grep -o 'public://[^'"'"'" ]*' "$yml" || true)
done
uniq_files=()
while IFS= read -r l; do uniq_files+=("$l"); done < <(printf '%s\n' "${files[@]}" | sort -u)
files=("${uniq_files[@]}")

if [[ $dry_run -eq 1 ]]; then
  printf '%s\n' "${files[@]}"
  echo "${#files[@]} files would be zipped for $SITE."
  exit 0
fi

command -v terminus >/dev/null || { echo "ERROR: terminus not found on PATH. Install it and run 'terminus auth:login'." >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
zipname="starterkit-sync-$(git rev-parse --short HEAD).zip"
(cd starterkit && zip -q "$tmp/$zipname" "${files[@]}")

SFTP=$(terminus connection:info "$SITE" --field=sftp_command)
eval "$SFTP:/files/ <<< 'put $tmp/$zipname'"

status=0
terminus drush "$SITE" -- content:import "../../files/$zipname" || status=$?
eval "$SFTP:/files/ <<< 'rm $zipname'" || true

echo "Done. Check /admin/content/media and /admin/content on $SITE."
exit "$status"
