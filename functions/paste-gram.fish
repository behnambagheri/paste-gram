function paste-gram --description "Send text or file to Telegram" --argument cmdArg
    set -l token $TELEGRAM_TOKEN
    set -l chat_id $TELEGRAM_CHAT_ID
    set -l api_url (set -q TELEGRAM_API_URL; and echo $TELEGRAM_API_URL; or echo "https://api.telegram.org")

    if test -z "$token" -o -z "$chat_id"
        echo "❌ TELEGRAM_TOKEN and TELEGRAM_CHAT_ID must be set" >&2
        return 1
    end

    set -l include_hostname (set -q PASTEGRAM_HOSTNAME; and echo $PASTEGRAM_HOSTNAME; or echo "false")
    set -l include_command (set -q PASTEGRAM_LAST_COMMAND; and echo $PASTEGRAM_LAST_COMMAND; or echo "false")

    set -l m_hostname (hostname)

    sync_history
    set -l full_cmd (history --max 2 | head -n 1)

    set -l head_message_text_file (mktemp)
    set -l body_meesage_text_file (mktemp)
    set -l message_text_file (mktemp)
    set -l splitdir (mktemp -d)



    if test $include_hostname = "true"; or \
       test $include_hostname = "True"; or \
       test $include_hostname = "1"
        echo -e "<b>Hostname:</b> <u>$m_hostname</u>" >> "$head_message_text_file"
#         echo -e "Hostname: $m_hostname"
    end

    if test $include_command = "true"; or \
       test $include_command = "True"; or \
       test $include_command = "1"
        echo -e "\$ <b><u>$full_cmd</u></b>" >> "$head_message_text_file"
#         echo -e "FullCommand: $full_cmd"
    end


    if test $include_command  = "true";  or \
       test $include_command  = "True";  or \
       test $include_command  = "1"   ;  or \
       test $include_hostname = "true";  or \
       test $include_hostname = "True";  or \
       test $include_hostname = "1"
        echo -e "\n=======================\n" >> "$head_message_text_file"
    end

#     cat $head_message_text_file

#++++++++++++++++++++++++++++++++++++++++++

    if isatty stdin
        if test -n "$argv"
#             echo "Reading from arguments..."
            if test -f "$argv[1]"
                echo "Uploading file..."
                set -l file $argv[1]
                set -l abs_path (realpath $file)

                echo -e "Caption:\n" > "$message_text_file"
                cat "$head_message_text_file" >> "$message_text_file"
                echo -e "<b>File:</b> <u>$file</u>" >> "$message_text_file"
                echo -e "<b>PATH:</b> <u>$abs_path</u>" >> "$message_text_file"

                set -l caption (printf "📄 <b>File:</b> %s\n📍 <b>Path:</b> %s" (basename $file) $abs_path)

                set response (curl -s -X POST "$api_url"/bot$token/"sendDocument" \
                    -F chat_id="$chat_id" \
                    -F document=@"$file" \
                    -F caption="$(cat $message_text_file)" \
                    -F parse_mode="HTML" \
                    --connect-timeout 10 \
                    --max-time 30)

                    if test $status -ne 0
                        echo "Error: Failed to connect to Telegram API!"
                        return 1
                    end

                    if not echo $response | jq -e '.ok' >/dev/null
                        echo "Error: Failed to send chunk: "(echo $response | jq -r '.description // "Unknown error"')
                        return 1
                    end
            else
#                 echo "string from argument: $argv"
                set -l message $argv[1]
                echo -e "$message" >> "$body_meesage_text_file"
                if test (uname) = "Darwin"
                    sed -i '' 's#<#-#g' $body_meesage_text_file
                    sed -i '' 's#>#-#g' $body_meesage_text_file
                else
                    sed -i 's#<#-#g' $body_meesage_text_file
                    sed -i 's#>#-#g' $body_meesage_text_file
                end
                cat "$head_message_text_file" > "$message_text_file"
                echo -e "<pre>" >> "$message_text_file"
                cat "$body_meesage_text_file" >> "$message_text_file"
                echo -e "</pre>" >> "$message_text_file"

                # Split file into chunks
                split -b 3800 $message_text_file $splitdir/chunk_
                # find the very last chunk
                set -l last_chunk (ls $splitdir/chunk_* | sort | tail -n1)

                # Send each chunk
                for chunk in $splitdir/chunk_*
                    echo "Sending chunk "(basename $chunk)"..."
                    # 1) First chunk: append closing </pre> if it’s not already there
                    if test $chunk = "$splitdir/chunk_aa"; and not grep -q '</pre>' "$chunk"
                        echo '</pre>' >>"$chunk"
                    end
                    # 2) Middle chunks: wrap in both <pre>…</pre>
                    if test $chunk != "$splitdir/chunk_aa"; and test $chunk != "$last_chunk"
                        echo '<pre>' | cat - "$chunk" >"$chunk.tmp"
                        mv "$chunk.tmp" "$chunk"
                        echo '</pre>' >>"$chunk"
                    end
                    # 3) Last chunk: prepend opening <pre> if it’s not already there
                    if test $chunk = "$last_chunk"; and not grep -q '<pre>' "$chunk"
                        echo '<pre>' | cat - "$chunk" >"$chunk.tmp"
                        mv "$chunk.tmp" "$chunk"
                    end


                    set response (curl -s -X POST "$api_url/bot$token/sendMessage" \
                        -d chat_id="$chat_id" \
                        --data-urlencode text="$(cat $message_text_file)" \
                        -d parse_mode="HTML" \
                        --connect-timeout 10 \
                        --max-time 30)

                    if test $status -ne 0
                        echo "Error: Failed to connect to Telegram API!"
                        return 1
                    end

                    if not echo $response | jq -e '.ok' >/dev/null
                        echo "Error: Failed to send chunk: "(echo $response | jq -r '.description // "Unknown error"')
                        return 1
                    end
                end
            end
        else
            echo "⚠️ no input detected"
        end
    else
        cat >> $body_meesage_text_file
        #echo "string from pipe: $combined"
        # Regular message
        cat "$head_message_text_file" > "$message_text_file"
        echo -e "<pre>" >> "$message_text_file"
        if test (uname) = "Darwin"
            sed -i '' 's#<#-#g' $body_meesage_text_file
            sed -i '' 's#>#-#g' $body_meesage_text_file
        else
            sed -i 's#<#-#g' $body_meesage_text_file
            sed -i 's#>#-#g' $body_meesage_text_file
        end
        cat "$body_meesage_text_file" >> "$message_text_file"
        echo -e "</pre>" >> "$message_text_file"

        # Split file into chunks
        split -b 3800 $message_text_file $splitdir/chunk_
        # find the very last chunk
        set -l last_chunk (ls $splitdir/chunk_* | sort | tail -n1)

        # Send each chunk
        for chunk in $splitdir/chunk_*
            echo "Sending chunk "(basename $chunk)"..."
            # 1) First chunk: append closing </pre> if it’s not already there
            if test $chunk = "$splitdir/chunk_aa"; and not grep -q '</pre>' "$chunk"
                echo '</pre>' >>"$chunk"
            end
            # 2) Middle chunks: wrap in both <pre>…</pre>
            if test $chunk != "$splitdir/chunk_aa"; and test $chunk != "$last_chunk"
                echo '<pre>' | cat - "$chunk" >"$chunk.tmp"
                mv "$chunk.tmp" "$chunk"
                echo '</pre>' >>"$chunk"
            end
            # 3) Last chunk: prepend opening <pre> if it’s not already there
            if test $chunk = "$last_chunk"; and not grep -q '<pre>' "$chunk"
                echo '<pre>' | cat - "$chunk" >"$chunk.tmp"
                mv "$chunk.tmp" "$chunk"
            end

            set response (curl -s -X POST "$api_url/bot$token/sendMessage" \
                -d chat_id="$chat_id" \
                --data-urlencode text="$(cat $chunk)" \
                -d parse_mode="HTML" \
                --connect-timeout 10 \
                --max-time 30)


            if test $status -ne 0
                echo "Error: Failed to connect to Telegram API!"
                return 1
            end

            if not echo $response | jq -e '.ok' >/dev/null
                echo "Error: Failed to send chunk: "(echo $response | jq -r '.description // "Unknown error"')
                return 1
            end
        end
    end
end
