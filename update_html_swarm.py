import re

with open("index.html", "r") as f:
    html = f.read()

old_text = "providing sub-millisecond, zero-copy (IOSurface) control over your screen—drastically outperforming traditional Ubuntu VNC pixel-scraping.</p>"
new_text = "providing sub-millisecond, zero-copy (IOSurface) control over your screen. By bypassing the HTML engine and predictively pasting pre-rendered JPG backgrounds, UI rendering cost drops to near zero. Genie takes the 99% freed CPU capacity and spins up <b>Headless Background Swarms</b>—invisible VMs that speculatively pre-compute your next tasks, compile code, and run heavy asynchronous workloads while you view the instant UI.</p>"

if old_text in html:
    html = html.replace(old_text, new_text)
    with open("index.html", "w") as f:
        f.write(html)
    print("Success: Updated index.html")
else:
    print("Error: Could not find the text to replace.")
