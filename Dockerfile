# ─────────────────────────────────────────────────────────────────────────────
#  Leech Bot — Docker Image
#  Engine : aioaria2 WebSocket + Pyrofork
#  Base   : python:3.11-slim
#  Owner  : GouthamSER (@im_goutham_josh)
# ─────────────────────────────────────────────────────────────────────────────

FROM python:3.11-slim

# Prevent Python from buffering stdout/stderr logs
ENV PYTHONUNBUFFERED=1
# Keeps pip quiet
ENV PIP_NO_CACHE_DIR=1
ENV PIP_QUIET=1

WORKDIR /app

# ── System packages ───────────────────────────────────────────────────────────
# aria2   — download engine (HTTP, magnet, torrent)
# curl    — RPC health check in start.sh
# wget    — static binary fallback in start.sh
# ca-certificates — HTTPS tracker connections
# netcat-openbsd  — optional port checks
# procps  — pkill used to restart aria2c
RUN apt-get update -qq && \
    apt-get install -y -qq \
        aria2 \
        curl \
        wget \
        ca-certificates \
        netcat-openbsd \
        procps \
    && rm -rf /var/lib/apt/lists/*

# ── Python dependencies ───────────────────────────────────────────────────────
# Copy requirements first so Docker cache is reused when only code changes
COPY requirements.txt /app/requirements.txt
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt

# ── Project files ─────────────────────────────────────────────────────────────
COPY . /app

# ── Permissions ───────────────────────────────────────────────────────────────
RUN chmod +x start.sh

# ── Runtime directory ─────────────────────────────────────────────────────────
RUN mkdir -p /tmp/downloads

# ── Exposed ports ─────────────────────────────────────────────────────────────
# 6800 — aria2c JSON-RPC (HTTP POST + WebSocket on same port)
# 8000 — bot keep-alive web server (health checks for Render/Koyeb/Railway)
EXPOSE 6800
EXPOSE 8000

# ── Start ─────────────────────────────────────────────────────────────────────
ENTRYPOINT ["./start.sh"]
