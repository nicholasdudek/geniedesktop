#if targetEnvironment(macCatalyst) || os(iOS)
import SwiftUI
import PencilKit

// MARK: - Genie Virtual DOM: AI Co-Creation Canvas
// A transparent, infinite drawing layer that supports Apple Pencil and AI-injected programmatic strokes.

struct GeniePencilCanvas: NSViewRepresentable {
    @Binding var canvasView: PKCanvasView
    
    func makeNSView(context: Context) -> PKCanvasView {
        // Initialize the Native PencilKit Canvas
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .white, width: 2.0)
        
        // Make it completely transparent to act as a "Liquid Glass" overlay over the OS
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
        
        return canvasView
    }
    
    func updateNSView(_ nsView: PKCanvasView, context: Context) {
        // Handle dynamic updates (e.g. changing tool colors or brush sizes)
    }
}

class GenieArtEngine {
    
    /// Allows the AI to autonomously draw on the user's canvas.
    /// The local model generates vector coordinates, and Genie translates them into a human-like PKStroke.
    static func aiInjectStroke(into canvas: PKCanvasView, start: CGPoint, end: CGPoint, color: NSColor) {
        
        // 1. Define the mathematical path of the AI's stroke
        let path = CGMutablePath()
        path.move(to: start)
        // Add some bezier curves here to make it look like a natural human hand, not a robot
        path.addQuadCurve(to: end, control: CGPoint(x: (start.x + end.x) / 2 + 20, y: (start.y + end.y) / 2 - 20))
        
        // 2. Convert to PencilKit Stroke Points
        var strokePoints: [PKStrokePoint] = []
        let pointCount = 20
        
        for i in 0...pointCount {
            let t = CGFloat(i) / CGFloat(pointCount)
            // Interpolate along the curve
            let currentPoint = CGPoint(
                x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t
            )
            
            let strokePoint = PKStrokePoint(
                location: currentPoint,
                timeOffset: TimeInterval(t * 0.5), // Simulates the speed of the AI drawing
                size: CGSize(width: 3.0, height: 3.0),
                opacity: 0.8,
                force: 1.0,
                azimuth: 0,
                altitude: .pi / 4
            )
            strokePoints.append(strokePoint)
        }
        
        // 3. Construct the stroke with a glowing or magical ink type
        let strokePath = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        let ink = PKInk(.marker, color: color)
        let aiStroke = PKStroke(ink: ink, path: strokePath)
        
        // 4. Inject into the user's live canvas
        canvas.drawing.strokes.append(aiStroke)
    }
}
#endif
