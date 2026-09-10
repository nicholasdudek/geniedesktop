//
//  ServiceRegistry.swift
//  GoldGate / Core Lazy Dependency & Service Registry
//  Architected with Claude Code & OpenAI Codex CLI
//

import Foundation

/// Thread-safe service and module registry that enforces lazy factory resolution,
/// ensuring the main thread launch sequence remains deterministic and non-blocking (<50ms).
public final class ServiceRegistry: @unchecked Sendable {
    public static let shared = ServiceRegistry()

    private let lock = NSLock()
    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var instances: [ObjectIdentifier: Any] = [:]

    private init() {}

    /// Registers a deferred factory for a service or window controller.
    /// The factory is never executed until explicitly resolved by user interaction.
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        lock.lock()
        defer { lock.unlock() }
        factories[ObjectIdentifier(type)] = factory
    }

    /// Lazily resolves or instantiates the singleton instance of the registered service.
    public func resolve<T>(_ type: T.Type) -> T {
        lock.lock()
        defer { lock.unlock() }

        let key = ObjectIdentifier(type)
        if let existing = instances[key] as? T {
            return existing
        }

        guard let factory = factories[key] else {
            fatalError("[ServiceRegistry] No registered factory found for type \(String(describing: type))")
        }

        let instance = factory() as! T
        instances[key] = instance
        return instance
    }

    /// Checks if a service is registered.
    public func isRegistered<T>(_ type: T.Type) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return factories[ObjectIdentifier(type)] != nil
    }

    /// Resets cached instances (useful for testing or profile switches).
    public func resetInstances() {
        lock.lock()
        defer { lock.unlock() }
        instances.removeAll()
    }
}
