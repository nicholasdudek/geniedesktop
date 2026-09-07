import AppKit
import Foundation
import Vision

// MARK: - Screen Vision OCR Engine
// Uses Apple Vision framework on the Apple Neural Engine to extract text from any screen coordinate in <25ms.

public final class GenieVisionOCREngine {
    public static let shared = GenieVisionOCREngine()

    public struct RecognizedTextBlock: Identifiable {
        public let id = UUID()
        public let text: String
        public let confidence: Float
        public let boundingBox: CGRect
    }

    /// Perform OCR on a CGImage
    public func recognizeText(in image: CGImage) async -> [RecognizedTextBlock] {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, error in
                guard error == nil, let observations = req.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let blocks: [RecognizedTextBlock] = observations.compactMap { obs in
                    guard let topCandidate = obs.topCandidates(1).first else { return nil }
                    return RecognizedTextBlock(
                        text: topCandidate.string,
                        confidence: topCandidate.confidence,
                        boundingBox: obs.boundingBox
                    )
                }
                continuation.resume(returning: blocks)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
