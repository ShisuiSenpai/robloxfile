#!/usr/bin/env python3
"""
Simple HTTP server to view the cannon models
"""

import http.server
import socketserver
import os
import webbrowser

PORT = 8000

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add headers to allow cross-origin requests for external resources
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

os.chdir(os.path.dirname(os.path.abspath(__file__)))

print(f"Starting server on http://localhost:{PORT}")
print("\nAvailable cannon models:")
print("1. Three.js version: http://localhost:8000/cannon.html")
print("2. Babylon.js version: http://localhost:8000/cannon-babylon.html")
print("\nPress Ctrl+C to stop the server")

with socketserver.TCPServer(("", PORT), MyHTTPRequestHandler) as httpd:
    # Optionally open the browser
    webbrowser.open(f'http://localhost:{PORT}/cannon.html')
    httpd.serve_forever()