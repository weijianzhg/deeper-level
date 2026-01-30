#!/usr/bin/env python3
"""
Local proxy server to bypass CORS and handle World Labs API authentication
"""
import os
import requests
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from dotenv import load_dotenv

load_dotenv()
API_KEY = os.getenv('WORLDLABS_API_KEY')

class ProxyHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        # Set the directory to serve files from
        super().__init__(*args, directory=os.getcwd(), **kwargs)
    
    def do_GET(self):
        # Handle proxy requests
        if self.path.startswith('/proxy?url='):
            self.handle_proxy()
        else:
            # Serve static files (viewer.html, etc.)
            super().do_GET()
    
    def handle_proxy(self):
        """Proxy requests to World Labs with authentication"""
        try:
            # Extract the target URL
            query = parse_qs(urlparse(self.path).query)
            target_url = query.get('url', [None])[0]
            
            if not target_url:
                self.send_error(400, "Missing url parameter")
                return
            
            print(f"📦 Proxying request to: {target_url}")
            
            # Fetch with API key (don't stream, get full content)
            headers = {}
            if 'worldlabs.ai' in target_url:
                headers['WLT-Api-Key'] = API_KEY
            
            response = requests.get(target_url, headers=headers)
            response.raise_for_status()
            
            # Get the full binary content
            content = response.content
            
            print(f"📊 Content size: {len(content)} bytes")
            
            # Forward the response
            self.send_response(200)
            
            # Add CORS headers
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', '*')
            
            # Forward content headers
            content_type = response.headers.get('Content-Type', 'application/octet-stream')
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(content)))
            
            # Important for binary data
            self.send_header('Accept-Ranges', 'bytes')
            
            self.end_headers()
            
            # Write the complete binary content
            self.wfile.write(content)
            
            print(f"✅ Proxied successfully ({len(content)} bytes)")
            
        except requests.exceptions.RequestException as e:
            print(f"❌ Request error: {e}")
            self.send_error(502, f"Failed to fetch from upstream: {str(e)}")
        except Exception as e:
            print(f"❌ Proxy error: {e}")
            import traceback
            traceback.print_exc()
            self.send_error(500, f"Proxy error: {str(e)}")
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom logging"""
        if not self.path.startswith('/proxy'):
            print(f"📄 {args[0]}")

def run_server(port=8000):
    server = HTTPServer(('localhost', port), ProxyHandler)
    print("=" * 60)
    print(f"🚀 Proxy Server Running!")
    print("=" * 60)
    print(f"📍 Server: http://localhost:{port}")
    print(f"📄 Viewer: http://localhost:{port}/viewer.html")
    print(f"🔑 API Key loaded: {'✅' if API_KEY else '❌'}")
    print("=" * 60)
    print("\nPress Ctrl+C to stop\n")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n👋 Server stopped")
        server.shutdown()

if __name__ == "__main__":
    run_server()
