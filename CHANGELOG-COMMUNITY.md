# Changelog - Community Fork for Claude Code & Vibe

## Version 1.0.0-community (2025-12-28)

### 🎯 Purpose
This fork makes swift-mcp-server fully functional with MCP clients like **Claude Code** and **Vibe CLI**, fixing critical bugs that prevented 10 out of 15 tools from working.

### 🐛 Critical Bug Fixes

#### Schema Parameter Mismatches (5 tools fixed)
These tools had incomplete JSON schemas that caused "Invalid params" errors:

1. **analyze_project**
   - **Bug:** Schema missing `project_path` parameter
   - **Fix:** Added required `project_path` parameter to schema
   - **Impact:** Tool now accepts project path and returns real analysis

2. **detect_architecture**
   - **Bug:** Schema missing `project_path` parameter
   - **Fix:** Added required `project_path` parameter to schema
   - **Impact:** Tool now correctly identifies MVC, MVVM, VIPER, Custom patterns

3. **analyze_symbol_usage**
   - **Bug:** Schema only had `symbol_name`, handler required both `project_path` AND `symbol_name`
   - **Fix:** Added `project_path` to required parameters
   - **Impact:** Tool now finds symbol occurrences across project

4. **create_project_memory**
   - **Bug:** Schema missing `project_path` parameter
   - **Fix:** Added required `project_path` parameter to schema
   - **Impact:** Tool now captures key symbols and code patterns

5. **generate_migration_plan**
   - **Bug:** Schema only had `target_architecture`, handler required both parameters
   - **Fix:** Added `project_path` parameter and `enum` constraint for valid architecture values
   - **Values:** ["MVC", "MVVM", "VIPER", "Features-based", "Clean Architecture", "Modular", "Custom"]
   - **Impact:** Tool now generates real migration plans with proper architecture validation

#### LSP Tool Implementations (4 tools converted from mocks to real)

6. **find_references**
   - **Bug:** Returned hardcoded fake data (non-existent UserModel.swift)
   - **Fix:** Implemented real symbol extraction and SymbolSearchEngine.findReferences()
   - **Implementation:** Added `extractSymbolAtPosition()` helper to get symbol at line/character
   - **Impact:** Returns actual references from real Swift files

7. **get_definition**
   - **Bug:** Returned hardcoded fake locations
   - **Fix:** Uses real SymbolSearchEngine.findSymbols() to locate definitions
   - **Impact:** Returns actual definition locations for symbols

8. **get_hover_info**
   - **Bug:** Returned generic "class User { let name: String }" examples
   - **Fix:** Uses real SymbolSearchEngine with formatted output (kind, container, detail, location)
   - **Impact:** Returns actual symbol information from project

9. **format_document**
   - **Bug:** Returned fake "// Auto-formatted" comment insertions
   - **Fix:** Returns honest message about requiring external tools (swift-format or SwiftFormat)
   - **Impact:** Users understand real formatting requires external tool integration

#### Helper Functions Added

- **extractSymbolAtPosition(filePath:line:character:)**: Extracts Swift identifier at given position
  - Handles both absolute and relative file paths
  - Expands character-by-character to find full identifier
  - Validates line/character bounds
  - Returns nil gracefully if no symbol found

- **isIdentifierChar(_:)**: Validates Swift identifier characters (letters, numbers, underscores)

### ✅ Testing Results

All tools verified working with **Vibe CLI** and **Claude Code**:

#### Schema-Fixed Tools (verified with real data):
- ✅ analyze_project: Returns 186 files, 54,170 lines, Custom architecture
- ✅ detect_architecture: Correctly identifies "Custom" for StageAssistant project
- ✅ analyze_symbol_usage: Finds real symbol occurrences (1 Swift definition found)
- ✅ create_project_memory: Captures 31 symbols, 44 patterns
- ✅ generate_migration_plan: Generates real migration steps (5 steps, low effort)

#### Previously Working Tools (verified still working):
- ✅ find_symbols: Returns actual Swift symbols from files
- ✅ analyze_pop_usage: Returns protocol-oriented programming metrics
- ✅ intelligent_project_memory: Caches and retrieves project analysis
- ✅ generate_documentation: Creates real README.md with 1572 API items
- ✅ analyze_ios_frameworks: Returns real framework usage (76 UIKit, 28 ViewControllers)
- ✅ generate_template: Creates project templates

#### LSP Tools (converted to real implementations):
- ✅ find_references: No longer returns fake UserModel.swift
- ✅ get_definition: Returns real definition locations
- ✅ get_hover_info: Returns real symbol information
- ✅ format_document: Honestly reports external tool requirement

### 🔍 Known Limitations

1. **Storyboard/XIB Files**: SymbolSearchEngine only searches `.swift` files
   - Impact: Symbol usage counts may be incomplete for UIKit projects
   - Example: CustomUITableView has 13 total occurrences but only 1 found (12 in storyboards missed)

2. **Position-Based Extraction**: LSP tools use regex-based symbol extraction, not compiler-accurate
   - Impact: May have edge cases with complex Swift syntax
   - Alternative: Use SwiftLens MCP server for compiler-accurate analysis

3. **No Real Formatting**: format_document requires external swift-format or SwiftFormat
   - Impact: Cannot format files through MCP
   - Alternative: Use gzaal/swift-mcp-server which integrates real formatters

### 🏗️ Architecture Clarification

The original README claimed "SourceKit-LSP integration," but the actual implementation uses:

- **SymbolSearchEngine**: Regex-based Swift file parsing (REAL, works well)
- **SwiftLanguageServer**: Intended LSP bridge (MOCKED, never implemented)

This fork:
- ✅ Makes all tools use the working SymbolSearchEngine
- ✅ Documents the actual implementation accurately
- ✅ Provides foundation for future real SourceKit-LSP integration

### 📊 Summary

**Before fixes:**
- 5/15 tools broken (schema bugs)
- 4/15 tools mocked (fake data)
- 6/15 tools working (66% functional)

**After fixes:**
- 14/15 tools fully functional (93%)
- 1/15 tool honest about limitation
- 0/15 tools return fake data

### 🙏 Credits

- Original project: [anhptimx/swift-mcp-server](https://github.com/anhptimx/swift-mcp-server)
- Community fixes: Discovered and fixed while testing with Vibe CLI and Claude Code
- Testing environment: Mistral Vibe CLI + LM Studio (local Devstral model)

### 📝 License

MIT License (same as original project)
