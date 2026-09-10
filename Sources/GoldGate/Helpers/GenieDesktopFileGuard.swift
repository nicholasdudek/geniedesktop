import Foundation

/// Single authority on where Genie's agent is allowed to create or modify files.
///
/// The policy is deliberately narrow: **the Desktop is Genie's workspace, and nothing
/// else is.** The agent may create, edit, and delete freely under `~/Desktop`, plus the
/// process-scoped temporary directories it needs to stage work. Every other path —
/// including the rest of the home directory (`~/Library`, `~/.ssh`, `~/Documents`) and
/// all system locations — is refused.
///
/// This guards *in-process* Swift writes. Subprocesses are separately confined by the
/// `sandbox-exec` profile in `GenieSandboxedExecutionEngine`, which is kept in agreement
/// with this policy. Both layers are required: `sandbox-exec` does not constrain
/// `FileManager` calls made inside the app, and this guard does not constrain a shell.
public enum GenieDesktopFileGuard {

    public enum Violation: LocalizedError {
        case outsideDesktop(attempted: String)
        case systemPath(attempted: String)

        public var errorDescription: String? {
            switch self {
            case .outsideDesktop(let p):
                return "Genie may only create files on the Desktop. Refused: \(p)"
            case .systemPath(let p):
                return "Genie may not modify system files. Refused: \(p)"
            }
        }
    }

    /// Genie's writable root. Resolved through symlinks so that a link planted inside
    /// the Desktop cannot widen the boundary.
    public static var desktopRoot: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop", isDirectory: true)
            .resolvingSymlinksInPath()
    }

    /// Staging areas the agent needs for intermediate work. Deliberately does not
    /// include all of `/private/var`, which holds system databases.
    private static var scratchRoots: [URL] {
        var roots = [URL(fileURLWithPath: "/tmp").resolvingSymlinksInPath()]
        roots.append(URL(fileURLWithPath: NSTemporaryDirectory()).resolvingSymlinksInPath())
        return roots
    }

    /// Paths that must never be written even if some future change widens the roots.
    private static let forbiddenPrefixes: [String] = [
        "/System", "/usr", "/bin", "/sbin", "/Library/LaunchDaemons",
        "/Library/LaunchAgents", "/private/etc", "/Applications",
    ]

    /// True when `url` is a path Genie's agent may create or modify.
    ///
    /// Symlinks are resolved on the *parent* directory rather than the leaf, so that a
    /// file which does not exist yet still validates while a symlinked directory cannot
    /// be used to escape the Desktop.
    public static func isWritable(_ url: URL) -> Bool {
        (try? validate(url)) != nil
    }

    /// Throws a `Violation` describing why `url` is refused, or returns the resolved,
    /// standardized URL that should actually be written.
    @discardableResult
    public static func validate(_ url: URL) throws -> URL {
        let resolved = resolveForWriting(url)
        let path = resolved.path

        for prefix in forbiddenPrefixes where path == prefix || path.hasPrefix(prefix + "/") {
            throw Violation.systemPath(attempted: path)
        }

        let permitted = [desktopRoot] + scratchRoots
        for root in permitted {
            let rootPath = root.path
            if path == rootPath || path.hasPrefix(rootPath + "/") { return resolved }
        }

        throw Violation.outsideDesktop(attempted: path)
    }

    /// Resolves `..` segments and symlinked parent directories without requiring the
    /// leaf to exist yet.
    private static func resolveForWriting(_ url: URL) -> URL {
        let standardized = url.standardizedFileURL
        let parent = standardized.deletingLastPathComponent()
        let resolvedParent = parent.resolvingSymlinksInPath()
        return resolvedParent
            .appendingPathComponent(standardized.lastPathComponent)
            .standardizedFileURL
    }
}
