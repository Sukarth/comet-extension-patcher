# Troubleshooting Guide

## Common Issues

### Windows

#### "Execution policy" error
```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Script won't run
- Right-click the PowerShell file and select "Run with PowerShell"
- Or run from PowerShell: `powershell -ExecutionPolicy Bypass -File script.ps1`

#### Comet not found
- Make sure Comet browser is installed
- Try running Comet once normally to create necessary folders
- Use the file dialog to manually select `comet.exe`

#### Extensions still don't work
- Use the "MCP Enhanced" shortcut, not the regular Comet icon
- Close all Comet windows and restart using the patched shortcut
- Check that developer mode is enabled in `chrome://extensions/`

### macOS

#### "Cannot be opened because the developer cannot be verified"
```bash
chmod +x enable-mcp-comet.sh
xattr -d com.apple.quarantine enable-mcp-comet.sh
```

#### Comet.app not found
- Install Comet browser from Perplexity
- Make sure it's in `/Applications` or `~/Applications`
- Use the file dialog to select the correct Comet.app

#### Permission denied errors
```bash
sudo bash enable-mcp-comet.sh
```

#### App won't launch
- Right-click the "MCP Enhanced" app and select "Open"
- Check Console app for error messages
- Verify Comet is properly installed

## Extension Setup

### Installing the MCP Extension
1. Download from: https://github.com/Sukarth/perplexity-web-mcp-extension
2. Extract the ZIP file
3. Open Comet using the "MCP Enhanced" launcher
4. Navigate to `chrome://extensions/`
5. Enable "Developer mode" (top right toggle)
6. Click "Load unpacked" and select the extracted folder

### Starting the MCP Bridge
The MCP extension requires a bridge server running:
```bash
npx perplexity-web-mcp-bridge
```

### Verifying Everything Works
1. Open perplexity.ai in the MCP-enhanced Comet
2. Look for the MCP extension icon in the toolbar
3. Click the icon to check connection status
4. Try using MCP tools in a Perplexity conversation

## Advanced Debugging

### Check Browser Console
1. Press F12 to open developer tools
2. Go to the Console tab
3. Look for extension-related errors
4. Check for WebSocket connection issues

### Verify Settings Applied
**Windows:** Check `%LOCALAPPDATA%\Perplexity\Comet\User Data\Local State`
**macOS:** Check `~/Library/Application Support/Comet/Local State`

Look for:
```json
"Allow-external-extensions-scripting-on-NTP": true
```

### Log Files
**Windows:** PowerShell output during execution
**macOS:** `~/Library/Logs/Comet-MCP-Enhanced.log`

## Still Having Issues?

1. **Check Requirements:**
   - Comet browser installed and working
   - MCP bridge server running on port 54319
   - Extension properly loaded in developer mode

2. **Reset and Retry:**
   - Close all Comet windows
   - Run the patcher again
   - Restart using the "MCP Enhanced" launcher

3. **Get Help:**
   - Open an issue: https://github.com/Sukarth/comet-extension-patcher/issues
   - Include your OS version, error messages, and steps tried
   - Check existing issues for similar problems