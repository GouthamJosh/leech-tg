# 🤖 Advanced Leech Bot

<div align="center">

![Python](https://img.shields.io/badge/Python-3.10%2B-blue?style=for-the-badge&logo=python)
![Pyrogram](https://img.shields.io/badge/Pyrogram-v2.2.18-green?style=for-the-badge)
![Aria2](https://img.shields.io/badge/Aria2-v1.36.0-orange?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)

**A high-speed Telegram Leech Bot that downloads direct links, magnets & torrents and uploads them directly to Telegram.**

*Maintained & Owned by [@im_goutham_josh](https://t.me/im_goutham_josh)*

</div>

---

## ✨ Features

- ⬇️ **Multi-download** — queue multiple links at once via `/ql`
- 🧲 **Magnet & Torrent** — full BitTorrent support via Aria2 with 20 supercharged trackers
- 📦 **Auto-Extract** — `.zip`, `.7z`, `.tar.gz`, `.tgz`, `.tar` supported
- 📊 **Unified Dashboard** — ONE message per user shows all active tasks (download → extract → upload)
- 🔄 **Auto-Refresh** — dashboard updates every 15 seconds automatically, no button needed
- 🚫 **FloodWait Eliminated** — serialised edit queue + minimum gap between edits makes Telegram rate limits impossible
- 🎬 **Video / Document toggle** — choose how media files are sent to Telegram
- 🧹 **Smart Filename Cleaning** — strips site URLs, channel tags, brackets from filenames
- 🌐 **Keep-Alive Server** — built-in HTTP server for Render / Koyeb / Railway deployments
- ⚡ **Speed Optimised** — uvloop + TgCrypto + 200 max peers + DHT/LPD/PEX

---

## 📋 Commands

| Command | Description |
|---|---|
| `/ql <link1> <link2>` | Download multiple links / magnets at once |
| `/leech <link>` | Download a single direct link |
| `/leech <link> -e` | Download and auto-extract an archive |
| `/l <link>` | Shorthand for `/leech` |
| `/stop <task_id>` | Cancel an active download or upload |
| `/settings` | Toggle between Document and Video upload mode |
| `/help` | Show help message |
| `/start` | Welcome message |

> **Tip:** You can also send a `.torrent` file directly to the bot — no command needed.

---

## 🗂 Project Structure

```
leech-bot/
├── bot.py          # Main bot logic — dashboard, download, extract, upload
├── config.py       # All configuration and environment variables
├── start.sh        # Aria2 daemon startup script
└── README.md       # This file
```

---

## ⚙️ Configuration

All settings live in `config.py` and can be overridden with environment variables.

### Required Variables

| Variable | Description |
|---|---|
| `API_ID` | Telegram API ID — get from [my.telegram.org](https://my.telegram.org/apps) |
| `API_HASH` | Telegram API Hash |
| `BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) |
| `OWNER_ID` | Your Telegram user ID |
| `ARIA2_SECRET` | Secret token for Aria2 RPC (must match `start.sh`) |

### Optional Variables

| Variable | Default | Description |
|---|---|---|
| `OWNER_PREMIUM` | `false` | Set `true` for 4 GB upload limit (Telegram Premium) |
| `DOWNLOAD_DIR` | `/tmp/downloads` | Directory where files are downloaded |
| `PORT` | `8000` | Port for the keep-alive web server |
| `ARIA2_HOST` | `http://localhost` | Aria2 RPC host |
| `ARIA2_PORT` | `6800` | Aria2 RPC port |
| `DASHBOARD_REFRESH_INTERVAL` | `15` | Seconds between automatic dashboard refreshes |
| `MIN_EDIT_GAP` | `12` | Minimum seconds between any two message edits (FloodWait prevention) |

---

## 🚀 Deployment

### Requirements

```
python-pyrogram==2.2.18
aria2p
aiohttp
py7zr
psutil
tgcrypto      # strongly recommended — massively boosts upload speed
uvloop        # optional — faster async event loop
```

Install all at once:

```bash
pip install pyrogram==2.2.18 aria2p aiohttp py7zr psutil tgcrypto uvloop
```

### 1. Clone & configure

```bash
git clone https://github.com/yourrepo/leech-bot
cd leech-bot
```

Set your environment variables (or edit the defaults in `config.py` directly):

```bash
export API_ID="your_api_id"
export API_HASH="your_api_hash"
export BOT_TOKEN="your_bot_token"
export OWNER_ID="your_telegram_id"
export ARIA2_SECRET="your_secret"
```

### 2. Start Aria2 daemon

```bash
bash start.sh
```

### 3. Start the bot

```bash
python bot.py
```

---

### 🐳 Docker (optional)

```dockerfile
FROM python:3.11-slim
RUN apt-get update && apt-get install -y aria2
WORKDIR /app
COPY . .
RUN pip install pyrogram==2.2.18 aria2p aiohttp py7zr psutil tgcrypto uvloop
CMD ["bash", "-c", "bash start.sh && python bot.py"]
```

---

### ☁️ Platform Deployment

#### Render / Koyeb / Railway

1. Set all environment variables in the platform dashboard
2. Set **Start Command** to:
   ```bash
   bash start.sh && python bot.py
   ```
3. The built-in keep-alive server will answer health checks on `PORT` (default `8000`)

---

## 🛡 FloodWait — How It's Prevented

Telegram limits how often a bot can edit the same message (~20 edits/min). This bot uses a 4-layer system so FloodWait can never happen:

| Layer | Mechanism |
|---|---|
| **1. Serialised Queue** | One `edit_worker` coroutine per user — edits are never concurrent |
| **2. Duplicate Skip** | Edit is skipped entirely if dashboard text hasn't changed |
| **3. MIN_EDIT_GAP** | Hard 12-second minimum between any two edits |
| **4. flood_until window** | If FloodWait somehow occurs, worker sleeps exact required duration and resumes cleanly |

The Refresh button also shows a friendly countdown (`⏳ Rate limit active — resumes in 8s`) instead of crashing.

---

## 📊 Dashboard Preview

```
Task By @im_goutham_josh — ⬇️ 2 downloading | ⬆️ 1 uploading

1. Kannadi (2026) Tamil HQ HDRip - x264 - AAC - 700MB.mkv
├ [⬢⬢⬢⬢⬢⬢⬡⬡⬡⬡⬡⬡] 50.0%
├ Processed → 350.00 MB of 700.00 MB
├ Status → Download
├ Speed → 3.20 MB/s
├ Time → Elapsed: 1m 50s | ETA: 3m 38s
├ Connections → 12
├ Engine → ARIA2 v1.36.0 | Mode → #ARIA2 → #Leech
└ Stop → /stop_6acde619
─────────────────────────────────────────
2. Kannadi (2026) Tamil HQ HDRip - x264 - AAC - 400MB.mkv
├ [⬢⬢⬢⬢⬢⬢⬢⬢⬢⬡⬡⬡] 75.0%
├ Processed → 300.00 MB of 400.00 MB
├ Status → Upload
├ Speed → 1.05 MB/s
├ Time → Elapsed: 3m 50s | ETA: 1m 35s
├ Engine → Pyro v2.2.18 | Mode → #Aria2 → #Leech
└ Stop → /stop_d0a84620

© Bot Stats
├ CPU → 25.0% | F → 13.37GB [65.8%]
└ RAM → 33.1% | UP → 5h 8m 32s
```

---

## 📜 License

MIT License — free to use, modify and distribute.

---

<div align="center">

**Made with ❤️ by [GouthamSER](https://t.me/im_goutham_josh)**

*Code Owner & Maintainer*

</div>
