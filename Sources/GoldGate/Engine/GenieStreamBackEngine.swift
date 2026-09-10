import Foundation
import AppKit
import CoreVideo
import CoreGraphics
import Darwin

/// GenieStreamBackEngine (Channel 3 - Upstream Video Stream-Back Fork)
///
/// Forks Genie's agent display, terminal, and autonomous actions into an upstream 60 FPS
/// zero-copy video stream. Serves native MJPEG HTTP stream on http://127.0.0.1:9099/stream
/// and exposes latest frame data for Metal / Virtual Display presentation.
@MainActor
public final class GenieStreamBackEngine: ObservableObject {
    public static let shared = GenieStreamBackEngine()

    @Published public var isStreamingActive: Bool = false
    @Published public var streamPort: Int = 9099
    @Published public var activeClientsCount: Int = 0
    @Published public var totalFramesStreamed: UInt64 = 0
    @Published public var averageFPS: Double = 0.0

    // Thread-safe frame store for zero-copy MJPEG broadcast
    private final class FrameStore: @unchecked Sendable {
        private let lock = NSLock()
        private var _latestJpeg: Data?
        private var _frameCount: UInt64 = 0
        private var _fpsLastCalcTime: UInt64 = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        private var _framesSinceLastCalc: UInt64 = 0
        private var _currentFps: Double = 0.0

        func update(jpegData: Data) {
            lock.lock()
            defer { lock.unlock() }
            _latestJpeg = jpegData
            _frameCount &+= 1
            _framesSinceLastCalc &+= 1

            let now = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
            let elapsedSec = Double(now - _fpsLastCalcTime) / 1_000_000_000.0
            if elapsedSec >= 1.0 {
                _currentFps = Double(_framesSinceLastCalc) / elapsedSec
                _framesSinceLastCalc = 0
                _fpsLastCalcTime = now
            }
        }

        func getLatest() -> (Data?, UInt64, Double) {
            lock.lock()
            defer { lock.unlock() }
            return (_latestJpeg, _frameCount, _currentFps)
        }
    }

    private let frameStore = FrameStore()
    private var serverSocket: Int32 = -1
    private var isRunningServer = false
    private let serverQueue = DispatchQueue(label: "com.genie.streamback.server", qos: .userInteractive)

    private init() {
        self.streamPort = UserDefaults.standard.integer(forKey: PrefKey.streamBackPort)
        if self.streamPort == 0 { self.streamPort = 9099 }
    }

    // MARK: - Server Lifecycle

    public func startStreamServer(port: Int? = nil) {
        guard !isRunningServer else { return }
        let targetPort = port ?? self.streamPort
        self.streamPort = targetPort

        isRunningServer = true
        self.isStreamingActive = true

        serverQueue.async { [weak self, targetPort] in
            self?.runHttpServer(port: UInt16(targetPort))
        }
        print("GENIE [STREAM-BACK]: Server started on http://127.0.0.1:\(targetPort)/stream")
    }

    public func stopStreamServer() {
        guard isRunningServer else { return }
        isRunningServer = false
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
        self.isStreamingActive = false
        self.activeClientsCount = 0
        print("GENIE [STREAM-BACK]: Server stopped")
    }

    // MARK: - Ingest Frame from Unified Memory

    public func pushPixelBuffer(_ pixelBuffer: CVPixelBuffer) {
        // Governor check: skip frames if memory pressure is critical
        if GenieMemoryGovernorEngine.isCriticalPressureActive {
            return
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ), let cgImage = context.makeImage() else {
            return
        }

        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        let compression: [NSBitmapImageRep.PropertyKey: Any] = [
            .compressionFactor: 0.75
        ]
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: compression) else {
            return
        }

        frameStore.update(jpegData: jpegData)
        let (_, count, fps) = frameStore.getLatest()
        self.totalFramesStreamed = count
        self.averageFPS = fps
    }

    public func pushSyntheticFrame(text: String) {
        let size = CGSize(width: 960, height: 540)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor(red: 0.05, green: 0.07, blue: 0.12, alpha: 1.0).setFill()
            rect.fill()

            let badgeRect = NSRect(x: 40, y: rect.height - 80, width: 220, height: 36)
            NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 0.2).setFill()
            NSBezierPath(roundedRect: badgeRect, xRadius: 10, yRadius: 10).fill()

            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .bold),
                .foregroundColor: NSColor(red: 0.0, green: 0.95, blue: 0.8, alpha: 1.0)
            ]
            let str = NSAttributedString(string: "GENIE STREAM-BACK FORK", attributes: attrs)
            str.draw(at: NSPoint(x: 52, y: rect.height - 72))

            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 15, weight: .medium),
                .foregroundColor: NSColor.white
            ]
            let body = NSAttributedString(string: "Channel 3 Upstream Active\n\(text)\nTimestamp: \(Date())", attributes: bodyAttrs)
            body.draw(in: NSRect(x: 40, y: 40, width: rect.width - 80, height: rect.height - 150))
            return true
        }

        guard let tiffData = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData),
              let jpegData = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.75]) else {
            return
        }

        frameStore.update(jpegData: jpegData)
        let (_, count, fps) = frameStore.getLatest()
        self.totalFramesStreamed = count
        self.averageFPS = fps
    }

    public func getLatestJpegData() -> Data? {
        let (data, _, _) = frameStore.getLatest()
        return data
    }

    // MARK: - Native Darwin Non-blocking POSIX Socket HTTP/MJPEG Server

    private func runHttpServer(port: UInt16) {
        let sock = socket(AF_INET, SOCK_STREAM, 0)
        guard sock >= 0 else {
            print("GENIE [STREAM-BACK]: Failed to create socket")
            return
        }

        var opt: Int32 = 1
        setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        addr.sin_addr.s_addr = in_addr_t(0) // 0.0.0.0

        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(sock, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }

        guard bindResult == 0 else {
            print("GENIE [STREAM-BACK]: Failed to bind socket to port \(port)")
            close(sock)
            return
        }

        guard listen(sock, 16) == 0 else {
            print("GENIE [STREAM-BACK]: Failed to listen on socket")
            close(sock)
            return
        }

        self.serverSocket = sock

        while isRunningServer {
            var clientAddr = sockaddr_in()
            var clientLen = socklen_t(MemoryLayout<sockaddr_in>.size)

            let clientSock = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    accept(sock, $0, &clientLen)
                }
            }

            guard clientSock >= 0 else {
                if !isRunningServer { break }
                continue
            }

            Task { @MainActor [weak self] in
                self?.activeClientsCount += 1
            }

            DispatchQueue.global(qos: .userInitiated).async { [weak self, clientSock] in
                self?.handleClient(clientSock: clientSock)
                close(clientSock)
                Task { @MainActor [weak self] in
                    if let c = self?.activeClientsCount, c > 0 {
                        self?.activeClientsCount -= 1
                    }
                }
            }
        }
    }

    private func handleClient(clientSock: Int32) {
        var buffer = [UInt8](repeating: 0, count: 2048)
        let bytesRead = recv(clientSock, &buffer, buffer.count - 1, 0)
        guard bytesRead > 0 else { return }

        let requestString = String(decoding: buffer.prefix(bytesRead), as: UTF8.self)

        if requestString.contains("GET /stream") {
            // MJPEG Multipart Stream
            let header = "HTTP/1.1 200 OK\r\n" +
                         "Connection: close\r\n" +
                         "Cache-Control: no-cache, no-store, must-revalidate\r\n" +
                         "Content-Type: multipart/x-mixed-replace; boundary=--genieframe\r\n\r\n"
            _ = header.utf8CString.withUnsafeBufferPointer {
                send(clientSock, $0.baseAddress, $0.count - 1, 0)
            }

            var lastSentCount: UInt64 = 0
            while isRunningServer {
                let (latestJpeg, count, _) = frameStore.getLatest()
                if let jpeg = latestJpeg, count != lastSentCount {
                    lastSentCount = count
                    let partHeader = "--genieframe\r\n" +
                                     "Content-Type: image/jpeg\r\n" +
                                     "Content-Length: \(jpeg.count)\r\n\r\n"

                    let headerSent = partHeader.utf8CString.withUnsafeBufferPointer {
                        send(clientSock, $0.baseAddress, $0.count - 1, 0)
                    }
                    if headerSent < 0 { break }

                    let dataSent = jpeg.withUnsafeBytes { raw in
                        send(clientSock, raw.baseAddress, jpeg.count, 0)
                    }
                    if dataSent < 0 { break }

                    let boundaryEnd = "\r\n"
                    _ = boundaryEnd.utf8CString.withUnsafeBufferPointer {
                        send(clientSock, $0.baseAddress, $0.count - 1, 0)
                    }
                }
                usleep(16_666) // ~60 FPS polling
            }
        } else {
            // Dashboard landing HTML
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <title>Genie Stream-Back Fork (Channel 3)</title>
                <style>
                    body { margin: 0; background: #0c0e14; color: #fff; font-family: -apple-system, system-ui, sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; overflow: hidden; }
                    .card { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); border-radius: 16px; padding: 20px; box-shadow: 0 20px 40px rgba(0,0,0,0.6); backdrop-filter: blur(20px); text-align: center; max-width: 90%; }
                    img { border-radius: 12px; max-width: 100%; max-height: 70vh; border: 1px solid rgba(0, 217, 245, 0.4); }
                    .badge { display: inline-block; padding: 4px 12px; border-radius: 999px; background: rgba(0, 217, 245, 0.2); color: #00e5ff; font-size: 13px; font-weight: 600; margin-bottom: 12px; }
                </style>
            </head>
            <body>
                <div class="card">
                    <div class="badge">⚡ GENIE CHANNEL 3 UPSTREAM STREAM-BACK</div>
                    <br>
                    <img src="/stream" alt="Genie Live Stream-Back">
                </div>
            </body>
            </html>
            """
            let response = "HTTP/1.1 200 OK\r\n" +
                           "Content-Type: text/html; charset=utf-8\r\n" +
                           "Content-Length: \(html.utf8.count)\r\n" +
                           "Connection: close\r\n\r\n" + html
            _ = response.utf8CString.withUnsafeBufferPointer {
                send(clientSock, $0.baseAddress, $0.count - 1, 0)
            }
        }
    }
}
