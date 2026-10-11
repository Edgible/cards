# A check for test-card, run after Verify with card.env exported and HOSTNAME_<APP> set.
# An MCP client's whole path through Edgible: with a fresh Edgible API key it opens a
# session over Streamable HTTP, lists the tools, and calls the test server's echo tool.
# A wrong key is refused. The key is deleted afterwards, and never printed.
set -eu
B="https://$HOSTNAME_MCP_BRIDGE/mcp"
app=${HOSTNAME_MCP_BRIDGE%%.*}
tmp=$(mktemp -d)
key_id=
cleanup() {
  [ -z "$key_id" ] || edgible app api-keys delete --app "$app" --key-id "$key_id" --yes >/dev/null 2>&1 || true
  rm -rf "$tmp"
}
trap cleanup EXIT
edgible -o json app api-keys create --app "$app" --name mcp-bridge-test \
  --expires "$(date -u -v+1d +%F 2>/dev/null || date -u -d tomorrow +%F)" 2>/dev/null > "$tmp/key.json"
key_id=$(jq -er .keyData.id "$tmp/key.json")
jq -er .apiKey "$tmp/key.json" > "$tmp/key"

# POST one JSON-RPC message; the answer may be JSON or a server-sent event stream.
rpc() {
  curl -sS -D "$tmp/headers" -o "$tmp/body" -w '%{http_code}' "$B" \
    -H "Authorization: Bearer $(cat "$tmp/key")" \
    -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream' \
    ${session:+-H "Mcp-Session-Id: $session"} --data "$1"
}
answer() { sed -n 's/^data: //p' "$tmp/body" | grep . || cat "$tmp/body"; }

code=$(curl -sS -o /dev/null -w '%{http_code}' "$B" -H 'Authorization: Bearer wrong-key' \
  -H 'Content-Type: application/json' --data '{}')
[ "$code" = 401 ] || { echo "a wrong key answered $code"; exit 1; }

session=
code=$(rpc '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"mcp-bridge-test","version":"1"}}}')
[ "$code" = 200 ] || { echo "initialize answered $code"; exit 1; }
answer | jq -e '.result.serverInfo.name' >/dev/null || { echo "initialize gave no serverInfo"; exit 1; }
session=$(sed -n 's/^[Mm]cp-[Ss]ession-[Ii]d: *\([^[:space:]]*\).*/\1/p' "$tmp/headers")
[ -n "$session" ] || { echo "no Mcp-Session-Id in the answer"; exit 1; }

rpc '{"jsonrpc":"2.0","method":"notifications/initialized"}' >/dev/null

code=$(rpc '{"jsonrpc":"2.0","id":2,"method":"tools/list"}')
[ "$code" = 200 ] || { echo "tools/list answered $code"; exit 1; }
answer | jq -e '.result.tools | map(.name) | index("echo")' >/dev/null || { echo "no echo tool listed"; exit 1; }

code=$(rpc '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"echo","arguments":{"message":"hello through Edgible"}}}')
[ "$code" = 200 ] || { echo "tools/call answered $code"; exit 1; }
answer | jq -e '.result.content[0].text | test("hello through Edgible")' >/dev/null || { echo "echo did not answer"; exit 1; }
