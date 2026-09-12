#!/usr/bin/env python3
"""
=============================================================================
  🧞‍♂️ GENIE NEURAL WEIGHT-TO-TOOL MAPPER (2026)
  Directly maps the unified neural network's weights and activation tensors
  to Genie's concrete agent tools across Swift AgentRuntime, Desktop Agent,
  iPhone Mirroring, Spatial DOM, and System Utilities.
=============================================================================
"""

import os
import sys
import json
import torch
import torch.nn as nn
import torch.nn.functional as F

# ---------------------------------------------------------------------------
# 1. Complete Catalog of Genie Agent Tools
# ---------------------------------------------------------------------------

GENIE_TOOL_REGISTRY = [
    {
        "id": 0,
        "name": "list_files",
        "category": "filesystem",
        "mutating": False,
        "description": "Lists workspace files up to 2,000 entries excluding build artifacts.",
        "arguments": ["path"],
        "weight_signature_dim": 512
    },
    {
        "id": 1,
        "name": "read_file",
        "category": "filesystem",
        "mutating": False,
        "description": "Reads file contents up to 5 MB UTF-8 text.",
        "arguments": ["path"],
        "weight_signature_dim": 512
    },
    {
        "id": 2,
        "name": "search_files",
        "category": "filesystem",
        "mutating": False,
        "description": "Literal text substring search across workspace files up to 100 matches.",
        "arguments": ["query"],
        "weight_signature_dim": 512
    },
    {
        "id": 3,
        "name": "edit_file",
        "category": "filesystem",
        "mutating": True,
        "description": "Single-match exact string replacement in workspace text files with read-back verification.",
        "arguments": ["path", "old_text", "new_text"],
        "weight_signature_dim": 512
    },
    {
        "id": 4,
        "name": "write_file",
        "category": "filesystem",
        "mutating": True,
        "description": "Writes or creates new file with atomic read-back and expected content check.",
        "arguments": ["path", "expected_content", "content"],
        "weight_signature_dim": 512
    },
    {
        "id": 5,
        "name": "merge_files",
        "category": "filesystem",
        "mutating": True,
        "description": "Three-way file merge preview between current, base, and incoming branches.",
        "arguments": ["path", "base_path", "incoming_path"],
        "weight_signature_dim": 512
    },
    {
        "id": 6,
        "name": "run_command",
        "category": "system",
        "mutating": True,
        "description": "Executes zsh command in isolated process-group with 300s timeout and kill(-pid, SIGKILL).",
        "arguments": ["command"],
        "weight_signature_dim": 512
    },
    {
        "id": 7,
        "name": "read_ui",
        "category": "accessibility",
        "mutating": False,
        "description": "Inspects macOS application accessibility tree and UI elements.",
        "arguments": ["app"],
        "weight_signature_dim": 512
    },
    {
        "id": 8,
        "name": "copy_text",
        "category": "accessibility",
        "mutating": True,
        "description": "Copies text from UI element into system clipboard.",
        "arguments": ["element_id", "scope"],
        "weight_signature_dim": 512
    },
    {
        "id": 9,
        "name": "paste_text",
        "category": "accessibility",
        "mutating": True,
        "description": "Pastes validated text into targeted UI element with expected value check.",
        "arguments": ["element_id", "expected_value", "text"],
        "weight_signature_dim": 512
    },
    {
        "id": 10,
        "name": "desktop_agent",
        "category": "autonomous_gui",
        "mutating": True,
        "description": "Autonomous desktop control: open, click, click_text (Vision OCR), drag, scroll, type, key, snapshot.",
        "arguments": ["action", "x", "y", "label", "text", "key_combo"],
        "weight_signature_dim": 512
    },
    {
        "id": 11,
        "name": "iphone_agent",
        "category": "continuity",
        "mutating": True,
        "description": "iPhone Mirroring touch control: open_iphone, tap, double_tap, long_press, swipe, swipe_home, type_iphone.",
        "arguments": ["gesture", "x", "y", "text"],
        "weight_signature_dim": 512
    },
    {
        "id": 12,
        "name": "phone_bridge",
        "category": "continuity",
        "mutating": True,
        "description": "Direct iMessage bridge: instant ping and reply transmission to user's iPhone.",
        "arguments": ["text", "ping"],
        "weight_signature_dim": 512
    },
    {
        "id": 13,
        "name": "spatial_dom",
        "category": "web_dom",
        "mutating": True,
        "description": "Zero-cursor direct DOM event dispatch and bounding box targeting (!dom click, !dom calc).",
        "arguments": ["selector", "bbox", "centroid", "action"],
        "weight_signature_dim": 512
    },
    {
        "id": 14,
        "name": "polyglot_code",
        "category": "engineering",
        "mutating": False,
        "description": "Autonomous full-stack code generator across Swift 6, Python, Rust, Go, TS, C++, Shell, SQL.",
        "arguments": ["language", "code"],
        "weight_signature_dim": 512
    },
    {
        "id": 15,
        "name": "agent_network",
        "category": "mesh",
        "mutating": True,
        "description": "P2P local network sharing via Bonjour _genie-agent._tcp.local. and APFS CoW clone bridge.",
        "arguments": ["path", "target_host"],
        "weight_signature_dim": 512
    },
    {
        "id": 16,
        "name": "airdrop",
        "category": "mesh",
        "mutating": True,
        "description": "Native macOS AirDrop automation via AppKit NSSharingService.",
        "arguments": ["path"],
        "weight_signature_dim": 512
    },
    {
        "id": 17,
        "name": "app_doc",
        "category": "inspection",
        "mutating": False,
        "description": "Application scripting dictionary (/usr/bin/sdef) and bundle metadata harvester.",
        "arguments": ["app_name"],
        "weight_signature_dim": 512
    }
]

# ---------------------------------------------------------------------------
# 2. Neural Tool Routing Layer
# ---------------------------------------------------------------------------

class ModelToolWeightRouter(nn.Module):
    """
    Directly maps latent model representations to tool activations using
    learnable tool weight vectors and cosine similarity routing.
    """
    def __init__(self, hidden_dim=512, num_tools=len(GENIE_TOOL_REGISTRY)):
        super().__init__()
        self.num_tools = num_tools
        self.hidden_dim = hidden_dim
        
        # Tool Weight Matrix: each column represents the prototype embedding of one tool
        self.tool_weight_matrix = nn.Parameter(torch.randn(hidden_dim, num_tools) * 0.02)
        # Learnable tool bias
        self.tool_bias = nn.Parameter(torch.zeros(num_tools))
        # Temperature scaling parameter for calibrated probabilities
        self.temperature = nn.Parameter(torch.ones(1) * 0.1)

    def forward(self, latent_features):
        """
        latent_features: [batch_size, hidden_dim]
        returns:
          logits: [batch_size, num_tools]
          probabilities: [batch_size, num_tools]
        """
        # Normalize for cosine similarity routing
        norm_features = F.normalize(latent_features, p=2, dim=-1)
        norm_weights = F.normalize(self.tool_weight_matrix, p=2, dim=0)
        
        cosine_sim = torch.matmul(norm_features, norm_weights)
        scaled_logits = (cosine_sim / torch.clamp(self.temperature, min=0.01)) + self.tool_bias
        probabilities = F.softmax(scaled_logits, dim=-1)
        
        return scaled_logits, probabilities

    def get_tool_weight_vector(self, tool_id: int):
        """Extracts the exact weight slice corresponding to a specific tool."""
        return self.tool_weight_matrix[:, tool_id].detach()

    def map_query_embedding_to_tools(self, query_emb: torch.Tensor, top_k: int = 3):
        """
        Given a query embedding, computes exact tool activation ranking and scores.
        """
        with torch.no_grad():
            if query_emb.dim() == 1:
                query_emb = query_emb.unsqueeze(0)
            logits, probs = self.forward(query_emb)
            top_probs, top_indices = torch.topk(probs[0], k=top_k)
            
            results = []
            for prob, idx in zip(top_probs, top_indices):
                tool_info = GENIE_TOOL_REGISTRY[idx.item()]
                results.append({
                    "tool_id": tool_info["id"],
                    "tool_name": tool_info["name"],
                    "category": tool_info["category"],
                    "mutating": tool_info["mutating"],
                    "activation_confidence": float(prob.item()),
                    "weight_norm": float(torch.norm(self.tool_weight_matrix[:, idx.item()]).item())
                })
            return results

# ---------------------------------------------------------------------------
# 3. Weight Manifest Exporter
# ---------------------------------------------------------------------------

def export_weight_tool_mapping(router: ModelToolWeightRouter, output_path: str):
    """
    Exports a comprehensive JSON manifest documenting the exact parameter shape,
    norm, and dispatch metadata connecting model weights to Genie tools.
    """
    manifest = {
        "version": "1.0.0-GoldGate",
        "num_tools": router.num_tools,
        "hidden_dimension": router.hidden_dim,
        "temperature": float(router.temperature.item()),
        "tools": []
    }
    
    with torch.no_grad():
        for tool in GENIE_TOOL_REGISTRY:
            t_id = tool["id"]
            weight_vec = router.tool_weight_matrix[:, t_id]
            norm = float(torch.norm(weight_vec).item())
            mean = float(torch.mean(weight_vec).item())
            std = float(torch.std(weight_vec).item())
            
            # Sample top 8 prominent weight dimensions
            top_weights, top_dims = torch.topk(torch.abs(weight_vec), k=8)
            
            tool_entry = dict(tool)
            tool_entry["weights_metadata"] = {
                "l2_norm": round(norm, 6),
                "mean": round(mean, 6),
                "std": round(std, 6),
                "prominent_dimensions": top_dims.tolist(),
                "prominent_amplitudes": [round(float(w), 6) for w in top_weights]
            }
            manifest["tools"].append(tool_entry)
            
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        
    print(f"[✓] Exported neural weight-to-tool manifest to: {output_path}")
    return manifest

if __name__ == "__main__":
    if torch.backends.mps.is_available():
        device = torch.device("mps")
    elif torch.cuda.is_available():
        device = torch.device("cuda")
    else:
        device = torch.device("cpu")
    print(f"[*] Initializing Neural Weight-to-Tool Router on {device}...")
    
    router = ModelToolWeightRouter().to(device)
    out_json = "/Users/nicholasdudek/Desktop/Genie/UnifiedTraining/genie_tool_weight_map.json"
    manifest = export_weight_tool_mapping(router, out_json)
    
    # Test query mapping
    test_latent = torch.randn(1, 512, device=device)
    ranked = router.map_query_embedding_to_tools(test_latent, top_k=3)
    print("\n[Sample Weight Dispatch Test]")
    for r in ranked:
        print(f" - Tool: {r['tool_name']:<15} | Activation Confidence: {r['activation_confidence']:.4f} | Mutating: {r['mutating']}")
