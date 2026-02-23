#!/usr/bin/env bash
# Export blog path -> discussion URL for each discussion in "Post discussions" category.
# Writes data/discussions.json so Hugo can link "Discuss this post" to the right thread.
# Run after ensure-blog-discussions.sh. Requires: GH_TOKEN (or GITHUB_TOKEN), jq, curl.

set -e
OWNER="${OWNER:-genomicsxai}"
REPO="${REPO:-genomicsxai.github.io}"
BASE="${GITHUB_API_URL:-https://api.github.com}"
API="${BASE%/}/graphql"
TOKEN="${GH_TOKEN:-$GITHUB_TOKEN}"
OUT="${1:-data/discussions.json}"

if [ -z "$TOKEN" ]; then
  echo "No GH_TOKEN or GITHUB_TOKEN set; writing empty discussions map."
  mkdir -p "$(dirname "$OUT")"
  echo '{}' > "$OUT"
  exit 0
fi

QUERY='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id
    discussionCategories(first: 20) { nodes { id name } }
  }
}'
RES=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"query\": $(echo "$QUERY" | jq -Rs .), \"variables\": {\"owner\": \"$OWNER\", \"name\": \"$REPO\"}}" "$API")
if ! echo "$RES" | jq -e '.data.repository' >/dev/null 2>&1; then
  echo "GraphQL repo query failed; writing empty discussions map."
  mkdir -p "$(dirname "$OUT")"
  echo '{}' > "$OUT"
  exit 0
fi
REPO_ID=$(echo "$RES" | jq -r '.data.repository.id')
CATEGORY_ID=$(echo "$RES" | jq -r '.data.repository.discussionCategories.nodes[] | select(.name | test("Post [Dd]iscussions"; "i")) | .id' | head -1)
if [ -z "$CATEGORY_ID" ] || [ "$CATEGORY_ID" = "null" ]; then
  echo "Could not find Post discussions category; writing empty discussions map."
  mkdir -p "$(dirname "$OUT")"
  echo '{}' > "$OUT"
  exit 0
fi

# Fetch discussions with url, reaction count, and comment count (auth required for counts)
Q2='query($rid: ID!, $cid: ID!) {
  repository(id: $rid) {
    discussions(first: 100, categoryId: $cid) {
      nodes {
        title
        url
        reactions(first: 1) { totalCount }
        comments(first: 0) { totalCount }
      }
    }
  }
}'
RES2=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d "{\"query\": $(echo "$Q2" | jq -Rs .), \"variables\": {\"rid\": \"$REPO_ID\", \"cid\": \"$CATEGORY_ID\"}}" "$API")
NODES=$(echo "$RES2" | jq -c '.data.repository.discussions.nodes // []')
# Build JSON: path -> { url, reactions, comments } for Hugo
MAP=$(echo "$NODES" | jq '[.[] | {"key": .title, "value": {"url": .url, "reactions": (.reactions.totalCount // 0), "comments": (.comments.totalCount // 0)}}] | from_entries')
mkdir -p "$(dirname "$OUT")"
echo "$MAP" > "$OUT"
echo "Wrote $(echo "$NODES" | jq 'length') discussion(s) (with counts) to $OUT"
