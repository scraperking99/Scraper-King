#!/data/data/com.termux/files/usr/bin/bash
# Self-healing CRLF protection
if grep -q $'\r' "$0" 2>/dev/null; then
    tr -d '\r' < "$0" > "$0.tmp" && mv "$0.tmp" "$0" && chmod +x "$0"
    exec bash "$0" "$@"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="${SCRIPT_DIR//$'\r'/}"
cd "$SCRIPT_DIR"

REQUIRED_VER="v24.22.1"
CURRENT_VER="$(node -v 2>/dev/null || echo "none")"
DEVICE_ARCH="$(uname -m 2>/dev/null || echo "unknown")"

echo "[*] Device: $DEVICE_ARCH | Installed Node: $CURRENT_VER"

# 1. If device has older/different Node (e.g. v24.17.0), auto-upgrade Termux to required v24.22.1
if [ "$CURRENT_VER" != "$REQUIRED_VER" ]; then
    echo "[*] Node version mismatch ($CURRENT_VER detected). Upgrading to required LTS engine ($REQUIRED_VER)..."
    pkg update -y && pkg install -y nodejs-lts
    CURRENT_VER="$(node -v 2>/dev/null || echo "none")"
fi

# 2. Unpack exact matching Node runtime if present (ensures 100% V8 bytecode compatibility)
if [ ! -f "$SCRIPT_DIR/bin/node" ]; then
    if [ -f "$SCRIPT_DIR/bin/node.gz" ]; then
        echo "[*] First-time setup: Unpacking dedicated Node runtime..."
        mkdir -p "$SCRIPT_DIR/bin"
        gunzip -c "$SCRIPT_DIR/bin/node.gz" > "$SCRIPT_DIR/bin/node"
        chmod +x "$SCRIPT_DIR/bin/node"
    fi
fi

# 3. Determine best working runtime (dedicated binary or updated system node)
NODE_CMD="node"
if [ -x "$SCRIPT_DIR/bin/node" ]; then
    if "$SCRIPT_DIR/bin/node" -v >/dev/null 2>&1; then
        NODE_CMD="$SCRIPT_DIR/bin/node"
    fi
fi

# Verify runtime is operational
if ! "$NODE_CMD" -v >/dev/null 2>&1; then
    echo ""
    echo "  [!] Runtime Check Failed"
    echo "      Device Arch    : $DEVICE_ARCH"
    echo "      Current Node   : $CURRENT_VER"
    echo "      Required Build : $REQUIRED_VER"
    echo "      Please run: pkg update && pkg install nodejs-lts"
    echo ""
    exit 1
fi

# 2. Ensure bytenode runtime engine is installed
if ! "$NODE_CMD" -e "require('bytenode')" >/dev/null 2>&1; then
    echo "[*] Setting up bytenode engine..."
    npm install bytenode@^2.0.0 chalk@4.1.2 https-proxy-agent@5.0.0 socks-proxy-agent@5.0.0 axios@^1.7.0 --no-audit --no-fund --silent
fi

echo "[*] Launching Scraper King Command Center..."
exec "$NODE_CMD" -r bytenode "$SCRIPT_DIR/scraper.jsc" "$@"
