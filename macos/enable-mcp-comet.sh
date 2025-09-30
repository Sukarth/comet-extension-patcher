#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Comet MCP Extension Enabler for macOS
# -----------------------------------------------------------------------------
# Enables MCP extension functionality in Comet browser by creating a wrapper
# shortcut app that patches the extension scripting settings before launch.
# Based on the original Comet patcher by theJayTea
# -----------------------------------------------------------------------------

set -euo pipefail

# ----------------------------- Config & Paths --------------------------------
APP_NAME="Comet Browser - MCP Enhanced"
BUNDLE_ID="app.mcp.cometpatched"
TARGET_DIR="${HOME}/Applications"
APP_DIR="${TARGET_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RES_DIR="${CONTENTS_DIR}/Resources"
ICON_NAME="app.icns"
INSTALL_LOG_PREFIX="[MCP Installer]"

# ----------------------------- Pretty Printers --------------------------------
msg() { printf "%s %s\\n" "$INSTALL_LOG_PREFIX" "$*" >&2; }
ok() { printf "✅ %s\\n" "$*" >&2; }
warn() { printf "⚠️  %s\\n" "$*" >&2; }
err() { printf "❌ %s\\n" "$*" >&2; }

# ------------------------------ Intro Banner ----------------------------------
print_intro() {
    printf "\\n" >&2
    printf "============================================================\\n" >&2
    printf " MCP Extension Enabler for Comet Browser (macOS)\\n" >&2
    printf "============================================================\\n\\n" >&2
    printf "This script enables MCP (Model Context Protocol) extensions\\n" >&2
    printf "to work in Comet browser by creating a patched launcher.\\n" >&2
    printf "\\n" >&2
    printf "After installation, use the 'MCP Enhanced' launcher instead\\n" >&2
    printf "of the regular Comet to enable extension functionality.\\n" >&2
    printf "\\n" >&2
    printf "============================================================\\n\\n" >&2
    printf "⚙️ Setup Log:" >&2
    printf "\\n\\n" >&2
}

# -------------------------- Find Comet.app (friendly) -------------------------
find_comet_app() {
    msg "Looking for Comet.app in the usual places…"
    
    for candidate in "/Applications/Comet.app" "${HOME}/Applications/Comet.app"; do
        if [[ -d "$candidate" ]]; then
            ok "Found Comet installed at: $candidate"
            echo "$candidate"
            return 0
        fi
    done
    
    warn "Comet.app wasn't found in /Applications or ~/Applications."
    msg "Please select it in the dialog… (Select the real Comet.app)"
    
    local chosen
    set +e
    chosen="$(osascript <<'AS'
try
    set theApp to choose application with prompt "Select Comet.app"
    POSIX path of (theApp as alias)
on error
    return ""
end try
AS
    )"
    local rc=$?
    set -e
    
    if [[ $rc -ne 0 || -z "$chosen" || ! -d "${chosen%/}" ]]; then
        err "No valid app selected. Exiting."
        exit 1
    fi
    
    ok "Using Comet at: ${chosen%/}"
    echo "${chosen%/}"
}

# --------------------------------- Run! ---------------------------------------
print_intro

# Capture only the path (no log noise)
COMET_APP_PATH="$(find_comet_app)"
COMET_APP_PATH="${COMET_APP_PATH%/}"
ICON_SRC="${COMET_APP_PATH}/Contents/Resources/app.icns"

# --------------------------- Build .app bundle --------------------------------
msg "Creating MCP-enhanced wrapper app at: ${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RES_DIR}"

# Minimal Info.plist for a runnable Application bundle
cat > "${CONTENTS_DIR}/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>${ICON_NAME%.*}</string>
</dict>
</plist>
PLIST

# Copy Comet's icon for the shortcut
if [[ -f "${ICON_SRC}" ]]; then
    cp -f "${ICON_SRC}" "${RES_DIR}/${ICON_NAME}" || true
    ok "Borrowed Comet's icon for the MCP launcher"
else
    warn "Couldn't find Comet's icon at: ${ICON_SRC}"
    warn "Proceeding without a custom icon."
fi

# ----------------------- Launcher script inside the app -----------------------
cat > "${MACOS_DIR}/${APP_NAME}" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

# (Installer will substitute this path)
COMET_APP_PATH="@@COMET_APP_PATH@@"

USER_DATA_DIR="${HOME}/Library/Application Support/Comet"
LOCAL_STATE="${USER_DATA_DIR}/Local State"
BACKUP="${LOCAL_STATE}.mcp.bak"
LOG="${HOME}/Library/Logs/Comet-MCP-Enhanced.log"

# ----------------------------- Helpers ---------------------------------------
log() { printf "[%s] %s\\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG"; }

is_running() { 
    osascript -e 'application "Comet" is running' 2>/dev/null | grep -qi true; 
}

ensure_dirs() {
    mkdir -p "${USER_DATA_DIR}"
    mkdir -p "$(dirname "$LOG")"
    : > "$LOG" || true
}

backup_local_state() {
    if [[ -f "$LOCAL_STATE" ]]; then
        cp -f "$LOCAL_STATE" "$BACKUP" || true
    else
        # Create a minimal JSON file so sed/grep have something to work with
        printf '{}' > "$LOCAL_STATE"
    fi
}

verify_true() {
    grep -Eq '"Allow-external-extensions-scripting-on-NTP"[[:space:]]*:[[:space:]]*true' "$LOCAL_STATE"
}

patch_settings() {
    local before after
    before="$(grep -Eo '"Allow-external-extensions-scripting-on-NTP"[[:space:]]*:[[:space:]]*(true|false)' "$LOCAL_STATE" || true)"
    
    # Multiple MCP-friendly patches
    /usr/bin/sed -E -i '' \
        -e 's/"Allow-external-extensions-scripting-on-NTP"[[:space:]]*:[[:space:]]*false/"Allow-external-extensions-scripting-on-NTP": true/g' \
        -e 's/"developer_mode_disabled"[[:space:]]*:[[:space:]]*true/"developer_mode_disabled": false/g' \
        -e 's/"extension_install_allowlist_enabled"[[:space:]]*:[[:space:]]*true/"extension_install_allowlist_enabled": false/g' \
        "$LOCAL_STATE"
    
    after="$(grep -Eo '"Allow-external-extensions-scripting-on-NTP"[[:space:]]*:[[:space:]]*(true|false)' "$LOCAL_STATE" || true)"
    log "Settings updated: ${before:-none} -> ${after:-patched}"
}

ask_quit_if_running() {
    if is_running; then
        osascript <<'AS' || true
try
    display dialog "Comet is currently running. Quit and relaunch with MCP extension support?" buttons {"Cancel", "Quit & Relaunch"} default button "Quit & Relaunch" with icon caution
    tell application "Comet" to quit
on error
end try
AS
        # Wait up to ~10s for Comet to quit
        i=0
        while is_running && [ $i -lt 100 ]; do
            sleep 0.1
            i=$((i+1))
        done
    fi
}

launch_comet() {
    if [[ -d "$COMET_APP_PATH" ]]; then
        log "Launching Comet with MCP extension support enabled."
        open "$COMET_APP_PATH"
    else
        log "Launching Comet via app name."
        open -a "Comet"
    fi
}

main() {
    log "=== Comet MCP Extension Launch Begin ==="
    ensure_dirs
    ask_quit_if_running
    backup_local_state
    patch_settings
    
    if verify_true; then
        log "✅ MCP extension settings verified before launch."
        launch_comet
    else
        log "❌ Verification failed; not launching Comet."
        log "Check your Local State file and try again."
        exit 1
    fi
    
    log "=== Comet MCP Extension Launch End ==="
}

main "$@"
LAUNCHER

# ---------------------- Substitute the Comet path safely ----------------------
escaped_path="$(printf '%s' "${COMET_APP_PATH}" | sed -e 's/[\/&]/\\&/g')"
sed -E -i '' "s/@@COMET_APP_PATH@@/${escaped_path}/g" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# ----------------------------- Success Message --------------------------------
printf "\\n" >&2
printf "============================================================\\n\\n" >&2
ok "✅ MCP Extension Support Enabled!"
printf "\\n" >&2
printf "🚀 What's next:\\n" >&2
printf "   1. Start MCP Bridge: npx perplexity-web-mcp-bridge\\n" >&2
printf "   2. Install MCP Extension in Comet (developer mode)\\n" >&2
printf "   3. Launch via Spotlight: '%s'\\n" "${APP_NAME}" >&2
printf "\\n" >&2
printf "📁 Your patched launcher: %s\\n" "${TARGET_DIR}" >&2
printf "🔗 Extension download: https://github.com/Sukarth/perplexity-web-mcp-extension\\n" >&2
printf "\\n" >&2
printf "Each launch will automatically enable MCP extension support!\\n" >&2
printf "============================================================\\n" >&2