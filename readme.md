# 🤖 Advanced Leech Bot

<div align="center">

![Python](https://img.shields.io/badge/Python-3.11%2B-blue?style=for-the-badge&logo=python)
![Pyrofork](https://img.shields.io/badge/Pyrofork-2.2.18-green?style=for-the-badge)
![aioaria2](https://img.shields.io/badge/aioaria2-WebSocket-orange?style=for-the-badge)
![Aria2](https://img.shields.io/badge/Aria2-v1.37.0-red?style=for-the-badge)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker)
![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)

**A high-speed Telegram Leech Bot powered by aioaria2 WebSocket events.**
Downloads direct links, magnets & torrents — uploads directly to Telegram.

*Maintained & Owned by [@im_goutham_josh](https://t.me/im_goutham_josh)*

</div>

---

## ✨ Features

- ⬇️ **Multi-download** — queue multiple links at once via `/ql link1 link2`
- 🧲 **Magnet & Torrent** — full BitTorrent support with 20 supercharged trackers
- 📦 **Auto-Extract** — `.zip` `.7z` `.tar.gz` `.tgz` `.tar` supported
- ⚡ **Instant completion** — aioaria2 WebSocket events fire the moment a download finishes, no polling delay
- 📊 **Unified Dashboard** — ONE shared message per user shows all active tasks
- 🔄 **Auto-Refresh** — dashboard updates every 15s automatically, no button press needed
- 🚫 **FloodWait Eliminated** — serialised edit queue + minimum gap between edits
- 🎬 **Video / Document toggle** — choose how media files are sent to Telegram
- 🧹 **Smart Filename Cleaning** — strips site URLs, channel tags, brackets
- 🌐 **Keep-Alive Server** — built-in aiohttp server for Render / Koyeb / Railway
- 🐳 **Docker Ready** — single `docker build` and run

---

## 🆚 aioaria2 vs aria2p

This bot uses **aioaria2** instead of the older `aria2p` library.

| | aria2p | aioaria2 |
|---|---|---|
| Protocol | HTTP polling | WebSocket (persistent) |
| Completion detection | Polling every 2–3s | Instant push event |
| Magnet resolution | Polling `followedBy` | Push event on new GID |
| Error detection | Polling `has_failed` | Instant `onDownloadError` event |
| Native async | Partial | Full |

---

## 📋 Commands

| Command | Description |
|---|---|
| `/ql <link1> <link2>` | Download multiple links or magnets at once |
| `/leech <link>` | Download a single direct link |
| `/leech <link> -e` | Download and auto-extract archive |
| `/l <link>` | Shorthand for `/leech` |
| `/stop <task_id>` | Cancel an active task and clean up files |
| `/settings` | Toggle Document vs Video upload mode |
| `/help` | Show help message |
| `/start` | Welcome message |

> **Tip:** Send a `.torrent` file directly to the bot — no command needed.
> Add `-e` as the file caption to auto-extract after download.

---

## 🗂 Project Structure

```
leech-bot/
├── bot.py            # Main bot — dashboard, aioaria2 events, download, extract, upload
├── config.py         # All settings and environment variables
├── start.sh          # Universal startup — installs aria2c, requirements, launches bot
├── requirements.txt  # Python dependencies
├── Dockerfile        # Docker image definition
├── Procfile          # Render / Railway / Heroku process definition
└── README.md         # This file
```

---

## ⚙️ Configuration

All settings live in `config.py` and can be overridden with environment variables.

### Required

| Variable | Description |
|---|---|
| `API_ID` | Telegram API ID — from [my.telegram.org](https://my.telegram.org/apps) |
| `API_HASH` | Telegram API Hash |
| `BOT_TOKEN` | Bot token from [@BotFather](https://t.me/BotFather) |
| `OWNER_ID` | Your Telegram user ID |
| `ARIA2_SECRET` | Secret token for aria2 RPC (must match `start.sh`) |

### Optional

| Variable | Default | Description |
|---|---|---|
| `OWNER_PREMIUM` | `false` | Set `true` for 4 GB upload limit (Telegram Premium) |
| `DOWNLOAD_DIR` | `/tmp/downloads` | Where files are downloaded |
| `PORT` | `8000` | Keep-alive web server port |
| `ARIA2_HOST` | `http://localhost` | aria2 RPC host — bot strips `http://` to build `ws://` URL |
| `ARIA2_PORT` | `6800` | aria2 RPC port (HTTP POST and WebSocket share this port) |
| `DASHBOARD_REFRESH_INTERVAL` | `15` | Seconds between auto dashboard refreshes |
| `MIN_EDIT_GAP` | `12` | Minimum seconds between any two message edits |
| `WORKERS` | `300` | Pyrofork worker threads |
| `MAX_CONCURRENT_TRANSMISSIONS` | `15` | Parallel Telegram upload streams |

---

## 🚀 Deployment

### Requirements

```
pyrofork
TgCrypto
aioaria2
aiohttp
py7zr
psutil
uvloop
```

### Local / VPS

```bash
# 1. Clone
git clone https://github.com/yourrepo/leech-bot
cd leech-bot

# 2. Set environment variables
export API_ID="your_api_id"
export API_HASH="your_api_hash"
export BOT_TOKEN="your_bot_token"
export OWNER_ID="your_telegram_id"
export ARIA2_SECRET="your_secret"

# 3. Run — start.sh handles everything
bash start.sh
```

### 🐳 Docker

```bash
# Build
docker build -t leech-bot .

# Run
docker run -d \
  -e API_ID=your_api_id \
  -e API_HASH=your_api_hash \
  -e BOT_TOKEN=your_bot_token \
  -e OWNER_ID=your_telegram_id \
  -e ARIA2_SECRET=your_secret \
  -p 8000:8000 \
  --name leech-bot \
  leech-bot
```

### ☁️ Render / Koyeb / Railway

1. Set all environment variables in the platform dashboard
2. Set **Start Command** to `bash start.sh`  
   *(or leave blank — `Procfile` handles it automatically)*
3. The keep-alive server answers health checks on `PORT` (default `8000`)

---

## 🛡 FloodWait Prevention

Telegram limits message edits (~20/min per chat). This bot uses 4 layers so FloodWait can never happen:

| Layer | Mechanism |
|---|---|
| **1. Serialised queue** | One `edit_worker` coroutine per user — edits never run concurrently |
| **2. Duplicate skip** | Edit is skipped entirely if dashboard text hasn't changed |
| **3. MIN_EDIT_GAP** | Hard 12s minimum between any two edits |
| **4. flood_until window** | If FloodWait somehow occurs, worker sleeps the exact required duration |

The Refresh button shows a friendly countdown (`⏳ Rate limit — resumes in 8s`) instead of crashing.

---

## ⚡ aioaria2 WebSocket Events

Unlike the old polling approach, this bot uses push notifications from aria2:

```
aria2c  ──WebSocket──▶  aioaria2  ──event──▶  task.done_event.set()
                                               task.error_event.set()
```

| Event | Trigger |
|---|---|
| `onDownloadStart` | Download begins |
| `onDownloadComplete` | HTTP/FTP download finishes |
| `onBtDownloadComplete` | Torrent/magnet download finishes |
| `onDownloadError` | Download failed |
| `onDownloadStop` | Download cancelled |

`process_task_execution` waits on `done_event` or `error_event` — wakes up **instantly** when aria2 fires, not after a polling delay.

---

## 📊 Dashboard Preview

```
Task By @im_goutham_josh — ⬇️ 1 downloading | ⬆️ 1 uploading

1. Movie.2024.1080p.BluRay.mkv
├ [⬢⬢⬢⬢⬢⬢⬡⬡⬡⬡⬡⬡] 50.0%
├ Processed → 700.00 MB of 1.40 GB
├ Status → Download
├ Speed → 4.20 MB/s
├ Time → Elapsed: 2m 47s | ETA: 3m 21s
├ Seeders → 42 | Leechers → 8
├ Engine → ARIA2 v1.37.0 | Mode → #ARIA2 → #Leech
└ Stop → /stop_6acde619
─────────────────────
2. Series.S01E01.mkv
├ [⬢⬢⬢⬢⬢⬢⬢⬢⬢⬡⬡⬡] 75.0%
├ Uploaded → 300.00 MB of 400.00 MB
├ Status → Upload
├ Speed → 1.80 MB/s
├ Time → Elapsed: 2m 47s | ETA: 55s
├ Engine → Pyrofork
├ In Mode → #Aria2
├ Out Mode → #Leech
└ Stop → /stop_d0a84620

© Bot Stats
├ CPU → 18.3% | F → 11.20GB [72.4%]
└ RAM → 29.6% | UP → 3h 42m 18s

[🔄 Refresh]
```

---

## 📜 License

MIT License — free to use, modify and distribute.

---

<div align="center">

**Made with ❤️ by [GouthamSER](https://github.com/GouthamSER)**

*Code Owner & Maintainer*

</div>
