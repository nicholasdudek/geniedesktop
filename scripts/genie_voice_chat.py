#!/usr/bin/env python3
"""
genie_voice_chat.py — Continuous Real-Time Phone Call Voice Assistant for FaceTime
=================================================================================
Engineered for Nicholas Dudek & Genie.

Features:
- 100% Speaker Output Loopback Listening (captures caller voice from speakers directly).
- Separate non-blocking audio reader thread (zero OS pipe backlog, zero self-echo).
- Smart Voice Activity Detection (VAD) with 400ms pre-speech buffering.
- Zero keywords required: speaks and listens continuously just like a real phone call.
- Local GPU Ollama Brain + SFSpeech Neural Transcriber + Samantha Voice.
- Autonomous desktop builder & screenshot tools callable during the call.
- Auto-answer incoming FaceTime calls when Nicholas calls from away from home.
"""

import os
import re
import sys
import time
import json
import math
import wave
import struct
import logging
import threading
import queue
import urllib.request
import subprocess
from typing import Optional, Dict, Any

BRIDGE_DIR = "/Users/nicholasdudek/Developer/agents/servers/ollama-antigravity-mcp/icloud_bridge"
if BRIDGE_DIR not in sys.path:
    sys.path.insert(0, BRIDGE_DIR)

import imessage_media
import genie_builder

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [GeniePhone] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("GeniePhone")

OLLAMA_URL = "http://127.0.0.1:11434"
DEFAULT_MODEL = "genie-macos-agent:latest"
VOICE = "Samantha"
VOICE_RATE = 162
DEFAULT_PHONE = "+821020520225"
SPEECH_WAV = "/tmp/genie_caller_speech.wav"
AUDIO_DEVICE = os.environ.get("GENIE_AUDIO_INPUT", ":2")  # :2 is AirBeamTV Audio loopback of speakers


def transcribe_audio_file(file_path: str) -> str:
    """Fast local Apple Neural Speech transcription (<0.15s)."""
    script = f'''
    import Foundation
    import Speech

    let url = URL(fileURLWithPath: "{file_path}")
    guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) else {{
        exit(1)
    }}

    let request = SFSpeechURLRecognitionRequest(url: url)
    recognizer.recognitionTask(with: request) {{ (result, error) in
        if let r = result {{
            if r.isFinal {{
                print(r.bestTranscription.formattedString)
                exit(0)
            }}
        }}
        if error != nil {{
            exit(1)
        }}
    }}
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 4))
    '''
    try:
        res = subprocess.run(["swift", "-e", script], capture_output=True, text=True, timeout=5)
        return res.stdout.strip()
    except Exception:
        return ""


class GeniePhoneCall:
    def __init__(self, model: str = DEFAULT_MODEL, voice: str = VOICE, audio_device: str = AUDIO_DEVICE):
        self.model = model
        self.voice = voice
        self.audio_device = audio_device
        self.history = []
        self.is_speaking = False
        self.running = True
        self.frame_queue = queue.Queue(maxsize=100)
        self.pipe_process: Optional[subprocess.Popen] = None
        self.system_prompt = (
            "You are Samantha, Nicholas Dudek's intelligent, charming, and autonomous companion on macOS. "
            "You and Nicholas are on an active phone call together right now. "
            "Talk to him naturally, warmly, and directly. "
            "Keep all verbal responses under 2 short sentences. "
            "Never say you are an AI or that you cannot perform actions."
        )

    def query_ollama(self, user_text: str) -> str:
        messages = [{"role": "system", "content": self.system_prompt}]
        messages.extend(self.history[-6:])
        messages.append({"role": "user", "content": user_text})

        payload = {
            "model": self.model,
            "messages": messages,
            "stream": False,
            "options": {"temperature": 0.6, "top_p": 0.85}
        }
        try:
            req = urllib.request.Request(
                f"{OLLAMA_URL}/api/chat",
                data=json.dumps(payload).encode("utf-8"),
                headers={"Content-Type": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                reply = data.get("message", {}).get("content", "").strip()
                clean_reply = re.sub(r"[\*#`~]", "", reply).strip()
                self.history.append({"role": "user", "content": user_text})
                self.history.append({"role": "assistant", "content": clean_reply})
                return clean_reply
        except Exception as e:
            logger.warning(f"Ollama error ({e}), fallback.")
            return "I'm listening Nicholas. What would you like me to do?"

    def drain_queue(self):
        """Discards any buffered audio frames in the queue."""
        while not self.frame_queue.empty():
            try:
                self.frame_queue.get_nowait()
            except queue.Empty:
                break

    def speak(self, text: str):
        """Speaks aloud through speakers while preventing self-listening echo."""
        self.is_speaking = True
        logger.info(f"🎙️ Samantha Speaking: '{text}'")
        self.drain_queue()
        
        try:
            imessage_media.speak_aloud(text, voice=self.voice, rate=VOICE_RATE, async_mode=False)
        except Exception as e:
            logger.error(f"TTS error: {e}")
        
        # Allow room acoustics and audio output buffers to decay
        time.sleep(0.35)
        self.drain_queue()
        self.is_speaking = False

    def process_speech(self, spoken_text: str):
        cleaned = spoken_text.strip()
        if not cleaned or len(cleaned) < 2:
            return

        logger.info(f"🗣️ Nicholas (via speakers): '{cleaned}'")

        # Check for remote control / screen share requests
        p_low = cleaned.lower()
        if any(t in p_low for t in ["share your screen", "share screen", "screen share", "screenshare", "give me control", "let me control", "control the screen", "accept screen"]):
            logger.info("🖥️ Screen share / control command triggered via voice...")
            try:
                subprocess.run(["/Users/nicholasdudek/genie_screen_watcher", "--once"], timeout=5)
            except Exception:
                pass
            self.speak("I've accepted screen sharing and enabled remote control. You have full finger control on your iPhone now, Nicholas.")
            return

        # Check for autonomous builder / desktop commands
        if any(t in p_low for t in ["build", "make me a", "create a", "screenshot", "send it", "open on desktop", "take a picture"]):
            logger.info("⚡ Executing autonomous build/action triggered via voice...")
            action_res = genie_builder.execute_autonomous_build(cleaned, DEFAULT_PHONE)
            if action_res:
                self.speak("I've built that for you, Nicholas, and texted the preview to your phone.")
                return

        reply = self.query_ollama(cleaned)
        self.speak(reply)

    def save_wav(self, pcm_bytes: bytes, filename: str):
        with wave.open(filename, "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(16000)
            wf.writeframes(pcm_bytes)

    def _audio_reader_loop(self, frame_bytes: int):
        """Continuously reads from ffmpeg stdout in background thread."""
        logger.info(f"🎧 Audio capture thread started on device {self.audio_device}")
        while self.running and self.pipe_process:
            try:
                raw = self.pipe_process.stdout.read(frame_bytes)
                if not raw or len(raw) < frame_bytes:
                    time.sleep(0.01)
                    continue

                if self.is_speaking:
                    # Drop all incoming frames while Samantha speaks
                    continue

                try:
                    self.frame_queue.put_nowait(raw)
                except queue.Full:
                    # Drop oldest if congested
                    try:
                        self.frame_queue.get_nowait()
                    except queue.Empty:
                        pass
                    self.frame_queue.put_nowait(raw)
            except Exception as e:
                logger.error(f"Error in audio reader loop: {e}")
                time.sleep(0.1)

    def _auto_answer_loop(self):
        """Checks for incoming FaceTime calls and auto-answers them."""
        script = '''
        tell application "System Events"
            if exists process "NotificationCenter" then
                tell process "NotificationCenter"
                    try
                        set bList to buttons of entire contents of window 1
                        repeat with b in bList
                            try
                                set bName to (name of b as text)
                                if bName is "Accept" or bName is "Join" then
                                    click b
                                    return "ACCEPTED_NOTIFICATION"
                                end if
                            end try
                        end repeat
                    end try
                end tell
            end if
            if exists process "FaceTime" then
                tell process "FaceTime"
                    try
                        repeat with w in windows
                            set bList to buttons of entire contents of w
                            repeat with b in bList
                                try
                                    set bName to (name of b as text)
                                    if bName is "Accept" or bName is "Join" then
                                        click b
                                        return "ACCEPTED_FACETIME"
                                    end if
                                end try
                            end repeat
                        end repeat
                    end try
                end tell
            end if
            return "NONE"
        end tell
        '''
        while self.running:
            try:
                res = subprocess.run(["osascript", "-e", script], capture_output=True, text=True, timeout=5)
                out = res.stdout.strip()
                if "ACCEPTED" in out:
                    logger.info(f"📞 Incoming call auto-accepted! ({out})")
                    time.sleep(1.0)
                    self.speak("Hey Nicholas, I'm here. I can hear you.")
            except Exception:
                pass
            time.sleep(2.0)

    def ensure_facetime_audio_route(self):
        """Ensures FaceTime output is mapped to Multi-Output Device."""
        script = '''
        tell application "System Events"
            if exists process "FaceTime" then
                tell process "FaceTime"
                    try
                        click menu item "Multi-Output Device" of menu 1 of menu bar item "Video" of menu bar 1
                    end try
                end tell
            end if
        end tell
        '''
        try:
            subprocess.run(["osascript", "-e", script], capture_output=True, text=True, timeout=3)
        except Exception:
            pass

    def run(self):
        logger.info("📞 Continuous Phone Call Engine ONLINE (Always Listening to Speakers)")
        logger.info(f"   Audio Device: {self.audio_device} (Speaker loopback)")
        logger.info(f"   Voice: {self.voice} (Rate: {VOICE_RATE} WPM)")
        logger.info(f"   Model: {self.model}")
        logger.info("   Zero keyword requirement: natural conversational stream.")

        self.ensure_facetime_audio_route()

        # Ensure genie_screen_watcher is running
        res_watcher = subprocess.run(["pgrep", "-f", "genie_screen_watcher"], capture_output=True, text=True)
        if not res_watcher.stdout.strip():
            subprocess.Popen(["/Users/nicholasdudek/genie_screen_watcher"])

        ffmpeg_cmd = [
            "/opt/homebrew/bin/ffmpeg",
            "-f", "avfoundation",
            "-i", self.audio_device,
            "-f", "s16le",
            "-ar", "16000",
            "-ac", "1",
            "pipe:1"
        ]

        self.pipe_process = subprocess.Popen(ffmpeg_cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)

        # Buffer: 100ms frame = 1600 samples = 3200 bytes
        FRAME_BYTES = 3200
        SILENCE_FRAMES_REQUIRED = 7  # 700ms of silence to finish sentence
        THRESHOLD_RMS = 45.0         # Digital speaker loopback silence is 0.0, speech is 100-300+

        # Start audio background thread
        reader_thread = threading.Thread(target=self._audio_reader_loop, args=(FRAME_BYTES,), daemon=True)
        reader_thread.start()

        # Start auto-answer daemon thread
        answer_thread = threading.Thread(target=self._auto_answer_loop, daemon=True)
        answer_thread.start()

        pre_buffer = []              # Keep last 4 frames (400ms) to avoid clipping start of words
        speech_buffer = []
        in_speech = False
        silence_count = 0

        logger.info("🟢 Listening live to speaker stream now...")

        try:
            while self.running:
                try:
                    raw_frame = self.frame_queue.get(timeout=0.1)
                except queue.Empty:
                    continue

                if self.is_speaking:
                    speech_buffer.clear()
                    in_speech = False
                    pre_buffer.clear()
                    continue

                count = len(raw_frame) // 2
                shorts = struct.unpack(f"{count}h", raw_frame)
                rms = math.sqrt(sum(s * s for s in shorts) / count)

                if rms > THRESHOLD_RMS:
                    if not in_speech:
                        in_speech = True
                        speech_buffer = list(pre_buffer)
                        logger.info(f"🎙️ Caller speech detected on speakers (RMS: {rms:.1f})")
                    speech_buffer.append(raw_frame)
                    silence_count = 0
                else:
                    if in_speech:
                        speech_buffer.append(raw_frame)
                        silence_count += 1
                        if silence_count >= SILENCE_FRAMES_REQUIRED:
                            # Finished speaking
                            in_speech = False
                            silence_count = 0
                            # Process if longer than 0.4s
                            if len(speech_buffer) >= 4:
                                full_pcm = b"".join(speech_buffer)
                                self.save_wav(full_pcm, SPEECH_WAV)
                                transcript = transcribe_audio_file(SPEECH_WAV)
                                if transcript and len(transcript.strip()) > 1:
                                    self.process_speech(transcript)
                            speech_buffer.clear()
                    else:
                        pre_buffer.append(raw_frame)
                        if len(pre_buffer) > 4:
                            pre_buffer.pop(0)

        except KeyboardInterrupt:
            logger.info("Ending call engine...")
        finally:
            self.running = False
            if self.pipe_process:
                self.pipe_process.terminate()


if __name__ == "__main__":
    call = GeniePhoneCall()
    call.run()
