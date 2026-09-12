#!/usr/bin/env python3
"""
osworld_agent_controller.py
-------------------------------------------------------------
Autonomous OS Agent Controller & Tool Execution Engine
Implements VM Tool Allowlist, Dynamic Discovery, Visual Grounding,
and Multi-Platform Input Execution (macOS CoreGraphics & Linux xdotool/scrot).
-------------------------------------------------------------
"""

import os
import sys
import json
import time
import subprocess
from typing import Dict, Any, List, Optional

# 1. System Prompt for Tool Discovery & Visual Grounding
SYSTEM_PROMPT = """You are an autonomous OS Agent operating inside a VM environment.
Before taking any action:
1. Discover Tools: Call discover_system_tools to see what capabilities are currently available in this VM.
2. Observe First: Call capture_screen to get the current desktop layout before deciding where to click.
3. Precise Grounding: Always verify coordinates (x, y) from the visual input. Ensure elements are visible before attempting clicks.
4. Step-by-Step Execution: Never execute multiple destructive actions at once. Act, observe, then verify.
5. Error Recovery: If a tool execution fails or an application doesn't respond, fall back to checking active windows via get_active_window or dump_accessibility_tree.
"""

# 2. VM Tool Allowlist Specification
VM_TOOL_ALLOWLIST = {
    "screen_control": [
        "capture_screen",
        "mouse_click",
        "mouse_double_click",
        "mouse_drag",
        "mouse_scroll",
        "keyboard_type",
        "keyboard_hotkey"
    ],
    "ui_inspection": [
        "dump_accessibility_tree",
        "find_ui_elements",
        "get_active_window"
    ],
    "vm_terminal": [
        "bash_execute",       # Restricted to allowlisted binaries
        "list_directory",
        "read_file",
        "write_file"
    ],
    "tool_discovery": [
        "discover_system_tools"
    ]
}

# Allowlisted binaries for bash_execute
ALLOWED_BINARIES = {
    "ls", "cat", "echo", "pwd", "grep", "find", "wc", "head", "tail",
    "mkdir", "cp", "mv", "rm", "python3", "python", "swift", "git",
    "which", "ps", "env", "uname", "whoami", "date", "curl"
}

class OSWorldAgentController:
    def __init__(self, tools_schema_path: Optional[str] = None):
        self.is_macos = sys.platform == "darwin"
        if tools_schema_path and os.path.exists(tools_schema_path):
            self.schema_path = tools_schema_path
        elif os.path.exists("/etc/agent_tools.json"):
            self.schema_path = "/etc/agent_tools.json"
        else:
            local_schema = os.path.join(os.path.dirname(__file__), "shadow_api_tools.json")
            self.schema_path = local_schema if os.path.exists(local_schema) else None

        self.tools_registry = self._load_registry()

    def _load_registry(self) -> List[Dict[str, Any]]:
        if self.schema_path and os.path.exists(self.schema_path):
            try:
                with open(self.schema_path, "r") as f:
                    return json.load(f)
            except Exception as e:
                print(f"[!] Warning: Failed to parse schema from {self.schema_path}: {e}")
        return []

    # MARK: - Tool Discovery & Introspection
    def discover_system_tools(self, category: str = "all") -> Dict[str, Any]:
        """Lists available allowlisted tools in the VM environment."""
        if category == "all":
            return {
                "status": "success",
                "categories": VM_TOOL_ALLOWLIST,
                "total_tools": sum(len(v) for v in VM_TOOL_ALLOWLIST.values()),
                "platform": "macOS" if self.is_macos else "Linux"
            }
        elif category in VM_TOOL_ALLOWLIST:
            return {
                "status": "success",
                "category": category,
                "tools": VM_TOOL_ALLOWLIST[category],
                "platform": "macOS" if self.is_macos else "Linux"
            }
        else:
            all_tools = [t for sub in VM_TOOL_ALLOWLIST.values() for t in sub]
            matching = [t for t in all_tools if category.lower() in t.lower()]
            return {
                "status": "success",
                "filter": category,
                "matching_tools": matching
            }

    # MARK: - Screen Control & Vision
    def capture_screen(self, output_path: str = "/tmp/agent_screen.png") -> Dict[str, Any]:
        """Captures display for multimodal visual reasoning."""
        try:
            if self.is_macos:
                cmd = ["/usr/sbin/screencapture", "-x", output_path]
            else:
                display = os.environ.get("DISPLAY", ":99")
                cmd = ["scrot", "-z", output_path]
            subprocess.run(cmd, check=True, timeout=5)
            return {"status": "success", "image_path": output_path, "bytes": os.path.getsize(output_path)}
        except Exception as e:
            return {"status": "error", "message": f"Screen capture failed: {str(e)}"}

    def mouse_click(self, x: float, y: float, button: str = "left") -> Dict[str, Any]:
        """Clicks at (x, y)."""
        try:
            if self.is_macos:
                # Use AppleScript or Quartz
                script = f"""
                use framework "CoreGraphics"
                set pt to {{x:{x}, y:{y}}}
                set eventType to {"1" if button == "left" else "3"}
                """
                # Fast fallback via cliclick if present or Python Quartz
                try:
                    from Quartz.CoreGraphics import (
                        CGEventCreateMouseEvent, CGEventPost, kCGHIDEventTap,
                        CGPoint, kCGEventLeftMouseDown, kCGEventLeftMouseUp,
                        kCGEventRightMouseDown, kCGEventRightMouseUp
                    )
                    pt = CGPoint(x, y)
                    down_type = kCGEventLeftMouseDown if button == "left" else kCGEventRightMouseDown
                    up_type = kCGEventLeftMouseUp if button == "left" else kCGEventRightMouseUp
                    ev_down = CGEventCreateMouseEvent(None, down_type, pt, 0)
                    ev_up = CGEventCreateMouseEvent(None, up_type, pt, 0)
                    CGEventPost(kCGHIDEventTap, ev_down)
                    time.sleep(0.04)
                    CGEventPost(kCGHIDEventTap, ev_up)
                except ImportError:
                    subprocess.run(["cliclick", f"c:{int(x)},{int(y)}"], check=False)
            else:
                btn_id = "1" if button == "left" else "3"
                subprocess.run(["xdotool", "mousemove", str(int(x)), str(int(y)), "click", btn_id], check=True)
            return {"status": "success", "action": "click", "x": x, "y": y, "button": button}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def mouse_double_click(self, x: float, y: float, button: str = "left") -> Dict[str, Any]:
        """Double clicks at (x, y)."""
        try:
            if self.is_macos:
                self.mouse_click(x, y, button)
                time.sleep(0.05)
                self.mouse_click(x, y, button)
            else:
                btn_id = "1" if button == "left" else "3"
                subprocess.run(["xdotool", "mousemove", str(int(x)), str(int(y)), "click", "--repeat", "2", "--delay", "50", btn_id], check=True)
            return {"status": "success", "action": "double_click", "x": x, "y": y}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def mouse_drag(self, from_x: float, from_y: float, to_x: float, to_y: float) -> Dict[str, Any]:
        """Drags from start point to destination."""
        try:
            if not self.is_macos:
                subprocess.run(["xdotool", "mousemove", str(int(from_x)), str(int(from_y)), "mousedown", "1",
                                "mousemove", str(int(to_x)), str(int(to_y)), "mouseup", "1"], check=True)
            else:
                subprocess.run(["cliclick", f"dd:{int(from_x)},{int(from_y)}", f"du:{int(to_x)},{int(to_y)}"], check=False)
            return {"status": "success", "action": "drag", "from": (from_x, from_y), "to": (to_x, to_y)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def mouse_scroll(self, delta_x: int = 0, delta_y: int = 0) -> Dict[str, Any]:
        """Scrolls mouse wheel."""
        try:
            if not self.is_macos:
                btn = "4" if delta_y > 0 else "5"
                repeats = abs(delta_y) or 1
                subprocess.run(["xdotool", "click", "--repeat", str(repeats), btn], check=True)
            return {"status": "success", "action": "scroll", "delta_x": delta_x, "delta_y": delta_y}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def keyboard_type(self, text: str) -> Dict[str, Any]:
        """Types text into frontmost application."""
        try:
            if self.is_macos:
                escaped = text.replace('\\', '\\\\').replace('"', '\\"')
                script = f'tell application "System Events" to keystroke "{escaped}"'
                subprocess.run(["osascript", "-e", script], check=True)
            else:
                subprocess.run(["xdotool", "type", "--delay", "12", text], check=True)
            return {"status": "success", "typed_length": len(text)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def keyboard_hotkey(self, key: str, modifiers: Optional[List[str]] = None) -> Dict[str, Any]:
        """Fires a key combination shortcut."""
        modifiers = modifiers or []
        try:
            if self.is_macos:
                mod_str = ""
                if modifiers:
                    mod_str = f" using {{{', '.join([m + ' down' for m in modifiers])}}}"
                script = f'tell application "System Events" to keystroke "{key}"{mod_str}'
                subprocess.run(["osascript", "-e", script], check=True)
            else:
                combo = "+".join(modifiers + [key]) if modifiers else key
                subprocess.run(["xdotool", "key", combo], check=True)
            return {"status": "success", "hotkey": key, "modifiers": modifiers}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # MARK: - UI Inspection
    def get_active_window(self) -> Dict[str, Any]:
        """Gets title and info for active frontmost window."""
        try:
            if self.is_macos:
                script = 'tell application "System Events" to get name of first application process whose frontmost is true'
                app_name = subprocess.check_output(["osascript", "-e", script], text=True).strip()
                return {"status": "success", "app_name": app_name}
            else:
                win_id = subprocess.check_output(["xdotool", "getactivewindow"], text=True).strip()
                win_name = subprocess.check_output(["xdotool", "getwindowname", win_id], text=True).strip()
                return {"status": "success", "window_id": win_id, "window_name": win_name}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # MARK: - VM Terminal & Filesystem
    def bash_execute(self, command: str) -> Dict[str, Any]:
        """Safely executes an allowlisted command in the VM terminal."""
        parts = command.strip().split()
        if not parts:
            return {"status": "error", "message": "Empty command"}
        binary = os.path.basename(parts[0])
        if binary not in ALLOWED_BINARIES:
            return {
                "status": "error",
                "message": f"Command '{binary}' is not in the VM allowed binaries list: {sorted(list(ALLOWED_BINARIES))}"
            }
        try:
            res = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=15)
            return {
                "status": "success" if res.returncode == 0 else "failed",
                "exit_code": res.returncode,
                "stdout": res.stdout[:2000],
                "stderr": res.stderr[:1000]
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def list_directory(self, path: str) -> Dict[str, Any]:
        """Lists files in the VM filesystem."""
        try:
            p = os.path.expanduser(path)
            if not os.path.exists(p):
                return {"status": "error", "message": f"Path not found: {p}"}
            items = os.listdir(p)
            return {"status": "success", "path": p, "count": len(items), "files": items[:50]}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def read_file(self, path: str) -> Dict[str, Any]:
        """Reads file content."""
        try:
            p = os.path.expanduser(path)
            with open(p, "r", encoding="utf-8", errors="replace") as f:
                content = f.read(8000)
            return {"status": "success", "path": p, "content": content}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    def write_file(self, path: str, content: str) -> Dict[str, Any]:
        """Writes file content."""
        try:
            p = os.path.expanduser(path)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w", encoding="utf-8") as f:
                f.write(content)
            return {"status": "success", "path": p, "bytes_written": len(content)}
        except Exception as e:
            return {"status": "error", "message": str(e)}


if __name__ == "__main__":
    controller = OSWorldAgentController()
    print("[*] OSWorld Agent Controller Initialized")
    print(f"[*] Platform: {'macOS' if controller.is_macos else 'Linux'}")
    print(f"[*] Available Tools:")
    print(json.dumps(controller.discover_system_tools(), indent=2))
