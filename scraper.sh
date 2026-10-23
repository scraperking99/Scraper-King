#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v node >/dev/null 2>&1; then
    echo "[*] Installing Node.js..."
    pkg update -y && pkg install nodejs-lts -y
fi

if ! node -e "require('bytenode')" >/dev/null 2>&1; then
    echo "[*] Setting up bytenode engine..."
    npm install bytenode@^1.6.0 chalk@4.1.2 https-proxy-agent@5.0.0 socks-proxy-agent@5.0.0 axios@^1.7.0 --no-audit --no-fund --silent
fi

echo "[*] Launching Scraper King Command Center..."
exec node -r bytenode "$SCRIPT_DIR/scraper.jsc" "$@"
