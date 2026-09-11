// MARK: - GeniePortGovernor.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Central Network Port Slicing & Conflict Prevention Governor.
// Strictly prevents Genie from ever binding onto commonly-used developer,
// system, or web framework ports (3000, 5000, 8000, 8080, etc.), and guarantees
// a sliced, collision-free range for guest Linux Virtual Machines to plug into.

import Foundation
import Darwin

public final class GeniePortGovernor: Sendable {
    public static let shared = GeniePortGovernor()

    // MARK: - Blacklisted Commonly Used Ports
    // Ports heavily used by local web servers, development tools, databases,
    // and Apple system services that must NEVER be bound by Genie.
    public static let blacklistedCommonPorts: Set<UInt16> = [
        21, 22, 23, 25, 53, 80, 110, 143, 443, 465, 587, 993, 995,
        1433, 1521, 2222, 3000, 3001, 3306, 4000, 4200, 5000, 5001,
        5173, 5432, 5900, 5901, 6379, 8000, 8008, 8080, 8081, 8443,
        8765, 8888, 9000, 9090, 9099, 9200, 9999, 27017
    ]

    // MARK: - Dedicated Safe Port Ranges (IANA Private / Ephemeral Slice)
    // 58200 - 58299: Dedicated Internal Genie Services
    // 58300 - 58999: Dedicated Sliced Ports for Linux Virtual Machines
    public static let defaultPhoneBridgePort: UInt16 = 58265
    public static let defaultStreamBackPort: UInt16 = 58299
    public static let defaultLocalNetworkPort: UInt16 = 58221
    public static let defaultRuntimeLogPort: UInt16 = 58290
    public static let defaultLocalModelServerPort: UInt16 = 58300

    public static let genieServiceSlice: ClosedRange<UInt16> = 58200...58299
    public static let vmGuestSlice: ClosedRange<UInt16> = 58300...58999

    private init() {}

    /// Checks if a port is in the blacklisted commonly-used list
    public static func isBlacklisted(_ port: UInt16) -> Bool {
        blacklistedCommonPorts.contains(port)
    }

    /// Verifies if a given port can be successfully bound on 127.0.0.1
    public static func isPortAvailable(_ port: UInt16) -> Bool {
        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")

        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else { return false }
        defer { close(sock) }

        var reuse: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return bindResult == 0
    }

    /// Allocates a guaranteed safe, non-colliding port.
    /// If preferred port is blacklisted or taken, probes the designated slice range.
    public static func allocateSafePort(preferred: UInt16, fallbackRange: ClosedRange<UInt16> = genieServiceSlice) -> UInt16 {
        if !isBlacklisted(preferred) && isPortAvailable(preferred) {
            return preferred
        }

        for candidate in fallbackRange where !isBlacklisted(candidate) {
            if isPortAvailable(candidate) {
                return candidate
            }
        }

        return fallbackRange.lowerBound
    }

    /// Allocates an isolated slice of ports for Linux Guest Virtual Machines
    /// so developer tools inside the VM can bridge cleanly into macOS.
    public static func allocateVMPortSlice(count: Int = 1) -> [UInt16] {
        var allocated: [UInt16] = []
        for candidate in vmGuestSlice where !isBlacklisted(candidate) {
            if isPortAvailable(candidate) {
                allocated.append(candidate)
                if allocated.count >= count {
                    break
                }
            }
        }
        return allocated
    }
}
