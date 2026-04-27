#!/usr/bin/env python3
import argparse, time, sys
import cv2
import numpy as np
import websocket

parser = argparse.ArgumentParser(description='Test WebsocketCAM JPEG frames over WebSocket')
parser.add_argument('url', nargs='?', default='ws://192.168.50.30:3535')
parser.add_argument('--no-window', action='store_true', help='do not show OpenCV preview window')
parser.add_argument('--max-frames', type=int, default=0, help='stop after N decoded frames')
args = parser.parse_args()

state = {'frames': 0, 'bytes': 0, 't0': time.time(), 'last': time.time()}

def on_open(ws):
    print(f'Connected to {args.url}. Start/open camera in WebsocketCAM on phone if needed.', flush=True)

def on_message(ws, message):
    if isinstance(message, str):
        print('Text message:', message[:200], flush=True)
        return
    state['frames'] += 1
    state['bytes'] += len(message)
    arr = np.frombuffer(message, np.uint8)
    frame = cv2.imdecode(arr, cv2.IMREAD_COLOR)
    if frame is None:
        print(f'Frame {state["frames"]}: {len(message)} bytes, JPEG decode FAILED', flush=True)
        return
    h, w = frame.shape[:2]
    now = time.time()
    if now - state['last'] >= 1.0:
        dt = now - state['t0']
        fps = state['frames'] / dt if dt > 0 else 0
        mbps = (state['bytes'] * 8 / dt / 1_000_000) if dt > 0 else 0
        print(f'OK frames={state["frames"]} size={w}x{h} avg_fps={fps:.1f} avg_mbps={mbps:.1f}', flush=True)
        state['last'] = now
    if not args.no_window:
        cv2.imshow('WebsocketCAM test - ESC/q to quit', frame)
        key = cv2.waitKey(1) & 0xff
        if key in (27, ord('q')):
            ws.close()
    if args.max_frames and state['frames'] >= args.max_frames:
        ws.close()

def on_error(ws, error):
    print('WebSocket error:', repr(error), flush=True)

def on_close(ws, code, msg):
    print('Connection closed:', code, msg, flush=True)
    cv2.destroyAllWindows()

websocket.enableTrace(False)
ws = websocket.WebSocketApp(args.url, on_open=on_open, on_message=on_message, on_error=on_error, on_close=on_close)
try:
    ws.run_forever(ping_interval=20, ping_timeout=10)
except KeyboardInterrupt:
    print('\nStopped by user')
    ws.close()
    cv2.destroyAllWindows()
