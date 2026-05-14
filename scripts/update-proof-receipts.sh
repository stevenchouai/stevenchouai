#!/usr/bin/env bash
# update-proof-receipts.sh
# Queries GitHub API for recent PRs/commits across StevenOS repos and updates
# the "Today's proof receipts" and "Builder Velocity" sections in README.md.
#
# Requirements: gh (authenticated), jq, bash 4+
# Usage: GITHUB_TOKEN=... bash scripts/update-proof-receipts.sh

set -euo pipefail

OWNER="stevenchouai"
README="README.md"
REPOS=(
  "agent-scorecard"
  "personalWebsite"
  "digital-twin"
  "knowledge-harness"
)

# Collect PRs from last 7 days
TODAY=$(date +%Y-%m-%d)
WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null || echo "")

declare -A REPO_PRS
declare -A REPO_MERGED
declare -A REPO_OPEN
TOTAL_PRS=0
TOTAL_MERGED=0
TOTAL_OPEN=0

for repo in "${REPOS[@]}"; do
  # Get recent PRs (merged + open)
  prs=$(gh pr list --repo "$OWNER/$repo" --state all --limit 20 \
    --json number,title,state,mergedAt,createdAt,url 2>/dev/null || echo "[]")

  # Filter to last 7 days
  recent=$(echo "$prs" | python3 -c "
import json, sys
from datetime import datetime, timedelta
prs = json.load(sys.stdin)
cutoff = datetime.utcnow() - timedelta(days=7)
recent = []
for p in prs:
    created = p.get('createdAt', '')
    if created:
        try:
            dt = datetime.fromisoformat(created.replace('Z', '+00:00')).replace(tzinfo=None)
            if dt >= cutoff:
                recent.append(p)
        except: pass
for p in recent:
    merged = 'merged' if p.get('mergedAt') else p['state'].lower()
    print(f\"{p['number']}|{merged}|{p['title']}|{p['url']}\")
" 2>/dev/null || echo "")

  merged_count=0
  open_count=0
  pr_lines=""

  while IFS='|' read -r num state title url; do
    [[ -z "$num" ]] && continue
    if [[ "$state" == "merged" ]]; then
      ((merged_count++)) || true
      pr_lines+="| [$repo#$num]($url) | Merged | $title |"$'\n'
    elif [[ "$state" == "open" ]]; then
      ((open_count++)) || true
      pr_lines+="| [$repo#$num]($url) | Open | $title |"$'\n'
    fi
  done <<< "$recent"

  REPO_MERGED[$repo]=$merged_count
  REPO_OPEN[$repo]=$open_count
  REPO_PRS[$repo]="$pr_lines"
  ((TOTAL_MERGED += merged_count)) || true
  ((TOTAL_OPEN += open_count)) || true
  ((TOTAL_PRS += merged_count + open_count)) || true
done

# Count commits across all repos (last 7 days)
TOTAL_COMMITS=0
for repo in "${REPOS[@]}"; do
  count=$(git -C "$HOME/Projects/$repo" log --oneline --since="$WEEK_AGO" 2>/dev/null | wc -l | tr -d ' ')
  ((TOTAL_COMMITS += count)) || true
done

# Build proof receipts table (last 5 shipped items, newest first)
RECEIPTS=""
count=0
for repo in agent-scorecard personalWebsite digital-twin knowledge-harness; do
  while IFS='|' read -r num state title url; do
    [[ -z "$num" ]] && continue
    [[ $count -ge 5 ]] && break
    RECEIPTS+="| [$repo#$num]($url) | $title | $(date +%Y-%m-%d) |"$'\n'
    ((count++)) || true
  done <<< "${REPO_PRS[$repo]}"
  [[ $count -ge 5 ]] && break
done

# Build velocity section
VELOCITY="| Metric | Count |\n|---|---|\n"
VELOCITY+="| PRs this week | $TOTAL_PRS |\n"
VELOCITY+="| Merged | $TOTAL_MERGED |\n"
VELOCITY+="| Open (pending review) | $TOTAL_OPEN |\n"
VELOCITY+="| Commits (7d) | $TOTAL_COMMITS |\n"
VELOCITY+="| Active repos | ${#REPOS[@]} |\n"
VELOCITY+="\n*Last auto-update: $TODAY*\n"

# Replace sections in README
python3 -c "
import re, sys

readme = sys.stdin.read()

# Replace proof receipts section
receipts_pattern = r'(## Latest shipped proof\n\n\| Artifact.*?\n)(\n##|\Z)'
receipts_repl = '''## Latest shipped proof

| Artifact | What it ships | Date |
|---|---|---|
${RECEIPTS}
'''
if not re.search(receipts_pattern, readme, re.DOTALL):
    # Section doesn't exist yet, insert after 'Today's proof receipts'
    old_pattern = r'(## Today.s proof receipts.*?\n\nOn .*?\n\n\| Artifact.*?\n(?:\|.*?\n)*)(\n##)'
    if re.search(old_pattern, readme, re.DOTALL):
        readme = re.sub(old_pattern, r'\1\n## Latest shipped proof\n\n| Artifact | What it ships | Date |\n|---|---|---|\n' + RECEIPTS + r'\2', readme, flags=re.DOTALL)
else:
    readme = re.sub(receipts_pattern, receipts_repl + r'\2', readme, flags=re.DOTALL)

# Replace velocity section
velocity_pattern = r'(## Builder Velocity\n\n\| Metric.*?\n)(\n##|\Z)'
velocity_repl = '''## Builder Velocity

''' + VELOCITY + '''
'''
if re.search(velocity_pattern, readme, re.DOTALL):
    readme = re.sub(velocity_pattern, velocity_repl + r'\2', readme, flags=re.DOTALL)
else:
    # Insert before '## Operating Principles'
    readme = readme.replace('## Operating Principles', '## Builder Velocity\n\n' + VELOCITY + '\n## Operating Principles')

# Update the date in 'Today's proof receipts' to today
readme = re.sub(r'On \d{4}-\d{2}-\d{2} ', 'On $TODAY ', readme)

sys.stdout.write(readme)
" < "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

echo "Updated $README with $TOTAL_PRS PRs ($TOTAL_MERGED merged, $TOTAL_OPEN open), $TOTAL_COMMITS commits across ${#REPOS[@]} repos."
