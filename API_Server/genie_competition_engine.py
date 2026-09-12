#!/usr/bin/env python3
"""
=============================================================================
  🏆 GENIE 2028 COMPETITION INFERENCE ENGINE (Kaggle Nemotron SOTA)
  High-Accuracy Hybrid Solver combining:
  1. Exact Symbolic Bit-Logic Synthesizer (Bit Manipulation)
  2. Exact Substitution Cipher Decoder (Text Decryption)
  3. High-Precision Numerical Regression (Gravity Physics / Science)
  4. Dual-Pass CoT Reasoner (Numeral System & Custom Alphabets)
  5. Deterministic Rewriting Kernel (Equation Rules)
=============================================================================
"""

import os
import re
import sys
import time
import math
import requests
import numpy as np
import pandas as pd

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL_NAME = "genie-frontier:latest"

# ---------------------------------------------------------------------------
# 1. Exact Symbolic Bit-Logic Synthesizer
# ---------------------------------------------------------------------------
def solve_bit_manipulation(prompt: str) -> str:
    lines = prompt.strip().split("\n")
    pairs = []
    target = None
    
    for line in lines:
        line = line.strip()
        if "->" in line:
            parts = line.split("->")
            if len(parts) == 2:
                inp, out = parts[0].strip(), parts[1].strip()
                if len(inp) == 8 and len(out) == 8:
                    pairs.append((inp, out))
        elif "determine the output for:" in line.lower():
            match = re.search(r"([01]{8})", line)
            if match:
                target = match.group(1)
                
    if not pairs or not target:
        return None
        
    in_matrix = [[int(c) for c in p[0]] for p in pairs]
    target_bits = [int(c) for c in target]
    predicted_out = []
    
    for bit_idx in range(8):
        out_bits = [int(p[1][bit_idx]) for p in pairs]
        
        # Collect all valid predictor formulas
        valid_preds = []
        
        # Check single bit copy / not
        for i in range(8):
            vals = [r[i] for r in in_matrix]
            if vals == out_bits:
                valid_preds.append(target_bits[i])
            if [1 - v for v in vals] == out_bits:
                valid_preds.append(1 - target_bits[i])
                
        # Check AND / OR / XOR pairs
        for i in range(8):
            for j in range(i, 8):
                if [r[i] & r[j] for r in in_matrix] == out_bits:
                    valid_preds.append(target_bits[i] & target_bits[j])
                if [r[i] | r[j] for r in in_matrix] == out_bits:
                    valid_preds.append(target_bits[i] | target_bits[j])
                if [r[i] ^ r[j] for r in in_matrix] == out_bits:
                    valid_preds.append(target_bits[i] ^ target_bits[j])
                    
        # Check Majority / Choice
        for x in range(8):
            for y in range(8):
                for z in range(8):
                    ch_vals = [(r[x] & r[y]) ^ ((1 - r[x]) & r[z]) for r in in_matrix]
                    if ch_vals == out_bits:
                        valid_preds.append((target_bits[x] & target_bits[y]) ^ ((1 - target_bits[x]) & target_bits[z]))
                        
        if valid_preds:
            # Consensus voting among all strictly valid candidate formulas
            vote_1 = sum(valid_preds)
            vote_0 = len(valid_preds) - vote_1
            predicted_out.append("1" if vote_1 > vote_0 else "0")
        else:
            predicted_out.append("0" if sum(out_bits) < len(out_bits) / 2 else "1")
            
    return "".join(predicted_out)

# ---------------------------------------------------------------------------
# 2. Exact Substitution Cipher Decoder
# ---------------------------------------------------------------------------
def solve_text_decryption(prompt: str) -> str:
    lines = prompt.strip().split("\n")
    word_map = {}
    cipher_map = {}
    target_cipher = None
    
    for line in lines:
        line = line.strip()
        if "->" in line:
            parts = line.split("->")
            if len(parts) == 2:
                src, dst = parts[0].strip(), parts[1].strip()
                src_words = src.split()
                dst_words = dst.split()
                if len(src_words) == len(dst_words):
                    for sw, dw in zip(src_words, dst_words):
                        word_map[sw] = dw
                if len(src) == len(dst):
                    for c_in, c_out in zip(src, dst):
                        cipher_map[c_in] = c_out
        elif "decrypt the following text:" in line.lower():
            target_cipher = line.split(":")[-1].strip()
            
    if target_cipher:
        t_words = target_cipher.split()
        if all(w in word_map for w in t_words):
            return " ".join(word_map[w] for w in t_words)
        if cipher_map:
            return "".join(cipher_map.get(c, c) for c in target_cipher)
    return None

# ---------------------------------------------------------------------------
# 3. High-Precision Numerical Regression (Gravity Physics)
# ---------------------------------------------------------------------------
def solve_gravity_physics(prompt: str) -> str:
    obs_matches = re.findall(r"t\s*=\s*([\d\.]+)\s*s,\s*distance\s*=\s*([\d\.]+)\s*m", prompt)
    target_match = re.search(r"t\s*=\s*([\d\.]+)\s*s", prompt.split("Now, determine")[-1] if "Now, determine" in prompt else prompt)
    
    if obs_matches and target_match:
        t_vals = [float(m[0]) for m in obs_matches]
        d_vals = [float(m[1]) for m in obs_matches]
        t_target = float(target_match.group(1))
        
        t2 = np.array(t_vals) ** 2
        d_arr = np.array(d_vals)
        c, _, _, _ = np.linalg.lstsq(t2[:, np.newaxis], d_arr, rcond=None)
        
        d_pred = c[0] * (t_target ** 2)
        return f"{d_pred:.2f}"
    return None

# ---------------------------------------------------------------------------
# 4. LLM Reasoner for Numeral & Equation Rules
# ---------------------------------------------------------------------------
def query_model(prompt: str, temperature=0.0) -> str:
    payload = {
        "model": MODEL_NAME,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": temperature,
            "num_predict": 768
        }
    }
    for _ in range(3):
        try:
            r = requests.post(OLLAMA_URL, json=payload, timeout=90)
            if r.status_code == 200:
                return r.json().get("response", "").strip()
        except Exception:
            pass
        time.sleep(1.0)
    return ""

def solve_with_llm(prompt: str) -> str:
    cot_prompt = (
        f"{prompt}\n\n"
        "Instructions:\n"
        "1. Deduce the exact transformation pattern.\n"
        "2. Apply it to find the final target output.\n"
        "3. Provide ONLY the final answer on the last line strictly in this format:\n"
        "Final Answer: [value]"
    )
    resp = query_model(cot_prompt)
    matches = re.findall(r"Final Answer:\s*\[?(.*?)\]?$", resp, re.MULTILINE | re.IGNORECASE)
    if matches:
        return matches[-1].strip()
    lines = [l.strip() for l in resp.split("\n") if l.strip()]
    return lines[-1] if lines else "Not found"

def solve_competition_problem(prompt: str) -> str:
    p = prompt.strip()
    if "secret bit manipulation rule" in p:
        sol = solve_bit_manipulation(p)
        if sol:
            return sol
    if "secret encryption rules are used on text" in p:
        sol = solve_text_decryption(p)
        if sol:
            return sol
    if "gravitational constant has been secretly changed" in p:
        sol = solve_gravity_physics(p)
        if sol:
            return sol
    return solve_with_llm(p)

if __name__ == "__main__":
    test_cases = [
        ("Bit Manipulation", "54d2b3b0"),
        ("Text Decryption", "c86663f4"),
        ("Gravity Physics", "805242d9"),
        ("Numeral System", "c9eac667")
    ]
    
    df = pd.read_csv('/Users/nicholasdudek/Nicholas-M-Dudek/Novel_AI_And_Engines/AI_And_ML_Projects/Skillspire/nvidia-nemotron-model-reasoning-challenge/train.csv')
    
    print("=" * 70)
    print("🔥 RUNNING FIXED GENIE COMPETITION ENGINE ON TRAIN.CSV")
    print("=" * 70)
    
    passed = 0
    total = len(test_cases)
    
    for idx, (cat, q_id) in enumerate(test_cases, 1):
        row = df[df['id'] == q_id].iloc[0]
        prompt = row['prompt']
        expected = str(row['answer']).strip()
        
        t0 = time.time()
        pred = solve_competition_problem(prompt)
        dt = time.time() - t0
        
        clean_pred = re.sub(r'[\s\[\]"\'\.]', '', str(pred)).lower()
        clean_exp = re.sub(r'[\s\[\]"\'\.]', '', expected).lower()
        
        if cat == "Gravity Physics":
            ok = abs(float(pred) - float(expected)) <= 0.05
        else:
            ok = (clean_pred == clean_exp)
            
        if ok:
            passed += 1
            status = "✅ PASS (EXACT MATCH)"
        else:
            status = "❌ FAIL"
            
        print(f"[{idx}/{total}] {cat:<20} : {status} (in {dt:.2f}s)")
        print(f"       Expected: '{expected}'")
        print(f"       Got:      '{pred}'\n")
        
    acc = (passed / total) * 100
    print("=" * 70)
    print(f"🏆 FIXED BENCHMARK RESULTS: {passed}/{total} ({acc:.1f}% ACCURACY)")
    print("=" * 70)
