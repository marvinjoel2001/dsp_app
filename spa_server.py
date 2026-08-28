import http.server
import socketserver
import os
import mimetypes

PORT = 8080
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

class SPAServerHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def do_GET(self):
        # Remove query parameters if present
        clean_path = self.path.split('?')[0].split('#')[0]
        full_path = os.path.join(DIRECTORY, clean_path.lstrip('/'))

        # If it's a file that exists, serve it normally
        if os.path.isfile(full_path):
            return super().do_GET()

        # Otherwise, if it's an SPA route (like /login, /register, /feed), rewrite to /index.html
        self.path = '/index.html'
        return super().do_GET()

def run():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(('0.0.0.0', PORT), SPAServerHandler) as httpd:
        print(f"SPA Server running on http://0.0.0.0:{PORT} (Serving {DIRECTORY})")
        httpd.serve_forever()

if __name__ == '__main__':
    run()
