#!/bin/bash
# Real install smoke test: actually installs this plugin from the local
# working tree via the real `claude plugin` CLI and checks it loads.
#
# This exists because `claude plugin validate` -- the check `npm run
# validate:plugin` runs -- only checks manifest schema. It does NOT catch a
# plugin that is schema-valid but fails to actually load: this project
# shipped for weeks with `"hooks": "./hooks/hooks.json"` in plugin.json,
# which is schema-valid but causes a real "Duplicate hooks file detected"
# load failure, because Claude Code already auto-loads hooks/hooks.json by
# convention. `claude plugin validate` passed the whole time; only a real
# `claude plugin install` ever surfaced the failure. This script is that
# real install check, runnable locally (not in CI -- the Claude Code CLI
# isn't available there).
#
# Not idempotent-safe to run concurrently with other plugin work on this
# machine: it removes and re-adds a marketplace/plugin named "verify-first"
# in your real user-scope Claude Code config, then cleans up after itself.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_ID="verify-first@verify-first"

cleanup() {
  claude plugin remove "$PLUGIN_ID" >/dev/null 2>&1 || true
  claude plugin marketplace remove verify-first >/dev/null 2>&1 || true
}
trap cleanup EXIT

cleanup # start from a clean slate in case a previous run left state behind

claude plugin marketplace add "$REPO_ROOT" >/dev/null
claude plugin install "$PLUGIN_ID" -y >/dev/null

STATUS_JSON="$(claude plugin list --json 2>/dev/null)"
# `enabled` stays true even when a plugin has a real load failure -- the
# failure only shows up in a separate `errors` array. This was found by
# testing this very check against the reintroduced bug: the first version
# of this script checked only `enabled` and reported success on a plugin
# that `claude plugin list` (non-JSON) plainly showed as
# "✘ failed to load". So both fields have to be checked.
RESULT="$(printf '%s' "$STATUS_JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data:
    if p.get('id') == '$PLUGIN_ID':
        errors = p.get('errors') or []
        if p.get('enabled') and not errors:
            print('ok')
        else:
            print('FAILED: enabled=' + str(p.get('enabled')) + ' errors=' + json.dumps(errors))
        sys.exit(0)
print('FAILED: plugin not found in \'claude plugin list --json\' output')
")"

if [ "$RESULT" = "ok" ]; then
  echo "✔ $PLUGIN_ID installs and loads for real (not just schema-valid), with no load errors."
  exit 0
else
  echo "✘ $RESULT" >&2
  exit 1
fi
