#!/usr/bin/env python3
import unittest
import os

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SOURCES_DIR = os.path.join(REPO_ROOT, "Sources", "GoldGate")

class TestTailAndScrollWheel(unittest.TestCase):
    def test_tail_in_genie_native_tool_engine(self):
        engine_file = os.path.join(SOURCES_DIR, "Engine", "GenieNativeToolEngine.swift")
        self.assertTrue(os.path.isfile(engine_file))
        with open(engine_file, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("func runTail(argument: String", content)
        self.assertIn("case \"tail\"", content)
        self.assertIn("runRetrieveRecentItems", content)
        self.assertIn("runRetrieveSystemLogs", content)
        self.assertIn("runRetrieveTerminalHistory", content)
        self.assertIn("runRetrieveCrashReports", content)
        self.assertIn("runRetrieveXcodeLogs", content)

    def test_tail_in_local_model_manager(self):
        lmm_file = os.path.join(SOURCES_DIR, "Engine", "LocalModelManager.swift")
        self.assertTrue(os.path.isfile(lmm_file))
        with open(lmm_file, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("TAIL LOGS, PAST COMPUTER LOGS", content)
        self.assertIn("```tool:tail recent", content)
        self.assertIn("func appendAssistantMessage", content)

    def test_tail_in_chat_window_view(self):
        chat_file = os.path.join(SOURCES_DIR, "Views", "FinderStyleChatWindowView.swift")
        self.assertTrue(os.path.isfile(chat_file))
        with open(chat_file, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("/tail", content)
        self.assertIn("shortcutPill(title: \"/tail\"", content)

    def test_scroll_wheel_optional_preference_keys(self):
        pref_file = os.path.join(SOURCES_DIR, "Helpers", "PreferenceKeys.swift")
        self.assertTrue(os.path.isfile(pref_file))
        with open(pref_file, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("enableScrollWheelStationNavigation", content)
        self.assertIn("showThickScrollBars", content)

    def test_scroll_wheel_guard_in_continuous_engine(self):
        engine_file = os.path.join(SOURCES_DIR, "Engine", "ContinuousStationScrollEngine.swift")
        self.assertTrue(os.path.isfile(engine_file))
        with open(engine_file, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("enableScrollWheelStationNavigation", content)

    def test_standard_directories_and_apple_conventions(self):
        dnp_file = os.path.join(SOURCES_DIR, "Helpers", "DesktopNotePrinter.swift")
        self.assertTrue(os.path.isfile(dnp_file))
        with open(dnp_file, "r", encoding="utf-8") as f:
            content = f.read()

        # Check standard install directory variables
        self.assertIn("struct GenieStandardDirectories", content)
        self.assertIn("static var rootURL", content)
        self.assertIn("static var notesURL", content)
        self.assertIn("static var polaroidsURL", content)
        self.assertIn("static var chatsURL", content)
        self.assertIn("static var presentationsURL", content)
        self.assertIn("static var documentsURL", content)
        self.assertIn("static var scriptsURL", content)
        self.assertIn("static var recordingsURL", content)
        self.assertIn("static var extensionsURL", content)
        self.assertIn("static var environmentsURL", content)

    def test_capabilities_shared_support_directory(self):
        cap_file = os.path.join(SOURCES_DIR, "Helpers", "GenieCapabilities.swift")
        self.assertTrue(os.path.isfile(cap_file))
        with open(cap_file, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("static var sharedSupportDirectory", content)
        self.assertIn("group.com.nicholasdudek.genie", content)

if __name__ == "__main__":
    unittest.main()
