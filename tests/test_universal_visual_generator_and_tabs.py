import unittest
import os
import re

class TestUniversalVisualGeneratorAndTabs(unittest.TestCase):
    def setUp(self):
        self.swift_file = "/Users/nicholasdudek/Desktop/Genie/GoldGate/Sources/GoldGate/Engine/GenieUniversalVisualGenerator.swift"
        self.components_file = "/Users/nicholasdudek/Desktop/Genie/GoldGate/Sources/GoldGate/Views/GenieChatComponents.swift"
        
        with open(self.swift_file, 'r', encoding='utf-8') as f:
            self.generator_code = f.read()
            
        with open(self.components_file, 'r', encoding='utf-8') as f:
            self.components_code = f.read()

    def test_visual_language_types_exist(self):
        """Verify all 10 requested visual medium languages are defined."""
        expected_cases = [
            "svg", "htmlCanvas", "mermaid", "metal", "glsl",
            "python", "swift", "latex", "ascii", "genericHtml"
        ]
        for case in expected_cases:
            self.assertIn(f"case {case}", self.generator_code)

    def test_tab_labels(self):
        """Verify each visual language has its exact descriptive tab label."""
        expected_labels = {
            "svg": "SVG",
            "htmlCanvas": "Canvas (JS)",
            "mermaid": "Mermaid",
            "metal": "Metal MSL",
            "glsl": "GLSL Shader",
            "python": "Python",
            "swift": "SwiftUI",
            "latex": "LaTeX / TikZ",
            "ascii": "ASCII Art",
            "genericHtml": "HTML / Web"
        }
        for case, label in expected_labels.items():
            self.assertIn(f'case .{case}: return "{label}"', self.generator_code)

    def test_background_themes_defined(self):
        """Verify canvas background themes (Dark, Light, Grid/Checkerboard) are supported."""
        self.assertIn("case dark =", self.generator_code)
        self.assertIn("case light =", self.generator_code)
        self.assertIn("case checkerboard =", self.generator_code)
        self.assertIn("#090b10", self.generator_code)
        self.assertIn("#ffffff", self.generator_code)

    def test_html_wrappers_present(self):
        """Verify self-contained GPU-accelerated wrappers exist for each medium."""
        self.assertIn("func wrapSvg", self.generator_code)
        self.assertIn("func wrapCanvas", self.generator_code)
        self.assertIn("func wrapMermaid", self.generator_code)
        self.assertIn("func wrapGlsl", self.generator_code)
        self.assertIn("func wrapMetal", self.generator_code)
        self.assertIn("func wrapPythonPlot", self.generator_code)
        self.assertIn("func wrapSwiftVector", self.generator_code)
        self.assertIn("func wrapLatex", self.generator_code)
        self.assertIn("func wrapAscii", self.generator_code)
        self.assertIn("func wrapGenericHtml", self.generator_code)

    def test_chat_bubble_routing(self):
        """Verify GenieChatComponents routes visual blocks to GenieInlineHtmlBubble with exact language tab."""
        self.assertIn("GenieUniversalVisualGenerator.detectVisualLanguage", self.components_code)
        self.assertIn("GenieInlineHtmlBubble", self.components_code)
        self.assertIn("language: visualType", self.components_code)
        self.assertIn("GenieWebSnapshotController", self.components_code)
        self.assertIn("snapshotController.takeSnapshot", self.components_code)

    def test_tab_pills_in_bubble(self):
        """Verify the chat bubble contains Image Preview and language tab pills."""
        self.assertIn('label: "Image Preview"', self.components_code)
        self.assertIn('label: language.tabLabel', self.components_code)
        self.assertIn('icon: language.iconName', self.components_code)

if __name__ == '__main__':
    unittest.main()
