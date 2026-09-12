import os
import json
import torch
import pytest

UNIFIED_DIR = os.path.dirname(os.path.abspath(__file__))
MASTER_DATASET = os.path.join(UNIFIED_DIR, "genie_unified_master_train.jsonl")
MASTER_WEIGHTS = os.path.join(UNIFIED_DIR, "genie_unified_master_weights.pt")
TOOL_WEIGHT_MAP = os.path.join(UNIFIED_DIR, "genie_tool_weight_map.json")
MASTER_MODELFILE = os.path.join(UNIFIED_DIR, "Modelfile.genie-master")
FRONTIER_MODELFILE = os.path.join(UNIFIED_DIR, "Modelfile.genie-frontier")

from genie_tool_weight_mapper import GENIE_TOOL_REGISTRY, ModelToolWeightRouter
from genie_unified_merger import (
    GenieUnifiedMasterModel,
    PixelToWeightNeuralEncoder,
    TrillionMacPixelsVisionWeightRenderer
)

def test_tool_registry_integrity():
    assert len(GENIE_TOOL_REGISTRY) >= 15
    names = [t["name"] for t in GENIE_TOOL_REGISTRY]
    expected = [
        "list_files", "read_file", "search_files", "edit_file", "write_file",
        "run_command", "read_ui", "copy_text", "paste_text",
        "desktop_agent", "iphone_agent", "phone_bridge",
        "spatial_dom", "polyglot_code", "agent_network", "airdrop", "app_doc"
    ]
    for exp in expected:
        assert exp in names, f"Missing tool in registry: {exp}"

def test_model_tool_weight_router():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    router = ModelToolWeightRouter(hidden_dim=512, num_tools=len(GENIE_TOOL_REGISTRY)).to(device)
    
    latent = torch.randn(4, 512, device=device)
    logits, probs = router(latent)
    
    assert logits.shape == (4, len(GENIE_TOOL_REGISTRY))
    assert probs.shape == (4, len(GENIE_TOOL_REGISTRY))
    # Probabilities must sum to 1
    assert torch.allclose(probs.sum(dim=-1), torch.ones(4, device=device), atol=1e-4)

def test_unified_model_forward():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = GenieUnifiedMasterModel(vocab_size=8192, embed_dim=256, hidden_dim=512, num_codebase_files=50).to(device)
    
    tokens = torch.randint(0, 8192, (2, 32), device=device)
    bbox, point, codebase_logits, tool_logits, tool_probs, latent = model(tokens)
    
    assert bbox.shape == (2, 4)
    assert point.shape == (2, 2)
    assert codebase_logits.shape == (2, 50)
    assert tool_logits.shape == (2, len(GENIE_TOOL_REGISTRY))
    assert tool_probs.shape == (2, len(GENIE_TOOL_REGISTRY))
    assert latent.shape == (2, 512)

def test_dataset_jsonl_validity_if_generated():
    if os.path.exists(MASTER_DATASET):
        with open(MASTER_DATASET, "r", encoding="utf-8") as f:
            lines = [json.loads(line) for line in f if line.strip()]
        assert len(lines) > 50
        for entry in lines[:20]:
            assert "messages" in entry
            roles = [m["role"] for m in entry["messages"]]
            assert "user" in roles
            assert "assistant" in roles

def test_tool_weight_map_json_if_generated():
    if os.path.exists(TOOL_WEIGHT_MAP):
        with open(TOOL_WEIGHT_MAP, "r", encoding="utf-8") as f:
            data = json.load(f)
        assert data["num_tools"] == len(GENIE_TOOL_REGISTRY)
        assert len(data["tools"]) == len(GENIE_TOOL_REGISTRY)
        for t in data["tools"]:
            assert "weights_metadata" in t
            assert "l2_norm" in t["weights_metadata"]
            assert len(t["weights_metadata"]["prominent_dimensions"]) == 8

def test_frontier_modelfile_if_generated():
    if os.path.exists(FRONTIER_MODELFILE):
        with open(FRONTIER_MODELFILE, "r", encoding="utf-8") as f:
            content = f.read()
        assert "Genie Frontier Model" in content or "Genie Frontier" in content
        assert "FROM " in content

def test_pixel_to_weight_encoder():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    encoder = PixelToWeightNeuralEncoder(in_channels=3, embed_dim=256, hidden_dim=512).to(device)
    pixels = torch.rand(4, 3, 64, 64, device=device)
    w, b = encoder(pixels)
    assert w.shape == (512, 512)
    assert b.shape == (512,)
    assert not torch.isnan(w).any()
    assert not torch.isnan(b).any()

def test_trillion_mac_pixels_renderer():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    renderer = TrillionMacPixelsVisionWeightRenderer(device=device)
    pixels, batch_px = renderer.render_screen_pixel_batch(batch_size=16, patch_dim=64, simulated_frames=500)
    assert pixels.shape == (16, 3, 64, 64)
    assert batch_px > 100_000_000
    assert renderer.total_pixels_rendered == batch_px

def test_unified_model_forward_with_screen_pixels():
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    model = GenieUnifiedMasterModel(vocab_size=8192, embed_dim=256, hidden_dim=512, num_codebase_files=50).to(device)
    tokens = torch.randint(0, 8192, (2, 32), device=device)
    pixels = torch.rand(2, 3, 64, 64, device=device)
    bbox, point, codebase_logits, tool_logits, tool_probs, latent = model(tokens, screen_pixels=pixels)
    assert bbox.shape == (2, 4)
    assert point.shape == (2, 2)
    assert codebase_logits.shape == (2, 50)
    assert tool_logits.shape == (2, len(GENIE_TOOL_REGISTRY))
    assert tool_probs.shape == (2, len(GENIE_TOOL_REGISTRY))
    assert latent.shape == (2, 512)


