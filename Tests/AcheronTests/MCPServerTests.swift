//
//  MCPServerTests.swift
//  Acheron
//
//  Copyright © 2026 Aepryus Software. All rights reserved.
//

#if canImport(Network)
import Foundation
import Network
import Testing
@testable import Acheron

/// An app relaunched before its last instance has let go of the port finds it in use: the server keeps trying, and
/// answers once the port is free.
@Test func mcpServerListensOnceThePortIsFree() async throws {
    let port: UInt16 = 47_391 + UInt16.random(in: 0..<500)
    let parameters: NWParameters = .tcp
    parameters.requiredLocalEndpoint = .hostPort(host: .ipv4(.loopback), port: NWEndpoint.Port(rawValue: port)!)
    let holder: NWListener = try NWListener(using: parameters)
    holder.newConnectionHandler = { $0.cancel() }
    holder.start(queue: .global())
    try await Task.sleep(for: .milliseconds(300))

    let server: MCPServer = MCPServer(name: "test", version: "1", port: port, token: "t", tools: [])
    try server.start()
    try await Task.sleep(for: .milliseconds(500))
    holder.cancel()

    var answered: Int? = nil
    for _ in 0..<20 where answered == nil {
        try await Task.sleep(for: .milliseconds(500))
        var request: URLRequest = URLRequest(url: URL(string: server.url)!)
        request.httpMethod = "POST"
        request.setValue("Bearer t", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = Data(#"{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}"#.utf8)
        request.timeoutInterval = 2
        if let (_, response) = try? await URLSession.shared.data(for: request) { answered = (response as? HTTPURLResponse)?.statusCode }
    }
    server.stop()
    #expect(answered == 200)
}
#endif
