from flask import Flask, jsonify
import socket
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def home():
    hostname = socket.gethostname()
    return f'''<!DOCTYPE html>
<html><head><title>Server: {hostname}</title>
<style>
body {{font-family: Arial; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
      display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0;}}
.container {{background: white; border-radius: 20px; padding: 40px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); max-width: 600px;}}
h1 {{color: #667eea; text-align: center;}}
.info {{background: #f8f9fa; border-left: 4px solid #667eea; padding: 20px; margin: 15px 0; border-radius: 8px;}}
.label {{font-weight: bold; color: #555;}}
.value {{font-size: 1.2em; color: #333; margin-top: 5px;}}
button {{background: #667eea; color: white; border: none; padding: 12px 30px; border-radius: 8px; 
         cursor: pointer; font-size: 1em; width: 100%; margin-top: 20px;}}
button:hover {{background: #764ba2;}}
</style></head><body>
<div class="container">
<h1>🖥️ Server Information</h1>
<div class="info"><div class="label">Hostname:</div><div class="value">{hostname}</div></div>
<div class="info"><div class="label">IP Address:</div><div class="value">{socket.gethostbyname(hostname)}</div></div>
<div class="info"><div class="label">Time:</div><div class="value">{datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</div></div>
<button onclick="location.reload()">🔄 Refresh to See Load Balancing</button>
</div></body></html>'''

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'hostname': socket.gethostname()}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
