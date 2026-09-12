#!/usr/bin/env python3
"""
Generate comprehensive framework knowledge pairs for Genie rollout in messages format.
"""

import json
import os

OUTPUT_FILE = os.path.join(os.path.dirname(__file__), "genie_frameworks_master_train.jsonl")

frameworks_data = [
    # Frontend
    {
        "framework": "React 19",
        "user": "Explain React 19 Server Components, Actions, and useOptimistic hooks for high-performance desktop UI rendering in Genie.",
        "assistant": "React 19 introduces native form Actions and the useActionState hook, eliminating manual useState/useEffect plumbing for form submissions. In Genie desktop web views, useOptimistic enables immediate client-side UI rendering while async agent background tasks complete. Key APIs: useActionState(fn, initialState), useOptimistic(passthroughState, updateFn), and <form action={action}>."
    },
    {
        "framework": "Next.js 15",
        "user": "Detail Next.js 15 App Router conventions, Server Actions, and partial prerendering (PPR) for high-scale apps.",
        "assistant": "Next.js 15 uses the App Router with default React Server Components (RSC), async request headers (cookies(), headers() returning promises), and Partial Prerendering (PPR). Static shell layouts render instantly via edge CDN while dynamic holes stream via Suspense boundaries. Server Actions ('use server') provide type-safe RPCs without custom REST route handlers."
    },
    {
        "framework": "Svelte 5",
        "user": "Outline Svelte 5 Runes ($state, $derived, $effect) and fine-grained reactivity in modern web apps.",
        "assistant": "Svelte 5 replaces let assignments and $: reactive declarations with universal Runes: $state() for reactive values, $derived() for computed values, and $effect() for side effects. Runes work inside .svelte files and standard .svelte.js/.ts utility modules, enabling fine-grained signal-based reactivity without virtual DOM overhead."
    },
    {
        "framework": "Tailwind CSS v4",
        "user": "How does Tailwind CSS v4 simplify configuration with CSS-first @theme directive and Lightning CSS?",
        "assistant": "Tailwind v4 moves configuration from tailwind.config.js directly into CSS using the @theme directive and Lightning CSS engine. Themes are declared with standard CSS variables (--color-primary: ...;), supporting modern P3 color spaces, container queries, and sub-millisecond incremental builds."
    },
    {
        "framework": "TypeScript 5.6+",
        "user": "What are TypeScript 5.6+ best practices for template literal types, satisfies operator, and const type parameters?",
        "assistant": "TypeScript provides the 'satisfies' operator to validate that an expression matches a type without widening its literal types, and 'const' type parameters (<const T>) to preserve literal tuples and objects upon function invocation without manual 'as const' assertions. Template literal types (e.g., `workspace_${string}`) provide compiler-guaranteed string schemas."
    },
    # Backend & Distributed
    {
        "framework": "FastAPI & Pydantic v2",
        "user": "How should FastAPI with Pydantic v2 be configured for low-latency agent streaming and structured JSON?",
        "assistant": "FastAPI leverages Pydantic v2 (Rust-core parsing) and Starlette ASGI. For agent workflows, use async def handlers with StreamingResponse for SSE (Server-Sent Events) or WebSockets. Enforce strict response models using TypeAdapter and model_dump(mode='json') for deterministic JSON schemas."
    },
    {
        "framework": "Rust Axum 0.7",
        "user": "How do you structure an ultra-fast REST & WebSocket service in Rust using Axum and Tokio?",
        "assistant": "Axum structures services around Router::new().route('/endpoint', get(handler)) with type-safe extractors (State, Json, Path). Handlers return impl IntoResponse. Tokio multi-threaded work-stealing runtime powers non-blocking I/O, while Tower middleware provides rate-limiting, CORS, and tracing layers with zero runtime overhead."
    },
    {
        "framework": "Go Gin & Fiber",
        "user": "When should you choose Fiber vs Gin in Go backend microservices?",
        "assistant": "Gin is built on net/http with mature middleware and strict memory allocations via gin.Context. Fiber is built on Fasthttp, achieving ultra-high RPS and zero-allocation routing by avoiding net/http compatibility. Both use goroutines for lightweight concurrent task scheduling."
    },
    {
        "framework": "ASP.NET Core 9 / C# 13",
        "user": "How does ASP.NET Core 9 Minimal APIs and Native AOT achieve high performance?",
        "assistant": "ASP.NET Core Minimal APIs remove Controller overhead by mapping endpoints directly with app.MapGet(). C# 13 Native AOT (Ahead-Of-Time compilation) compiles code straight into native machine instructions without JIT, drastically reducing cold start times to single-digit milliseconds and memory usage to tens of megabytes."
    },
    # Apple Native & Systems
    {
        "framework": "SwiftUI & AppKit",
        "user": "How does NSViewRepresentable and NSPanel facilitate borderless floating HUD overlays in macOS?",
        "assistant": "In macOS development, NSPanel with styleMask [.borderless, .nonactivatingPanel] and level = .floating creates auxiliary HUD overlays that do not steal key focus. Wrapping SwiftUI views inside NSHostingView or using NSViewRepresentable bridges AppKit's fine-grained WindowServer controls (e.g. ignoresMouseEvents, canJoinAllSpaces) into declarative SwiftUI hierarchies."
    },
    {
        "framework": "Apple Vision & ScreenCaptureKit",
        "user": "How does ScreenCaptureKit stream display buffers directly to VNRecognizeTextRequest for sub-50ms OCR?",
        "assistant": "ScreenCaptureKit (SCStream) captures display or window video buffers into CMSampleBuffer at up to 120 FPS. Passing CVPixelBufferRef into VNImageRequestHandler with VNRecognizeTextRequest (recognitionLevel: .accurate) allows real-time optical character recognition (OCR) with bounding boxes normalized to Quartz screen coordinates in sub-50ms."
    },
    {
        "framework": "Metal 3 & Apple Silicon Unified Memory",
        "user": "How does Metal 3 zero-copy buffer sharing work with Apple Silicon Unified Memory Architecture (UMA)?",
        "assistant": "On Apple Silicon, CPU and GPU share physical unified memory. MTLResourceStorageModeShared enables zero-copy buffer sharing between CPU pointers and Metal compute kernels without PCIe transfers. MTLComputePipelineState executes custom matrix multiplication and attention shaders with maximum memory bandwidth."
    },
    # AI & Agents
    {
        "framework": "LangGraph",
        "user": "Explain LangGraph stateful multi-agent cyclical graphs vs linear chains.",
        "assistant": "LangGraph models agent workflows as cyclical state machines (graphs) with TypedDict / Pydantic state schemas. Nodes represent agent tool-calling or reasoning routines; edges (conditional or direct) route execution based on tool output or router decisions. Checkpointers persist intermediate graph state for human-in-the-loop approval or time-travel debugging."
    },
    {
        "framework": "Google ADK & Gemini",
        "user": "What are the core components of building a Google ADK agent with tool bindings and state callbacks?",
        "assistant": "Google ADK structures agents around declarative tool declarations, model orchestration hooks, and runtime session state. Tools are declared as strongly-typed functions with docstrings. The agent passes tool schemas to the model, intercepts ToolCall choices, executes local code, and passes ToolResponse back into the conversational context."
    },
    {
        "framework": "vLLM & LoRA Serving",
        "user": "How does vLLM achieve high throughput with PagedAttention and multi-LoRA dynamic serving?",
        "assistant": "vLLM partitions the Key-Value (KV) cache into non-contiguous physical memory blocks (PagedAttention), eliminating memory fragmentation and enabling 2-4x higher batch sizes. Dynamic LoRA serving loads and unloads parameter-efficient adapter weights per request without reloading or duplicating the base model weights in GPU VRAM."
    },
    # Cloud & DevOps
    {
        "framework": "Kubernetes & Containers",
        "user": "How do you deploy an auto-scaling, resilient agent cluster on Kubernetes?",
        "assistant": "A production Kubernetes setup uses Deployment with rollingUpdate strategy, resource requests and limits, readiness and liveness probes, and an HPA targeting CPU/memory or custom Prometheus metrics. Networking is handled via ClusterIP Service and an Ingress (Envoy/NGINX) with TLS termination."
    },
    {
        "framework": "Terraform & IaC",
        "user": "What are Terraform best practices for multi-cloud multi-region infrastructure modules?",
        "assistant": "Use remote backend with S3/GCS state storage and DynamoDB/Cloud KMS state locking. Structure modules with explicit input variables, outputs, and provider alias blocks for multi-region or multi-cloud topologies. Enforce terraform plan validation in CI/CD pipelines before terraform apply."
    }
]

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    for item in frameworks_data:
        entry = {
            "messages": [
                {"role": "system", "content": f"You are Genie AI Master, an authority on {item['framework']} and full-stack software architecture."},
                {"role": "user", "content": item["user"]},
                {"role": "assistant", "content": item["assistant"]}
            ]
        }
        f.write(json.dumps(entry) + "\n")

print(f"✨ Successfully generated {len(frameworks_data)} framework knowledge entries in {OUTPUT_FILE}")
