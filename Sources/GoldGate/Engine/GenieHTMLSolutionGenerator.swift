import Foundation

/// Generates interactive, translucent HTML templates connected to Swift via WebKit message handlers.
/// Every template automatically instruments clickable images, solution cards, and action buttons.
public enum GenieHTMLSolutionGenerator {

    /// Standard injected JavaScript bridge for capturing mouse interactions on images, buttons, and solution elements.
    public static let bridgeScript: String = """
    <script>
    (function() {
        // Safe postMessage wrapper
        function dispatchToSwift(payload) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.genieBridge) {
                window.webkit.messageHandlers.genieBridge.postMessage(payload);
            } else {
                console.log("[GenieBridge fallback]", payload);
            }
        }

        // Auto-instrument all clickable items on load and DOM changes
        function wireInteractiveElements() {
            // Clickable images
            document.querySelectorAll('img, .clickable-image, .solution-card, button, [data-action]').forEach(function(el) {
                if (el.__genieWired) return;
                el.__genieWired = true;

                el.addEventListener('click', function(ev) {
                    ev.stopPropagation();
                    
                    // Ripple / pulse effect
                    el.style.transform = 'scale(0.96)';
                    setTimeout(function() { el.style.transform = ''; }, 120);

                    var payload = {
                        eventType: 'click',
                        tag: el.tagName.toLowerCase(),
                        id: el.id || '',
                        className: el.className || '',
                        src: el.src || (el.querySelector('img') ? el.querySelector('img').src : ''),
                        alt: el.alt || (el.querySelector('img') ? el.querySelector('img').alt : ''),
                        action: el.getAttribute('data-action') || '',
                        value: el.getAttribute('data-value') || '',
                        title: el.getAttribute('data-title') || el.innerText || el.alt || 'Item',
                        clientX: ev.clientX,
                        clientY: ev.clientY
                    };
                    dispatchToSwift(payload);
                });

                // Mouse hover feedback
                el.addEventListener('mouseenter', function() {
                    dispatchToSwift({
                        eventType: 'hover',
                        id: el.id || '',
                        action: el.getAttribute('data-action') || '',
                        title: el.getAttribute('data-title') || el.alt || ''
                    });
                });
            });
        }

        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', wireInteractiveElements);
        } else {
            wireInteractiveElements();
        }

        // MutationObserver for dynamically added solutions
        var observer = new MutationObserver(function() { wireInteractiveElements(); });
        observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
    })();
    </script>
    """

    /// Translucent Apple-glass theme styling
    public static let baseCSS: String = """
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-user-select: none;
            user-select: none;
        }
        body {
            background: transparent;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", sans-serif;
            color: #ffffff;
            overflow-x: hidden;
            padding: 24px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }
        .overlay-container {
            width: 100%;
            max-width: 860px;
            background: rgba(18, 22, 34, 0.65);
            -webkit-backdrop-filter: blur(28px) saturate(190%);
            backdrop-filter: blur(28px) saturate(190%);
            border: 1px solid rgba(255, 255, 255, 0.16);
            border-radius: 24px;
            padding: 28px;
            box-shadow: 0 30px 60px rgba(0, 0, 0, 0.45), inset 0 1px 0 rgba(255, 255, 255, 0.25);
            animation: fadeIn 0.3s cubic-bezier(0.16, 1, 0.3, 1);
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: scale(0.97) translateY(8px); }
            to { opacity: 1; transform: scale(1.0) translateY(0); }
        }
        .header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 20px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.10);
            padding-bottom: 14px;
        }
        .header-title {
            font-size: 20px;
            font-weight: 700;
            background: linear-gradient(135deg, #ffffff 0%, #a5b4fc 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .badge {
            background: rgba(99, 102, 241, 0.25);
            border: 1px solid rgba(129, 140, 248, 0.4);
            color: #c7d2fe;
            font-size: 11px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 12px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .grid-solutions {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 16px;
            margin-top: 16px;
        }
        .solution-card {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.10);
            border-radius: 16px;
            padding: 16px;
            cursor: pointer;
            transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
            position: relative;
            overflow: hidden;
        }
        .solution-card:hover {
            background: rgba(255, 255, 255, 0.12);
            border-color: rgba(147, 197, 253, 0.5);
            transform: translateY(-2px);
            box-shadow: 0 12px 24px rgba(0, 0, 0, 0.25);
        }
        .solution-icon {
            font-size: 28px;
            margin-bottom: 8px;
        }
        .solution-title {
            font-size: 14px;
            font-weight: 600;
            color: #ffffff;
            margin-bottom: 4px;
        }
        .solution-desc {
            font-size: 11.5px;
            color: rgba(255, 255, 255, 0.65);
            line-height: 1.4;
        }
        .image-gallery {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 14px;
            margin-top: 16px;
        }
        .image-card {
            background: rgba(255, 255, 255, 0.04);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 14px;
            overflow: hidden;
            cursor: pointer;
            transition: all 0.22s ease;
        }
        .image-card:hover {
            border-color: #38bdf8;
            transform: scale(1.03);
            box-shadow: 0 10px 20px rgba(56, 189, 248, 0.25);
        }
        .image-card img {
            width: 100%;
            height: 110px;
            object-fit: cover;
            display: block;
        }
        .image-info {
            padding: 10px;
            background: rgba(0, 0, 0, 0.25);
        }
        .image-label {
            font-size: 12px;
            font-weight: 600;
            color: #f1f5f9;
        }
        .image-sub {
            font-size: 10px;
            color: #94a3b8;
            margin-top: 2px;
        }
        .btn-action {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: linear-gradient(135deg, #3b82f6 0%, #6366f1 100%);
            border: 1px solid rgba(255, 255, 255, 0.2);
            color: white;
            font-size: 12px;
            font-weight: 600;
            padding: 8px 14px;
            border-radius: 10px;
            cursor: pointer;
            transition: transform 0.15s ease, opacity 0.15s ease;
            margin-top: 10px;
        }
        .btn-action:hover {
            opacity: 0.92;
            transform: scale(1.02);
        }
    </style>
    """

    /// Generates the Autonomous Control Deck HTML template connecting iPhone touch and model routing to Swift.
    public static func autonomousDeckHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Genie Autonomous Deck</title>
            \(baseCSS)
            <style>
                .telemetry-bar {
                    display: flex;
                    gap: 12px;
                    margin-bottom: 20px;
                    background: rgba(0, 0, 0, 0.35);
                    border: 1px solid rgba(255, 255, 255, 0.08);
                    border-radius: 12px;
                    padding: 10px 16px;
                    align-items: center;
                    justify-content: space-between;
                }
                .tel-item {
                    display: flex;
                    flex-direction: column;
                    gap: 2px;
                }
                .tel-label {
                    font-size: 10px;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                    color: rgba(255, 255, 255, 0.5);
                }
                .tel-val {
                    font-size: 12px;
                    font-weight: 700;
                    color: #38bdf8;
                }
                .section-header {
                    font-size: 12px;
                    font-weight: 700;
                    letter-spacing: 0.6px;
                    text-transform: uppercase;
                    color: rgba(255, 255, 255, 0.6);
                    margin: 16px 0 8px 0;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                .actuator-row {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
                    gap: 10px;
                    margin-bottom: 12px;
                }
                .actuator-btn {
                    background: rgba(30, 41, 59, 0.7);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    border-radius: 12px;
                    padding: 12px 10px;
                    text-align: center;
                    cursor: pointer;
                    transition: all 0.15s ease;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    gap: 6px;
                }
                .actuator-btn:hover {
                    background: rgba(56, 189, 248, 0.18);
                    border-color: rgba(56, 189, 248, 0.5);
                    transform: translateY(-2px);
                }
                .actuator-icon {
                    font-size: 20px;
                }
                .actuator-title {
                    font-size: 11px;
                    font-weight: 600;
                    color: #f8fafc;
                }
                .brain-selector {
                    display: flex;
                    gap: 8px;
                    margin-bottom: 16px;
                }
                .brain-chip {
                    flex: 1;
                    padding: 8px 12px;
                    background: rgba(15, 23, 42, 0.8);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    border-radius: 10px;
                    cursor: pointer;
                    text-align: center;
                    font-size: 11px;
                    font-weight: 600;
                    color: #cbd5e1;
                    transition: all 0.15s ease;
                }
                .brain-chip:hover {
                    background: rgba(147, 51, 234, 0.25);
                    border-color: #a855f7;
                    color: #ffffff;
                }
            </style>
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <div class="header-title">
                        <span>🛸 Genie Autonomous Command Deck</span>
                    </div>
                    <span class="badge">Live Quartz & Mirroring Actuator</span>
                </div>

                <div class="telemetry-bar">
                    <div class="tel-item">
                        <span class="tel-label">ANE Vision OCR</span>
                        <span class="tel-val">3.6 ms (Hardware)</span>
                    </div>
                    <div class="tel-item">
                        <span class="tel-label">Active Brain</span>
                        <span class="tel-val">genie-iphone:latest</span>
                    </div>
                    <div class="tel-item">
                        <span class="tel-label">iPhone Viewport</span>
                        <span class="tel-val">393 × 852 (Pro)</span>
                    </div>
                    <div class="tel-item">
                        <span class="tel-label">Safety Screening</span>
                        <span class="tel-val">Governor Active 🛡️</span>
                    </div>
                </div>

                <div class="section-header">📱 iPhone Physical Continuity Actuator</div>
                <div class="actuator-row">
                    <div class="actuator-btn" data-action="openIPhone" data-title="Activate iPhone Mirroring">
                        <span class="actuator-icon">📱</span>
                        <span class="actuator-title">Open iPhone</span>
                    </div>
                    <div class="actuator-btn" data-action="iphoneTapHome" data-title="Home Gesture">
                        <span class="actuator-icon">🏠</span>
                        <span class="actuator-title">Swipe Home</span>
                    </div>
                    <div class="actuator-btn" data-action="iphoneControlCenter" data-title="Control Center">
                        <span class="actuator-icon">⚙️</span>
                        <span class="actuator-title">Control Center</span>
                    </div>
                    <div class="actuator-btn" data-action="iphoneNotifications" data-title="Notification Center">
                        <span class="actuator-icon">🔔</span>
                        <span class="actuator-title">Notifications</span>
                    </div>
                    <div class="actuator-btn" data-action="iphoneSnapshot" data-title="Snapshot to Polaroid">
                        <span class="actuator-icon">📸</span>
                        <span class="actuator-title">Snapshot</span>
                    </div>
                </div>

                <div class="section-header">🧠 Dual-Brain Neural Model Switcher</div>
                <div class="brain-selector">
                    <div class="brain-chip" data-action="setBrainModel" data-value="genie-iphone:latest" data-title="Genie iPhone Touch (30B)">
                        📱 iPhone Touch (30B)
                    </div>
                    <div class="brain-chip" data-action="setBrainModel" data-value="genie:latest" data-title="Genie Deep Architecture (30B)">
                        🏗️ Deep Master (30B)
                    </div>
                    <div class="brain-chip" data-action="setBrainModel" data-value="genie-3:7b" data-title="Turbo Edge (7B @ 120 tok/s)">
                        ⚡ Turbo Edge (120 tok/s)
                    </div>
                </div>

                <div class="section-header">🏛️ The 3 Pillars Command Operations</div>
                <div class="actuator-row">
                    <div class="actuator-btn" data-action="inspectAdmin" data-title="Audit Admin Authority">
                        <span class="actuator-icon">🛡️</span>
                        <span class="actuator-title">Inspect Admin</span>
                    </div>
                    <div class="actuator-btn" data-action="openReviewQueue" data-title="Human Review Queue">
                        <span class="actuator-icon">📬</span>
                        <span class="actuator-title">Review Queue</span>
                    </div>
                    <div class="actuator-btn" data-action="syncCloud" data-title="Sync Cloud Vault">
                        <span class="actuator-icon">☁️</span>
                        <span class="actuator-title">Sync Cloud</span>
                    </div>
                    <div class="actuator-btn" data-action="switchStation" data-value="zenith" data-title="Dialogue Studio">
                        <span class="actuator-icon">🌌</span>
                        <span class="actuator-title">Chat Studio</span>
                    </div>
                </div>
            </div>
            \(bridgeScript)
        </body>
        </html>
        """
    }

    /// Generates the Solutions Hub HTML template with clickable cards wired directly to Swift actions.
    public static func solutionsHubHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Genie Solutions Hub</title>
            \(baseCSS)
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <div class="header-title">
                        <span>🧞‍♂️ Genie Interactive Solutions</span>
                    </div>
                    <span class="badge">Swift Native Bridge</span>
                </div>
                
                <p style="font-size: 12px; color: rgba(255, 255, 255, 0.7); line-height: 1.5; margin-bottom: 12px;">
                    Click any solution tile or image below to trigger immediate native Swift actions, station navigation, or AI workflows.
                </p>

                <div class="grid-solutions">
                    <div class="solution-card" data-action="switchStation" data-value="zenith" data-title="Dialogue Studio (Zenith)">
                        <div class="solution-icon">🌌</div>
                        <div class="solution-title">Dialogue Studio (Zenith)</div>
                        <div class="solution-desc">Switch vertical canvas to the top screen to chat with local AI models.</div>
                    </div>

                    <div class="solution-card" data-action="switchStation" data-value="horizon" data-title="Desktop Canvas (Horizon)">
                        <div class="solution-icon">🖥️</div>
                        <div class="solution-title">Desktop Canvas (Horizon)</div>
                        <div class="solution-desc">Return to the clean center desktop workspace and active windows.</div>
                    </div>

                    <div class="solution-card" data-action="switchStation" data-value="nadir" data-title="Applications Atelier (Nadir)">
                        <div class="solution-icon">🚀</div>
                        <div class="solution-title">Applications Atelier (Nadir)</div>
                        <div class="solution-desc">Open the bottom screen application launcher and widget atelier.</div>
                    </div>

                    <div class="solution-card" data-action="runCommand" data-value="top -l 1 | head -n 10" data-title="System Health Telemetry">
                        <div class="solution-icon">⚡</div>
                        <div class="solution-title">System Diagnostics</div>
                        <div class="solution-desc">Execute instant live CPU, RAM, and hardware telemetry via Swift.</div>
                    </div>

                    <div class="solution-card" data-action="openFinder" data-value="Desktop" data-title="Open Desktop Folder">
                        <div class="solution-icon">📁</div>
                        <div class="solution-title">Inspect Desktop Files</div>
                        <div class="solution-desc">Focus the native Finder and inspect files on your clean desktop.</div>
                    </div>

                    <div class="solution-card" data-action="promptAgent" data-value="Summarize the frontmost open windows and propose a workflow." data-title="Genie AI Orchestrator">
                        <div class="solution-icon">✨</div>
                        <div class="solution-title">AI Action Plan</div>
                        <div class="solution-desc">Send structured prompt to Genie's Agent runtime to analyze open spaces.</div>
                    </div>
                </div>
            </div>
            \(bridgeScript)
        </body>
        </html>
        """
    }

    /// Generates an Image Gallery HTML template with clickable images wired to Swift.
    public static func imageGalleryHTML(images: [(url: String, title: String, subtitle: String, action: String)]) -> String {
        var itemsHTML = ""
        for item in images {
            itemsHTML += """
            <div class="image-card solution-card" data-action="\(item.action)" data-value="\(item.url)" data-title="\(item.title)">
                <img src="\(item.url)" alt="\(item.title)" class="clickable-image">
                <div class="image-info">
                    <div class="image-label">\(item.title)</div>
                    <div class="image-sub">\(item.subtitle)</div>
                </div>
            </div>
            """
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>Genie Image Solutions</title>
            \(baseCSS)
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <div class="header-title">
                        <span>🖼️ Interactive Clickable Images</span>
                    </div>
                    <span class="badge">Mouse Connected</span>
                </div>
                
                <p style="font-size: 12px; color: rgba(255, 255, 255, 0.7); margin-bottom: 12px;">
                    Click any image tile to select it, inspect metadata, or dispatch it directly to the Swift Vision pipeline.
                </p>

                <div class="image-gallery">
                    \(itemsHTML)
                </div>
            </div>
            \(bridgeScript)
        </body>
        </html>
        """
    }

    /// Wraps custom user/AI generated HTML with the Swift mouse bridge and transparent glass stylesheet.
    public static func wrapCustomHTML(_ customBody: String, title: String = "Genie Custom Solution") -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>\(title)</title>
            \(baseCSS)
        </head>
        <body>
            <div class="overlay-container">
                <div class="header">
                    <div class="header-title">
                        <span>✨ \(title)</span>
                    </div>
                    <span class="badge">Live HTML Solution</span>
                </div>
                \(customBody)
            </div>
            \(bridgeScript)
        </body>
        </html>
        """
    }
}
