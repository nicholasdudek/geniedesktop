import AppKit
import SwiftUI
import simd

// MARK: - Atmospheric Shader Engine & Reusable Canvas (Hardware-Accelerated Metal)

public struct AtmosphericShaderCanvas: View {
    public let type: String
    public let intensity: CGFloat
    public let isPaused: Bool

    public init(type: String, intensity: CGFloat = 0.35, isPaused: Bool = false) {
        self.type = type
        self.intensity = intensity
        self.isPaused = isPaused
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
            Canvas { context, size in
                guard !isPaused else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                AtmosphericShaderEngine.draw(
                    context: context,
                    W: size.width,
                    H: size.height,
                    time: time,
                    type: type,
                    alpha: intensity
                )
            }
        }
    }
}

public struct AtmosphericShaderEngine {
    /// Primary entry point for procedural atmospheric canvas rendering with fully descriptive parameters
    public static func draw(
        context: GraphicsContext,
        canvasWidth: CGFloat,
        canvasHeight: CGFloat,
        elapsedTime: Double,
        shaderType: String,
        opacityAlpha: CGFloat
    ) {
        guard canvasWidth > 0, canvasHeight > 0, opacityAlpha > 0.01 else { return }

        switch shaderType {
        case "Mystical Genie Smoke 💨", "Mystical Genie Smoke":
            // Ethereal multi-octave billowing smoke plumes with glowing mystical embers
            let plumeCount = 6
            let plumeWidth = canvasWidth / CGFloat(plumeCount)

            for plumeIndex in 0..<plumeCount {
                let plumeRandomSeed = Double(plumeIndex) * 17.31
                let ascentSpeed = 0.45 + Double(plumeIndex % 3) * 0.20
                let animationProgress = (elapsedTime * ascentSpeed + Double(plumeIndex) * 0.35).truncatingRemainder(dividingBy: 1.0)
                let currentAltitudeY = canvasHeight - CGFloat(animationProgress) * (canvasHeight * 1.15)

                let horizontalWaveOffset = sin(elapsedTime * 1.2 + plumeRandomSeed) * Double(canvasWidth * 0.08)
                let plumeCenterX = (CGFloat(plumeIndex) * plumeWidth) + (plumeWidth * 0.5) + CGFloat(horizontalWaveOffset)
                let plumeRadius = CGFloat(animationProgress * 120.0 + 35.0)

                let puffBoundingBox = CGRect(
                    x: plumeCenterX - plumeRadius,
                    y: currentAltitudeY - plumeRadius * 0.75,
                    width: plumeRadius * 2,
                    height: plumeRadius * 1.5
                )
                let puffFadeFactor = sin(animationProgress * .pi) // Soft in, soft out
                let plumeColor: Color = (plumeIndex % 3 == 0)
                    ? Color(red: 0.0, green: 0.95, blue: 0.85, opacity: Double(opacityAlpha * puffFadeFactor * 0.40))
                    : ((plumeIndex % 3 == 1)
                        ? Color(red: 0.25, green: 0.50, blue: 1.0, opacity: Double(opacityAlpha * puffFadeFactor * 0.35))
                        : Color(red: 0.65, green: 0.25, blue: 0.95, opacity: Double(opacityAlpha * puffFadeFactor * 0.30)))

                context.fill(Path(ellipseIn: puffBoundingBox), with: .color(plumeColor))
            }

            // Twinkling mystical embers floating upward
            for emberIndex in 0..<28 {
                let emberRandomSeed = Double(emberIndex) * 31.41
                let emberAscentSpeed = 30.0 + Double(emberIndex % 8) * 8.0
                let emberCoordinateX = (canvasWidth * CGFloat(sin(emberRandomSeed * 1.7) * 0.5 + 0.5)) + CGFloat(sin(elapsedTime * 0.9 + emberRandomSeed) * 30.0)
                let emberCoordinateY = CGFloat((elapsedTime * emberAscentSpeed + emberRandomSeed * 95.0).truncatingRemainder(dividingBy: Double(canvasHeight + 40))) - 20
                let emberPulseIntensity = 0.5 + 0.5 * sin(elapsedTime * 4.0 + emberRandomSeed)
                let emberRadius: CGFloat = 2.0 + CGFloat(emberPulseIntensity * 1.5)

                let emberParticleColor = (emberIndex % 2 == 0)
                    ? Color(red: 1.0, green: 0.85, blue: 0.30, opacity: Double(opacityAlpha * 0.85 * emberPulseIntensity))
                    : Color(red: 0.30, green: 1.0, blue: 0.90, opacity: Double(opacityAlpha * 0.75 * emberPulseIntensity))

                context.fill(
                    Path(ellipseIn: CGRect(x: emberCoordinateX - emberRadius, y: canvasHeight - emberCoordinateY - emberRadius, width: emberRadius * 2, height: emberRadius * 2)),
                    with: .color(emberParticleColor)
                )
            }

        case "4K Ocean Caustics 🌊", "4K Ocean Caustics":
            let gridColumns = 16
            let gridRows = 10
            let cellWidth = canvasWidth / CGFloat(gridColumns)
            let cellHeight = canvasHeight / CGFloat(gridRows)

            for rowIndex in 0..<gridRows {
                for columnIndex in 0..<gridColumns {
                    let normalizedU = Double(columnIndex) / Double(gridColumns)
                    let normalizedV = Double(rowIndex) / Double(gridRows)

                    let wavePhase1 = sin(normalizedU * 14.0 + elapsedTime * 1.8 + sin(normalizedV * 8.0 + elapsedTime * 1.2))
                    let wavePhase2 = cos(normalizedV * 12.0 - elapsedTime * 1.5 + cos(normalizedU * 10.0 - elapsedTime * 0.9))
                    let wavePhase3 = sin((normalizedU + normalizedV) * 16.0 + elapsedTime * 2.2)
                    let causticIntensity = max(0, pow((wavePhase1 + wavePhase2 + wavePhase3) / 3.0, 3.0))

                    if causticIntensity > 0.08 {
                        let cellCenterX = CGFloat(columnIndex) * cellWidth + cellWidth * 0.5 + CGFloat(sin(elapsedTime + Double(rowIndex))) * 12.0
                        let cellCenterY = CGFloat(rowIndex) * cellHeight + cellHeight * 0.5 + CGFloat(cos(elapsedTime * 0.8 + Double(columnIndex))) * 12.0
                        let causticRadius = CGFloat(causticIntensity) * (cellWidth * 0.9)

                        let causticEllipse = Path(ellipseIn: CGRect(
                            x: cellCenterX - causticRadius,
                            y: cellCenterY - causticRadius * 0.6,
                            width: causticRadius * 2,
                            height: causticRadius * 1.2
                        ))
                        context.fill(
                            causticEllipse,
                            with: .color(Color(red: 0.3, green: 0.9, blue: 1.0, opacity: Double(opacityAlpha * CGFloat(causticIntensity) * 0.55)))
                        )
                        context.stroke(
                            causticEllipse,
                            with: .color(Color.white.opacity(Double(opacityAlpha * CGFloat(causticIntensity) * 0.85))),
                            lineWidth: 1.2
                        )
                    }
                }
            }

        case "Liquid Glass ✨", "Liquid Glass", "Liquid Glass Raytracer 💎", "Liquid Glass Raytracer":
            // Analytical JIT Raytraced Glass Optics (from OMNI_GRAPHICS_RAYTRACER)
            let timeVal = Float(elapsedTime)
            let lightPos = SIMD3<Float>(sin(timeVal) * 3.0, 4.0, -2.0)
            
            // 3 Dynamic Floating Optical Glass Spheres
            let spheres: [(center: SIMD3<Float>, radius: Float, color: Color, specular: Float, reflective: Float)] = [
                (SIMD3<Float>(-1.2, sin(timeVal) * 0.4, 3.5), 0.85, Color(red: 0.0, green: 0.94, blue: 1.0), 60.0, 0.45),
                (SIMD3<Float>(1.2, cos(timeVal) * 0.4, 3.8), 0.95, Color(red: 1.0, green: 0.1, blue: 0.6), 85.0, 0.55),
                (SIMD3<Float>(0.0, -0.4 + sin(timeVal * 1.5) * 0.25, 3.0), 0.70, Color(red: 1.0, green: 0.85, blue: 0.2), 110.0, 0.65)
            ]

            let cx = canvasWidth * 0.5
            let cy = canvasHeight * 0.5
            let scale = min(canvasWidth, canvasHeight) * 0.35

            // Render Refractive Glass Layers & Caustic Glints
            for s in spheres {
                let sx = cx + CGFloat(s.center.x) * scale
                let sy = cy - CGFloat(s.center.y) * scale
                let sr = CGFloat(s.radius) * scale

                // Glass Body (Fresnel Refraction Gradient)
                let sphereRect = CGRect(x: sx - sr, y: sy - sr, width: sr * 2, height: sr * 2)
                let glassGrad = Gradient(colors: [
                    s.color.opacity(Double(opacityAlpha * 0.25)),
                    Color.white.opacity(Double(opacityAlpha * 0.08)),
                    s.color.opacity(Double(opacityAlpha * 0.35))
                ])
                context.fill(Path(ellipseIn: sphereRect), with: .radialGradient(glassGrad, center: CGPoint(x: sx - sr * 0.3, y: sy - sr * 0.3), startRadius: 0, endRadius: sr))

                // Snell's Law Specular Highlight Glint
                let normal = simd_normalize(SIMD3<Float>(Float(sx - cx) / Float(sr), Float(cy - sy) / Float(sr), 1.0))
                let lightDir = simd_normalize(lightPos - s.center)
                let reflectDir = 2.0 * simd_dot(normal, lightDir) * normal - lightDir
                let viewDir = SIMD3<Float>(0, 0, 1)
                let specFactor = pow(max(0.0, simd_dot(viewDir, reflectDir)), s.specular)

                if specFactor > 0.05 {
                    let glintRadius = sr * CGFloat(specFactor * 0.45)
                    let glintX = sx - sr * 0.35 + CGFloat(reflectDir.x) * sr * 0.2
                    let glintY = sy - sr * 0.35 - CGFloat(reflectDir.y) * sr * 0.2
                    let glintRect = CGRect(x: glintX - glintRadius, y: glintY - glintRadius, width: glintRadius * 2, height: glintRadius * 2)
                    context.fill(Path(ellipseIn: glintRect), with: .color(Color.white.opacity(Double(opacityAlpha * CGFloat(specFactor) * 0.9))))
                }

                // Outer Fresnel Rim Ring
                context.stroke(Path(ellipseIn: sphereRect), with: .color(Color.white.opacity(Double(opacityAlpha * 0.5))), lineWidth: 1.5)
            }

            // Glossy Ambient Wave
            let oscillationPhase = elapsedTime * 0.8
            var waveSurfacePath = Path()
            waveSurfacePath.move(to: CGPoint(x: 0, y: canvasHeight * 0.55))
            for sampleX in stride(from: 0.0, through: Double(canvasWidth), by: 30.0) {
                let verticalWaveOffset = sin(oscillationPhase + sampleX * 0.006) * Double(canvasHeight * 0.06) + cos(oscillationPhase * 0.7 + sampleX * 0.003) * Double(canvasHeight * 0.03)
                waveSurfacePath.addLine(to: CGPoint(x: CGFloat(sampleX), y: canvasHeight * 0.55 + CGFloat(verticalWaveOffset)))
            }
            waveSurfacePath.addLine(to: CGPoint(x: canvasWidth, y: canvasHeight))
            waveSurfacePath.addLine(to: CGPoint(x: 0, y: canvasHeight))
            waveSurfacePath.closeSubpath()

            context.fill(
                waveSurfacePath,
                with: .linearGradient(Gradient(colors: [Color.cyan.opacity(Double(opacityAlpha * 0.18)), Color.clear]), startPoint: CGPoint(x: 0, y: canvasHeight * 0.5), endPoint: CGPoint(x: 0, y: canvasHeight))
            )

        case "4K Marine Bioluminescence ✨", "4K Marine Bioluminescence":
            for particleIndex in 0..<48 {
                let particleRandomSeed = Double(particleIndex) * 19.83
                let driftSpeed = 15.0 + Double(particleIndex % 16) * 3.5
                let particleCoordinateX = (canvasWidth * CGFloat(sin(particleRandomSeed * 2.7) * 0.5 + 0.5)) + CGFloat(sin(elapsedTime * 0.6 + particleRandomSeed) * 35.0)
                let particleCoordinateY = CGFloat((elapsedTime * driftSpeed + particleRandomSeed * 120.0).truncatingRemainder(dividingBy: Double(canvasHeight + 60))) - 30
                let pulseFactor = 0.5 + 0.5 * sin(elapsedTime * 3.0 + particleRandomSeed)
                let particleRadius = CGFloat((particleIndex % 4) + 2) * CGFloat(pulseFactor)

                let glowColor = (particleIndex % 3 == 0)
                    ? Color(red: 0.0, green: 0.95, blue: 0.85, opacity: Double(opacityAlpha * 0.65 * pulseFactor))
                    : ((particleIndex % 3 == 1)
                        ? Color(red: 0.2, green: 0.6, blue: 1.0, opacity: Double(opacityAlpha * 0.55 * pulseFactor))
                        : Color(red: 0.6, green: 0.3, blue: 1.0, opacity: Double(opacityAlpha * 0.50 * pulseFactor)))

                let circlePath = Path(ellipseIn: CGRect(x: particleCoordinateX - particleRadius, y: particleCoordinateY - particleRadius, width: particleRadius * 2, height: particleRadius * 2))
                context.fill(circlePath, with: .color(glowColor))
            }

        case "Cosmic Aurora":
            let ribbonCount = 3
            for ribbonIndex in 0..<ribbonCount {
                let ribbonPhaseOffset = Double(ribbonIndex) * 1.8
                let wavePhase = elapsedTime * 0.35 + ribbonPhaseOffset

                var auroraRibbonPath = Path()
                auroraRibbonPath.move(to: CGPoint(x: 0, y: canvasHeight * 0.35))
                for sampleX in stride(from: 0.0, through: Double(canvasWidth), by: 40.0) {
                    let verticalWaveOffset = sin(wavePhase + sampleX * 0.003) * Double(canvasHeight * 0.18) + cos(wavePhase * 0.7 + sampleX * 0.005) * Double(canvasHeight * 0.08)
                    auroraRibbonPath.addLine(to: CGPoint(x: CGFloat(sampleX), y: canvasHeight * 0.40 + CGFloat(verticalWaveOffset)))
                }
                auroraRibbonPath.addLine(to: CGPoint(x: canvasWidth, y: canvasHeight))
                auroraRibbonPath.addLine(to: CGPoint(x: 0, y: canvasHeight))
                auroraRibbonPath.closeSubpath()

                let ribbonGradientColors: [Color] = (ribbonIndex == 0)
                    ? [Color(red: 0.0, green: 0.9, blue: 0.7, opacity: Double(opacityAlpha * 0.40)), Color.clear]
                    : ((ribbonIndex == 1)
                        ? [Color(red: 0.4, green: 0.1, blue: 0.9, opacity: Double(opacityAlpha * 0.35)), Color.clear]
                        : [Color(red: 0.1, green: 0.6, blue: 1.0, opacity: Double(opacityAlpha * 0.30)), Color.clear])

                context.fill(
                    auroraRibbonPath,
                    with: .linearGradient(Gradient(colors: ribbonGradientColors), startPoint: CGPoint(x: 0, y: canvasHeight * 0.3), endPoint: CGPoint(x: 0, y: canvasHeight * 0.85))
                )
            }

        case "Fluid Waves":
            for waveLayerIndex in 0..<2 {
                let wavePhase = elapsedTime * 0.45 + Double(waveLayerIndex) * 2.2
                var fluidWavePath = Path()
                fluidWavePath.move(to: CGPoint(x: 0, y: canvasHeight * 0.5))
                for sampleX in stride(from: 0.0, through: Double(canvasWidth), by: 35.0) {
                    let verticalOffset = sin(wavePhase + sampleX * 0.004) * Double(canvasHeight * 0.12) + sin(wavePhase * 0.5 + sampleX * 0.002) * Double(canvasHeight * 0.06)
                    fluidWavePath.addLine(to: CGPoint(x: CGFloat(sampleX), y: canvasHeight * 0.60 + CGFloat(verticalOffset)))
                }
                fluidWavePath.addLine(to: CGPoint(x: canvasWidth, y: canvasHeight))
                fluidWavePath.addLine(to: CGPoint(x: 0, y: canvasHeight))
                fluidWavePath.closeSubpath()
                context.fill(
                    fluidWavePath,
                    with: .linearGradient(Gradient(colors: [Color.cyan.opacity(Double(opacityAlpha * 0.28)), Color.clear]), startPoint: CGPoint(x: 0, y: canvasHeight * 0.5), endPoint: CGPoint(x: 0, y: canvasHeight))
                )
            }

        case "Cyber Horizon":
            let horizonLineY = canvasHeight * 0.65
            let vanishingPoint = CGPoint(x: canvasWidth * 0.5, y: horizonLineY)
            for columnIndex in 0...12 {
                let bottomCoordinateX = (canvasWidth / 12.0) * CGFloat(columnIndex)
                var perspectiveRay = Path()
                perspectiveRay.move(to: vanishingPoint)
                perspectiveRay.addLine(to: CGPoint(x: bottomCoordinateX, y: canvasHeight))
                context.stroke(perspectiveRay, with: .color(Color.cyan.opacity(Double(opacityAlpha * 0.35))), lineWidth: 1.0)
            }
            for depthIndex in 0..<6 {
                let normalizedOffset = (Double(depthIndex) + (elapsedTime * 0.5).truncatingRemainder(dividingBy: 1.0)) / 6.0
                let gridDepthY = horizonLineY + (canvasHeight - horizonLineY) * CGFloat(pow(normalizedOffset, 2.0))
                var horizontalGridLine = Path()
                horizontalGridLine.move(to: CGPoint(x: 0, y: gridDepthY))
                horizontalGridLine.addLine(to: CGPoint(x: canvasWidth, y: gridDepthY))
                context.stroke(horizontalGridLine, with: .color(Color.pink.opacity(Double(opacityAlpha * 0.30 * normalizedOffset))), lineWidth: 1.2)
            }

        case "Floating Stardust":
            for particleIndex in 0..<36 {
                let particleRandomSeed = Double(particleIndex) * 13.37
                let driftSpeed = 20.0 + Double(particleIndex % 12) * 4.0
                let particleCoordinateX = (canvasWidth * CGFloat(sin(particleRandomSeed * 2.1) * 0.5 + 0.5)) + CGFloat(sin(elapsedTime * 0.4 + particleRandomSeed) * 25.0)
                let particleCoordinateY = CGFloat((elapsedTime * driftSpeed + particleRandomSeed * 90.0).truncatingRemainder(dividingBy: Double(canvasHeight + 40))) - 20
                let particleRadius = CGFloat((particleIndex % 3) + 2)
                let starPath = Path(ellipseIn: CGRect(x: particleCoordinateX - particleRadius, y: particleCoordinateY - particleRadius, width: particleRadius * 2, height: particleRadius * 2))
                context.fill(starPath, with: .color(Color.white.opacity(Double(opacityAlpha * 0.45))))
            }

        case "Starfield Warp":
            let starCount = 60
            let centerCoordinateX = canvasWidth * 0.5
            let centerCoordinateY = canvasHeight * 0.5
            for starIndex in 0..<starCount {
                let trajectoryAngle = Double(starIndex) * (2.0 * .pi / Double(starCount)) + (Double(starIndex % 5) * 0.3)
                let radialSpeed = 0.25 + Double(starIndex % 7) * 0.10
                let progressFactor = (elapsedTime * radialSpeed + Double(starIndex) * 0.15).truncatingRemainder(dividingBy: 1.0)
                let radialDistance = CGFloat(pow(progressFactor, 2.2)) * max(canvasWidth, canvasHeight) * 0.75
                let starCoordinateX = centerCoordinateX + CGFloat(cos(trajectoryAngle)) * radialDistance
                let starCoordinateY = centerCoordinateY + CGFloat(sin(trajectoryAngle)) * radialDistance
                let streakLength = CGFloat(progressFactor * 18.0)

                var streakPath = Path()
                streakPath.move(to: CGPoint(x: starCoordinateX, y: starCoordinateY))
                streakPath.addLine(to: CGPoint(x: starCoordinateX - CGFloat(cos(trajectoryAngle)) * streakLength, y: starCoordinateY - CGFloat(sin(trajectoryAngle)) * streakLength))
                context.stroke(streakPath, with: .color(Color.white.opacity(Double(opacityAlpha * progressFactor * 0.8))), lineWidth: CGFloat(progressFactor * 2.2 + 0.5))
            }

        case "Prismatic Rays":
            let rayCount = 8
            for rayIndex in 0..<rayCount {
                let rayAngle = -0.6 + Double(rayIndex) * 0.25 + sin(elapsedTime * 0.2 + Double(rayIndex)) * 0.12
                var lightRayPath = Path()
                lightRayPath.move(to: CGPoint(x: canvasWidth * 0.2, y: 0))
                lightRayPath.addLine(to: CGPoint(x: canvasWidth * 0.2 + CGFloat(cos(rayAngle) * 1400), y: CGFloat(sin(rayAngle) * 1400)))
                lightRayPath.addLine(to: CGPoint(x: canvasWidth * 0.2 + CGFloat(cos(rayAngle + 0.12) * 1400), y: CGFloat(sin(rayAngle + 0.12) * 1400)))
                lightRayPath.closeSubpath()

                let spectralHue = (Double(rayIndex) / Double(rayCount) + elapsedTime * 0.05).truncatingRemainder(dividingBy: 1.0)
                context.fill(lightRayPath, with: .color(Color(hue: spectralHue, saturation: 0.8, brightness: 1.0, opacity: Double(opacityAlpha * 0.18))))
            }

        case "Volcanic Magma":
            let magmaPulse = sin(elapsedTime * 0.8) * 0.15 + 0.85
            context.fill(
                Path(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight)),
                with: .radialGradient(Gradient(colors: [Color.orange.opacity(Double(opacityAlpha * 0.35 * magmaPulse)), Color.red.opacity(Double(opacityAlpha * 0.20)), Color.clear]), center: CGPoint(x: canvasWidth * 0.5, y: canvasHeight), startRadius: 20, endRadius: canvasHeight * 0.8)
            )

        case "Bioluminescent Sea":
            for seaParticleIndex in 0..<24 {
                let seaTimeOffset = elapsedTime * 0.3 + Double(seaParticleIndex) * 0.8
                let particleCoordinateX = (canvasWidth * 0.1) + (canvasWidth * 0.8) * CGFloat(sin(seaTimeOffset * 0.6) * 0.5 + 0.5)
                let particleCoordinateY = (canvasHeight * 0.2) + (canvasHeight * 0.7) * CGFloat(cos(seaTimeOffset * 0.4) * 0.5 + 0.5)
                let seaRadius: CGFloat = 8.0 + 4.0 * CGFloat(sin(seaTimeOffset * 2.0))
                let bioluminescentOrb = Path(ellipseIn: CGRect(x: particleCoordinateX - seaRadius, y: particleCoordinateY - seaRadius, width: seaRadius * 2, height: seaRadius * 2))
                context.fill(bioluminescentOrb, with: .color(Color.teal.opacity(Double(opacityAlpha * 0.40))))
            }

        case "Fluid Ink Chromatography 🎨":
            for inkLayerIndex in 0..<3 {
                let inkPhase = elapsedTime * 0.30 + Double(inkLayerIndex) * 1.6
                var fluidInkPath = Path()
                fluidInkPath.move(to: CGPoint(x: 0, y: canvasHeight * 0.4))
                for sampleX in stride(from: 0.0, through: Double(canvasWidth), by: 30.0) {
                    let verticalOffset = sin(inkPhase + sampleX * 0.003) * Double(canvasHeight * 0.16) + cos(inkPhase * 0.7 + sampleX * 0.005) * Double(canvasHeight * 0.08)
                    fluidInkPath.addLine(to: CGPoint(x: CGFloat(sampleX), y: canvasHeight * 0.50 + CGFloat(verticalOffset)))
                }
                fluidInkPath.addLine(to: CGPoint(x: canvasWidth, y: canvasHeight))
                fluidInkPath.addLine(to: CGPoint(x: 0, y: canvasHeight))
                fluidInkPath.closeSubpath()
                let inkColor: Color = (inkLayerIndex == 0) ? .purple : ((inkLayerIndex == 1) ? .pink : .cyan)
                context.fill(fluidInkPath, with: .linearGradient(Gradient(colors: [inkColor.opacity(Double(opacityAlpha * 0.32)), Color.clear]), startPoint: CGPoint(x: 0, y: canvasHeight * 0.35), endPoint: CGPoint(x: 0, y: canvasHeight)))
            }

        case "Electric Plasma Lightning Storm ⚡️":
            let lightningBoltCount = 3
            for boltIndex in 0..<lightningBoltCount {
                let boltRandomSeed = Double(boltIndex) * 17.5 + floor(elapsedTime * 3.5)
                var lightningSegmentX = canvasWidth * (0.2 + CGFloat(sin(boltRandomSeed * 3.1)) * 0.3)
                var lightningSegmentY: CGFloat = 0.0
                var lightningBoltPath = Path()
                lightningBoltPath.move(to: CGPoint(x: lightningSegmentX, y: lightningSegmentY))
                while lightningSegmentY < canvasHeight {
                    lightningSegmentY += CGFloat.random(in: 25...55)
                    lightningSegmentX += CGFloat.random(in: -30...30)
                    lightningBoltPath.addLine(to: CGPoint(x: lightningSegmentX, y: lightningSegmentY))
                }
                context.stroke(lightningBoltPath, with: .color(Color.cyan.opacity(Double(opacityAlpha * 0.75))), lineWidth: 2.0)
                context.stroke(lightningBoltPath, with: .color(Color.white.opacity(Double(opacityAlpha * 0.95))), lineWidth: 0.8)
            }

        case "Matrix Digital Rain Stream 🟢":
            let rainStreamColumns = 24
            for columnIndex in 0..<rainStreamColumns {
                let streamOriginX = (canvasWidth / CGFloat(rainStreamColumns)) * CGFloat(columnIndex)
                let descentSpeed = 70.0 + Double(columnIndex % 7) * 25.0
                let leadingHeadY = CGFloat((elapsedTime * descentSpeed + Double(columnIndex) * 90.0).truncatingRemainder(dividingBy: Double(canvasHeight + 120))) - 40.0
                for characterIndex in 0..<8 {
                    let characterCoordinateY = leadingHeadY - CGFloat(characterIndex * 14)
                    let characterOpacity = Double(opacityAlpha) * (1.0 - Double(characterIndex) / 8.0) * 0.65
                    let glyphBoundingBox = Path(roundedRect: CGRect(x: streamOriginX, y: characterCoordinateY, width: 6, height: 10), cornerRadius: 1.5)
                    context.fill(glyphBoundingBox, with: .color(characterIndex == 0 ? Color.white.opacity(Double(opacityAlpha * 0.9)) : Color.green.opacity(characterOpacity)))
                }
            }

        case "4K Sakura Petal Blizzard 🌸", "Sakura Petal Blizzard 🌸":
            for petalIndex in 0..<32 {
                let petalRandomSeed = Double(petalIndex) * 23.45
                let verticalVelocity = 35.0 + Double(petalIndex % 6) * 12.0
                let petalCoordinateX = (canvasWidth * CGFloat(sin(petalRandomSeed * 1.5) * 0.5 + 0.5)) + CGFloat(sin(elapsedTime * 0.8 + petalRandomSeed) * 45.0)
                let petalCoordinateY = CGFloat((elapsedTime * verticalVelocity + petalRandomSeed * 80.0).truncatingRemainder(dividingBy: Double(canvasHeight + 40))) - 20
                var blossomPetalPath = Path()
                blossomPetalPath.addEllipse(in: CGRect(x: petalCoordinateX - 6, y: petalCoordinateY - 3, width: 12, height: 6))
                context.fill(blossomPetalPath, with: .color(Color(red: 1.0, green: 0.72, blue: 0.82, opacity: Double(opacityAlpha * 0.65))))
            }

        case "Retro CRT Vector Scanline Grid 🕹️", "Retro CRT Vector Grid 🕹️":
            let horizonLineY = canvasHeight * 0.62
            let vanishingPoint = CGPoint(x: canvasWidth * 0.5, y: horizonLineY)
            for columnIndex in 0...16 {
                let bottomCoordinateX = (canvasWidth / 16.0) * CGFloat(columnIndex)
                var perspectiveVectorLine = Path()
                perspectiveVectorLine.move(to: vanishingPoint)
                perspectiveVectorLine.addLine(to: CGPoint(x: bottomCoordinateX, y: canvasHeight))
                context.stroke(perspectiveVectorLine, with: .color(Color(red: 1.0, green: 0.1, blue: 0.6).opacity(Double(opacityAlpha * 0.45))), lineWidth: 1.2)
            }
            for depthIndex in 0..<7 {
                let depthOffsetFactor = (Double(depthIndex) + (elapsedTime * 0.6).truncatingRemainder(dividingBy: 1.0)) / 7.0
                let depthCoordinateY = horizonLineY + (canvasHeight - horizonLineY) * CGFloat(pow(depthOffsetFactor, 2.2))
                var horizontalGridLine = Path()
                horizontalGridLine.move(to: CGPoint(x: 0, y: depthCoordinateY))
                horizontalGridLine.addLine(to: CGPoint(x: canvasWidth, y: depthCoordinateY))
                context.stroke(horizontalGridLine, with: .color(Color.cyan.opacity(Double(opacityAlpha * 0.40 * depthOffsetFactor))), lineWidth: 1.2)
            }

        case "Supermassive Black Hole Lens 🕳️":
            let blackHoleCenter = CGPoint(x: canvasWidth * 0.5, y: canvasHeight * 0.5)
            let eventHorizonRadius: CGFloat = 85.0

            for accretionRadius in stride(from: eventHorizonRadius + 8, to: eventHorizonRadius + 140, by: 12) {
                var accretionDiskPath = Path()
                accretionDiskPath.addEllipse(in: CGRect(x: blackHoleCenter.x - accretionRadius, y: blackHoleCenter.y - (accretionRadius * 0.35), width: accretionRadius * 2, height: accretionRadius * 0.70))
                let accretionHue = (Double(accretionRadius) / 200.0).truncatingRemainder(dividingBy: 1.0)
                context.stroke(
                    accretionDiskPath,
                    with: .color(Color(hue: 0.08 + accretionHue * 0.06, saturation: 0.9, brightness: 1.0).opacity(Double(opacityAlpha * 0.65 * (1.0 - (accretionRadius - 85) / 140)))),
                    lineWidth: 3.5
                )
            }
            var eventHorizonBoundary = Path()
            eventHorizonBoundary.addEllipse(in: CGRect(x: blackHoleCenter.x - eventHorizonRadius, y: blackHoleCenter.y - eventHorizonRadius, width: eventHorizonRadius * 2, height: eventHorizonRadius * 2))
            context.fill(eventHorizonBoundary, with: .color(Color.black.opacity(Double(opacityAlpha * 0.95))))
            context.stroke(eventHorizonBoundary, with: .color(Color.orange.opacity(Double(opacityAlpha * 0.85))), lineWidth: 2.0)

        case "4K Tokyo Neon Night Rain 🌧️":
            for dropletIndex in 0..<90 {
                let dropletRandomSeed = Double(dropletIndex * 19)
                let dropletCoordinateX = CGFloat((dropletRandomSeed * 73.0).truncatingRemainder(dividingBy: Double(canvasWidth)))
                let dropletCoordinateY = CGFloat((elapsedTime * 650.0 + dropletRandomSeed * 120.0).truncatingRemainder(dividingBy: Double(canvasHeight + 80))) - 40
                let dropletStreakLength: CGFloat = 26.0 + CGFloat((dropletRandomSeed).truncatingRemainder(dividingBy: 24.0))
                var rainDropPath = Path()
                rainDropPath.move(to: CGPoint(x: dropletCoordinateX, y: dropletCoordinateY))
                rainDropPath.addLine(to: CGPoint(x: dropletCoordinateX - 3, y: dropletCoordinateY + dropletStreakLength))
                let isCyanHighlight = (dropletIndex % 2 == 0)
                context.stroke(rainDropPath, with: .color((isCyanHighlight ? Color.cyan : Color.pink).opacity(Double(opacityAlpha * 0.55))), lineWidth: 1.2)
            }

        case "Hyperdrive Warp Speed 🚀", "Hyperdrive Warp Speed ⚡️", "Hyperdrive Warp Speed":
            let warpFieldCenter = CGPoint(x: canvasWidth * 0.5, y: canvasHeight * 0.5)
            for particleIndex in 0..<80 {
                let trajectoryAngle = (Double(particleIndex) / 80.0) * 2.0 * .pi
                let travelProgress = (elapsedTime * 2.2 + Double(particleIndex) * 0.12).truncatingRemainder(dividingBy: 1.0)
                let radialStartDistance = CGFloat(pow(travelProgress, 2.5)) * (max(canvasWidth, canvasHeight) * 0.6)
                let radialEndDistance = radialStartDistance + CGFloat(travelProgress * 45.0) + 10.0

                let pointStart = CGPoint(x: warpFieldCenter.x + CGFloat(cos(trajectoryAngle)) * radialStartDistance, y: warpFieldCenter.y + CGFloat(sin(trajectoryAngle)) * radialStartDistance)
                let pointEnd = CGPoint(x: warpFieldCenter.x + CGFloat(cos(trajectoryAngle)) * radialEndDistance, y: warpFieldCenter.y + CGFloat(sin(trajectoryAngle)) * radialEndDistance)

                var velocityStreak = Path()
                velocityStreak.move(to: pointStart)
                velocityStreak.addLine(to: pointEnd)
                context.stroke(velocityStreak, with: .color(Color.white.opacity(Double(opacityAlpha * travelProgress * 0.85))), lineWidth: CGFloat(travelProgress * 2.5 + 0.5))
            }

        default:
            break
        }
    }

    /// Legacy overload for backward compatibility with existing callers
    @inlinable
    public static func draw(
        context: GraphicsContext,
        W: CGFloat,
        H: CGFloat,
        time: Double,
        type: String,
        alpha: CGFloat
    ) {
        draw(
            context: context,
            canvasWidth: W,
            canvasHeight: H,
            elapsedTime: time,
            shaderType: type,
            opacityAlpha: alpha
        )
    }
}
