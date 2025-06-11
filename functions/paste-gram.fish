function paste-gram --description "Send text or file to Telegram" --argument cmdArg
    set -l token $TELEGRAM_TOKEN
    set -l chat_id $TELEGRAM_CHAT_ID
    set -l api_url (set -q TELEGRAM_API_URL; and echo $TELEGRAM_API_URL; or echo "https://api.telegram.org")

    if test -z "$token" -o -z "$chat_id"
        echo "❌ TELEGRAM_TOKEN and TELEGRAM_CHAT_ID must be set" >&2
        return 1
    end

    set -l full_cmd (status current-commandline)
    set -l hostname (hostname)

    if test -n "$cmdArg" -a -f "$cmdArg"
        # File Mode
        echo "📤 Sending file: $cmdArg"
        curl -s -F "chat_id=$chat_id" \
            -F "document=@$cmdArg" \
            -F "caption=$hostname\n$full_cmd" \
            "$api_url/bot$token/sendDocument"
    else
        # Text Mode
        set -l message ""

        if not isatty stdin
            # Input from pipe
            set message (cat)
        else if test -n "$cmdArg"
            # Direct argument
            set message "$cmdArg"
        else
            echo "⚠️ No input provided" >&2
            return 1
        end

        set message "$hostname\n$full_cmd\n$message"

        echo "📤 Sending message..."
        curl -s -X POST "$api_url/bot$token/sendMessage" \
            -d "chat_id=$chat_id" \
            --data-urlencode "text=$message"
    end
end