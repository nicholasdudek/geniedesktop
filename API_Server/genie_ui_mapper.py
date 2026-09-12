#!/usr/bin/env python3
"""
=============================================================================
  🧞‍♂️ GENIE UI-TO-TOOL CALL MAPPER ENGINE
  Maps natural UI actions, visual elements, and Accessibility hierarchy
  into deterministic, verifiable Genie tool calls.
=============================================================================
"""

import os
import sys
import json
import re
from typing import Dict, Any, List, Optional, Tuple

class GenieUIMapper:
    """
    Translates high-level UI interaction intents and Accessibility Tree elements
    into exact, atomic, verifiable Genie tool calls.
    """

    # Complete UI Intent Action Matrix
    INTENT_MAP = {
        # 1. Inspection & Discovery
        "inspect_app": {
            "description": "Scan and discover all visible UI elements in an application",
            "tool_sequence": ["read_ui"],
            "primary_tool": "read_ui",
            "required_args": ["app"]
        },
        "find_element": {
            "description": "Locate a specific button, input field, or menu item by label/role",
            "tool_sequence": ["read_ui"],
            "primary_tool": "read_ui",
            "filter_keys": ["role", "title", "description"]
        },
        # 2. Text Reading & Extraction
        "read_text": {
            "description": "Read exact text from a UI text field or document view",
            "tool_sequence": ["read_ui", "grab_text"],
            "primary_tool": "grab_text",
            "required_args": ["element_id", "scope"]
        },
        # 3. Clipboard & Selection
        "copy_element_text": {
            "description": "Copy text from a UI element into the macOS clipboard with verification",
            "tool_sequence": ["read_ui", "copy_text"],
            "primary_tool": "copy_text",
            "required_args": ["element_id", "scope"]
        },
        # 4. Text Input & Form Filling
        "type_text": {
            "description": "Paste verified text into a text field with pre-flight check and readback",
            "tool_sequence": ["read_ui", "paste_text"],
            "primary_tool": "paste_text",
            "required_args": ["element_id", "expected_value", "text"]
        },
        # 5. Spatial Clicking & Mouse Actions
        "click_button": {
            "description": "Click an interactive UI element by name, role, or coordinates",
            "tool_sequence": ["read_ui", "spatial_dom"],
            "primary_tool": "spatial_dom",
            "required_args": ["element_id", "action"]
        },
        # 6. Window & Workspace Layout
        "split_workspace": {
            "description": "Adjust partition boundaries between Desktop 1 and Desktop 2",
            "tool_sequence": ["desktop_agent"],
            "primary_tool": "desktop_agent",
            "required_args": ["split_ratio"]
        },
        # 7. Menu Navigation
        "trigger_menu": {
            "description": "Activate an application menu item (e.g. File > Save)",
            "tool_sequence": ["read_ui", "run_command"],
            "primary_tool": "run_command",
            "required_args": ["command"]
        }
    }

    # Common macOS Bundle IDs
    APP_REGISTRY = {
        "xcode": "com.apple.dt.Xcode",
        "safari": "com.apple.Safari",
        "terminal": "com.apple.Terminal",
        "finder": "com.apple.finder",
        "vscode": "com.microsoft.VSCode",
        "notes": "com.apple.Notes",
        "messages": "com.apple.MobileSMS",
        "settings": "com.apple.systempreferences",
        "chrome": "com.google.Chrome"
    }

    @classmethod
    def resolve_bundle_id(cls, app_name: str) -> str:
        """Resolve friendly application name to macOS bundle identifier."""
        clean = app_name.lower().strip()
        if clean in cls.APP_REGISTRY:
            return cls.APP_REGISTRY[clean]
        if "." in clean:
            return clean
        return f"com.apple.{clean.capitalize()}"

    @classmethod
    def map_intent_to_tool_calls(cls, intent_description: str, app: Optional[str] = None, target_element: Optional[str] = None, text_content: Optional[str] = None) -> Dict[str, Any]:
        """
        Synthesizes the optimal tool call sequence for any natural language UI request.
        """
        bundle_id = cls.resolve_bundle_id(app or "finder")
        text_lower = intent_description.lower()

        # Keyword patterns with word boundaries
        if re.search(r"\b(copy|clipboard|grab)\b", text_lower):
            return {
                "intent": "copy_element_text",
                "bundle_id": bundle_id,
                "strategy": "Extract text via AXValue / AXSelectedText attribute and populate pasteboard",
                "tool_calls": [
                    {
                        "step": 1,
                        "tool": "read_ui",
                        "arguments": {"app": bundle_id},
                        "purpose": "Locate element ID in target application"
                    },
                    {
                        "step": 2,
                        "tool": "copy_text",
                        "arguments": {
                            "element_id": "resolved_from_read_ui",
                            "scope": "selection" if "selection" in text_lower or "selected" in text_lower else "value"
                        },
                        "purpose": "Copy text to clipboard with readback verification"
                    }
                ]
            }

        elif re.search(r"\b(type|enter|insert|write|fill)\b", text_lower):
            content = text_content or "Hello World"
            return {
                "intent": "type_text",
                "bundle_id": bundle_id,
                "strategy": "Inspect field, verify baseline value, post CGEvent key strokes, verify final text",
                "tool_calls": [
                    {
                        "step": 1,
                        "tool": "read_ui",
                        "arguments": {"app": bundle_id},
                        "purpose": "Locate AXTextField and get current snapshot value"
                    },
                    {
                        "step": 2,
                        "tool": "paste_text",
                        "arguments": {
                            "element_id": "resolved_from_read_ui",
                            "expected_value": "",
                            "text": content
                        },
                        "purpose": f"Insert '{content}' with cryptographic readback verification"
                    }
                ]
            }

        elif re.search(r"\b(click|press|tap|push|select)\b", text_lower):
            target = target_element or "Run"
            return {
                "intent": "click_button",
                "bundle_id": bundle_id,
                "strategy": "Inspect AX hierarchy, locate target centroid, dispatch non-focus-stealing click",
                "tool_calls": [
                    {
                        "step": 1,
                        "tool": "read_ui",
                        "arguments": {"app": bundle_id},
                        "purpose": "Discover accessibility tree and resolve unique element_id"
                    },
                    {
                        "step": 2,
                        "tool": "spatial_dom",
                        "arguments": {
                            "action": "click",
                            "target_label": target,
                            "element_role": "AXButton"
                        },
                        "purpose": f"Dispatch click to element '{target}'"
                    }
                ]
            }

        elif re.search(r"\b(read|inspect|check|scan|view|elements|tree)\b", text_lower):
            return {
                "intent": "inspect_app",
                "bundle_id": bundle_id,
                "strategy": "Full breadth-first AXUIElement tree walk (max 500 nodes)",
                "tool_calls": [
                    {
                        "step": 1,
                        "tool": "read_ui",
                        "arguments": {"app": bundle_id},
                        "purpose": "Extract all accessible elements, roles, titles, and IDs"
                    }
                ]
            }

        elif any(w in text_lower for w in ["copy", "clipboard", "grab"]):
            return {
                "intent": "copy_element_text",
                "bundle_id": bundle_id,
                "strategy": "Extract text via AXValue attribute and populate general pasteboard",
                "tool_calls": [
                    {
                        "step": 1,
                        "tool": "read_ui",
                        "arguments": {"app": bundle_id},
                        "purpose": "Locate element ID"
                    },
                    {
                        "step": 2,
                        "tool": "copy_text",
                        "arguments": {
                            "element_id": "resolved_from_read_ui",
                            "scope": "value"
                        },
                        "purpose": "Copy text to clipboard with readback check"
                    }
                ]
            }

        else:
            # Fallback to general command / desktop execution
            return {
                "intent": "general_desktop_action",
                "bundle_id": bundle_id,
                "strategy": "Execute via sandboxed command runner",
                "tool_calls": [
                    {
                        "step": 1,
                        "tool": "run_command",
                        "arguments": {"command": f"osascript -e 'tell application \"{app or 'System Events'}\" to activate'"},
                        "purpose": "Execute UI dispatch"
                    }
                ]
            }

    @classmethod
    def generate_ui_mapping_reference(cls) -> Dict[str, Any]:
        """Returns the full UI Intent-to-Tool mapping table."""
        return {
            "system": "Genie Autonomous UI Grounding System",
            "version": "3.0-Universal",
            "mappings": cls.INTENT_MAP,
            "bundle_directory": cls.APP_REGISTRY
        }

if __name__ == "__main__":
    mapper = GenieUIMapper()
    print("=" * 70)
    print("  🧞‍♂️ GENIE UI-TO-TOOL CALL MAPPER DEMONSTRATION")
    print("=" * 70)

    scenarios = [
        ("Click the 'Submit' button in Safari", "safari", "Submit", None),
        ("Type 'import numpy as np' into VS Code editor", "vscode", None, "import numpy as np"),
        ("Inspect all buttons and inputs in System Settings", "settings", None, None),
        ("Copy the selected text from Notes", "notes", None, None)
    ]

    for intent, app, elem, txt in scenarios:
        mapping = mapper.map_intent_to_tool_calls(intent, app, elem, txt)
        print(f"\n🎯 User UI Intent: \"{intent}\"")
        print(f"   Target App:   {mapping['bundle_id']}")
        print(f"   Strategy:     {mapping['strategy']}")
        print(f"   Tool Sequence:")
        for tc in mapping['tool_calls']:
            print(f"     Step {tc['step']}: {tc['tool']}({json.dumps(tc['arguments'])})")
            print(f"             ↳ Purpose: {tc['purpose']}")
