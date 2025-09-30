# Comet Extension Patcher

Allows extensions to work in Perplexity.ai pages in Perplexity's Comet browser.

## Quick Install

### Windows
```
irm "https://raw.githubusercontent.com/sukarth/comet-extension-patcher/main/windows/enable-mcp-comet.ps1" | iex
```

### macOS
```
curl -fsSL "https://raw.githubusercontent.com/sukarth/comet-extension-patcher/main/macos/enable-mcp-comet.sh" | bash
```

## What This Does

- Creates a patched Comet launcher that enables extension scripting
- Allows browser extensions to work on Perplexity.ai pages
- Safe: Creates backups and doesn't modify Comet directly

## Next Steps

1. **Start MCP Bridge**: `npx perplexity-web-mcp-bridge`
2. **Install Extension**: [Download MCP Extension](https://github.com/Sukarth/perplexity-web-mcp-extension)
3. **Launch**: Use the "MCP Enhanced" shortcut instead of regular Comet

## Troubleshooting

- Make sure MCP Bridge is running
- Use the patched launcher, not the original Comet icon
- Enable developer mode in Comet extensions page

## Credits

- Original concept by [Pham Ngoc Duong](https://github.com/pnd280)
- macOS implementation inspired by [theJayTea](https://github.com/theJayTea)

---

Made with ❤️ by Sukarth