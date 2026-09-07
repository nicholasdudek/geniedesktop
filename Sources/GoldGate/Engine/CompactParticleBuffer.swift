import Foundation
import SwiftUI

// MARK: - Virtualized Attention Sink & Compact Ring Buffer
// Derived from Live Context Streamer Virtualized Attention Sink architecture.
// Enforces strict O(1) memory bounds and eliminates heap allocations during 120 FPS render loops.

public struct AttentionSinkBuffer<T>: Sequence {
    public private(set) var elements: [T] = []
    public let capacity: Int
    public let anchorCount: Int

    public init(capacity: Int = 64, anchorCount: Int = 4) {
        self.capacity = Swift.max(capacity, 8)
        self.anchorCount = Swift.min(anchorCount, self.capacity / 2)
        self.elements.reserveCapacity(self.capacity)
    }

    public var count: Int {
        elements.count
    }

    public var isEmpty: Bool {
        elements.isEmpty
    }

    public mutating func append(_ item: T) {
        if elements.count < capacity {
            elements.append(item)
        } else {
            // Attention Sink eviction: Preserve first `anchorCount` elements, drop oldest sliding window element
            let evictIndex = anchorCount
            if evictIndex < elements.count {
                elements.remove(at: evictIndex)
            }
            elements.append(item)
        }
    }

    public mutating func removeAll(keepingCapacity: Bool = true) {
        elements.removeAll(keepingCapacity: keepingCapacity)
    }

    public mutating func removeAll(where predicate: (T) -> Bool) {
        elements.removeAll(where: predicate)
    }

    public subscript(index: Int) -> T {
        get { elements[index] }
        set { elements[index] = newValue }
    }

    public func makeIterator() -> IndexingIterator<[T]> {
        elements.makeIterator()
    }
}
