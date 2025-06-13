# 📬 paste-gram

Send text or files to your Telegram chat directly from the Fish shell!

`paste-gram` is a lightweight Fish plugin that sends any input (either text or a file) to your Telegram bot using the Bot API. You can pipe output from other commands or pass messages/files directly. Perfect for quick remote sharing, logging, or personal note-taking!

### 🚀 New in v1.1.0
- Files over 50MB are now automatically compressed using `tar.gz`.
- Compressed files are split into 49MB chunks and sent in sequence.
- Compatible with both Linux and macOS.
- Enhanced HTML-based captions include hostname, last command, and absolute path.

---

## ✨ Features

- 🐟 Native Fish shell function
- 📦 Works with `fisher` plugin manager
- 🧾 Sends:
  - Messages (via direct argument or stdin)
  - Files (as documents with optional caption)
- 🖥️ Can prepend hostname and/or command line (configurable)
- 🔐 Gets config from environment variables

---

## 🧰 Requirements

- Fish shell 3.0 or higher
- `curl`
- `jq`
- `curl`
- `tar`
- `split`
- Telegram bot with a valid token
- Your own chat ID (or a group chat ID where your bot is added)

---

## ⚙️ Installation

1. **Install with [Fisher](https://github.com/jorgebucaran/fisher):**

```fish
fisher install behnambagheri/paste-gram
```

2. **Set environment variables:**

```fish
set -Ux TELEGRAM_TOKEN 'your_bot_token_here'
set -Ux TELEGRAM_CHAT_ID '123456789'
# Optional:
set -Ux TELEGRAM_API_URL 'https://api.telegram.org'
set -Ux PASTEGRAM_HOSTNAME 'true'
set -Ux PASTEGRAM_LAST_COMMAND 'true'
```

---

## 🤖 How to Get Your Telegram Bot Token

1. Open Telegram and search for [`@BotFather`](https://t.me/BotFather)
2. Start a chat and send `/newbot`
3. Follow the prompts to name and create your bot
4. After success, BotFather will give you a **bot token** like:
   ```
   123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
   ```
5. Copy it and set it as `TELEGRAM_TOKEN`

---

## 🆔 How to Find Your Chat ID

### 📥 Option 1: Using [@getidsbot](https://t.me/getidsbot)

1. Start a chat with [@getidsbot](https://t.me/getidsbot)
2. Send `/start`
3. It will respond with your numeric chat ID

### 📤 Option 2: Using Bot API (if you’re in a group):

1. Add your bot to the group
2. Send a message to the group
3. Use this API endpoint:

```
https://api.telegram.org/bot<your_token>/getUpdates
```

Check the response JSON for `"chat":{"id":...}`

---

## 🧪 Usage

```fish
# Pipe output from any command
echo "Hello from pipe" | ptg

# Send direct message
ptg "Direct hello from fish"

# Send a file with optional caption
ptg ~/Documents/log.txt
```

If `PASTEGRAM_HOSTNAME` or `PASTEGRAM_LAST_COMMAND` is set to `"true"`, those will be prepended to your message or file caption.

---

## 🔧 Environment Variables

| Variable                  | Required | Default | Description                                                  |
|---------------------------|----------|---------|--------------------------------------------------------------|
| `TELEGRAM_TOKEN`          | ✅ yes   | —       | Telegram bot token from BotFather                           |
| `TELEGRAM_CHAT_ID`        | ✅ yes   | —       | Chat ID (from @getidsbot or Bot API)                        |
| `TELEGRAM_API_URL`        | ❌ no    | `https://api.telegram.org` | Override default Telegram API URL (e.g. for proxy) |
| `PASTEGRAM_HOSTNAME`      | ❌ no    | `false` | If `"true"`, includes hostname in message                    |
| `PASTEGRAM_LAST_COMMAND`  | ❌ no    | `false` | If `"true"`, includes executed command line in message       |

---

## 🧾 License

MIT License © 2025 [Behnam Bagheri]