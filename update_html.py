import re

with open("index.html", "r") as f:
    html = f.read()

new_block = """    <!-- Latest Update — Build 500 Features -->
    <div class="menubar-update-band" style="margin-top: 20px;">
      <div class="menubar-update-grid">
        <div>
          <span class="menubar-update-pill">New in Build 500</span>
          <h3>Duo Fold Settings & WebSocket Acceleration</h3>
          <p>Genie's massive Build 500 is here. All 12 legacy control center tabs (Apps, Desktop, Themes, VIP Packs, etc.) have been fully restored and integrated natively into the iPad Duo Fold code editor as swipeable tabs. Under the hood, Genie now features native training pipelines for <b>GenieHypervisorEngine</b>, enabling instant macOS/Linux VM spin-ups. We've also hardwired the AI to use native WebSocket IO, providing sub-millisecond, zero-copy (IOSurface) control over your screen—drastically outperforming traditional Ubuntu VNC pixel-scraping.</p>
        </div>
      </div>
    </div>

"""

html = html.replace('<!-- Latest Update — Genie\'s own bar now runs alongside the system menu bar -->', new_block + '    <!-- Latest Update — Genie\'s own bar now runs alongside the system menu bar -->')

with open("index.html", "w") as f:
    f.write(html)
