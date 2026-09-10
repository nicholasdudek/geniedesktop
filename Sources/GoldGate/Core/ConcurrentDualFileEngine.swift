//
//  ConcurrentDualFileEngine.swift
//  GoldGate / Ultra-Compact Swift 6 Dual-File Engine
//

import Foundation
import CryptoKit

public enum FilePairSyncMode: String, CaseIterable, Codable, Sendable {
    case independent, mirrored, differentialDelta
}

public struct ConcurrentDualWriteResult: Sendable, Codable {
    public let pathA, pathB: String
    public let bytesWrittenA, bytesWrittenB: Int
    public let hashA, hashB: String
    public let timestampA, timestampB: Date
    public let latencyDeltaMicroseconds: Int64
    public var isConcurrent: Bool { abs(latencyDeltaMicroseconds) < 50_000 }
}

public struct ConcurrentDualReadResult: Sendable {
    public let pathA, pathB, contentA, contentB: String
    public let readTimestamp: Date
    public let durationMicroseconds: Int64
}

public struct FileVaultEntry: Identifiable, Codable, Sendable {
    public var id = UUID().uuidString
    public let key, vaultPathA, vaultPathB: String
    public let mode: FilePairSyncMode
    public var createdAt = Date(), lastModified = Date()
    public var hashA: String, hashB: String
}

public actor ConcurrentDualFileEngine {
    public static let shared = ConcurrentDualFileEngine()
    public let vaultURL = FileManager.default.homeDirectoryForCurrentUser.appending(path: ".genie/secure_vault")

    public init() {
        try? FileManager.default.createDirectory(at: vaultURL, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    }

    public func writeConcurrently(pathA: String, contentA: String, pathB: String, contentB: String) async throws -> ConcurrentDualWriteResult {
        async let wA = Self.writeFile(pathA, contentA)
        async let wB = Self.writeFile(pathB, contentB)
        let (cntA, hA, tA, nA) = try await wA, (cntB, hB, tB, nB) = try await wB
        return .init(pathA: pathA, pathB: pathB, bytesWrittenA: cntA, bytesWrittenB: cntB, hashA: hA, hashB: hB, timestampA: tA, timestampB: tB, latencyDeltaMicroseconds: Int64(abs(Int64(nA) - Int64(nB))) / 1000)
    }

    public func readConcurrently(pathA: String, pathB: String) async throws -> ConcurrentDualReadResult {
        let t0 = DispatchTime.now().uptimeNanoseconds
        async let rA = Self.readFile(pathA), rB = Self.readFile(pathB)
        let (cA, cB) = try await (rA, rB)
        return .init(pathA: pathA, pathB: pathB, contentA: cA, contentB: cB, readTimestamp: Date(), durationMicroseconds: Int64(DispatchTime.now().uptimeNanoseconds - t0) / 1000)
    }

    public func writeToSecureVault(key: String, contentA: String, contentB: String, mode: FilePairSyncMode = .independent) async throws -> FileVaultEntry {
        let slug = SHA256.hash(data: Data(key.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        let urlA = vaultURL.appending(path: ".\(slug)_partA.vault"), urlB = vaultURL.appending(path: ".\(slug)_partB.vault")
        let res = try await writeConcurrently(pathA: urlA.path, contentA: contentA, pathB: urlB.path, contentB: contentB)
        let entry = FileVaultEntry(key: key, vaultPathA: res.pathA, vaultPathB: res.pathB, mode: mode, hashA: res.hashA, hashB: res.hashB)
        let manifestURL = vaultURL.appending(path: ".manifest.json")
        var entries = (try? JSONDecoder().decode([FileVaultEntry].self, from: Data(contentsOf: manifestURL)))?.filter { $0.key != key } ?? []
        entries.append(entry)
        try? (try? JSONEncoder().encode(entries))?.write(to: manifestURL, options: .atomic)
        return entry
    }

    public func readFromSecureVault(key: String) async throws -> (contentA: String, contentB: String) {
        let slug = SHA256.hash(data: Data(key.utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
        let res = try await readConcurrently(pathA: vaultURL.appending(path: ".\(slug)_partA.vault").path, pathB: vaultURL.appending(path: ".\(slug)_partB.vault").path)
        return (res.contentA, res.contentB)
    }

    private nonisolated static func writeFile(_ path: String, _ content: String) throws -> (Int, String, Date, UInt64) {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data(content.utf8)
        try data.write(to: url, options: .atomic)
        try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        return (data.count, hash, Date(), DispatchTime.now().uptimeNanoseconds)
    }

    private nonisolated static func readFile(_ path: String) throws -> String {
        guard let str = String(data: try Data(contentsOf: URL(fileURLWithPath: path)), encoding: .utf8) else {
            throw NSError(domain: "ConcurrentDualFileEngine", code: 422, userInfo: [NSLocalizedDescriptionKey: "UTF-8 decode failed"])
        }
        return str
    }
}

// MARK: - Backward Compatibility Aliases
public typealias QuantumDualFileEngine = ConcurrentDualFileEngine
public typealias QuantumEntanglementMode = FilePairSyncMode
public typealias QuantumDualWriteResult = ConcurrentDualWriteResult
public typealias QuantumDualReadResult = ConcurrentDualReadResult
public typealias QuantumVaultEntry = FileVaultEntry
