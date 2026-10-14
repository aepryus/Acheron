//
//  MCPServer.swift
//  Acheron
//
//  Created by Joe Charlier on 10/14/26.
//  Copyright © 2026 Aepryus Software. All rights reserved.
//
//  An app's own MCP server (the Model Context Protocol, modelcontextprotocol.io): the app offers an AI — Claude Code,
//  Claude Desktop — a set of tools, each a name, what it does, a JSON Schema for its arguments and a function, and the
//  AI calls them in the middle of a conversation, against the app's live model rather than a copy of it. It speaks the
//  Streamable HTTP transport, the plain half of it: JSON-RPC posted to one endpoint (/mcp) and answered with JSON, no
//  event stream. It listens on the loopback interface only; every request carries the app's bearer token, and none
//  from a web page is answered (an Origin that isn't the machine's own is refused: DNS rebinding). A tool runs on the
//  main actor, where an app's model lives, and may take its time — a write can wait for the person to approve it.
//
//  A Catalyst or iOS app needs com.apple.security.network.server in its sandbox to listen.
//

#if canImport(Network)
import Foundation
import Network

public struct MCPTool {
    public let name: String
    public let description: String
    /// The JSON Schema of the tool's arguments: ["type": "object", "properties": [...], "required": [...]].
    public let schema: [String: Any]
    /// Given the arguments, what the tool answers; a thrown error is answered as the tool's error.
    public let run: @MainActor ([String: Any]) async throws -> String

    public init(name: String, description: String, schema: [String: Any], run: @escaping @MainActor ([String: Any]) async throws -> String) {
        self.name = name
        self.description = description
        self.schema = schema
        self.run = run
    }
}

/// What a tool answers when it can't do what was asked: its message goes back to the AI as the tool's error.
public struct MCPError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public final class MCPServer {
    public let name: String
    public let version: String
    public let port: UInt16
    public let token: String
    /// Told to the AI when it connects: what the app is and how its tools are meant to be used.
    public let instructions: String?
    public let tools: [MCPTool]
    public var url: String { "http://127.0.0.1:\(port)/mcp" }

    private var listener: NWListener?
    private let queue: DispatchQueue = DispatchQueue(label: "Acheron.MCPServer")
    private static let versions: [String] = ["2025-06-18", "2025-03-26", "2024-11-05"]

    public init(name: String, version: String, port: UInt16, token: String, instructions: String? = nil, tools: [MCPTool]) {
        self.name = name
        self.version = version
        self.port = port
        self.token = token
        self.instructions = instructions
        self.tools = tools
    }

    public func start() throws {
        guard let port: NWEndpoint.Port = NWEndpoint.Port(rawValue: port) else { throw MCPError("no port \(self.port)") }
        let parameters: NWParameters = .tcp
        parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: port)
        parameters.allowLocalEndpointReuse = true
        let listener: NWListener = try NWListener(using: parameters)
        listener.newConnectionHandler = { [weak self] (connection: NWConnection) in
            guard let self else { connection.cancel(); return }
            connection.start(queue: self.queue)
            self.serve(connection, Data())
        }
        listener.stateUpdateHandler = { [name] (state: NWListener.State) in
            if case .failed(let error) = state { print("[ \(name) MCP ] \(error)") }
        }
        listener.start(queue: queue)
        self.listener = listener
    }
    public func stop() {
        listener?.cancel()
        listener = nil
    }

// HTTP ============================================================================================
    private struct Request {
        let method: String
        let path: String
        let headers: [String: String]
        let body: Data
        var closes: Bool { headers["connection"]?.lowercased() == "close" }
    }
    private enum Taken { case request(Request), more, bad(Int, String) }

    /// The first whole request at the front of the buffer, taken off it; or that more must be read first.
    private static func take(from buffer: inout Data) -> Taken {
        guard let end: Range<Data.Index> = buffer.range(of: Data("\r\n\r\n".utf8)) else {
            return buffer.count > 64 * 1024 ? .bad(431, "Request Header Fields Too Large") : .more
        }
        guard let head: String = String(data: buffer[buffer.startIndex..<end.lowerBound], encoding: .utf8) else { return .bad(400, "Bad Request") }
        let lines: [Substring] = head.split(separator: "\r\n", omittingEmptySubsequences: false)
        let first: [Substring] = (lines.first ?? "").split(separator: " ")
        guard first.count >= 2 else { return .bad(400, "Bad Request") }
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon: String.Index = line.firstIndex(of: ":") else { continue }
            headers[line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()] = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
        }
        if headers["transfer-encoding"] != nil { return .bad(411, "Length Required") }
        let length: Int = Int(headers["content-length"] ?? "0") ?? 0
        guard length <= 16 * 1024 * 1024 else { return .bad(413, "Payload Too Large") }
        guard buffer.distance(from: end.upperBound, to: buffer.endIndex) >= length else { return .more }
        let bodyEnd: Data.Index = buffer.index(end.upperBound, offsetBy: length)
        let request: Request = Request(method: String(first[0]), path: String(first[1].split(separator: "?").first ?? ""), headers: headers, body: Data(buffer[end.upperBound..<bodyEnd]))
        buffer = Data(buffer[bodyEnd...])
        return .request(request)
    }
    private static func response(_ status: Int, _ reason: String, json: Any? = nil, headers: [String: String] = [:], closes: Bool = false) -> Data {
        let body: Data = json.flatMap { try? JSONSerialization.data(withJSONObject: $0) } ?? Data()
        var head: String = "HTTP/1.1 \(status) \(reason)\r\nContent-Length: \(body.count)\r\nConnection: \(closes ? "close" : "keep-alive")\r\n"
        if json != nil { head += "Content-Type: application/json\r\n" }
        for (key, value) in headers { head += "\(key): \(value)\r\n" }
        return Data((head + "\r\n").utf8) + body
    }

    /// Answers each request on the connection in turn, for as long as the client keeps it open.
    private func serve(_ connection: NWConnection, _ buffer: Data) {
        var buffer: Data = buffer
        switch MCPServer.take(from: &buffer) {
            case .request(let request):
                handle(request) { [weak self] (response: Data, closes: Bool) in
                    connection.send(content: response, completion: .contentProcessed { _ in
                        if closes || request.closes { connection.cancel() }
                        else { self?.serve(connection, buffer) }
                    })
                }
            case .bad(let status, let reason):
                connection.send(content: MCPServer.response(status, reason, closes: true), completion: .contentProcessed { _ in connection.cancel() })
            case .more:
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1 << 20) { [weak self] (data: Data?, _, complete: Bool, error: NWError?) in
                    if let data, !data.isEmpty { self?.serve(connection, buffer + data) }
                    else if complete || error != nil { connection.cancel() }
                    else { self?.serve(connection, buffer) }
                }
        }
    }
    private func handle(_ request: Request, _ reply: @escaping (Data, Bool) -> ()) {
        guard request.path == "/mcp" else { reply(MCPServer.response(404, "Not Found"), false); return }
        if let origin: String = request.headers["origin"], let host: String = URL(string: origin)?.host, !["localhost", "127.0.0.1", "::1", "[::1]"].contains(host) {
            reply(MCPServer.response(403, "Forbidden", closes: true), true); return
        }
        guard request.headers["authorization"] == "Bearer \(token)" else { reply(MCPServer.response(401, "Unauthorized", closes: true), true); return }
        guard request.method == "POST" else { reply(MCPServer.response(405, "Method Not Allowed", headers: ["Allow": "POST"]), false); return }
        guard let message: Any = try? JSONSerialization.jsonObject(with: request.body) else {
            reply(MCPServer.response(400, "Bad Request", json: MCPServer.failure(NSNull(), -32700, "Parse error")), false); return
        }
        Task {
            if let batch: [Any] = message as? [Any] {
                var answers: [[String: Any]] = []
                for one in batch { if let answer = await self.answer(one) { answers.append(answer) } }
                reply(answers.isEmpty ? MCPServer.response(202, "Accepted") : MCPServer.response(200, "OK", json: answers), false)
            } else if let answer = await self.answer(message) {
                let opened: Bool = (message as? [String: Any])?["method"] as? String == "initialize"
                reply(MCPServer.response(200, "OK", json: answer, headers: opened ? ["Mcp-Session-Id": UUID().uuidString] : [:]), false)
            } else {
                reply(MCPServer.response(202, "Accepted"), false)
            }
        }
    }

// JSON-RPC ========================================================================================
    private static func failure(_ id: Any, _ code: Int, _ message: String) -> [String: Any] {
        ["jsonrpc": "2.0", "id": id, "error": ["code": code, "message": message]]
    }
    /// The answer to one message; none to a notification.
    private func answer(_ message: Any) async -> [String: Any]? {
        guard let message: [String: Any] = message as? [String: Any] else { return MCPServer.failure(NSNull(), -32600, "Invalid Request") }
        guard let id: Any = message["id"] else { return nil }
        guard let method: String = message["method"] as? String else { return MCPServer.failure(id, -32600, "Invalid Request") }
        let params: [String: Any] = message["params"] as? [String: Any] ?? [:]
        let result: [String: Any]
        switch method {
            case "initialize":
                let asked: String = params["protocolVersion"] as? String ?? ""
                var opened: [String: Any] = [
                    "protocolVersion": MCPServer.versions.contains(asked) ? asked : MCPServer.versions[0],
                    "capabilities": ["tools": ["listChanged": false]],
                    "serverInfo": ["name": name, "version": version],
                ]
                if let instructions { opened["instructions"] = instructions }
                result = opened
            case "ping":
                result = [:]
            case "tools/list":
                result = ["tools": tools.map { ["name": $0.name, "description": $0.description, "inputSchema": $0.schema] }]
            case "tools/call":
                guard let name: String = params["name"] as? String, let tool: MCPTool = tools.first(where: { $0.name == name }) else {
                    return MCPServer.failure(id, -32602, "Unknown tool: \(params["name"] ?? "")")
                }
                let arguments: [String: Any] = params["arguments"] as? [String: Any] ?? [:]
                do {
                    let text: String = try await tool.run(arguments)
                    result = ["content": [["type": "text", "text": text]], "isError": false]
                } catch {
                    result = ["content": [["type": "text", "text": error.localizedDescription]], "isError": true]
                }
            default:
                return MCPServer.failure(id, -32601, "Method not found: \(method)")
        }
        return ["jsonrpc": "2.0", "id": id, "result": result]
    }
}
#endif
