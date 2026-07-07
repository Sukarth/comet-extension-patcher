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

## Support

If this project helps or saves you time, consider supporting my work, as it keeps projects like this free, open source, and maintained:

[![GitHub Sponsors](https://img.shields.io/badge/GitHub%20Sponsors-%E2%9D%A4-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/Sukarth)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-FF5E5B?logo=kofi&logoColor=white)](https://ko-fi.com/sukarth)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-☕-FFDD00?logoColor=black)](https://buymeacoffee.com/sukarth)

Can't donate? Starring the repo ⭐, reporting bugs, and sharing the project help just as much!

---

Made with ❤️ by Sukarth
