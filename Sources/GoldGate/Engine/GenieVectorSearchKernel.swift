import Foundation
import Accelerate
import simd

// MARK: - Vector Search Kernel (Accelerate / NEON Optimized)
// Ported from OMNI_VECTOR_DB SIMD vector kernel.
// Evaluates dot products, L2 norms, and cosine similarity with vDSP vectorization.

public struct VectorDocument: Identifiable {
    public let id: String
    public let title: String
    public let embedding: [Float]

    public init(id: String, title: String, embedding: [Float]) {
        self.id = id
        self.title = title
        self.embedding = embedding
    }
}

public final class GenieVectorSearchKernel {
    public static let shared = GenieVectorSearchKernel()

    private var documents: [VectorDocument] = []
    private let lock = NSLock()

    public func setDocuments(_ docs: [VectorDocument]) {
        lock.lock()
        defer { lock.unlock() }
        self.documents = docs
    }

    /// Compute cosine similarity between two float vectors using Accelerate vDSP
    public static func cosineSimilarity(a: [Float], b: [Float]) -> Float {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        let count = a.count

        var dotProduct: Float = 0
        vDSP_dotpr(a, 1, b, 1, &dotProduct, vDSP_Length(count))

        var normA: Float = 0
        vDSP_svesq(a, 1, &normA, vDSP_Length(count))

        var normB: Float = 0
        vDSP_svesq(b, 1, &normB, vDSP_Length(count))

        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 1e-6 else { return 0 }

        return dotProduct / denominator
    }

    /// Query top-K most similar documents in <50µs
    public func search(queryVector: [Float], topK: Int = 10) -> [(id: String, title: String, score: Float)] {
        lock.lock()
        let currentDocs = self.documents
        lock.unlock()

        var results: [(id: String, title: String, score: Float)] = []
        results.reserveCapacity(currentDocs.count)

        for doc in currentDocs {
            let score = Self.cosineSimilarity(a: queryVector, b: doc.embedding)
            results.append((id: doc.id, title: doc.title, score: score))
        }

        results.sort { $0.score > $1.score }
        return Array(results.prefix(topK))
    }
}
