import AppKit
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

// MARK: - 🖼️ Image Cache Manager
public final class GenieImageCache {
    public static let shared = GenieImageCache()
    private let cache = NSCache<NSURL, NSData>()

    private init() {
        cache.totalCostLimit = 128 * 1024 * 1024 // 128 MB cache
    }

    public func data(for url: URL) -> Data? {
        cache.object(forKey: url as NSURL) as Data?
    }

    public func set(data: Data, for url: URL) {
        cache.setObject(data as NSData, forKey: url as NSURL, cost: data.count)
    }
}

// MARK: - 📑 Image Metadata Inspector
public struct GenieImageMetadata: Equatable {
    public let width: Int
    public let height: Int
    public let format: String
    public let isAnimated: Bool
    public let frameCount: Int
    public let duration: Double
    public let fileSize: Int64

    public var dimensionsString: String {
        guard width > 0 && height > 0 else { return "" }
        return "\(width) × \(height)"
    }

    public var badgeLabel: String {
        if isAnimated {
            return "GIF • \(frameCount) frames"
        }
        return format.uppercased()
    }

    public static func inspect(url: URL) -> GenieImageMetadata? {
        if url.isFileURL {
            guard let data = try? Data(contentsOf: url) else { return nil }
            return inspect(data: data, fileSize: Int64(data.count))
        }
        if let data = GenieImageCache.shared.data(for: url) {
            return inspect(data: data, fileSize: Int64(data.count))
        }
        return nil
    }

    public static func inspect(data: Data, fileSize: Int64 = 0) -> GenieImageMetadata? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        let type = CGImageSourceGetType(source) as String? ?? "public.image"

        var format = "IMAGE"
        if type.contains("gif") { format = "GIF" }
        else if type.contains("jpeg") || type.contains("jpg") { format = "JPEG" }
        else if type.contains("png") { format = "PNG" }
        else if type.contains("webp") { format = "WEBP" }
        else if type.contains("heic") { format = "HEIC" }

        var width = 0
        var height = 0
        var totalDuration: Double = 0.0

        if let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
            width = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
            height = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        }

        let isAnimated = (count > 1 && (format == "GIF" || format == "WEBP" || type.contains("gif")))

        if isAnimated {
            for i in 0..<count {
                if let frameProps = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
                   let gifProps = frameProps[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                    let delay = gifProps[kCGImagePropertyGIFUnclampedDelayTime] as? Double
                        ?? gifProps[kCGImagePropertyGIFDelayTime] as? Double
                        ?? 0.1
                    totalDuration += max(0.02, delay)
                }
            }
        }

        return GenieImageMetadata(
            width: width,
            height: height,
            format: format,
            isAnimated: isAnimated,
            frameCount: count,
            duration: totalDuration,
            fileSize: fileSize > 0 ? fileSize : Int64(data.count)
        )
    }
}

// MARK: - 🎞️ Native AppKit Animated Image View Representable
/// Uses native macOS NSImageView with animates = true to smoothly play animated GIFs
/// and render high-resolution JPG/JPEG/PNG images with hardware acceleration.
public struct GenieAnimatedImageView: NSViewRepresentable {
    public let url: URL?
    public let image: NSImage?
    public var scaling: NSImageScaling = .scaleProportionallyUpOrDown
    public var animates: Bool = true
    public var onLoaded: ((GenieImageMetadata?) -> Void)? = nil

    public init(
        url: URL? = nil,
        image: NSImage? = nil,
        scaling: NSImageScaling = .scaleProportionallyUpOrDown,
        animates: Bool = true,
        onLoaded: ((GenieImageMetadata?) -> Void)? = nil
    ) {
        self.url = url
        self.image = image
        self.scaling = scaling
        self.animates = animates
        self.onLoaded = onLoaded
    }

    public func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = scaling
        imageView.animates = animates
        imageView.canDrawSubviewsIntoLayer = true
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        loadImage(into: imageView, context: context)
        return imageView
    }

    public func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.imageScaling = scaling
        nsView.animates = animates

        if context.coordinator.currentURL != url || (url == nil && context.coordinator.currentImage != image) {
            loadImage(into: nsView, context: context)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public final class Coordinator {
        var parent: GenieAnimatedImageView
        var currentURL: URL? = nil
        var currentImage: NSImage? = nil
        var loadTask: Task<Void, Never>? = nil

        init(_ parent: GenieAnimatedImageView) {
            self.parent = parent
        }

        deinit {
            loadTask?.cancel()
        }
    }

    private func loadImage(into imageView: NSImageView, context: Context) {
        context.coordinator.loadTask?.cancel()
        context.coordinator.currentURL = url
        context.coordinator.currentImage = image

        // If a direct NSImage was passed
        if let directImage = image {
            imageView.image = directImage
            if animates { imageView.animates = true }
            return
        }

        guard let targetURL = url else {
            imageView.image = nil
            return
        }

        // Local file loading
        if targetURL.isFileURL {
            DispatchQueue.global(qos: .userInitiated).async {
                guard let data = try? Data(contentsOf: targetURL),
                      let loadedImage = NSImage(data: data) else {
                    DispatchQueue.main.async { imageView.image = nil }
                    return
                }

                let meta = GenieImageMetadata.inspect(data: data, fileSize: Int64(data.count))

                DispatchQueue.main.async {
                    imageView.image = loadedImage
                    imageView.animates = animates
                    onLoaded?(meta)
                }
            }
            return
        }

        // Check memory cache for remote images
        if let cachedData = GenieImageCache.shared.data(for: targetURL),
           let cachedImage = NSImage(data: cachedData) {
            imageView.image = cachedImage
            imageView.animates = animates
            let meta = GenieImageMetadata.inspect(data: cachedData, fileSize: Int64(cachedData.count))
            onLoaded?(meta)
            return
        }

        // Asynchronous remote URL download
        context.coordinator.loadTask = Task { @MainActor in
            do {
                let (data, _) = try await URLSession.shared.data(from: targetURL)
                guard !Task.isCancelled else { return }

                GenieImageCache.shared.set(data: data, for: targetURL)

                if let downloadedImage = NSImage(data: data) {
                    imageView.image = downloadedImage
                    imageView.animates = animates
                    let meta = GenieImageMetadata.inspect(data: data, fileSize: Int64(data.count))
                    onLoaded?(meta)
                }
            } catch {
                // Silently handle canceled or failed downloads
                if !Task.isCancelled {
                    imageView.image = nil
                }
            }
        }
    }
}

// MARK: - 🌟 High-Level Genie Image & GIF Card View
/// Complete card for rendering JPG and GIF images with badges, metadata, zoom, and action buttons.
public struct GenieImageCardView: View {
    public let url: URL?
    public let altText: String?
    public var maxDisplayHeight: CGFloat = 340
    public var allowInspect: Bool = true

    @State private var metadata: GenieImageMetadata? = nil
    @State private var isHovering: Bool = false
    @State private var isPlayingGif: Bool = true
    @State private var showFullQuickLook: Bool = false
    @State private var isCopied: Bool = false

    public init(
        url: URL?,
        altText: String? = nil,
        maxDisplayHeight: CGFloat = 340,
        allowInspect: Bool = true
    ) {
        self.url = url
        self.altText = altText
        self.maxDisplayHeight = maxDisplayHeight
        self.allowInspect = allowInspect
    }

    private var isGif: Bool {
        if let meta = metadata { return meta.isAnimated }
        guard let url = url else { return false }
        return url.pathExtension.lowercased() == "gif"
    }

    private var isJpg: Bool {
        guard let url = url else { return false }
        let ext = url.pathExtension.lowercased()
        return ext == "jpg" || ext == "jpeg"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Main Animated / High-Res Image Viewport
                GenieAnimatedImageView(
                    url: url,
                    scaling: .scaleProportionallyUpOrDown,
                    animates: isPlayingGif,
                    onLoaded: { meta in
                        self.metadata = meta
                    }
                )
                .frame(maxHeight: maxDisplayHeight)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.40))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                )

                // Top Badge Strip (Format, Dimensions, Play/Pause for GIF)
                HStack(spacing: 5) {
                    if let meta = metadata {
                        // Type Badge
                        HStack(spacing: 3) {
                            Circle()
                                .fill(meta.isAnimated ? Color.pink : Color.cyan)
                                .frame(width: 5, height: 5)
                            Text(meta.badgeLabel)
                                .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.black.opacity(0.70)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))

                        if !meta.dimensionsString.isEmpty {
                            Text(meta.dimensionsString)
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.80))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.black.opacity(0.60)))
                        }
                    } else if isGif {
                        Text("GIF")
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.pink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.black.opacity(0.70)))
                    } else if isJpg {
                        Text("JPG")
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.black.opacity(0.70)))
                    }

                    Spacer()

                    // GIF Play / Pause Toggle Button
                    if isGif {
                        Button(action: {
                            isPlayingGif.toggle()
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: isPlayingGif ? "pause.fill" : "play.fill")
                                    .font(.system(size: 7.5, weight: .bold))
                                Text(isPlayingGif ? "Pause" : "Play")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.72)))
                            .overlay(Capsule().stroke(Color.pink.opacity(0.50), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                        .help(isPlayingGif ? "Pause GIF animation" : "Play GIF animation")
                    }

                    // Floating Quick Actions on Hover
                    HStack(spacing: 4) {
                        // Copy image
                        Button(action: copyImageToPasteboard) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 8.5))
                                .foregroundColor(.white.opacity(0.90))
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Color.black.opacity(0.65)))
                        }
                        .buttonStyle(.plain)
                        .help("Copy Image")

                        // Quick Look / Universal Viewer
                        if let validURL = url {
                            Button(action: {
                                QuickLookPresenter.shared.present([validURL], current: validURL)
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.white.opacity(0.90))
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(Color.black.opacity(0.65)))
                            }
                            .buttonStyle(.plain)
                            .help("Quick Look Image (Spacebar)")
                        }
                    }
                }
                .onTapGesture(count: 2) {
                    if let u = url {
                        NSWorkspace.shared.open(u)
                        HapticFeedback.selection()
                    }
                }
            }

            // Local File / Screenshot Interactive Quick Bar
            if let validURL = url {
                HStack(spacing: 6) {
                    Image(systemName: validURL.pathExtension.lowercased() == "gif" ? "play.rectangle.fill" : "photo.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.cyan)

                    Text(validURL.lastPathComponent)
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 4)

                    // Open in macOS Preview.app
                    Button(action: {
                        NSWorkspace.shared.open(validURL)
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 8))
                            Text("Open in Preview")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.blue.opacity(0.40)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Open in Preview.app")

                    // Reveal in Finder
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([validURL])
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 8))
                            Text("Finder")
                                .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.80))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    .help("Show in Finder")

                    // Quick Look Fullscreen
                    Button(action: {
                        QuickLookPresenter.shared.present([validURL], current: validURL)
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.80))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                    .help("Quick Look (Spacebar)")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                )
            }

            // Optional Alt Text / Caption
            if let alt = altText, !alt.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.50))
                    Text(alt)
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.70))
                        .lineLimit(2)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func copyImageToPasteboard() {
        guard let url = url else { return }
        if url.isFileURL {
            if let data = try? Data(contentsOf: url), let img = NSImage(data: data) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.writeObjects([img])
                HapticFeedback.success()
                withAnimation { isCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isCopied = false }
            }
        } else if let cachedData = GenieImageCache.shared.data(for: url), let img = NSImage(data: cachedData) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([img])
            HapticFeedback.success()
            withAnimation { isCopied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isCopied = false }
        }
    }
}
