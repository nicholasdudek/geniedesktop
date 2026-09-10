import Foundation
import CoreGraphics

// MARK: - 📈 Genie Regenerative Linear Regression Engine
// High-performance kinematics, trajectory forecasting, and kinetic energy recapture engine.
// Combines:
// 1. Exponential Time-Decay Weighted Ordinary Least Squares (WOLS)
// 2. Online Recursive Least Squares (RLS) with Dynamic Covariance Regeneration
// 3. R² Intent Confidence Analysis & Regenerative Momentum Braking
// 4. Ballistic Stopping Trajectory & System Resource Escalation Forecasting

/// A single timestamped kinematic sample along 1D spatial coordinates.
public struct KinematicSample: Sendable, Hashable {
    public let timestamp: TimeInterval
    public let position: CGFloat

    public init(timestamp: TimeInterval, position: CGFloat) {
        self.timestamp = timestamp
        self.position = position
    }
}

/// The analytical output of the Regenerative Linear Regression engine.
public struct RegressionFitResult: Sendable {
    /// Fitted slope: instantaneous velocity dy/dt in points/second.
    public let slope: CGFloat
    /// Fitted intercept at reference timestamp t = 0.
    public let intercept: CGFloat
    /// Pearson correlation coefficient r in [-1.0, 1.0].
    public let correlation: Double
    /// Coefficient of determination R² in [0.0, 1.0]. Represents intent stability.
    public let rSquared: Double
    /// Residual standard error of the fit.
    public let standardError: Double
    /// Count of valid samples included in this regression fit.
    public let sampleCount: Int
    /// Effective time delta span in seconds across the sample window.
    public let timeSpan: TimeInterval
    /// Regenerative kinetic damping scale in [0.0, 1.0] derived from R² intent confidence.
    public let regenerativeDampingScale: Double
    /// Final intent-adjusted release velocity: slope * regenerativeDampingScale.
    public let adjustedVelocity: CGFloat

    public init(
        slope: CGFloat,
        intercept: CGFloat,
        correlation: Double,
        rSquared: Double,
        standardError: Double,
        sampleCount: Int,
        timeSpan: TimeInterval,
        regenerativeDampingScale: Double,
        adjustedVelocity: CGFloat
    ) {
        self.slope = slope
        self.intercept = intercept
        self.correlation = correlation
        self.rSquared = rSquared
        self.standardError = standardError
        self.sampleCount = sampleCount
        self.timeSpan = timeSpan
        self.regenerativeDampingScale = regenerativeDampingScale
        self.adjustedVelocity = adjustedVelocity
    }

    /// Default empty / zero result when insufficient data points are available.
    public static var zero: RegressionFitResult {
        RegressionFitResult(
            slope: 0.0,
            intercept: 0.0,
            correlation: 0.0,
            rSquared: 0.0,
            standardError: 0.0,
            sampleCount: 0,
            timeSpan: 0.0,
            regenerativeDampingScale: 0.0,
            adjustedVelocity: 0.0
        )
    }
}

/// Tuning parameters for the Regenerative Linear Regression physics engine.
public struct RegenerativeParameters: Sendable {
    /// Half-life in seconds for exponential sample recency weighting (default 45ms).
    public var halfLifeSeconds: Double = 0.045
    /// Minimum samples required to compute a valid regression fit.
    public var minSamples: Int = 3
    /// Minimum R² intent threshold below which regenerative braking engages aggressively.
    public var minRSquaredForCoasting: Double = 0.60
    /// Exponent used to scale kinetic energy dissipation as a function of R².
    public var dampingCurveExponent: Double = 1.8
    /// Fluid friction gamma constant for exponential deceleration (v(t) = v0 * e^(-gamma*t)).
    public var fluidFrictionGamma: Double = 3.2

    public init(
        halfLifeSeconds: Double = 0.045,
        minSamples: Int = 3,
        minRSquaredForCoasting: Double = 0.60,
        dampingCurveExponent: Double = 1.8,
        fluidFrictionGamma: Double = 3.2
    ) {
        self.halfLifeSeconds = halfLifeSeconds
        self.minSamples = minSamples
        self.minRSquaredForCoasting = minRSquaredForCoasting
        self.dampingCurveExponent = dampingCurveExponent
        self.fluidFrictionGamma = fluidFrictionGamma
    }
}

// MARK: - Core Engine Implementation

public final class GenieRegenerativeLinearRegressionEngine: @unchecked Sendable {
    public static let shared = GenieRegenerativeLinearRegressionEngine()

    public var parameters: RegenerativeParameters

    public init(parameters: RegenerativeParameters = RegenerativeParameters()) {
        self.parameters = parameters
    }

    // MARK: - 1. Time-Decay Weighted Ordinary Least Squares (WOLS)

    /// Fits a time-decay weighted ordinary linear regression model to the given kinematic samples.
    /// Recent samples are exponentially weighted: w_i = exp(-ln(2) * (t_now - t_i) / halfLife).
    public func fit(
        samples: [KinematicSample],
        referenceTimestamp: TimeInterval? = nil
    ) -> RegressionFitResult {
        guard samples.count >= 2 else { return .zero }

        let tNow = referenceTimestamp ?? (samples.last?.timestamp ?? 0.0)
        let sorted = samples.sorted(by: { $0.timestamp < $1.timestamp })

        guard let first = sorted.first, let last = sorted.last else { return .zero }
        let totalSpan = last.timestamp - first.timestamp
        guard totalSpan > 0.002 else { return .zero }

        let tau = max(0.005, parameters.halfLifeSeconds)
        let decayConstant = log(2.0) / tau

        var sumW: Double = 0.0
        var sumWT: Double = 0.0
        var sumWY: Double = 0.0
        var sumWTT: Double = 0.0
        var sumWYY: Double = 0.0
        var sumWTY: Double = 0.0

        for sample in sorted {
            let dt = max(0.0, tNow - sample.timestamp)
            // Weight decreases exponentially with age
            let weight = exp(-decayConstant * dt)
            let t = sample.timestamp - first.timestamp // Normalized time from start of window
            let y = Double(sample.position)

            sumW += weight
            sumWT += weight * t
            sumWY += weight * y
            sumWTT += weight * t * t
            sumWYY += weight * y * y
            sumWTY += weight * t * y
        }

        guard sumW > 1e-9 else { return .zero }

        // Denominator: Covariance of T
        let deltaT = (sumW * sumWTT) - (sumWT * sumWT)
        guard abs(deltaT) > 1e-9 else {
            // Degenerate case: all samples at identical timestamp
            return .zero
        }

        // Weighted slope beta_1 = (W * sumWTY - sumWT * sumWY) / deltaT
        let slopeDouble = ((sumW * sumWTY) - (sumWT * sumWY)) / deltaT
        // Weighted intercept beta_0 = (sumWY - slope * sumWT) / sumW
        let interceptDouble = (sumWY - (slopeDouble * sumWT)) / sumW

        // Residual sum of squares & total sum of squares for R² calculation
        let meanY = sumWY / sumW
        var ssTot: Double = 0.0
        var ssRes: Double = 0.0

        for sample in sorted {
            let dt = max(0.0, tNow - sample.timestamp)
            let weight = exp(-decayConstant * dt)
            let t = sample.timestamp - first.timestamp
            let y = Double(sample.position)
            let yPred = (slopeDouble * t) + interceptDouble

            let residual = y - yPred
            let deviation = y - meanY

            ssRes += weight * residual * residual
            ssTot += weight * deviation * deviation
        }

        let rSquared: Double
        if ssTot > 1e-9 {
            rSquared = max(0.0, min(1.0, 1.0 - (ssRes / ssTot)))
        } else {
            // Zero variance in Y -> perfectly flat line
            rSquared = 1.0
        }

        let correlation = sqrt(rSquared) * (slopeDouble >= 0 ? 1.0 : -1.0)
        let standardError = samples.count > 2 ? sqrt(ssRes / Double(samples.count - 2)) : 0.0

        // Regenerative Damping Computation:
        // High R² (decisive gesture) preserves 100% of momentum.
        // Low R² (erratic stutter or hesitation) dampens velocity toward zero,
        // recapturing chaotic kinetic energy into potential anchor spring tension.
        let dampingScale: Double
        if rSquared >= parameters.minRSquaredForCoasting {
            // Normalized curve from minRSquaredForCoasting to 1.0
            let normalizedR2 = (rSquared - parameters.minRSquaredForCoasting) / (1.0 - parameters.minRSquaredForCoasting)
            dampingScale = 0.5 + 0.5 * pow(normalizedR2, parameters.dampingCurveExponent)
        } else {
            // Below threshold: sharp regenerative braking
            let ratio = max(0.0, rSquared / max(0.001, parameters.minRSquaredForCoasting))
            dampingScale = 0.5 * pow(ratio, 2.0)
        }

        let slope = CGFloat(slopeDouble)
        let adjustedVelocity = slope * CGFloat(dampingScale)

        return RegressionFitResult(
            slope: slope,
            intercept: CGFloat(interceptDouble),
            correlation: correlation,
            rSquared: rSquared,
            standardError: standardError,
            sampleCount: samples.count,
            timeSpan: totalSpan,
            regenerativeDampingScale: dampingScale,
            adjustedVelocity: adjustedVelocity
        )
    }

    // MARK: - 2. Ballistic Trajectory & Stopping Projection

    /// Projects the final stopping distance and endpoint accounting for exponential friction
    /// and regenerative kinetic damping.
    public func projectBallisticDisplacement(
        velocity: CGFloat,
        rSquared: Double,
        gamma: Double? = nil
    ) -> (rawDisplacement: CGFloat, regenerativeDisplacement: CGFloat, isFlickIntentValid: Bool) {
        let effGamma = CGFloat(gamma ?? parameters.fluidFrictionGamma)
        guard effGamma > 0.001 else { return (0, 0, false) }

        // Classic ballistic integration: integral from 0 to inf of v0 * e^(-gamma * t) dt = v0 / gamma
        let rawDisplacement = velocity / effGamma

        // Intent factor modulates whether the flick was intentional or accidental
        let isValidIntent = rSquared >= parameters.minRSquaredForCoasting
        let regenScale = isValidIntent ? 1.0 : (rSquared / max(0.001, parameters.minRSquaredForCoasting))
        let regenerativeDisplacement = rawDisplacement * CGFloat(regenScale)

        return (rawDisplacement, regenerativeDisplacement, isValidIntent)
    }

    // MARK: - 3. Streaming Online Recursive Least Squares (RLS) Tracker

    /// Creates an online O(1) recursive least squares estimator that updates continuously
    /// as live points stream from trackpad or sensor hardware.
    public func makeStreamingTracker(forgettingFactor: Double = 0.94) -> RecursiveLeastSquaresTracker {
        return RecursiveLeastSquaresTracker(lambda: forgettingFactor)
    }

    // MARK: - 4. Telemetry & Resource Drift Forecasting

    /// Computes the linear trend and predicted escalation rate for system metrics
    /// (e.g. process RAM MB or frame render latency).
    public func forecastTrend(
        timeSeries: [(timestamp: TimeInterval, value: Double)]
    ) -> (slopePerSecond: Double, rSquared: Double, projectedInSeconds: (Double) -> Double) {
        guard timeSeries.count >= 2 else {
            return (0.0, 0.0, { _ in timeSeries.last?.value ?? 0.0 })
        }

        let samples = timeSeries.map { KinematicSample(timestamp: $0.timestamp, position: CGFloat($0.value)) }
        let result = fit(samples: samples)
        let slope = Double(result.slope)
        let lastValue = timeSeries.last?.value ?? 0.0

        return (
            slopePerSecond: slope,
            rSquared: result.rSquared,
            projectedInSeconds: { (secondsAhead: Double) in
                return lastValue + (slope * secondsAhead)
            }
        )
    }
}

// MARK: - 🔄 Online Recursive Least Squares Tracker
/// Maintains a running estimate of slope and intercept with O(1) time and memory overhead.
public final class RecursiveLeastSquaresTracker: @unchecked Sendable {
    private let lambda: Double // Forgetting factor (0.90 to 0.99)
    private var theta: (slope: Double, intercept: Double) = (0.0, 0.0)
    private var P: (p00: Double, p01: Double, p10: Double, p11: Double) = (1000.0, 0.0, 0.0, 1000.0)
    private var referenceT: TimeInterval?
    private var count: Int = 0

    public init(lambda: Double = 0.95) {
        self.lambda = max(0.80, min(1.0, lambda))
    }

    /// Ingests a new live sample into the recursive filter.
    public func update(timestamp: TimeInterval, position: CGFloat) {
        if referenceT == nil {
            referenceT = timestamp
        }
        let t = timestamp - (referenceT ?? timestamp)
        let y = Double(position)
        count += 1

        if count == 1 {
            theta.intercept = y
            return
        }

        // x vector: [t, 1.0]
        let x0 = t
        let x1 = 1.0

        // P * x
        let Px0 = P.p00 * x0 + P.p01 * x1
        let Px1 = P.p10 * x0 + P.p11 * x1

        // x^T * P * x
        let xPx = x0 * Px0 + x1 * Px1
        let denom = lambda + xPx
        guard abs(denom) > 1e-9 else { return }

        // Kalman gain vector K = (P * x) / (lambda + x^T * P * x)
        let k0 = Px0 / denom
        let k1 = Px1 / denom

        // Innovation error e = y - x^T * theta
        let predY = x0 * theta.slope + x1 * theta.intercept
        let error = y - predY

        // State update: theta = theta + K * error
        theta.slope += k0 * error
        theta.intercept += k1 * error

        // Covariance regeneration: P = (1/lambda) * [P - K * (x^T * P)]
        let invLambda = 1.0 / lambda
        let k_xP_00 = k0 * Px0
        let k_xP_01 = k0 * Px1
        let k_xP_10 = k1 * Px0
        let k_xP_11 = k1 * Px1

        P.p00 = invLambda * (P.p00 - k_xP_00)
        P.p01 = invLambda * (P.p01 - k_xP_01)
        P.p10 = invLambda * (P.p10 - k_xP_10)
        P.p11 = invLambda * (P.p11 - k_xP_11)
    }

    public var currentVelocity: CGFloat {
        return CGFloat(theta.slope)
    }

    public var sampleCount: Int {
        return count
    }

    public func reset() {
        theta = (0.0, 0.0)
        P = (1000.0, 0.0, 0.0, 1000.0)
        referenceT = nil
        count = 0
    }
}
