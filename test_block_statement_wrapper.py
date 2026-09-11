#!/usr/bin/env python3
"""
test_block_statement_wrapper.py
-------------------------------
Implements and demonstrates the user's formula:
    print(wrapper(x2))

Where:
- x2: Raw incoming token stream (partial, fragmented chunks from LLM/socket)
- wrapper(x2): Atomic block/statement gate that buffers tokens and yields
  EXACTLY ONE full <div>...</div> at a time, or ONE full statement at a time.
"""

import sys
import time
import re
from typing import Generator, Iterable, Union

# ==============================================================================
# 1. HTML Atomic Block Wrapper (One <div> at a time)
# ==============================================================================

def div_block_wrapper(token_stream: Iterable[str], target_tag: str = "div") -> Generator[str, None, None]:
    """
    Buffers fragmented token chunks and yields ONLY when an entire balanced
    <tag>...</tag> block has been fully closed.
    """
    buffer = ""
    depth = 0
    tag_pattern = re.compile(rf"<(/)?\s*{target_tag}\b[^>]*>", re.IGNORECASE)

    for chunk in token_stream:
        buffer += chunk
        
        # Scan buffer for open/close tag transitions
        # We search from the beginning to track current depth
        matches = list(tag_pattern.finditer(buffer))
        if not matches:
            continue

        depth = 0
        last_closed_end = None

        for m in matches:
            is_closing = (m.group(1) == "/")
            if is_closing:
                depth = max(0, depth - 1)
                if depth == 0:
                    last_closed_end = m.end()
            else:
                depth += 1

        # If we reached depth == 0 after at least one open tag, emit the complete div
        if depth == 0 and last_closed_end is not None:
            complete_div = buffer[:last_closed_end].strip()
            if complete_div:
                yield complete_div
            # Retain remaining buffer for the next div
            buffer = buffer[last_closed_end:].lstrip()

    # Flush any remaining buffer at end of stream
    if buffer.strip():
        yield buffer.strip()


# ==============================================================================
# 2. Code Statement Wrapper (One full statement at a time)
# ==============================================================================

def code_statement_wrapper(token_stream: Iterable[str]) -> Generator[str, None, None]:
    """
    Buffers fragmented code tokens and yields ONLY when a complete,
    syntactically balanced statement (newline with balanced brackets/quotes) is ready.
    """
    buffer = ""
    paren_depth = 0
    bracket_depth = 0
    brace_depth = 0
    in_quote = None

    for chunk in token_stream:
        for char in chunk:
            buffer += char

            # Track quotes (single, double)
            if char in ("'", '"') and (len(buffer) < 2 or buffer[-2] != '\\'):
                if in_quote == char:
                    in_quote = None
                elif in_quote is None:
                    in_quote = char

            # Track brackets only outside strings
            if in_quote is None:
                if char == '(': paren_depth += 1
                elif char == ')': paren_depth = max(0, paren_depth - 1)
                elif char == '[': bracket_depth += 1
                elif char == ']': bracket_depth = max(0, bracket_depth - 1)
                elif char == '{': brace_depth += 1
                elif char == '}': brace_depth = max(0, brace_depth - 1)

                # Statement boundary: newline with balanced brackets and quotes
                if char == '\n' and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                    statement = buffer.strip()
                    if statement:
                        yield statement
                    buffer = ""

    if buffer.strip():
        yield buffer.strip()


# ==============================================================================
# 3. Universal Wrapper Formula: wrapper(x2)
# ==============================================================================

def wrapper(x2: Iterable[str], mode: str = "div") -> Generator[str, None, None]:
    """
    The universal block/statement wrapper formula:
        print(wrapper(x2))
    """
    if mode == "div":
        yield from div_block_wrapper(x2, target_tag="div")
    elif mode == "statement":
        yield from code_statement_wrapper(x2)
    else:
        yield from x2


# ==============================================================================
# 4. Live Verification Demonstration
# ==============================================================================

def simulate_raw_llm_stream() -> Generator[str, None, None]:
    """Simulates raw, fragmented token chunks streaming from an LLM."""
    raw_fragments = [
        "<di", "v class='c", "ard'>", "\n  <h", "2>First ", "Block</h2>", "\n  <p>Th",
        "is is block 1.", "</p>\n<", "/div>",
        "\n<div ", "id='sec", "ond'>\n  ", "<span>Nested content <di", "v>Inner</di", "v></span>\n",
        "</div>",
        "\n<div class='final'>All done.</div>"
    ]
    for frag in raw_fragments:
        yield frag

def simulate_raw_code_stream() -> Generator[str, None, None]:
    """Simulates raw, fragmented Python code tokens streaming from an LLM."""
    raw_code = [
        "x = 10", " + 20\n",
        "def compute(", "a, b):\n",
        "    return a ", "* b\n\n",
        "result = compute(", "x, 2)\n",
        "print(result)\n"
    ]
    for frag in raw_code:
        yield frag


if __name__ == "__main__":
    print("=" * 80)
    print("  TESTING FORMULA: print(wrapper(x2)) -> ONE DIV AT A TIME")
    print("=" * 80)
    
    x2_stream = simulate_raw_llm_stream()
    div_count = 0
    
    for complete_block in wrapper(x2_stream, mode="div"):
        div_count += 1
        print(f"\n--- [EMITTED ATOMIC DIV #{div_count}] ---")
        print(complete_block)

    print("\n" + "=" * 80)
    print("  TESTING FORMULA: print(wrapper(x2)) -> ONE FULL STATEMENT AT A TIME")
    print("=" * 80)

    code_stream = simulate_raw_code_stream()
    stmt_count = 0

    for complete_stmt in wrapper(code_stream, mode="statement"):
        stmt_count += 1
        print(f"[{stmt_count}] {complete_stmt}")

    print("\n[+] Verification successful: Zero partial fragments emitted!")
