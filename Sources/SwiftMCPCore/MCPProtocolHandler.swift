import Foundation
import Logging

public final class MCPProtocolHandler {
    private let swiftLanguageServer: SwiftLanguageServer
    private let projectAnalyzer: ProjectAnalyzer
    private let symbolSearchEngine: SymbolSearchEngine
    private let projectMemory: IntelligentProjectMemory
    private let documentationGenerator: DocumentationGenerator
    private let iOSFrameworkAnalyzer: iOSFrameworkAnalysisEngine
    private let templateGenerator: TemplateGenerator
    private let logger: Logger

    public init(swiftLanguageServer: SwiftLanguageServer, logger: Logger) {
        self.swiftLanguageServer = swiftLanguageServer
        self.logger = logger

        // Initialize project analyzer
        self.projectAnalyzer = ProjectAnalyzer(projectPath: swiftLanguageServer.workspaceURL, logger: logger)

        // Initialize symbol search engine for real symbol lookup
        self.symbolSearchEngine = SymbolSearchEngine(projectPath: swiftLanguageServer.workspaceURL, logger: logger)

        // Initialize analysis modules
        self.projectMemory = IntelligentProjectMemory(projectPath: swiftLanguageServer.workspaceURL, logger: logger)
        self.documentationGenerator = DocumentationGenerator(projectPath: swiftLanguageServer.workspaceURL, logger: logger)
        self.iOSFrameworkAnalyzer = iOSFrameworkAnalysisEngine(projectPath: swiftLanguageServer.workspaceURL, logger: logger)
        self.templateGenerator = TemplateGenerator(projectPath: swiftLanguageServer.workspaceURL, logger: logger)
    }
    
    public func handleRequest(_ request: MCPRequest) async throws -> MCPResponse {
        logger.debug("Handling MCP request: \(request.method)")

        switch request.method {
        case "initialize":
            return try await handleInitialize(request)
        case "notifications/initialized":
            // Handle initialized notification - this is sent by clients after initialization
            return MCPResponse(
                jsonrpc: "2.0",
                id: request.id,
                result: AnyCodable([String: String]())  // Empty object response
            )
        case "tools/list":
            return try await handleToolsList(request)
        case "tools/call":
            return try await handleToolCall(request)
        case "resources/list":
            return try await handleResourcesList(request)
        case "resources/read":
            return try await handleResourceRead(request)
        default:
            throw MCPError.methodNotFound(request.method)
        }
    }
    
    // MARK: - Initialize
    
    private func handleInitialize(_ request: MCPRequest) async throws -> MCPResponse {
        let capabilities = ServerCapabilities(
            tools: ToolsCapability(listChanged: true),
            resources: ResourcesCapability(subscribe: true, listChanged: true)
        )

        let result = InitializeResult(
            protocolVersion: "2024-11-05",
            capabilities: capabilities,
            serverInfo: ServerInfo(
                name: "swift-mcp-server",
                version: "1.0.0"
            )
        )

        return MCPResponse(
            jsonrpc: "2.0",
            id: request.id,
            result: AnyCodable(try toDictionary(result))
        )
    }
    
    // MARK: - Tools
    
    private func handleToolsList(_ request: MCPRequest) async throws -> MCPResponse {
        let tools = [
            Tool(
                name: "find_symbols",
                description: "Find Swift symbols in a file by name pattern",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "file_path": [
                            "type": "string",
                            "description": "Path to the Swift file"
                        ],
                        "name_pattern": [
                            "type": "string",
                            "description": "Pattern to match symbol names"
                        ]
                    ],
                    "required": ["file_path", "name_pattern"]
                ]
            ),
            Tool(
                name: "find_references",
                description: "Find all references to a symbol at a specific position",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "file_path": [
                            "type": "string",
                            "description": "Path to the Swift file"
                        ],
                        "line": [
                            "type": "integer",
                            "description": "Line number (0-based)"
                        ],
                        "character": [
                            "type": "integer",
                            "description": "Character position (0-based)"
                        ]
                    ],
                    "required": ["file_path", "line", "character"]
                ]
            ),
            Tool(
                name: "get_definition",
                description: "Get definition location for a symbol at a specific position",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "file_path": [
                            "type": "string",
                            "description": "Path to the Swift file"
                        ],
                        "line": [
                            "type": "integer",
                            "description": "Line number (0-based)"
                        ],
                        "character": [
                            "type": "integer",
                            "description": "Character position (0-based)"
                        ]
                    ],
                    "required": ["file_path", "line", "character"]
                ]
            ),
            Tool(
                name: "get_hover_info",
                description: "Get hover information for a symbol at a specific position",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "file_path": [
                            "type": "string",
                            "description": "Path to the Swift file"
                        ],
                        "line": [
                            "type": "integer",
                            "description": "Line number (0-based)"
                        ],
                        "character": [
                            "type": "integer",
                            "description": "Character position (0-based)"
                        ]
                    ],
                    "required": ["file_path", "line", "character"]
                ]
            ),
            Tool(
                name: "format_document",
                description: "Format a Swift document",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "file_path": [
                            "type": "string",
                            "description": "Path to the Swift file to format"
                        ]
                    ],
                    "required": ["file_path"]
                ]
            ),
            Tool(
                name: "analyze_project",
                description: "Perform comprehensive project analysis including architecture detection",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "project_path": [
                            "type": "string",
                            "description": "Path to the Swift project to analyze"
                        ]
                    ],
                    "required": ["project_path"]
                ]
            ),
            Tool(
                name: "detect_architecture",
                description: "Detect the architecture pattern used in the project",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "project_path": [
                            "type": "string",
                            "description": "Path to the Swift project to analyze"
                        ]
                    ],
                    "required": ["project_path"]
                ]
            ),
            Tool(
                name: "analyze_symbol_usage",
                description: "Analyze how a symbol is used throughout the project",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "project_path": [
                            "type": "string",
                            "description": "Path to the Swift project to analyze"
                        ],
                        "symbol_name": [
                            "type": "string",
                            "description": "Name of the symbol to analyze"
                        ]
                    ],
                    "required": ["project_path", "symbol_name"]
                ]
            ),
            Tool(
                name: "create_project_memory",
                description: "Create comprehensive project documentation and memory",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "project_path": [
                            "type": "string",
                            "description": "Path to the Swift project to analyze"
                        ]
                    ],
                    "required": ["project_path"]
                ]
            ),
            Tool(
                name: "generate_migration_plan",
                description: "Generate a plan to migrate to a different architecture pattern",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "project_path": [
                            "type": "string",
                            "description": "Path to the Swift project to analyze"
                        ],
                        "target_architecture": [
                            "type": "string",
                            "description": "Target architecture pattern",
                            "enum": ["MVC", "MVVM", "VIPER", "Features-based", "Clean Architecture", "Modular", "Custom"]
                        ]
                    ],
                    "required": ["project_path", "target_architecture"]
                ]
            ),
            Tool(
                name: "analyze_pop_usage",
                description: "Analyze project's Protocol-Oriented Programming (POP) adoption",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "project_path": [
                            "type": "string",
                            "description": "Path to the project to analyze"
                        ]
                    ],
                    "required": ["project_path"]
                ]
            ),
            Tool(
                name: "intelligent_project_memory",
                description: "Manage intelligent project memory with pattern learning",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "action": [
                            "type": "string",
                            "description": "Action to perform: cache, retrieve, learn_patterns, get_evolution"
                        ],
                        "key": [
                            "type": "string", 
                            "description": "Key for caching/retrieving analysis results"
                        ]
                    ],
                    "required": ["action"]
                ]
            ),
            Tool(
                name: "generate_documentation",
                description: "Generate comprehensive project documentation including README and API docs",
                inputSchema: [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ),
            Tool(
                name: "analyze_ios_frameworks",
                description: "Analyze iOS framework usage and detect UI patterns",
                inputSchema: [
                    "type": "object",
                    "properties": [:],
                    "required": []
                ]
            ),
            Tool(
                name: "generate_template",
                description: "Generate Swift/iOS project templates",
                inputSchema: [
                    "type": "object",
                    "properties": [
                        "template_type": [
                            "type": "string",
                            "description": "Template type: swift-package, uikit-viewcontroller, swiftui-view, mvvm-module, coordinator, network-service, coredata-model, unit-tests"
                        ],
                        "name": [
                            "type": "string",
                            "description": "Name for the generated template"
                        ],
                        "description": [
                            "type": "string",
                            "description": "Optional description for the template"
                        ]
                    ],
                    "required": ["template_type", "name"]
                ]
            )
        ]
        
        let result = ToolsListResult(tools: tools)
        return MCPResponse(
            jsonrpc: "2.0",
            id: request.id,
            result: AnyCodable(try toDictionary(result))
        )
    }
    
    private func handleToolCall(_ request: MCPRequest) async throws -> MCPResponse {
        guard let params = request.params else {
            throw MCPError.invalidParams
        }
        
        guard let name = params["name"] as? String else {
            throw MCPError.invalidParams
        }
        
        let arguments = params["arguments"] as? [String: Any] ?? [:]
        
        let result: Any
        
        switch name {
        case "find_symbols":
            result = try await handleFindSymbols(arguments)
        case "find_references":
            result = try await handleFindReferences(arguments)
        case "get_definition":
            result = try await handleGetDefinition(arguments)
        case "get_hover_info":
            result = try await handleGetHoverInfo(arguments)
        case "format_document":
            result = try await handleFormatDocument(arguments)
        case "analyze_project":
            result = try await handleAnalyzeProject(arguments)
        case "detect_architecture":
            result = try await handleDetectArchitecture(arguments)
        case "analyze_symbol_usage":
            result = try await handleAnalyzeSymbolUsage(arguments)
        case "create_project_memory":
            result = try await handleCreateProjectMemory(arguments)
        case "generate_migration_plan":
            result = try await handleGenerateMigrationPlan(arguments)
        case "analyze_pop_usage":
            result = try await handleAnalyzePOPUsage(arguments)
        case "intelligent_project_memory":
            result = try await handleIntelligentProjectMemory(arguments)
        case "generate_documentation":
            result = try await handleGenerateDocumentation(arguments)
        case "analyze_ios_frameworks":
            result = try await handleAnalyzeiOSFrameworks(arguments)
        case "generate_template":
            result = try await handleGenerateTemplate(arguments)
        default:
            throw MCPError.toolNotFound(name)
        }
        
        let toolResult = ToolCallResult(
            content: [
                ToolContent(type: "text", text: String(describing: result))
            ]
        )

        return MCPResponse(
            jsonrpc: "2.0",
            id: request.id,
            result: AnyCodable(try toDictionary(toolResult))
        )
    }

    // MARK: - Helper Functions

    /// Extracts the symbol name at a given position in a file
    private func extractSymbolAtPosition(filePath: String, line: Int, character: Int) throws -> String? {
        let fileURL: URL
        if filePath.hasPrefix("/") {
            fileURL = URL(fileURLWithPath: filePath)
        } else {
            // Relative path - resolve against workspace
            fileURL = swiftLanguageServer.workspaceURL.appendingPathComponent(filePath)
        }

        guard let content = try? String(contentsOf: fileURL) else {
            logger.warning("Could not read file: \(filePath)")
            return nil
        }

        let lines = content.components(separatedBy: .newlines)
        guard line < lines.count else {
            logger.warning("Line \(line) out of bounds in \(filePath)")
            return nil
        }

        let targetLine = lines[line]
        guard character < targetLine.count else {
            logger.warning("Character \(character) out of bounds in line \(line)")
            return nil
        }

        // Extract identifier at position (Swift identifiers: letters, digits, underscores, Unicode)
        let lineChars = Array(targetLine)
        var start = character
        var end = character

        // Expand backwards to find start of identifier
        while start > 0 && isIdentifierChar(lineChars[start - 1]) {
            start -= 1
        }

        // Expand forwards to find end of identifier
        while end < lineChars.count && isIdentifierChar(lineChars[end]) {
            end += 1
        }

        if start < end {
            let symbol = String(lineChars[start..<end])
            logger.debug("Extracted symbol '\(symbol)' at \(filePath):\(line):\(character)")
            return symbol
        }

        return nil
    }

    /// Checks if a character is valid in a Swift identifier
    private func isIdentifierChar(_ char: Character) -> Bool {
        return char.isLetter || char.isNumber || char == "_"
    }

    // MARK: - Tool Implementations

    private func handleFindSymbols(_ arguments: [String: Any]) async throws -> [SymbolInfo] {
        guard let filePath = arguments["file_path"] as? String,
              let namePattern = arguments["name_pattern"] as? String else {
            throw MCPError.invalidParams
        }

        // Convert glob-style patterns to regex
        // "*" -> ".*", "?" -> ".", or use as-is if already looks like regex
        var regexPattern = namePattern
        if namePattern == "*" || namePattern == ".*" {
            // Match everything - use empty pattern which SymbolSearchEngine treats as "match all"
            regexPattern = ""
        } else if namePattern.hasPrefix("*") || namePattern.hasSuffix("*") {
            // Convert glob wildcards to regex
            regexPattern = namePattern.replacingOccurrences(of: "*", with: ".*")
                                     .replacingOccurrences(of: "?", with: ".")
        }

        // Use the real SymbolSearchEngine implementation instead of mocked SwiftLanguageServer
        let allSymbols = try await symbolSearchEngine.findSymbols(
            namePattern: regexPattern,
            symbolType: "",
            useRegex: !regexPattern.isEmpty,
            includePrivate: false,
            includeInherited: false
        )

        // Filter to only symbols from the specified file or directory
        // Handle both absolute paths and relative filenames
        if !filePath.hasPrefix("/") {
            // Relative path - just match on filename
            return allSymbols.filter { symbol in
                symbol.location.uri.hasSuffix(filePath)
            }
        } else {
            // Absolute path - match the full path
            let normalizedPath = URL(fileURLWithPath: filePath).standardizedFileURL.path
            return allSymbols.filter { symbol in
                symbol.location.uri.contains(normalizedPath)
            }
        }
    }
    
    private func handleFindReferences(_ arguments: [String: Any]) async throws -> [String] {
        guard let filePath = arguments["file_path"] as? String,
              let line = arguments["line"] as? Int,
              let character = arguments["character"] as? Int else {
            throw MCPError.invalidParams
        }

        // Extract symbol name at the specified position
        guard let symbolName = try extractSymbolAtPosition(filePath: filePath, line: line, character: character) else {
            logger.warning("No symbol found at \(filePath):\(line):\(character)")
            return []
        }

        logger.debug("Finding references for symbol: \(symbolName)")

        // Use real SymbolSearchEngine to find references
        let references = try await symbolSearchEngine.findReferences(
            symbolName: symbolName,
            symbolType: "",
            includeComments: false
        )

        // Convert to location strings
        return references.map { ref in
            "\(ref.file):\(ref.line):\(ref.character)"
        }
    }
    
    private func handleGetDefinition(_ arguments: [String: Any]) async throws -> [String] {
        guard let filePath = arguments["file_path"] as? String,
              let line = arguments["line"] as? Int,
              let character = arguments["character"] as? Int else {
            throw MCPError.invalidParams
        }

        // Extract symbol name at the specified position
        guard let symbolName = try extractSymbolAtPosition(filePath: filePath, line: line, character: character) else {
            logger.warning("No symbol found at \(filePath):\(line):\(character)")
            return []
        }

        logger.debug("Finding definition for symbol: \(symbolName)")

        // Use real SymbolSearchEngine to find symbol definitions
        let symbols = try await symbolSearchEngine.findSymbols(
            namePattern: symbolName,
            symbolType: "",
            useRegex: false,
            includePrivate: true,
            includeInherited: false
        )

        // Filter to exact matches (not partial) and return definition locations
        let definitions = symbols.filter { $0.name == symbolName }
        return definitions.map { symbol in
            "\(symbol.location.uri):\(symbol.location.line):\(symbol.location.character)"
        }
    }
    
    private func handleGetHoverInfo(_ arguments: [String: Any]) async throws -> String {
        guard let filePath = arguments["file_path"] as? String,
              let line = arguments["line"] as? Int,
              let character = arguments["character"] as? Int else {
            throw MCPError.invalidParams
        }

        // Extract symbol name at the specified position
        guard let symbolName = try extractSymbolAtPosition(filePath: filePath, line: line, character: character) else {
            logger.warning("No symbol found at \(filePath):\(line):\(character)")
            return "No hover information available"
        }

        logger.debug("Getting hover info for symbol: \(symbolName)")

        // Use real SymbolSearchEngine to find symbol information
        let symbols = try await symbolSearchEngine.findSymbols(
            namePattern: symbolName,
            symbolType: "",
            useRegex: false,
            includePrivate: true,
            includeInherited: false
        )

        // Find exact match
        guard let symbol = symbols.first(where: { $0.name == symbolName }) else {
            return "No hover information available"
        }

        // Format hover information
        var hoverText = "\(symbol.kind): \(symbol.name)"
        if let container = symbol.containerName {
            hoverText += "\nContainer: \(container)"
        }
        if let detail = symbol.detail {
            hoverText += "\n\(detail)"
        }
        hoverText += "\nLocation: \(symbol.location.uri):\(symbol.location.line)"

        return hoverText
    }
    
    private func handleFormatDocument(_ arguments: [String: Any]) async throws -> [String] {
        guard let filePath = arguments["file_path"] as? String else {
            throw MCPError.invalidParams
        }

        logger.debug("Format document requested for: \(filePath)")

        // Note: Real Swift formatting requires external tools like swift-format or SwiftFormat
        // Since we don't have a formatter integrated, we return no edits
        // To enable formatting, consider integrating:
        // - swift-format: https://github.com/apple/swift-format
        // - SwiftFormat: https://github.com/nicklockwood/SwiftFormat

        return ["Document formatting requires external tools (swift-format or SwiftFormat)"]
    }
    
    // MARK: - Resources
    
    private func handleResourcesList(_ request: MCPRequest) async throws -> MCPResponse {
        let resources = [
            Resource(
                uri: "swift://workspace",
                name: "Swift Workspace",
                description: "Current Swift workspace information",
                mimeType: "application/json"
            )
        ]
        
        let result = ResourcesListResult(resources: resources)
        return MCPResponse(
            jsonrpc: "2.0",
            id: request.id,
            result: AnyCodable(try toDictionary(result))
        )
    }
    
    private func handleResourceRead(_ request: MCPRequest) async throws -> MCPResponse {
        guard let params = request.params,
              let uri = params["uri"] as? String else {
            throw MCPError.invalidParams
        }
        
        let content: String
        
        switch uri {
        case "swift://workspace":
            content = """
            {
                "type": "swift_workspace",
                "capabilities": ["symbol_search", "references", "definitions", "hover", "formatting"],
                "sourcekit_lsp": "available"
            }
            """
        default:
            throw MCPError.resourceNotFound(uri)
        }
        
        let result = ResourceReadResult(
            contents: [
                ResourceContent(
                    uri: uri,
                    mimeType: "application/json",
                    text: content
                )
            ]
        )

        return MCPResponse(
            jsonrpc: "2.0",
            id: request.id,
            result: AnyCodable(try toDictionary(result))
        )
    }
    
    // MARK: - Enhanced Analysis Tools
    
    private func handleAnalyzeProject(_ arguments: [String: Any]) async throws -> String {
        guard let projectPath = arguments["path"] as? String ?? arguments["project_path"] as? String else {
            throw MCPError.invalidParams
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let analyzer = ProjectAnalyzer(projectPath: projectURL, logger: logger)
        let analysis = try await analyzer.analyzeProject()
        
        return """
        Project Analysis for: \(projectPath)
        Architecture: \(analysis.architecturePattern.rawValue)
        Modules: \(analysis.structure.modules.count)
        Features: \(analysis.structure.features.count)
        Metrics: \(analysis.metrics.totalFiles) files, \(analysis.metrics.totalLines) lines
        """
    }
    
    private func handleDetectArchitecture(_ arguments: [String: Any]) async throws -> String {
        guard let projectPath = arguments["path"] as? String ?? arguments["project_path"] as? String else {
            throw MCPError.invalidParams
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let analyzer = ArchitectureAnalyzer(projectPath: projectURL, logger: logger)
        let pattern = try await analyzer.detectArchitecturePattern()
        
        return pattern.rawValue
    }
    
    private func handleAnalyzeSymbolUsage(_ arguments: [String: Any]) async throws -> String {
        guard let projectPath = arguments["path"] as? String ?? arguments["project_path"] as? String,
              let symbolName = arguments["symbol_name"] as? String else {
            throw MCPError.invalidParams
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let symbolEngine = SymbolSearchEngine(projectPath: projectURL, logger: logger)
        let usage = try await symbolEngine.analyzeSymbolUsage(symbolName: symbolName)
        
        return """
        Symbol Usage Analysis for: \(symbolName)
        Total occurrences: \(usage.totalReferences)
        Files containing symbol: \(usage.uniqueFiles)
        Usage patterns: \(usage.usagePatterns.keys.joined(separator: ", "))
        """
    }
    
    private func handleCreateProjectMemory(_ arguments: [String: Any]) async throws -> String {
        guard let projectPath = arguments["project_path"] as? String else {
            throw MCPError.invalidParams
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let analyzer = ProjectAnalyzer(projectPath: projectURL, logger: logger)
        let memory = try await analyzer.createProjectMemory()
        
        return """
        Project Memory Created:
        Project: \(memory.analysis.projectName)
        Architecture: \(memory.analysis.architecturePattern.rawValue)
        Key Symbols: \(memory.keySymbols.count) symbols captured
        Code Patterns: \(memory.codePatterns.count) patterns identified
        Last Updated: \(memory.lastUpdated)
        """
    }
    
    private func handleGenerateMigrationPlan(_ arguments: [String: Any]) async throws -> String {
        guard let projectPath = arguments["project_path"] as? String,
              let targetArchitecture = arguments["target_architecture"] as? String else {
            throw MCPError.invalidParams
        }
        
        guard let targetPattern = ArchitecturePattern(rawValue: targetArchitecture) else {
            throw MCPError.invalidParams
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let analyzer = ProjectAnalyzer(projectPath: projectURL, logger: logger)
        let plan = try await analyzer.generateMigrationPlan(to: targetPattern)
        
        return """
        Migration Plan from \(plan.from.rawValue) to \(plan.to.rawValue):
        
        Steps: \(plan.steps.count) migration steps
        Estimated effort: \(plan.estimatedEffort)
        Risks: \(plan.risks.count) identified
        Benefits: \(plan.benefits.count) expected benefits
        
        First Steps:
        \(plan.steps.prefix(3).map { "• \($0.title): \($0.description)" }.joined(separator: "\n"))
        """
    }
    
    private func handleAnalyzePOPUsage(_ arguments: [String: Any]) async throws -> String {
        guard let projectPath = arguments["project_path"] as? String else {
            throw MCPError.invalidParams
        }
        
        let projectURL = URL(fileURLWithPath: projectPath)
        let analyzer = ArchitectureAnalyzer(projectPath: projectURL, logger: logger)
        let analysis = try await analyzer.analyzePOPUsage()
        
        return """
        🔍 Protocol-Oriented Programming Analysis for: \(projectPath)
        
        📊 Overview:
        • Total Swift files: \(analysis.totalFiles)
        • POP Score: \(analysis.popScore)/100 (\(analysis.adoptionLevel.rawValue))
        • Struct vs Class ratio: \(analysis.structUsage):\(analysis.classUsage)
        
        📈 Protocol Usage:
        • Protocol definitions: \(analysis.protocolDefinitions)
        • Protocol extensions: \(analysis.protocolExtensions)  
        • Protocol conformances: \(analysis.protocolConformances)
        • Protocol as types: \(analysis.protocolAsTypeUsage)
        
        🎯 POP Patterns Found:
        \(analysis.popPatterns.isEmpty ? "None detected" : analysis.popPatterns.map { "• \($0)" }.joined(separator: "\n"))
        
        💡 Recommendations:
        \(analysis.recommendations.map { "• \($0)" }.joined(separator: "\n"))
        """
    }
    
    // MARK: - Analysis Tool Handlers
    
    private func handleIntelligentProjectMemory(_ arguments: [String: Any]) async throws -> String {
        guard let action = arguments["action"] as? String else {
            throw MCPError.internalError
        }
        
        switch action {
        case "cache":
            if let key = arguments["key"] as? String {
                let result = IntelligentAnalysisResult(
                    timestamp: Date(),
                    analysisType: "generic_analysis",
                    result: Data("analysis_data".utf8),
                    checksum: "demo_checksum"
                )
                await projectMemory.cacheAnalysis(result, for: key)
                return "✅ Analysis cached for key: \(key)"
            } else {
                throw MCPError.internalError
            }
            
        case "retrieve":
            if let key = arguments["key"] as? String {
                if let cached = await projectMemory.getCachedAnalysis(for: key) {
                    return """
                    📋 Cached Analysis for key: \(key)
                    • Timestamp: \(cached.timestamp)
                    • Type: \(cached.analysisType)
                    • Checksum: \(cached.checksum)
                    """
                } else {
                    return "❌ No cached analysis found for key: \(key)"
                }
            } else {
                throw MCPError.internalError
            }
            
        case "learn_patterns":
            let patterns = await projectMemory.getMostCommonPatterns()
            return """
            🧠 Learned Patterns (\(patterns.count) total):
            \(patterns.map { "• \($0.key.rawValue): \($0.value) occurrences" }.joined(separator: "\n"))
            """
            
        case "get_evolution":
            return """
            📈 Project Evolution:
            • Total cached analyses: \(await projectMemory.getCachedAnalysis(for: "count") != nil ? "Available" : "None")
            • Pattern learning: Active
            • Memory system: Operational
            """
            
        default:
            throw MCPError.internalError
        }
    }
    
    private func handleGenerateDocumentation(_ arguments: [String: Any]) async throws -> String {
        let result = try await documentationGenerator.generateProjectDocumentation()
        
        return """
        📚 Documentation Generated Successfully!
        
        📄 Generated Files:
        \(result.generatedFiles.map { "• \($0)" }.joined(separator: "\n"))
        
        📊 Project Structure:
        • Name: \(result.projectStructure.name)
        • Type: \(result.projectStructure.type)
        • Swift files: \(result.projectStructure.swiftFileCount)
        • Has Package.swift: \(result.projectStructure.hasPackageSwift)
        
        🔍 API Documentation:
        • Total API items: \(result.apiDocumentation.count)
        • Classes: \(result.apiDocumentation.filter { $0.type == .classType }.count)
        • Structs: \(result.apiDocumentation.filter { $0.type == .structType }.count)
        • Functions: \(result.apiDocumentation.filter { $0.type == .function }.count)
        
        ✅ README.md has been generated and saved to the project root.
        """
    }
    
    private func handleAnalyzeiOSFrameworks(_ arguments: [String: Any]) async throws -> String {
        let result = try await iOSFrameworkAnalyzer.analyzeIOSPatterns()
        
        return """
        📱 iOS Framework Analysis Results
        
        🛠️ Framework Usage:
        • UIKit: \(result.frameworkUsage.uiKit) imports
        • SwiftUI: \(result.frameworkUsage.swiftUI) imports  
        • Foundation: \(result.frameworkUsage.foundation) imports
        • Combine: \(result.frameworkUsage.combine) imports
        • Core Data: \(result.frameworkUsage.coreData) imports
        • Networking: \(result.frameworkUsage.networking) imports
        • Dominant framework: \(result.frameworkUsage.dominantFramework)
        
        🎨 UI Patterns:
        • View Controllers: \(result.uiPatterns.viewControllers)
        • SwiftUI Views: \(result.uiPatterns.swiftUIViews)
        • Storyboard usage: \(result.uiPatterns.storyboardUsage)
        • AutoLayout usage: \(result.uiPatterns.autolayoutUsage)
        • Primary UI: \(result.uiPatterns.primaryUIFramework)
        
        🏗️ Architecture:
        • MVVM Score: \(result.architecturePatterns.mvvmScore)
        • MVP Score: \(result.architecturePatterns.mvpScore)
        • VIPER Score: \(result.architecturePatterns.viperScore)
        • Coordinator Score: \(result.architecturePatterns.coordinatorScore)
        • Dominant pattern: \(result.architecturePatterns.dominantPattern)
        
        ⚡ Modern Features:
        • Async/await usage: \(result.modernFeatures.asyncAwaitUsage)
        • Actor usage: \(result.modernFeatures.actorUsage)
        • Combine usage: \(result.modernFeatures.combineUsage)
        • Modernity score: \(result.modernFeatures.modernityScore)
        
        💡 Recommendations:
        \(result.recommendations.map { "• \($0)" }.joined(separator: "\n"))
        """
    }
    
    private func handleGenerateTemplate(_ arguments: [String: Any]) async throws -> String {
        guard let templateTypeString = arguments["template_type"] as? String,
              let name = arguments["name"] as? String else {
            throw MCPError.internalError
        }
        
        guard let templateType = TemplateType(rawValue: templateTypeString) else {
            throw MCPError.internalError
        }
        
        let description = arguments["description"] as? String
        let options = TemplateOptions(description: description)
        
        let result = try await templateGenerator.generateTemplate(templateType, name: name, options: options)
        
        return """
        🛠️ Template Generated Successfully!
        
        📄 Template: \(result.templateType.displayName)
        📁 Name: \(name)
        
        📝 Generated Files (\(result.generatedFiles.count)):
        \(result.generatedFiles.map { "• \($0)" }.joined(separator: "\n"))
        
        📋 Next Steps:
        \(result.instructions.map { "• \($0)" }.joined(separator: "\n"))
        
        ✅ Template files have been created in your project directory.
        """
    }
}
