import Foundation
import simd

// MARK: - Spatial Quaternion Engine (6DOF Spatial Tracking & Gimbal-Lock-Free Navigation)
// Ported from C++/huml_core quaternion spatial engine.
// Implements full non-singular 3D rotations, SLERP interpolation, and 4x4 projection transforms.

public struct SpatialQuaternion: Equatable {
    public var w: Float
    public var x: Float
    public var y: Float
    public var z: Float

    public static let identity = SpatialQuaternion(w: 1, x: 0, y: 0, z: 0)

    public init(w: Float = 1, x: Float = 0, y: Float = 0, z: Float = 0) {
        self.w = w
        self.x = x
        self.y = y
        self.z = z
    }

    /// Construct quaternion from Euler angles (in radians: pitch, yaw, roll)
    public static func fromEuler(pitch: Float, yaw: Float, roll: Float) -> SpatialQuaternion {
        let cy = cos(yaw * 0.5)
        let sy = sin(yaw * 0.5)
        let cp = cos(pitch * 0.5)
        let sp = sin(pitch * 0.5)
        let cr = cos(roll * 0.5)
        let sr = sin(roll * 0.5)

        return SpatialQuaternion(
            w: cr * cp * cy + sr * sp * sy,
            x: sr * cp * cy - cr * sp * sy,
            y: cr * sp * cy + sr * cp * sy,
            z: cr * cp * sy - sr * sp * cy
        ).normalized()
    }

    public var magnitude: Float {
        sqrt(w * w + x * x + y * y + z * z)
    }

    public func normalized() -> SpatialQuaternion {
        let mag = magnitude
        guard mag > 1e-6 else { return .identity }
        let inv = 1.0 / mag
        return SpatialQuaternion(w: w * inv, x: x * inv, y: y * inv, z: z * inv)
    }

    public var conjugate: SpatialQuaternion {
        SpatialQuaternion(w: w, x: -x, y: -y, z: -z)
    }

    public var inverse: SpatialQuaternion {
        let magSq = w * w + x * x + y * y + z * z
        guard magSq > 1e-6 else { return .identity }
        let inv = 1.0 / magSq
        return SpatialQuaternion(w: w * inv, x: -x * inv, y: -y * inv, z: -z * inv)
    }

    public static func * (lhs: SpatialQuaternion, rhs: SpatialQuaternion) -> SpatialQuaternion {
        SpatialQuaternion(
            w: lhs.w * rhs.w - lhs.x * rhs.x - lhs.y * rhs.y - lhs.z * rhs.z,
            x: lhs.w * rhs.x + lhs.x * rhs.w + lhs.y * rhs.z - lhs.z * rhs.y,
            y: lhs.w * rhs.y - lhs.x * rhs.z + lhs.y * rhs.w + lhs.z * rhs.x,
            z: lhs.w * rhs.z + lhs.x * rhs.y - lhs.y * rhs.x + lhs.z * rhs.w
        )
    }

    public static func dot(_ q1: SpatialQuaternion, _ q2: SpatialQuaternion) -> Float {
        q1.w * q2.w + q1.x * q2.x + q1.y * q2.y + q1.z * q2.z
    }

    /// Spherical Linear Interpolation (SLERP) for jitter-free 120 FPS camera rotations
    public static func slerp(from q1: SpatialQuaternion, to q2: SpatialQuaternion, t: Float) -> SpatialQuaternion {
        var end = q2
        var cosOmega = dot(q1, end)

        if cosOmega < 0.0 {
            end = SpatialQuaternion(w: -end.w, x: -end.x, y: -end.y, z: -end.z)
            cosOmega = -cosOmega
        }

        if cosOmega > 0.9995 {
            // Linear interpolation fallback when very close to avoid division by zero
            return SpatialQuaternion(
                w: q1.w + t * (end.w - q1.w),
                x: q1.x + t * (end.x - q1.x),
                y: q1.y + t * (end.y - q1.y),
                z: q1.z + t * (end.z - q1.z)
            ).normalized()
        }

        let omega = acos(cosOmega)
        let sinOmega = sin(omega)
        let scale1 = sin((1.0 - t) * omega) / sinOmega
        let scale2 = sin(t * omega) / sinOmega

        return SpatialQuaternion(
            w: scale1 * q1.w + scale2 * end.w,
            x: scale1 * q1.x + scale2 * end.x,
            y: scale1 * q1.y + scale2 * end.y,
            z: scale1 * q1.z + scale2 * end.z
        ).normalized()
    }

    /// Rotate 3D vector by this quaternion: v' = q * v * q^-1
    public func rotateVector(_ v: SIMD3<Float>) -> SIMD3<Float> {
        let qv = SpatialQuaternion(w: 0, x: v.x, y: v.y, z: v.z)
        let rotated = (self * qv) * self.conjugate
        return SIMD3<Float>(rotated.x, rotated.y, rotated.z)
    }

    /// Convert to 3x3 rotation matrix
    public var rotationMatrix3x3: simd_float3x3 {
        let qn = self.normalized()
        let xx = qn.x * qn.x
        let yy = qn.y * qn.y
        let zz = qn.z * qn.z
        let xy = qn.x * qn.y
        let xz = qn.x * qn.z
        let yz = qn.y * qn.z
        let wx = qn.w * qn.x
        let wy = qn.w * qn.y
        let wz = qn.w * qn.z

        return simd_float3x3(
            SIMD3<Float>(1.0 - 2.0 * (yy + zz), 2.0 * (xy - wz), 2.0 * (xz + wy)),
            SIMD3<Float>(2.0 * (xy + wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz - wx)),
            SIMD3<Float>(2.0 * (xz - wy), 2.0 * (yz + wx), 1.0 - 2.0 * (xx + yy))
        )
    }
}
