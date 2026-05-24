#!/usr/bin/env bash
# update-proof-receipts.sh
# Queries GitHub API for recent PRs/commits across StevenOS repos and updates
# the "Today's proof receipts" and "Builder Velocity" sections in README.md.
#
# Requirements: gh (authenticated), bash 3.2+
# Usage: bash scripts/update-proof-receipts.sh

OWNER="stevenchouai"
README="README.md"
REPOS="agent-scorecard personalWebsite digital-twin knowledge-harness"

# Detect repo base path: CI clones to repos/, local uses ~/Projects/
if [ -d "repos" ]; then
  REPO_BASE="repos"
else
  REPO_BASE="${HOME:-/root}/Projects"
fi

TODAY=$(date +%Y-%m-%d)
WEEK_AGO=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d "7 days ago" +%Y-%m-%d 2>/dev/null || echo "1970-01-01")

echo "Running update-proof-receipts.sh: TODAY=$TODAY WEEK_AGO=$WEEK_AGO REPO_BASE=$REPO_BASE"

TOTAL_PRS=0
TOTAL_MERGED=0
TOTAL_OPEN=0
TOTAL_COMMITS=0
ALL_MERGED=""

for repo in $REPOS; do
  echo "Processing $repo..."

  # Filter to last 7 days and count
  counts=$(python3 -c "
import json, sys, urllib.request
from datetime import datetime, timedelta
repo = sys.argv[1]
owner = sys.argv[2]
cutoff = datetime.utcnow() - timedelta(days=7)
merged = 0
open_count = 0
merged_lines = []
try:
    req = urllib.request.Request(
        f'https://api.github.com/repos/{owner}/{repo}/pulls?state=all&per_page=20',
        headers={'User-Agent': 'Mozilla/5.0'}
    )
    with urllib.request.urlopen(req) as response:
        prs = json.loads(response.read().decode())
except Exception as e:
    prs = []
for p in prs:
    created = p.get('created_at', '')
    if created:
        try:
            dt = datetime.fromisoformat(created.replace('Z', '+00:00')).replace(tzinfo=None)
            if dt >= cutoff:
                if p.get('merged_at'):
                    merged += 1
                    merged_lines.append(f\"{p['number']}|{p['created_at']}|{p['title']}|{p['html_url']}\")
                elif p['state'].lower() == 'open':
                    open_count += 1
        except: pass
print(f'{merged}|{open_count}')
for line in merged_lines:
    print(line)
" "$repo" "$OWNER" 2>/dev/null) || counts="0|0"

  # Parse counts from first line
  merged_count=$(echo "$counts" | head -1 | cut -d'|' -f1)
  open_count=$(echo "$counts" | head -1 | cut -d'|' -f2)
  TOTAL_MERGED=$((TOTAL_MERGED + merged_count))
  TOTAL_OPEN=$((TOTAL_OPEN + open_count))
  TOTAL_PRS=$((TOTAL_PRS + merged_count + open_count))

  # Collect merged PR lines (skip the count line), prepend repo name
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ALL_MERGED="${ALL_MERGED}${repo}|${line}"$'\n'
  done < <(echo "$counts" | tail -n +2)

  # Count commits in this repo (last 7 days)
  count=$(git -C "$REPO_BASE/$repo" log --oneline --since="$WEEK_AGO" 2>/dev/null | wc -l | tr -d ' ')
  TOTAL_COMMITS=$((TOTAL_COMMITS + count))

  echo "  $repo: $merged_count merged, $open_count open, $count commits"
done

ACTIVE_REPOS=$(echo "$REPOS" | wc -w | tr -d ' ')

# Pick top 5 most recent merged PRs across all repos
RECEIPTS=$(echo "$ALL_MERGED" | { grep -v '^$' || true; } | sort -t'|' -k3 -r | head -5 | while IFS='|' read -r repo num created title url; do
  [[ -z "$num" ]] && continue
  echo "| [$repo#$num]($url) | $title | Shipped |"
done)

echo "Receipts collected:"
echo "$RECEIPTS"

# Build velocity section
VELOCITY="| Metric | Count |
|---|---|
| PRs this week | $TOTAL_PRS |
| Merged | $TOTAL_MERGED |
| Open (pending review) | $TOTAL_OPEN |
| Commits (7d) | $TOTAL_COMMITS |
| Active repos | $ACTIVE_REPOS |

*Last auto-update: $TODAY*
"

# Replace sections in README using Python (write script to temp file to avoid stdin conflict)
TMPSCRIPT=$(mktemp /tmp/update-receipts-XXXXXX.py)
cat > "$TMPSCRIPT" << 'PYEOF'
import re, sys, os

readme_path = os.environ["README_PATH"]
today = os.environ.get("TODAY", "")
receipts = os.environ.get("RECEIPTS", "")
velocity = os.environ.get("VELOCITY", "")

with open(readme_path) as f:
    readme = f.read()

# Replace 'Today's proof receipts' section content
receipts_pattern = r"(## Today.s proof receipts\n\n).*?(\n<details>|\n## )"
receipts_repl = (
    r"\1"
    "On " + today + " the autonomous builder loop checked recent PRs across StevenOS repos.\n\n"
    "| Artifact | Shipped proof | Status |\n"
    "|---|---|---|\n"
    + receipts
    + "\n"
    + r"\2"
)
if re.search(receipts_pattern, readme, re.DOTALL):
    readme = re.sub(receipts_pattern, receipts_repl, readme, count=1, flags=re.DOTALL)
    print("Updated proof receipts section")
else:
    print("WARNING: Could not find Today's proof receipts section", file=sys.stderr)

# Replace velocity section
velocity_pattern = r"(## Builder Velocity\n\n\| Metric.*?\n)(\n##|\Z)"
velocity_repl = "## Builder Velocity\n\n" + velocity + r"\2"
if re.search(velocity_pattern, readme, re.DOTALL):
    readme = re.sub(velocity_pattern, velocity_repl, readme, flags=re.DOTALL)
    print("Updated velocity section")
else:
    print("WARNING: Could not find Builder Velocity section", file=sys.stderr)

with open(readme_path, 'w') as f:
    f.write(readme)

print("README updated successfully")
PYEOF

export TODAY RECEIPTS VELOCITY README_PATH="$README"
python3 "$TMPSCRIPT"
rm -f "$TMPSCRIPT"

echo "Done: $TOTAL_PRS PRs ($TOTAL_MERGED merged, $TOTAL_OPEN open), $TOTAL_COMMITS commits across $ACTIVE_REPOS repos."
