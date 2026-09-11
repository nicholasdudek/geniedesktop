import os
import json
import subprocess
import time
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuration
TRIGGER_DIR = Path("/home/ubuntu/genie_runtimes")
LOG_FILE = Path("/home/ubuntu/genie_daemon.log")

class RuntimeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith(".json"):
            self.process_config(event.src_path)

    def on_created(self, event):
        if event.src_path.endswith(".json"):
            self.process_config(event.src_path)

    def process_config(self, path):
        try:
            with open(path, 'r') as f:
                config = json.load(f)
            
            runtime_id = config.get('id', 'unknown')
            print(f"[*] Provisioning Runtime: {runtime_id}...")
            
            # Here we would trigger the actual Spark/Docker command
            # Example: subprocess.run(["spark-submit", ...])
            
            with open(LOG_FILE, "a") as log:
                log.write(f"[{time.ctime()}] Provisioned {runtime_id} with {config.get('displayName')}\n")
                
        except Exception as e:
            with open(LOG_FILE, "a") as log:
                log.write(f"[{time.ctime()}] Error processing {path}: {str(e)}\n")

def setup_env():
    TRIGGER_DIR.mkdir(parents=True, exist_ok=True)
    print(f"[*] Daemon listening on {TRIGGER_DIR}")

if __name__ == "__main__":
    setup_env()
    event_handler = RuntimeHandler()
    observer = Observer()
    observer.schedule(event_handler, str(TRIGGER_DIR), recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
