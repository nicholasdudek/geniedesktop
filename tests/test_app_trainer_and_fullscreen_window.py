import unittest
import os

class TestGenieAppTrainerAndFullscreenWindow(unittest.TestCase):
    def test_app_trainer_engine_source_exists(self):
        engine_path = "Sources/GoldGate/Engine/GenieAppTrainerEngine.swift"
        self.assertTrue(os.path.exists(engine_path), "GenieAppTrainerEngine.swift must exist")
        with open(engine_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("class GenieAppTrainerEngine", content)
        self.assertIn("nonisolated static func categorizeApp", content)
        self.assertIn("generateTrainingSystemPrompt", content)
        self.assertIn("TrainedMacApp", content)

    def test_dashboard_fullscreen_and_position_persistence(self):
        dashboard_path = "Sources/GoldGate/Views/LiquidGlassTopDashboardView.swift"
        self.assertTrue(os.path.exists(dashboard_path), "LiquidGlassTopDashboardView.swift must exist")
        with open(dashboard_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("genieZenModeEnabled", content)
        self.assertIn("savedPosX", content)
        self.assertIn("savedPosY", content)
        self.assertIn("dismissDashboard()", content)
        self.assertIn("GenieTopDockNeuralEngineBannerView", content)

    def test_mario_block_banner_exists(self):
        banner_path = "Sources/GoldGate/Views/GenieTopDockNeuralEngineBannerView.swift"
        self.assertTrue(os.path.exists(banner_path), "GenieTopDockNeuralEngineBannerView.swift must exist")
        with open(banner_path, "r", encoding="utf-8") as f:
            content = f.read()
        self.assertIn("GenieTopDockNeuralEngineBannerView", content)
        self.assertIn("heroMode", content)

if __name__ == "__main__":
    unittest.main()
