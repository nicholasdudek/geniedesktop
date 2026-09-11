import unittest
import os

class TestChatTemplateAndToolAnimations(unittest.TestCase):
    def setUp(self):
        self.project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    def test_mega_template_contains_exhaustive_few_shots(self):
        engine_file = os.path.join(self.project_dir, "Sources/GoldGate/Engine/GenieArchitecturalChatTemplateEngine.swift")
        self.assertTrue(os.path.exists(engine_file))
        with open(engine_file, "r") as f:
            content = f.read()
        self.assertIn("SOVEREIGN MEGA-PROMPT", content)
        self.assertIn("MANDATORY STEP-BY-STEP REASONING CHAMBER", content)
        self.assertIn("<thought>", content)
        self.assertIn("tool:tail recent", content)
        self.assertIn("tool:siri dark_mode", content)
        self.assertIn("tool:compile", content)
        self.assertIn("tool:trash_airlock_promote", content)
        self.assertIn("isSmallerModel", content)

    def test_animated_tool_command_view_exists_and_styled(self):
        view_file = os.path.join(self.project_dir, "Sources/GoldGate/Views/GenieToolCommandAnimatedView.swift")
        self.assertTrue(os.path.exists(view_file))
        with open(view_file, "r") as f:
            content = f.read()
        self.assertIn("GenieToolCommandAnimatedView", content)
        self.assertIn("AngularGradient", content)
        self.assertIn("executeInteractiveTool", content)
        self.assertIn("laserOffset", content)
        self.assertIn("rotationAngle", content)

    def test_chat_components_routes_tool_commands_to_animated_view(self):
        comp_file = os.path.join(self.project_dir, "Sources/GoldGate/Views/GenieChatComponents.swift")
        self.assertTrue(os.path.exists(comp_file))
        with open(comp_file, "r") as f:
            content = f.read()
        self.assertIn("case .toolCommand(let toolName, let rawCommand):", content)
        self.assertIn("GenieToolCommandAnimatedView(toolName: toolName, commandText: rawCommand)", content)
        self.assertIn("case .toolResult(let toolName, let result):", content)

if __name__ == "__main__":
    unittest.main()
