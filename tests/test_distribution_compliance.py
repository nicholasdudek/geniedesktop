"""
Distribution compliance guards.

Genie ships two builds from one codebase:

  * Developer ID — direct, not sandboxed, notarized, full feature set.
  * Genie Lite   — Mac App Store, sandboxed, built with GENIE_MAS=1.

These tests are the regression net for the things that get a macOS app rejected
or silently broken. They scan source rather than running the app, matching the
convention of the other suites in this directory.
"""

import io
import os
import re
from pathlib import Path

SOURCES = Path("Sources")
CAPABILITIES = Path("Sources/GoldGate/Helpers/GenieCapabilities.swift")

# `Process()` as an instantiation, not as a suffix of e.g. startCaffeinateProcess()
PROCESS_INSTANTIATION = re.compile(r"(?<![A-Za-z0-9_])Process\(\)")
FUNC_DECL = re.compile(
    r"^\s*(?:@\w+\s+)*"
    r"(?:public |private |internal |fileprivate |nonisolated |static |class |final )*"
    r"func\s+(\w+)"
)


def swift_files():
    for root, _dirs, files in os.walk(SOURCES):
        for name in files:
            if name.endswith(".swift"):
                yield Path(root) / name


def strip_comments(text):
    """Remove // line comments and /* */ blocks so tests match code, not prose."""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return "\n".join(
        line for line in text.split("\n") if not line.lstrip().startswith("//")
    )


def test_no_remote_script_execution():
    """Guideline 2.5.2: Genie must never download and run a remote script."""
    offenders = []
    pattern = re.compile(r"curl[^\n\"]*\|\s*(sh|bash|zsh)\b")
    for path in swift_files():
        code = strip_comments(io.open(path, encoding="utf-8").read())
        if pattern.search(code):
            offenders.append(str(path))
    assert not offenders, f"curl-pipe-to-shell found in: {offenders}"


def test_admin_elevation_is_gated_and_singular():
    """
    Guideline 2.4.5(iv) bans privilege escalation. Exactly one code path may
    even mention it, and it must refuse before doing anything in the MAS build.
    """
    offenders = []
    for path in swift_files():
        code = strip_comments(io.open(path, encoding="utf-8").read())
        if "with administrator privileges" in code:
            offenders.append(str(path))

    assert offenders == ["Sources/GoldGate/Engine/GenieAdminAccessGovernor.swift"], (
        f"admin elevation must live only in the governor; found: {offenders}"
    )

    governor = io.open(offenders[0], encoding="utf-8").read()
    gate = governor.index("GenieCapabilities.canElevatePrivileges")
    use = governor.index("with administrator privileges")
    assert gate < use, "the capability gate must precede the elevation call"


def test_every_subprocess_is_capability_gated():
    """
    A sandboxed app cannot exec binaries outside its bundle. Every Process()
    instantiation must have a GenieCapabilities check ahead of it in the same
    function, so Genie Lite degrades with a message instead of silently failing.
    """
    ungated = []
    for path in swift_files():
        lines = strip_comments(io.open(path, encoding="utf-8").read()).split("\n")
        for i, line in enumerate(lines):
            if not PROCESS_INSTANTIATION.search(line):
                continue
            start, name = 0, "<top-level>"
            for j in range(i, -1, -1):
                match = FUNC_DECL.match(lines[j])
                if match:
                    start, name = j, match.group(1)
                    break
            if "GenieCapabilities." not in "\n".join(lines[start:i]):
                ungated.append(f"{path}:{i + 1} in {name}()")
    assert not ungated, "ungated subprocess launches:\n  " + "\n  ".join(ungated)


def test_capability_flags_split_on_build_flavour():
    """The forbidden capabilities must be derived from the build flavour."""
    code = io.open(CAPABILITIES, encoding="utf-8").read()
    assert "#if GENIE_MAS" in code
    for flag in [
        "canSpawnSubprocesses",
        "canElevatePrivileges",
        "canInstallExternalRuntimes",
        "canRequestFullDiskAccess",
        "canReadForeignAppContainers",
        "canWriteOutsideContainer",
        "canModifySystemPreferenceDomains",
        "canRelocateOwnBundle",
    ]:
        assert re.search(rf"{flag}\s*=\s*!isAppStoreBuild", code), (
            f"{flag} must be gated on !isAppStoreBuild"
        )


def test_package_swift_selects_flavour_from_environment():
    """GENIE_MAS=1 must switch the compiled define, or the scripts ship the wrong binary."""
    code = io.open("Package.swift", encoding="utf-8").read()
    assert 'environment["GENIE_MAS"]' in code
    assert 'isMASBuild ? "GENIE_MAS" : "GENIE_DEVELOPER_ID"' in code


def test_build_marker_exists_for_both_flavours():
    """The packaging scripts grep the binary for these; they must both exist."""
    code = io.open(CAPABILITIES, encoding="utf-8").read()
    assert "GENIE-BUILD-FLAVOUR:MAS" in code
    assert "GENIE-BUILD-FLAVOUR:DEVELOPER-ID" in code


def test_entitlement_profiles_are_distinct_and_correct():
    """The sandbox flag is what separates the two profiles."""
    appstore = io.open("Sources/GoldGate/Genie.AppStore.entitlements", encoding="utf-8").read()
    direct = io.open("Sources/GoldGate/Genie.entitlements", encoding="utf-8").read()

    def flag(text, key):
        match = re.search(
            rf"<key>{re.escape(key)}</key>\s*<(true|false)/>", text
        )
        return match.group(1) if match else None

    assert flag(appstore, "com.apple.security.app-sandbox") == "true"
    assert flag(direct, "com.apple.security.app-sandbox") == "false"

    # The App Store build talks to Ollama on localhost and to model APIs.
    assert flag(appstore, "com.apple.security.network.client") == "true"
    # Hardened Runtime + Apple Events are required for the direct build's automation.
    assert flag(direct, "com.apple.security.automation.apple-events") == "true"

    # A blanket Apple Events exception is not reviewable; it must be enumerated.
    assert "com.apple.security.temporary-exception.apple-events" in appstore
    assert "<string>com.apple.finder</string>" in appstore


def test_packaging_scripts_verify_the_flavour_they_sign():
    """Both scripts must refuse to sign a binary from the wrong flavour."""
    appstore_script = io.open("package_for_app_store.sh", encoding="utf-8").read()
    assert "GENIE_MAS=1 swift build" in appstore_script
    assert "GENIE-BUILD-FLAVOUR:MAS" in appstore_script

    finalize = io.open("finalize_goldgate.sh", encoding="utf-8").read()
    assert "GENIE-BUILD-FLAVOUR:DEVELOPER-ID" in finalize
    assert "GENIE-BUILD-FLAVOUR:MAS" in finalize
    # Direct distribution is useless unsigned-and-unnotarized.
    assert "notarytool submit" in finalize
    assert "stapler staple" in finalize
    assert "Developer ID Application" in finalize
