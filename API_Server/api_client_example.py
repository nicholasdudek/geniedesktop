#!/usr/bin/env python3
"""
Demonstration Client for Genie API Server.
Shows how standard REST, OpenAI SDK, and Simultaneous Partition APIs work with Genie.
"""

import urllib.request
import json
import time
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8089
SERVER_URL = f"http://127.0.0.1:{PORT}"

def post_json(endpoint: str, data: dict):
    req = urllib.request.Request(
        f"{SERVER_URL}{endpoint}",
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def get_json(endpoint: str):
    req = urllib.request.Request(f"{SERVER_URL}{endpoint}")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

def test_api():
    print("=" * 60)
    print("🧞‍♂️ TESTING GENIE REST & TOOL CALLING APIS")
    print("=" * 60)
    
    # 1. Health & Status
    health = get_json("/health")
    print(f"\n1. Health Check:\n{json.dumps(health, indent=2)}")
    
    # 2. Query Models
    models = get_json("/v1/models")
    print(f"\n2. Registered Models (/v1/models):\n{json.dumps(models, indent=2)}")
    
    # 3. Query Partition State
    state = get_json("/v1/partitions/state")
    print(f"\n3. Dual Desktop Partition State:\n   Desktop 1: {state['partition_a']['agent']} ({state['partition_a']['app']})\n   Desktop 2: {state['partition_b']['agent']} ({state['partition_b']['app']})\n   Split Ratio: {state['split_ratio']}")
    
    # 4. Standard OpenAI Chat Completions API with Tool Calling
    chat_payload = {
        "model": "genie-nemo-30b-adapter",
        "messages": [
            {"role": "user", "content": "Execute spatial_dom_click on the terminal run button"}
        ],
        "temperature": 0.0
    }
    chat_resp = post_json("/v1/chat/completions", chat_payload)
    print(f"\n4. OpenAI-Compatible Chat Completion Response:\n{json.dumps(chat_resp, indent=2)}")
    
    # 5. Simultaneous Dual-Agent Field Input API
    input_payload = {
        "inputA": {
            "text": "swiftc -parse-as-library MetalEngine.swift",
            "targetField": "editor.workspace.buffer"
        },
        "inputB": {
            "text": "https://huggingface.co/nvidia/Nemotron-3-30B-Base",
            "targetField": "browser.search.omnibox"
        }
    }
    input_resp = post_json("/v1/partitions/simultaneous-input", input_payload)
    print(f"\n5. Simultaneous Dual-Agent Field Input Response:\n{json.dumps(input_resp, indent=2)}")
    
    # 6. Dynamic Split Ratio API
    split_resp = post_json("/v1/partitions/split", {"ratio": 0.65})
    print(f"\n6. Dynamic Partition Split (65% / 35%):\n{json.dumps(split_resp, indent=2)}")

    # 7. Concurrent Dual-File Asynchronous I/O & Secure Vault API
    concurrent_payload = {
        "key": "workspace_file_pair",
        "contentA": "Module A: Agent Core Logic Implementation",
        "contentB": "Module B: Agent Test Suite Implementation",
        "secure_vault": True
    }
    concurrent_resp = post_json("/v1/files/concurrent-write", concurrent_payload)
    print(f"\n7. Concurrent Dual-File Write & Secure Vault Response:\n{json.dumps(concurrent_resp, indent=2)}")

if __name__ == "__main__":
    test_api()

