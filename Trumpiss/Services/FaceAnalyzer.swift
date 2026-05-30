//
//  FaceAnalyzer.swift
//  Trumpiss
//
//  On-device facial analysis powered by Apple's Vision framework.
//  No image ever leaves the device — every measurement is computed locally.
//

import Vision
import UIKit

/// Objective, low-level measurements extracted from a portrait.
struct FaceMetrics {
    var faceDetected: Bool = false
    var faceCount: Int = 0
    var faceFillRatio: Double = 0       // how much of the frame the face occupies (0...1)
    var roll: Double = 0                // head tilt in radians
    var yaw: Double = 0                 // head turn in radians
    var smileScore: Double = 0          // 0...1 derived from mouth landmarks
    var eyeOpenness: Double = 0         // 0...1 derived from eye landmarks
    var brightness: Double = 0.5        // 0...1 average luminance
    var symmetry: Double = 0.5          // 0...1 left/right landmark symmetry
    var captureQuality: Double = 0.5    // 0...1 Vision capture quality
    var seed: UInt64 = 0                // stable hash used for deterministic styling
}

enum FaceAnalyzerError: LocalizedError {
    case noFaceFound
    case analysisFailed

    var errorDescription: String? {
        switch self {
        case .noFaceFound:
            return "We couldn't find a clear face in that photo. Make sure your face is well lit and centered, then try again."
        case .analysisFailed:
            return "Something went wrong while analyzing your photo. Please try again."
        }
    }
}

struct FaceAnalyzer {

    func analyze(_ image: UIImage) async throws -> FaceMetrics {
        guard let cgImage = image.cgImage else { throw FaceAnalyzerError.analysisFailed }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let metrics = try Self.runRequests(on: cgImage, orientation: image.cgOrientation)
                    continuation.resume(returning: metrics)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func runRequests(on cgImage: CGImage, orientation: CGImagePropertyOrientation) throws -> FaceMetrics {
        var metrics = FaceMetrics()
        metrics.brightness = averageBrightness(of: cgImage)

        let landmarksRequest = VNDetectFaceLandmarksRequest()
        let qualityRequest = VNDetectFaceCaptureQualityRequest()

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        try handler.perform([landmarksRequest, qualityRequest])

        guard let faces = landmarksRequest.results, !faces.isEmpty else {
            throw FaceAnalyzerError.noFaceFound
        }

        // Pick the largest (closest) face as the subject.
        let subject = faces.max { lhs, rhs in
            lhs.boundingBox.area < rhs.boundingBox.area
        }!

        metrics.faceDetected = true
        metrics.faceCount = faces.count
        metrics.faceFillRatio = min(1.0, subject.boundingBox.area * 1.6)
        metrics.roll = subject.roll?.doubleValue ?? 0
        metrics.yaw = subject.yaw?.doubleValue ?? 0

        if let landmarks = subject.landmarks {
            metrics.smileScore = smileScore(from: landmarks)
            metrics.eyeOpenness = eyeOpenness(from: landmarks)
            metrics.symmetry = symmetry(from: landmarks)
        }

        if let qualityFace = qualityRequest.results?.first,
           let quality = qualityFace.faceCaptureQuality {
            metrics.captureQuality = Double(quality)
        }

        metrics.seed = stableSeed(for: subject, brightness: metrics.brightness)
        return metrics
    }

    // MARK: - Landmark heuristics

    private static func smileScore(from landmarks: VNFaceLandmarks2D) -> Double {
        guard let outerLips = landmarks.outerLips?.normalizedPoints, outerLips.count > 4 else { return 0.3 }
        let ys = outerLips.map { Double($0.y) }
        let xs = outerLips.map { Double($0.x) }
        guard let minY = ys.min(), let maxY = ys.max(),
              let minX = xs.min(), let maxX = xs.max() else { return 0.3 }
        let width = maxX - minX
        let height = maxY - minY
        guard height > 0 else { return 0.3 }
        // Wider, flatter mouths read as broader smiles.
        let ratio = width / height
        return min(1.0, max(0.0, (ratio - 1.4) / 3.0))
    }

    private static func eyeOpenness(from landmarks: VNFaceLandmarks2D) -> Double {
        func openness(_ region: VNFaceLandmarkRegion2D?) -> Double {
            guard let pts = region?.normalizedPoints, pts.count > 3 else { return 0.5 }
            let ys = pts.map { Double($0.y) }
            let xs = pts.map { Double($0.x) }
            guard let minY = ys.min(), let maxY = ys.max(),
                  let minX = xs.min(), let maxX = xs.max(), (maxX - minX) > 0 else { return 0.5 }
            return min(1.0, ((maxY - minY) / (maxX - minX)) * 2.2)
        }
        let left = openness(landmarks.leftEye)
        let right = openness(landmarks.rightEye)
        return (left + right) / 2.0
    }

    private static func symmetry(from landmarks: VNFaceLandmarks2D) -> Double {
        guard let left = landmarks.leftPupil?.normalizedPoints.first,
              let right = landmarks.rightPupil?.normalizedPoints.first,
              let nose = landmarks.nose?.normalizedPoints else { return 0.6 }
        let noseX = nose.map { Double($0.x) }.reduce(0, +) / Double(max(nose.count, 1))
        let leftDist = abs(noseX - Double(left.x))
        let rightDist = abs(Double(right.x) - noseX)
        let total = leftDist + rightDist
        guard total > 0 else { return 0.6 }
        let balance = 1.0 - abs(leftDist - rightDist) / total
        return min(1.0, max(0.0, balance))
    }

    // MARK: - Image helpers

    private static func averageBrightness(of cgImage: CGImage) -> Double {
        let width = 32
        let height = 32
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0.5 }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var total = 0.0
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let r = Double(pixels[i])
            let g = Double(pixels[i + 1])
            let b = Double(pixels[i + 2])
            total += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        }
        return total / Double(width * height)
    }

    private static func stableSeed(for face: VNFaceObservation, brightness: Double) -> UInt64 {
        var hasher = Hasher()
        hasher.combine(Int(face.boundingBox.origin.x * 100000))
        hasher.combine(Int(face.boundingBox.origin.y * 100000))
        hasher.combine(Int(face.boundingBox.width * 100000))
        hasher.combine(Int(face.boundingBox.height * 100000))
        hasher.combine(Int((face.roll?.doubleValue ?? 0) * 100000))
        hasher.combine(Int((face.yaw?.doubleValue ?? 0) * 100000))
        hasher.combine(Int(brightness * 100000))
        return UInt64(bitPattern: Int64(hasher.finalize()))
    }
}

private extension CGRect {
    var area: CGFloat { width * height }
}

private extension UIImage {
    var cgOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .upMirrored: return .upMirrored
        case .down: return .down
        case .downMirrored: return .downMirrored
        case .left: return .left
        case .leftMirrored: return .leftMirrored
        case .right: return .right
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
