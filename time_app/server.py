from http.server import BaseHTTPRequestHandler, HTTPServer
import json
from datetime import datetime, timezone, timedelta

class TimeServer(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()

            # Get current time in different time zones
            ny_time = datetime.now(timezone(timedelta(hours=-5)))
            berlin_time = datetime.now(timezone(timedelta(hours=1)))
            tokyo_time = datetime.now(timezone(timedelta(hours=9)))

            # Create HTML response
            html = f"<h1>Time in Different Time Zones</h1>" \
                   f"<p>New York: {ny_time}</p>" \
                   f"<p>Berlin: {berlin_time}</p>" \
                   f"<p>Tokyo: {tokyo_time}</p>"
            
            self.wfile.write(html.encode())

        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            # Create JSON response
            health = {'status': 'ok'}
            jsonResponse = json.dumps(health).encode()
            self.wfile.write(jsonResponse)

def main():
    host = 'localhost'
    port = 8080
    server = HTTPServer((host, port), TimeServer)
    print(f'Server listening on port {port}...')
    server.serve_forever()

if __name__ == "__main__":
    main()
