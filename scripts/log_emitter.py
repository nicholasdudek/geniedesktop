import socket
import time
import subprocess
import json

PORT = 9999

def stream_logs():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.bind(('0.0.0.0', PORT))
        s.listen()
        print(f"[*] Log Emitter active on port {PORT}...")
        
        while True:
            conn, addr = s.accept()
            with conn:
                print(f"[*] Mac App connected from {addr}")
                # Tail the daemon log and stream it
                proc = subprocess.Popen(['tail', '-f', '/home/nicholasdudek/genie_daemon.log'], 
                                       stdout=subprocess.PIPE, text=True)
                for line in proc.stdout:
                    log_entry = {
                        "timestamp": time.strftime("%H:%M:%S"),
                        "message": line.strip(),
                        "level": "INFO" if "Provisioned" in line else "ERROR" if "Error" in line else "DEBUG"
                    }
                    conn.sendall((json.dumps(log_entry) + "\n").encode())

if __name__ == "__main__":
    stream_logs()
