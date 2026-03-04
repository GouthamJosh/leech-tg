#!/bin/sh
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖  Leech Bot — Startup Script"
echo "  Engine: aioaria2 WebSocket RPC"
echo "  Supports: Koyeb · Render · Railway · VPS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p /tmp/downloads

ARCH=$(uname -m)
OS=$(uname -s)
echo "🖥️  Architecture: $ARCH | OS: $OS"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_aria2() {
    echo "⚠️  aria2c not found. Installing..."

    if command_exists apt-get; then
        echo "📦 Trying apt-get..."
        apt-get update -qq 2>/dev/null && apt-get install -y -qq aria2 2>/dev/null && {
            echo "✅ Installed via apt-get"; return 0
        }
    fi
    if command_exists apk; then
        echo "📦 Trying apk..."
        apk add --no-cache aria2 2>/dev/null && { echo "✅ Installed via apk"; return 0; }
    fi
    if command_exists yum; then
        echo "📦 Trying yum..."
        yum install -y aria2 2>/dev/null && { echo "✅ Installed via yum"; return 0; }
    fi
    if command_exists dnf; then
        echo "📦 Trying dnf..."
        dnf install -y aria2 2>/dev/null && { echo "✅ Installed via dnf"; return 0; }
    fi
    if command_exists pacman; then
        echo "📦 Trying pacman..."
        pacman -Sy --noconfirm aria2 2>/dev/null && { echo "✅ Installed via pacman"; return 0; }
    fi

    echo "📦 Trying static binary..."
    ARIA2_VER="1.37.0"
    mkdir -p /tmp/aria2

    case "$ARCH" in
        x86_64|amd64)
            URL="https://github.com/q3aql/aria2-static-builds/releases/download/v${ARIA2_VER}/aria2-${ARIA2_VER}-linux-gnu-64bit-build1.tar.bz2" ;;
        aarch64|arm64|armv7l|armhf)
            URL="https://github.com/q3aql/aria2-static-builds/releases/download/v${ARIA2_VER}/aria2-${ARIA2_VER}-linux-gnu-arm-rbpi-build1.tar.bz2" ;;
        i386|i686)
            URL="https://github.com/q3aql/aria2-static-builds/releases/download/v${ARIA2_VER}/aria2-${ARIA2_VER}-linux-gnu-32bit-build1.tar.bz2" ;;
        *)
            echo "❌ Unsupported architecture: $ARCH"; return 1 ;;
    esac

    if command_exists curl; then
        curl -fsSL "$URL" -o /tmp/aria2.tar.bz2 2>/dev/null
    elif command_exists wget; then
        wget -q "$URL" -O /tmp/aria2.tar.bz2 2>/dev/null
    else
        echo "❌ No curl or wget available"; return 1
    fi

    if [ -f /tmp/aria2.tar.bz2 ]; then
        tar -xjf /tmp/aria2.tar.bz2 -C /tmp/aria2 2>/dev/null
        BINARY=$(find /tmp/aria2 -name "aria2c" -type f 2>/dev/null | head -n1)
        if [ -n "$BINARY" ]; then
            if [ -w /usr/local/bin ]; then
                cp "$BINARY" /usr/local/bin/aria2c && chmod +x /usr/local/bin/aria2c
            else
                cp "$BINARY" /tmp/aria2c && chmod +x /tmp/aria2c
                export PATH="/tmp:$PATH"
            fi
            rm -rf /tmp/aria2 /tmp/aria2.tar.bz2
            echo "✅ Installed static binary"; return 0
        fi
    fi

    echo "❌ All install methods failed for $ARCH"; return 1
}

if ! command_exists aria2c; then
    install_aria2 || exit 1
fi

echo "🔍 Verifying aria2c..."
if ! aria2c --version >/dev/null 2>&1; then
    echo "❌ aria2c broken, reinstalling..."
    rm -f /usr/local/bin/aria2c /tmp/aria2c
    install_aria2 || exit 1
fi
echo "✅ aria2c: $(aria2c --version 2>/dev/null | head -n1 | awk '{print $3}')"

# ── Python requirements ───────────────────────────────────────────────────────
echo "📦 Installing Python requirements..."

if ! command_exists python3; then
    echo "❌ python3 not found"; exit 1
fi

if command_exists pip3; then
    PIP="pip3"
elif command_exists pip; then
    PIP="pip"
else
    python3 -m ensurepip --upgrade 2>/dev/null || true
    PIP="python3 -m pip"
fi

$PIP install --upgrade pip setuptools wheel --quiet 2>/dev/null || true

if [ -f requirements.txt ]; then
    $PIP install -r requirements.txt --no-cache-dir --quiet || {
        echo "❌ Failed to install requirements"; exit 1
    }
    echo "✅ Requirements installed from requirements.txt"
else
    echo "⚠️  No requirements.txt — installing core packages..."
    $PIP install --quiet --no-cache-dir \
        "pyrogram==2.2.18" \
        "aioaria2" \
        "aiohttp" \
        "py7zr" \
        "psutil" \
        "tgcrypto" \
        "uvloop" \
    || true
    echo "✅ Core packages installed"
fi

# ── Trackers ──────────────────────────────────────────────────────────────────
TRACKERS="udp://tracker.opentrackr.org:1337/announce"
TRACKERS="$TRACKERS,udp://tracker.openbittorrent.com:6969/announce"
TRACKERS="$TRACKERS,http://tracker.openbittorrent.com:80/announce"
TRACKERS="$TRACKERS,udp://tracker.torrent.eu.org:451/announce"
TRACKERS="$TRACKERS,udp://exodus.desync.com:6969/announce"
TRACKERS="$TRACKERS,udp://tracker.cyberia.is:6969/announce"
TRACKERS="$TRACKERS,udp://open.demonii.com:1337/announce"
TRACKERS="$TRACKERS,udp://9.rarbg.com:2810/announce"
TRACKERS="$TRACKERS,udp://tracker.moeking.me:6969/announce"
TRACKERS="$TRACKERS,udp://tracker.lelux.fi:6969/announce"
TRACKERS="$TRACKERS,udp://retracker.lanta-net.ru:2710/announce"
TRACKERS="$TRACKERS,udp://opentor.net:2710/announce"
TRACKERS="$TRACKERS,udp://tracker.dler.org:6969/announce"
TRACKERS="$TRACKERS,udp://tracker.tiny-vps.com:6969/announce"
TRACKERS="$TRACKERS,https://tracker.tamersunion.org:443/announce"
TRACKERS="$TRACKERS,https://tracker.loligirl.cn:443/announce"
TRACKERS="$TRACKERS,udp://tracker.theoks.net:6969/announce"
TRACKERS="$TRACKERS,udp://tracker1.bt.moack.co.kr:80/announce"
TRACKERS="$TRACKERS,udp://open.stealth.si:80/announce"
TRACKERS="$TRACKERS,udp://tracker.zemoj.com:6969/announce"

# ── Config from env ───────────────────────────────────────────────────────────
ARIA2_SECRET="${ARIA2_SECRET:-gjxml}"
RPC_PORT="${ARIA2_PORT:-6800}"

pkill -f "aria2c.*rpc-listen-port=$RPC_PORT" 2>/dev/null || true
sleep 1

# ─────────────────────────────────────────────────────────────────────────────
# Start Aria2c RPC daemon
#
# aioaria2 connects via WebSocket: ws://localhost:6800/jsonrpc
# aria2c serves BOTH HTTP POST and WebSocket on the same port automatically.
# --rpc-allow-origin-all is required for the WebSocket upgrade handshake.
# ─────────────────────────────────────────────────────────────────────────────
echo "🚀 Starting Aria2c RPC daemon (WS+HTTP on port $RPC_PORT)..."

aria2c \
    --enable-rpc=true \
    --rpc-listen-all=false \
    --rpc-listen-port="$RPC_PORT" \
    --rpc-secret="$ARIA2_SECRET" \
    --rpc-max-request-size=16M \
    --rpc-allow-origin-all=true \
    --dir=/tmp/downloads \
    --disk-cache=64M \
    --file-allocation=none \
    --allow-overwrite=true \
    --auto-file-renaming=false \
    --continue=true \
    --max-concurrent-downloads=5 \
    --max-connection-per-server=16 \
    --min-split-size=1M \
    --split=16 \
    --max-overall-download-limit=0 \
    --max-overall-upload-limit=1K \
    --enable-dht=true \
    --enable-dht6=true \
    --dht-listen-port=6881-6889 \
    --enable-peer-exchange=true \
    --bt-enable-lpd=true \
    --bt-max-peers=200 \
    --bt-request-peer-speed-limit=50M \
    --bt-save-metadata=true \
    --bt-seed-unverified=true \
    --bt-prioritize-piece=head=2M,tail=2M \
    --bt-remove-unselected-file=true \
    --seed-time=0 \
    --follow-torrent=true \
    --bt-tracker="$TRACKERS" \
    --log-level=warn \
    --daemon=true \
    2>/dev/null || true

echo "⏳ Waiting for RPC to come up..."
sleep 3

# ── Verify RPC ────────────────────────────────────────────────────────────────
RPC_OK=false

if command_exists curl; then
    HTTP_CHECK=$(curl -s --max-time 3 \
        -d "{\"jsonrpc\":\"2.0\",\"id\":\"ping\",\"method\":\"aria2.getVersion\",\"params\":[\"token:${ARIA2_SECRET}\"]}" \
        "http://localhost:${RPC_PORT}/jsonrpc" 2>/dev/null | grep -o '"version"' || true)
    if [ -n "$HTTP_CHECK" ]; then
        echo "✅ HTTP RPC  → live  — http://localhost:${RPC_PORT}/jsonrpc"
        echo "✅ WS  RPC  → live  — ws://localhost:${RPC_PORT}/jsonrpc"
        RPC_OK=true
    fi
fi

if [ "$RPC_OK" = false ]; then
    echo "⚠️  RPC check inconclusive — bot will retry on connect"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  RPC port : $RPC_PORT"
echo "  WS URL   : ws://localhost:${RPC_PORT}/jsonrpc"
echo "  Secret   : $ARIA2_SECRET"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Starting Leech Bot..."
exec python3 bot.py
