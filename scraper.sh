#!/data/data/com.termux/files/usr/bin/bash
# Self-healing CRLF protection
if grep -q $'\r' "$0" 2>/dev/null; then
    tr -d '\r' < "$0" > "$0.tmp" && mv "$0.tmp" "$0" && chmod +x "$0"
    exec bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="${SCRIPT_DIR//$'\r'/}"
cd "$SCRIPT_DIR"

REQUIRED_MAJOR="v24"
CURRENT_VER="$(node -v 2>/dev/null)"
CURRENT_MAJOR="${CURRENT_VER%%.*}"

if [ -z "$CURRENT_VER" ] || [ "$CURRENT_MAJOR" != "$REQUIRED_MAJOR" ]; then
    echo "[*] Node version mismatch (${CURRENT_VER:-none} detected). Installing required LTS engine ($REQUIRED_MAJOR)..."
    pkg uninstall -y nodejs nodejs-lts >/dev/null 2>&1
    pkg update -y && pkg install -y nodejs-lts
    rm -rf node_modules package-lock.json 2>/dev/null
fi

if ! node -e "require('bytenode')" >/dev/null 2>&1; then
    echo "[*] Setting up bytenode engine..."
    npm install bytenode@^2.0.0 chalk@4.1.2 https-proxy-agent@5.0.0 socks-proxy-agent@5.0.0 axios@^1.7.0 --no-audit --no-fund --silent
fi

# Ensure bytenode v2.x is installed (v1.x is incompatible with Node 24 V8 bytecode headers)
BYTENODE_VER="$(node -e "try{const v=require('bytenode/package.json').version;const major=parseInt(v.split('.')[0],10);process.stdout.write(String(major))}catch(e){process.stdout.write('0')}" 2>/dev/null)"
if [ "${BYTENODE_VER}" -lt 2 ] 2>/dev/null; then
    echo "[*] Upgrading bytenode to v2 (Node 24 compatibility)..."
    rm -rf node_modules/bytenode node_modules/.cache 2>/dev/null
    npm install bytenode@^2.0.0 chalk@4.1.2 https-proxy-agent@5.0.0 socks-proxy-agent@5.0.0 axios@^1.7.0 --no-audit --no-fund --silent
fi

echo "[*] Launching Scraper King Command Center..."
exec node -r bytenode "$SCRIPT_DIR/scraper.jsc" "$@"
