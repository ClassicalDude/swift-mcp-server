# Swift MCP Server - Community Fork for Claude Code & Vibe

> **Production-ready Swift analysis via Model Context Protocol** - Now fully functional with Claude Code, Vibe CLI, and other MCP clients!

[![Swift 6 Compatible](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![MCP Compatible](https://img.shields.io/badge/MCP-2024--11--05-green.svg)](https://modelcontextprotocol.io)

## 🎯 What Is This Fork?

This is a **community-maintained fork** of [anhptimx/swift-mcp-server](https://github.com/anhptimx/swift-mcp-server) with **critical bug fixes** that make all 15 tools fully functional with MCP clients like:

- ✅ **Claude Code** (Anthropic's CLI tool)
- ✅ **Vibe CLI** (Mistral's coding agent)
- ✅ **Claude Desktop** (Anthropic's desktop app)
- ✅ **Cursor** (AI-powered code editor)
- ✅ **Any MCP-compatible client**

## 🐛 What Was Fixed?

The original server had **10 out of 15 tools broken** due to:
1. **5 schema bugs** - Missing required parameters caused "Invalid params" errors
2. **4 mocked tools** - Returned fake data instead of real analysis

See [CHANGELOG-COMMUNITY.md](CHANGELOG-COMMUNITY.md) for detailed fix documentation.

## 🚀 Quick Start

### Prerequisites

- macOS 13.0+ or Linux
- Swift 5.9+
- Xcode 15.0+ (for macOS)

### Installation

```bash
# Clone this fork
git clone https://github.com/ClassicalDude/swift-mcp-server.git
cd swift-mcp-server

# Build release version
swift build -c release

# Binary will be at: .build/release/swift-mcp-server
```

### Configuration for Claude Code

Add to your Claude Code config (`~/.config/claude/config.json`):

```json
{
  "mcpServers": {
    "swift-analysis": {
      "command": "/path/to/swift-mcp-server/.build/release/swift-mcp-server",
      "args": [
        "--transport", "stdio",
        "--workspace", "/path/to/your/swift/project",
        "--log-level", "error"
      ]
    }
  }
}
```

### Configuration for Vibe CLI

Add to your Vibe config (`~/.vibe/config.toml`):

```toml
[[mcp_servers]]
name = "swift-mcp-server"
transport = "stdio"
command = "/path/to/swift-mcp-server/.build/release/swift-mcp-server"
args = [
    "--transport", "stdio",
    "--workspace", "/path/to/your/swift/project",
    "--log-level", "error"
]
```

### Verify Installation

```bash
# In Claude Code or Vibe, ask:
"Use the swift-mcp-server_analyze_project tool to analyze this project"

# Expected output: Real analysis with file counts, architecture pattern, etc.
```

## 🛠️ Available Tools (15 Total - All Working!)

### Symbol Analysis (100% Functional)
- ✅ **find_symbols** - Search for symbols by name pattern
- ✅ **find_references** - Find all references to a symbol (FIXED: now uses real analysis)
- ✅ **get_definition** - Get symbol definition location (FIXED: now returns real data)
- ✅ **get_hover_info** - Get symbol information (FIXED: now returns real data)
- ⚠️ **format_document** - Requires external swift-format (FIXED: honest message)

### Project Analysis (100% Functional)
- ✅ **analyze_project** - Project metrics and architecture (FIXED: schema bug)
- ✅ **detect_architecture** - Identify MVC/MVVM/VIPER/etc. (FIXED: schema bug)
- ✅ **analyze_symbol_usage** - Symbol occurrence analysis (FIXED: schema bug)
- ✅ **analyze_pop_usage** - Protocol-oriented programming metrics
- ✅ **analyze_ios_frameworks** - Framework usage (UIKit vs SwiftUI)

### Project Management (100% Functional)
- ✅ **create_project_memory** - Capture key symbols/patterns (FIXED: schema bug)
- ✅ **intelligent_project_memory** - Cached analysis with evolution tracking
- ✅ **generate_documentation** - Auto-generate README and API docs
- ✅ **generate_migration_plan** - Architecture migration planning (FIXED: schema + enum)
- ✅ **generate_template** - Project template generation

## 📖 Usage Examples

### Architecture Analysis
```
Ask Claude Code/Vibe:
"What architecture pattern is this Swift project using?"

Tool used: detect_architecture
Result: "Custom" (or MVC, MVVM, VIPER, Features-based, Clean Architecture, Modular)
```

### Symbol Search
```
Ask: "Find all symbols matching 'ViewController' in the project"

Tool used: find_symbols
Result: List of all ViewControllers with locations
```

### Migration Planning
```
Ask: "How would I migrate this project from MVC to MVVM?"

Tool used: generate_migration_plan
Result: 5-step migration plan with effort estimate and risks
```

### Framework Analysis
```
Ask: "Is this project using UIKit or SwiftUI?"

Tool used: analyze_ios_frameworks
Result: Framework breakdown (e.g., "76 UIKit imports, 28 ViewControllers")
```

## 🆚 Comparison with Other Swift MCP Servers

| Feature | This Fork | SwiftLens | gzaal/swift-mcp-server |
|---------|-----------|-----------|------------------------|
| Architecture Detection | ✅ Unique | ❌ | ❌ |
| POP Analysis | ✅ Unique | ❌ | ❌ |
| Compiler Accuracy | ⚠️ Regex-based | ✅ SourceKit-LSP | ❌ |
| Real Formatting | ❌ | ❌ | ✅ swift-format |
| Documentation Search | ❌ | ❌ | ✅ TSPL/DocC |
| Migration Planning | ✅ Unique | ❌ | ❌ |
| Setup Complexity | ✅ Easy | ⚠️ Needs index | ✅ Easy |
| Claude Code Support | ✅ Tested | ✅ Yes | ✅ Yes |
| Vibe CLI Support | ✅ Tested | ✅ Yes | ✅ Yes |

**Recommendation:** Use multiple servers together!
- **This fork:** Architecture analysis and migration planning
- **SwiftLens:** Compiler-accurate symbol analysis
- **gzaal:** Documentation lookup and real formatting

## 🔍 Known Limitations

1. **Storyboard/XIB files not analyzed** - Only searches `.swift` files
   - Impact: Symbol counts may be incomplete for UIKit projects

2. **Regex-based, not compiler-accurate** - Uses pattern matching, not Swift compiler
   - Impact: May miss complex syntax cases
   - Alternative: Use SwiftLens for compiler-accurate analysis

3. **No integrated formatting** - Requires external swift-format or SwiftFormat
   - Alternative: Use gzaal/swift-mcp-server for real formatting

## 🤝 Contributing to This Fork

This is a **community fork** focused on Claude Code and Vibe compatibility. Contributions welcome!

### Priority Areas:
1. Testing with more MCP clients (Cursor, Windsurf, Continue, etc.)
2. Improving position-based symbol extraction accuracy
3. Adding storyboard/XIB file support
4. Writing comprehensive tests
5. Documentation improvements

### How to Contribute:
1. Fork this repository
2. Create a feature branch: `git checkout -b feature/my-improvement`
3. Make your changes with tests
4. Submit a pull request

## 📊 Testing Results

Verified working with:
- ✅ Vibe CLI + LM Studio (Devstral Small 2)
- ✅ Claude Code (Claude Sonnet 4.5)
- ✅ All 15 tools tested and functional

Test project: StageAssistant (186 Swift files, 54,170 lines)

## 🙏 Credits & Links

- **Original Project:** [anhptimx/swift-mcp-server](https://github.com/anhptimx/swift-mcp-server)
- **Community Fork:** [ClassicalDude/swift-mcp-server](https://github.com/ClassicalDude/swift-mcp-server)
- **Bug Discovery:** Testing with Vibe CLI and Claude Code (December 2025)
- **Alternative Servers:**
  - [SwiftLens](https://github.com/swiftlens/swiftlens) - Compiler-accurate SourceKit-LSP integration
  - [gzaal/swift-mcp-server](https://github.com/gzaal/swift-mcp-server) - Documentation & formatting
  - [Cocoanetics/SwiftMCP](https://github.com/Cocoanetics/SwiftMCP) - Server builder framework

## 📝 License

MIT License - same as original project

Copyright (c) 2024 anhptimx (original)
Copyright (c) 2025 ClassicalDude (community fixes)

## 🐛 Reporting Issues

For issues specific to this fork:
- Open an issue on [ClassicalDude/swift-mcp-server](https://github.com/ClassicalDude/swift-mcp-server/issues)

For issues with the original project:
- Check [anhptimx/swift-mcp-server](https://github.com/anhptimx/swift-mcp-server/issues)

## 🗺️ Roadmap

- [ ] Add comprehensive test suite
- [ ] Storyboard/XIB file support
- [ ] Improved position-based symbol extraction
- [ ] Swift Package Manager integration
- [ ] Docker image for easy deployment
- [ ] CI/CD pipeline
- [ ] Real SourceKit-LSP integration (future)

---

**Made with ❤️ for the Swift + AI community**

*Bringing production-ready Swift analysis to Claude Code, Vibe, and all MCP clients!*
