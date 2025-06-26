#!/usr/bin/env python3
"""
Simple HTTP server for the Quantum Script Reader
Serves .sh files from the current directory
"""

import os
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import unquote
import mimetypes

class ScriptReaderHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        try:
            if self.path == '/':
                self.serve_file('index.html', 'text/html')
            elif self.path == '/api/files':
                self.serve_file_list()
            elif self.path.startswith('/api/file/'):
                filename = unquote(self.path[10:])  # Remove '/api/file/'
                self.serve_script_file(filename)
            else:
                self.send_error(404, "File not found")
        except Exception as e:
            print(f"Error handling request {self.path}: {e}")
            self.send_error(500, f"Internal server error: {str(e)}")

    def serve_file(self, filename, content_type):
        """Serve a static file"""
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                content = f.read()
            
            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.send_header('Content-Length', len(content.encode('utf-8')))
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
        except FileNotFoundError:
            self.send_error(404, f"File {filename} not found")
        except Exception as e:
            self.send_error(500, f"Error reading file: {str(e)}")

    def serve_file_list(self):
        """Serve list of .sh files in current directory"""
        try:
            # Get all .sh files in current directory
            files = [f for f in os.listdir('.') if f.endswith('.sh') and os.path.isfile(f)]
            files.sort()  # Sort alphabetically
            
            response = json.dumps(files)
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', len(response.encode('utf-8')))
            self.end_headers()
            self.wfile.write(response.encode('utf-8'))
            
            print(f"Served file list: {len(files)} files found")
            
        except Exception as e:
            print(f"Error getting file list: {e}")
            self.send_error(500, f"Error getting file list: {str(e)}")

    def serve_script_file(self, filename):
        """Serve content of a specific .sh file"""
        try:
            # Security check: ensure filename is safe
            if not filename.endswith('.sh') or '/' in filename or '\\' in filename or '..' in filename:
                self.send_error(400, "Invalid filename")
                return
            
            # Check if file exists
            if not os.path.isfile(filename):
                self.send_error(404, f"File {filename} not found")
                return
            
            # Read and serve file content
            with open(filename, 'r', encoding='utf-8') as f:
                content = f.read()
            
            self.send_response(200)
            self.send_header('Content-type', 'text/plain; charset=utf-8')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', len(content.encode('utf-8')))
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
            
            print(f"Served file: {filename} ({len(content)} characters)")
            
        except Exception as e:
            print(f"Error serving file {filename}: {e}")
            self.send_error(500, f"Error reading file: {str(e)}")

    def log_message(self, format, *args):
        """Custom log message format"""
        print(f"[{self.date_time_string()}] {format % args}")

def run_server(port=8000):
    """Run the HTTP server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, ScriptReaderHandler)
    
    print(f"🚀 Quantum Script Reader Server")
    print(f"📁 Serving files from: {os.getcwd()}")
    print(f"🌐 Server running at: http://localhost:{port}")
    print(f"📄 Found .sh files: {len([f for f in os.listdir('.') if f.endswith('.sh')])}")
    print(f"⚡ Press Ctrl+C to stop the server")
    print("-" * 50)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
        httpd.server_close()

if __name__ == '__main__':
    import sys
    
    # Get port from command line argument or use default
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print("Invalid port number. Using default port 8000.")
    
    run_server(port)