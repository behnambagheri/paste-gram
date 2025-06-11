# Changelog

## [v1.0.0] - 2025-06-11

### Added
- Telegram token, chat ID, and API endpoint pulled from env vars
- Supports three input modes: piped, direct string, and file input
- Optional headers: hostname (`PASTEGRAM_HOSTNAME=true`) and command (`PASTEGRAM_LAST_COMMAND=true`)
- HTML formatting for message headers and content blocks
- Automatic escaping of `<` and `>` characters
- File upload support with full file path and filename in caption
- Chunked message sending (Telegram 4096-char limit safe)

### Fixed
- Error handling for Telegram API and curl failures
- Corrected logic to prevent malformed HTML in message chunks
