#!/usr/bin/env python3
import argparse, queue, time, threading, sys
import cv2
import numpy as np
import websocket
import pyvirtualcam
from pyvirtualcam import PixelFormat

p = argparse.ArgumentParser(description='Bridge WebsocketCAM JPEG websocket to v4l2loopback virtual camera')
p.add_argument('url', nargs='?', default='ws://192.168.50.30:3535')
p.add_argument('--device', default='/dev/video10')
p.add_argument('--fps', type=float, default=30.0)
p.add_argument('--width', type=int, default=0, help='output width, default source width')
p.add_argument('--height', type=int, default=0, help='output height, default source height')
p.add_argument('--mirror', action='store_true')
args = p.parse_args()

frames = queue.Queue(maxsize=2)
stop = threading.Event()
stats = {'rx':0, 'tx':0, 'bytes':0, 't0':time.time(), 'last':time.time()}

def put_latest(frame):
    while frames.full():
        try: frames.get_nowait()
        except queue.Empty: break
    frames.put_nowait(frame)

def on_open(ws):
    print(f'Connected to {args.url}', flush=True)

def on_message(ws, message):
    if isinstance(message, str):
        print('Text:', message[:200], flush=True); return
    arr = np.frombuffer(message, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if frame is None:
        print(f'JPEG decode failed ({len(message)} bytes)', flush=True); return
    if args.mirror:
        frame = cv2.flip(frame, 1)
    stats['rx'] += 1; stats['bytes'] += len(message)
    put_latest(frame)

def on_error(ws, err):
    if not stop.is_set(): print('WebSocket error:', repr(err), flush=True)

def on_close(ws, code, msg):
    print('WebSocket closed:', code, msg, flush=True); stop.set()

def ws_thread():
    ws = websocket.WebSocketApp(args.url, on_open=on_open, on_message=on_message, on_error=on_error, on_close=on_close)
    ws.run_forever(ping_interval=20, ping_timeout=10)
    stop.set()

threading.Thread(target=ws_thread, daemon=True).start()
print('Waiting for first frame...', flush=True)
try:
    first = frames.get(timeout=10)
except queue.Empty:
    print('No frames received in 10s. Is WebsocketCAM camera open?', file=sys.stderr)
    sys.exit(2)

src_h, src_w = first.shape[:2]
out_w = args.width or src_w
out_h = args.height or src_h
print(f'Source {src_w}x{src_h}; virtual camera {out_w}x{out_h}@{args.fps} -> {args.device}', flush=True)

last_frame = first
try:
    with pyvirtualcam.Camera(width=out_w, height=out_h, fps=args.fps, fmt=PixelFormat.BGR, device=args.device, print_fps=False) as cam:
        print(f'Virtual camera active: {cam.device}. Press Ctrl+C to stop.', flush=True)
        while not stop.is_set():
            try:
                last_frame = frames.get_nowait()
            except queue.Empty:
                pass
            frame = last_frame
            if frame.shape[1] != out_w or frame.shape[0] != out_h:
                frame = cv2.resize(frame, (out_w, out_h), interpolation=cv2.INTER_AREA)
            cam.send(frame)
            stats['tx'] += 1
            now=time.time()
            if now-stats['last'] >= 2:
                dt=now-stats['t0']
                print(f'rx={stats["rx"]/dt:.1f} fps tx={stats["tx"]/dt:.1f} fps net={stats["bytes"]*8/dt/1e6:.1f} Mbps', flush=True)
                stats['last']=now
            cam.sleep_until_next_frame()
except KeyboardInterrupt:
    pass
finally:
    stop.set()
