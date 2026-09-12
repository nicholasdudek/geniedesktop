#!/usr/bin/env python3
"""
=============================================================================
  🌐 GENIE UNIVERSAL MODEL CONNECTOR
  Dynamic multi-backend bridge that connects Genie's OS tools, spatial 
  dual-desktop partitions, and simultaneous input engine to ANY model:
  
  1. Local Ollama: Qwen3-Coder, DeepSeek-R1, Codestral, Nemotron, Llama 3
  2. Apple Silicon MLX: Native 4-bit / 8-bit Metal models + LoRA adapters
  3. Local vLLM / llama.cpp servers: Any OpenAI-compatible local host
  4. Cloud Model Providers: OpenAI, Anthropic, Google Gemini, DeepSeek, Groq
=============================================================================
"""

import os
import re
import json
import time
import requests
from typing import Dict, List, Any, Optional

OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
VLLM_BASE_URL = os.getenv("VLLM_BASE_URL", "http://localhost:8000/v1")
OPENAI_API_BASE = os.getenv("OPENAI_API_BASE", "https://api.openai.com/v1")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

class UniversalModelConnector:
    def __init__(self):
        self.attached_providers: Dict[str, Dict[str, Any]] = {
            "ollama": {
                "type": "ollama",
                "base_url": OLLAMA_BASE_URL,
                "enabled": True
            },
            "vllm": {
                "type": "openai_compatible",
                "base_url": VLLM_BASE_URL,
                "api_key": "EMPTY",
                "enabled": False
            },
            "openai": {
                "type": "openai_compatible",
                "base_url": OPENAI_API_BASE,
                "api_key": OPENAI_API_KEY,
                "enabled": bool(OPENAI_API_KEY)
            }
        }
        
        # Partition-specific model bindings (Desktop 1 vs Desktop 2)
        self.partition_bindings = {
            "partition_a": "genie-frontier:latest",      # Desktop 1 (VS Code Coder)
            "partition_b": "deepseek-r1:32b"           # Desktop 2 (Browser / Reasoning)
        }

    def list_all_models(self) -> List[Dict[str, Any]]:
        """Auto-discovers and unifies models across all attached backends."""
        catalog = []
        
        # 1. Query Local Ollama
        try:
            r = requests.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=3)
            if r.status_code == 200:
                for m in r.json().get("models", []):
                    name = m.get("name")
                    details = m.get("details", {})
                    caps = m.get("capabilities", [])
                    catalog.append({
                        "id": name,
                        "object": "model",
                        "created": int(time.time()),
                        "owned_by": "ollama-local",
                        "backend": "ollama",
                        "parameter_size": details.get("parameter_size", "Unknown"),
                        "quantization": details.get("quantization_level", "Unknown"),
                        "capabilities": caps,
                        "genie_attached": True
                    })
        except Exception:
            pass

        # 2. Add Genie Custom LoRA Adapters
        catalog.extend([
            {
                "id": "genie-nemo-30b-adapter",
                "object": "model",
                "created": int(time.time()),
                "owned_by": "genie-metal",
                "backend": "mlx_peft",
                "parameter_size": "30.5B",
                "quantization": "4-bit",
                "capabilities": ["tools", "dual_partition", "macos_grounding"],
                "genie_attached": True
            },
            {
                "id": "genie-cot-adapter",
                "object": "model",
                "created": int(time.time()),
                "owned_by": "genie-metal",
                "backend": "mlx_peft",
                "parameter_size": "7B",
                "quantization": "4-bit",
                "capabilities": ["reasoning", "tools", "math_induction"],
                "genie_attached": True
            }
        ])

        # 3. Add Active CLI Subscriptions (Claude Code & OpenAI Codex)
        catalog.extend([
            {
                "id": "claude-code-cli",
                "object": "model",
                "created": int(time.time()),
                "owned_by": "anthropic-subscription",
                "backend": "claude_cli",
                "parameter_size": "claude-sonnet-5",
                "context_window": "1M",
                "capabilities": ["tools", "reasoning", "multimodal", "cli_subscription"],
                "genie_attached": True
            },
            {
                "id": "codex-cli",
                "object": "model",
                "created": int(time.time()),
                "owned_by": "openai-subscription",
                "backend": "codex_cli",
                "parameter_size": "gpt-5.5 (xhigh reasoning)",
                "context_window": "128k",
                "capabilities": ["tools", "reasoning", "cli_subscription"],
                "genie_attached": True
            }
        ])

        # 4. Add Configured Cloud Gateways
        cloud_models = [
            ("gpt-4o", "openai", "128k"),
            ("claude-3-5-sonnet", "anthropic", "200k"),
            ("deepseek-chat", "deepseek", "64k"),
            ("gemini-2.0-flash", "google", "1M")
        ]
        for c_id, provider, ctx in cloud_models:
            catalog.append({
                "id": c_id,
                "object": "model",
                "created": int(time.time()),
                "owned_by": provider,
                "backend": "cloud_gateway",
                "parameter_size": "frontier",
                "context_window": ctx,
                "capabilities": ["tools", "reasoning", "multimodal"],
                "genie_attached": True
            })

        return catalog

    def attach_custom_backend(self, name: str, backend_type: str, base_url: str, api_key: str = "") -> Dict[str, Any]:
        """Registers a new external runtime / model host into Genie."""
        self.attached_providers[name] = {
            "type": backend_type,
            "base_url": base_url,
            "api_key": api_key,
            "enabled": True
        }
        return {"status": "success", "message": f"Backend '{name}' attached to Genie."}

    def bind_partition_model(self, partition: str, model_id: str) -> Dict[str, Any]:
        """Assigns an independent model to a specific desktop partition."""
        key = "partition_a" if "0" in str(partition) or "a" in str(partition).lower() else "partition_b"
        self.partition_bindings[key] = model_id
        return {
            "status": "success",
            "partition": key,
            "bound_model": model_id
        }

    def dispatch_chat_completion(self, model: str, messages: List[Dict[str, Any]], tools: Optional[List[Dict[str, Any]]] = None, temperature: float = 0.2) -> Dict[str, Any]:
        """
        Dispatches completion to whichever model is requested, automatically
        attaching Genie's OS tools and spatial grounding.
        """
        # Resolve alias
        target_model = model
        if model in ["genie-nemo-30b-adapter", "default", "genie-master:latest", "genie-frontier", "genie-frontier:latest", "genie-frontier-model", "genie-frontier-model:latest"]:
            target_model = "genie-frontier:latest"

        # Determine target backend
        if "claude" in target_model.lower() or "anthropic" in target_model.lower():
            return self._call_claude_cli(target_model, messages, tools)
        elif "codex" in target_model.lower():
            return self._call_codex_cli(target_model, messages, tools)

        is_ollama_model = any(target_model.startswith(prefix) for prefix in [
            "genie", "qwen", "deepseek", "codestral", "nemotron", "llama", "phi", "mistral"
        ])

        if is_ollama_model:
            return self._call_ollama(target_model, messages, tools, temperature)
        else:
            return self._call_openai_compatible(target_model, messages, tools, temperature)

    def _extract_prompt_text(self, messages: List[Dict[str, Any]]) -> str:
        prompt_parts = []
        for m in messages:
            role = m.get("role", "user")
            content = m.get("content", "")
            if isinstance(content, list):
                # Multimodal or blocks
                text_blocks = [b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"]
                content = "\n".join(text_blocks)
            prompt_parts.append(f"[{role.upper()}]: {content}")
        return "\n\n".join(prompt_parts)

    def _call_claude_cli(self, model: str, messages: List[Dict[str, Any]], tools: Optional[List[Dict[str, Any]]]) -> Dict[str, Any]:
        """Dispatches request to local Claude Code CLI subscription."""
        import subprocess
        prompt = self._extract_prompt_text(messages)
        cmd = ["claude", "-p", prompt]
        try:
            t0 = time.time()
            res = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=45)
            output_text = res.stdout.strip()
            if not output_text and res.stderr:
                output_text = res.stderr.strip()
            duration = time.time() - t0
            return {
                "id": f"chatcmpl-claude-cli-{int(time.time())}",
                "object": "chat.completion",
                "created": int(time.time()),
                "model": "claude-sonnet-5 (subscription cli)",
                "choices": [{
                    "index": 0,
                    "message": {"role": "assistant", "content": output_text},
                    "finish_reason": "stop"
                }],
                "usage": {
                    "backend": "claude_cli",
                    "execution_time_seconds": round(duration, 2)
                }
            }
        except Exception as e:
            return {"error": f"Claude CLI error: {str(e)}"}

    def _call_codex_cli(self, model: str, messages: List[Dict[str, Any]], tools: Optional[List[Dict[str, Any]]]) -> Dict[str, Any]:
        """Dispatches request to local OpenAI Codex CLI subscription."""
        import subprocess
        prompt = self._extract_prompt_text(messages)
        cmd = ["codex", "exec", "--skip-git-repo-check", prompt]
        try:
            t0 = time.time()
            res = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=45)
            out = res.stdout.strip()
            lines = out.split("\n")
            if "codex" in lines:
                idx = lines.index("codex")
                out = "\n".join(lines[idx+1:])
            # Filter tokens used footer if present
            if "tokens used" in out:
                out = out.split("tokens used")[0].strip()
            output_text = out.strip() or res.stderr.strip()
            duration = time.time() - t0
            return {
                "id": f"chatcmpl-codex-cli-{int(time.time())}",
                "object": "chat.completion",
                "created": int(time.time()),
                "model": "gpt-5.5 (codex subscription cli)",
                "choices": [{
                    "index": 0,
                    "message": {"role": "assistant", "content": output_text},
                    "finish_reason": "stop"
                }],
                "usage": {
                    "backend": "codex_cli",
                    "execution_time_seconds": round(duration, 2)
                }
            }
        except Exception as e:
            return {"error": f"Codex CLI error: {str(e)}"}

    def _call_ollama(self, model: str, messages: List[Dict[str, Any]], tools: Optional[List[Dict[str, Any]]], temperature: float) -> Dict[str, Any]:
        # Format messages into ChatML string or pass messages endpoint
        url = f"{OLLAMA_BASE_URL}/api/chat"
        payload = {
            "model": model,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": 1024
            }
        }
        if tools:
            payload["tools"] = tools

        try:
            r = requests.post(url, json=payload, timeout=120)
            if r.status_code == 200:
                data = r.json()
                msg = data.get("message", {})
                return {
                    "id": f"chatcmpl-{data.get('created_at', int(time.time()))}",
                    "object": "chat.completion",
                    "created": int(time.time()),
                    "model": model,
                    "choices": [
                        {
                            "index": 0,
                            "message": msg,
                            "finish_reason": "stop" if not msg.get("tool_calls") else "tool_calls"
                        }
                    ],
                    "usage": {
                        "prompt_tokens": data.get("prompt_eval_count", 0),
                        "completion_tokens": data.get("eval_count", 0),
                        "total_tokens": data.get("prompt_eval_count", 0) + data.get("eval_count", 0)
                    }
                }
            else:
                return {"error": f"Ollama HTTP {r.status_code}: {r.text}"}
        except Exception as e:
            return {"error": f"Ollama connection error for model {model}: {str(e)}"}

    def _call_openai_compatible(self, model: str, messages: List[Dict[str, Any]], tools: Optional[List[Dict[str, Any]]], temperature: float) -> Dict[str, Any]:
        url = f"{OPENAI_API_BASE}/chat/completions"
        headers = {
            "Authorization": f"Bearer {OPENAI_API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature
        }
        if tools:
            payload["tools"] = tools

        try:
            r = requests.post(url, headers=headers, json=payload, timeout=60)
            return r.json()
        except Exception as e:
            return {"error": f"Cloud model error for {model}: {str(e)}"}

# Singleton instance
UNIVERSAL_CONNECTOR = UniversalModelConnector()
