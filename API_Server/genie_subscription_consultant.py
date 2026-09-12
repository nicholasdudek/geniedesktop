#!/usr/bin/env python3
import sys, time, subprocess, argparse
from concurrent.futures import ThreadPoolExecutor

def consult_cli(cmd, clean_fn=lambda x: x, timeout=120):
    t0 = time.time()
    try:
        r = subprocess.run(cmd, stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=timeout)
        out = (r.stdout if r.returncode == 0 else r.stderr).strip()
        return round(time.time() - t0, 2), clean_fn(out), r.returncode == 0
    except Exception as e:
        return round(time.time() - t0, 2), str(e), False

def consult_claude(p, timeout=120):
    return consult_cli(["claude", "-p", p], timeout=timeout)

def consult_codex(p, timeout=120):
    def clean(s):
        lines = s.split("\n")
        out = "\n".join(lines[lines.index("codex")+1:]) if "codex" in lines else s
        return out.split("tokens used")[0].strip() if "tokens used" in out else out.strip()
    return consult_cli(["codex", "exec", "--skip-git-repo-check", p], clean, timeout=timeout)

def main():
    parser = argparse.ArgumentParser(description="Genie Subscription Consultant")
    parser.add_argument("--claude", type=str)
    parser.add_argument("--codex", type=str)
    parser.add_argument("--dual", type=str)
    parser.add_argument("--review", type=str)
    args = parser.parse_args()

    if args.claude:
        t, res, ok = consult_claude(args.claude)
        print(f"[Claude Code ({t}s)]:\n{res}")
    elif args.codex:
        t, res, ok = consult_codex(args.codex)
        print(f"[OpenAI Codex ({t}s)]:\n{res}")
    elif args.dual:
        with ThreadPoolExecutor(2) as ex:
            f_cl, f_cx = ex.submit(consult_claude, args.dual), ex.submit(consult_codex, args.dual)
            t_cl, res_cl, _ = f_cl.result()
            t_cx, res_cx, _ = f_cx.result()
        print(f"--- Claude ({t_cl}s) ---\n{res_cl}\n\n--- Codex ({t_cx}s) ---\n{res_cx}")
    elif args.review:
        code = open(args.review).read()
        p = f"Review this Swift code for concurrency safety & elegance:\n```swift\n{code}\n```"
        with ThreadPoolExecutor(2) as ex:
            f_cl, f_cx = ex.submit(consult_claude, p), ex.submit(consult_codex, p)
            t_cl, res_cl, _ = f_cl.result()
            t_cx, res_cx, _ = f_cx.result()
        print(f"=== CLAUDE ({t_cl}s) ===\n{res_cl}\n\n=== CODEX ({t_cx}s) ===\n{res_cx}")

if __name__ == "__main__":
    main()
