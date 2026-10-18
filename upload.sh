#!/usr/bin/env bash
# upload.sh - upload finished ROM zips to GoFile and notify via Telegram bot
# Usage: ./upload.sh            (run from the source root after a successful build)
#
# Required env vars (do NOT hardcode them if your repo is public):
#   BOT_TOKEN   - Telegram bot token from @BotFather
#   CHAT_ID     - chat/channel/group ID to send the message to
# Optional:
#   DEVICE      - device codename (default: blossom)
#   OUT_DIR     - build output dir (default: out/target/product/$DEVICE)
#   ROM_NAME    - name shown in the message (default: taken from the zip name)
#   GOFILE_TOKEN - GoFile account token (uploads go to your account if set)

set -uo pipefail

DEVICE="${DEVICE:-blossom}"
OUT_DIR="${OUT_DIR:-out/target/product/$DEVICE}"

: "${BOT_TOKEN:?BOT_TOKEN is not set}"
: "${CHAT_ID:?CHAT_ID is not set}"

for tool in curl jq md5sum; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing dependency: $tool"; exit 1; }
done

# ---------- Telegram helpers ----------
tg_send() {
    # $1 = text (HTML), $2 = reply_markup JSON (optional)
    local text="$1" markup="${2:-}"
    local args=(-s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"
        --data-urlencode "chat_id=${CHAT_ID}"
        --data-urlencode "text=${text}"
        --data-urlencode "parse_mode=HTML"
        --data-urlencode "disable_web_page_preview=true")
    [ -n "$markup" ] && args+=(--data-urlencode "reply_markup=${markup}")
    curl "${args[@]}" >/dev/null
}

# ---------- GoFile upload ----------
gofile_upload() {
    # prints the download page URL on success
    local file="$1" resp url
    local args=(-s -F "file=@${file}")
    [ -n "${GOFILE_TOKEN:-}" ] && args+=(-H "Authorization: Bearer ${GOFILE_TOKEN}")
    resp=$(curl "${args[@]}" "https://upload.gofile.io/uploadfile")
    url=$(echo "$resp" | jq -r '.data.downloadPage // empty')
    if [ -z "$url" ]; then
        echo "GoFile upload failed for $file: $resp" >&2
        return 1
    fi
    echo "$url"
}

# ---------- Find the zips ----------
# OTA zip: anything ending in ota.zip
OTA_ZIP=$(ls -t "$OUT_DIR"/*ota.zip 2>/dev/null | head -n1 || true)

# ROM zip: newest .zip that is NOT an ota / target_files / symbols zip
ROM_ZIP=$(ls -t "$OUT_DIR"/*.zip 2>/dev/null \
    | grep -viE 'ota\.zip$|target_files|symbols|ota_' | head -n1 || true)

if [ -z "$ROM_ZIP" ] && [ -z "$OTA_ZIP" ]; then
    echo "No zips found in $OUT_DIR"
    tg_send "❌ <b>Upload failed</b>: no zip found in <code>${OUT_DIR}</code>"
    exit 1
fi

ROM_LINK=""
OTA_LINK=""
ROM_MD5=""
ROM_SIZE=""

if [ -n "$ROM_ZIP" ]; then
    echo "Uploading ROM zip: $ROM_ZIP"
    ROM_LINK=$(gofile_upload "$ROM_ZIP") || ROM_LINK=""
    ROM_MD5=$(md5sum "$ROM_ZIP" | cut -d' ' -f1)
    ROM_SIZE=$(du -h "$ROM_ZIP" | cut -f1)
fi

if [ -n "$OTA_ZIP" ]; then
    echo "Uploading OTA zip: $OTA_ZIP"
    OTA_LINK=$(gofile_upload "$OTA_ZIP") || OTA_LINK=""
fi

# ---------- Build the message ----------
MAIN_FILE="${ROM_ZIP:-$OTA_ZIP}"
NAME="${ROM_NAME:-$(basename "$MAIN_FILE" .zip)}"
DATE=$(date +%Y-%m-%d)

MSG="✅ <b>Build finished successfully</b>

• ROM: <code>${NAME}</code>
• DEVICE: ${DEVICE}
• DATE: ${DATE}"
[ -n "$ROM_SIZE" ] && MSG+="
• SIZE: ${ROM_SIZE}"
[ -n "$ROM_MD5" ] && MSG+="
• MD5SUM: <code>${ROM_MD5}</code>"
MSG+="

Flash responsibly and enjoy!"

# ---------- Buttons (one per link, each on its own row) ----------
BUTTONS='[]'
if [ -n "$ROM_LINK" ]; then
    BUTTONS=$(echo "$BUTTONS" | jq -c --arg u "$ROM_LINK" '. + [[{"text":"Download ROM","url":$u}]]')
fi
if [ -n "$OTA_LINK" ]; then
    BUTTONS=$(echo "$BUTTONS" | jq -c --arg u "$OTA_LINK" '. + [[{"text":"Download OTA","url":$u}]]')
fi

if [ "$BUTTONS" = '[]' ]; then
    tg_send "❌ <b>Build finished but GoFile upload failed.</b> Check the logs."
    exit 1
fi

MARKUP=$(jq -cn --argjson rows "$BUTTONS" '{inline_keyboard: $rows}')
tg_send "$MSG" "$MARKUP"

echo "Done."
