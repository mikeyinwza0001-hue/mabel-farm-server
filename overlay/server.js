const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { Tail } = require('tail');
const path = require('path');
const fs = require('fs');
const os = require('os');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

app.use(express.static(path.join(__dirname, 'public')));

// Serve overlay at /overlay.html for TikTok Studio compatibility
app.get('/overlay.html', (_req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ─── Mabel Tracker Config ────────────────────────────────────────────────────
const TRACKER_URL = process.env.TRACKER_URL || '';
const TRACKER_SECRET = process.env.TRACKER_SECRET || '';
const PLUGIN_NAME = 'mabel-riceFarm';
const PLUGIN_VERSION = '2.0.0';

let accessStatus = 'unknown'; // 'approved' | 'pending' | 'banned' | 'unknown'

async function pingTracker(event) {
    if (!TRACKER_URL || !TRACKER_SECRET) {
        accessStatus = 'approved';
        return { ok: true, status: 'approved' };
    }
    try {
        const res = await fetch(`${TRACKER_URL}/ping`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                secret: TRACKER_SECRET,
                event,
                server: os.hostname(),
                mc_version: '1.21.1',
                plugin_version: PLUGIN_VERSION,
                plugin_name: PLUGIN_NAME,
                players: 0,
                timestamp: new Date().toISOString()
            })
        });
        const data = await res.json();
        accessStatus = data.status || 'unknown';
        console.log(`[Tracker] ${event} → status: ${accessStatus}`);
        if (accessStatus === 'banned') {
            console.warn(`[Tracker] SERVER BANNED: ${data.reason || 'No reason'}`);
        }
        return data;
    } catch (e) {
        console.error('[Tracker] Ping failed:', e.message);
        return { ok: true, status: 'unknown' };
    }
}

// ─── Access check endpoint ───────────────────────────────────────────────────
app.get('/api/access-status', (_req, res) => {
    res.json({ status: accessStatus });
});

// ─── Log Watcher ─────────────────────────────────────────────────────────────
const logPath = path.join(__dirname, '..', 'plugins', 'Skript', 'logs', 'farm_progress.log');

if (!fs.existsSync(logPath)) {
    fs.mkdirSync(path.dirname(logPath), { recursive: true });
    fs.writeFileSync(logPath, '');
}

console.log(`Watching log file: ${logPath}`);
const tail = new Tail(logPath, { follow: true, fromBeginning: false, useWatchFile: true });

tail.on('line', (data) => {
    if (accessStatus === 'banned') return;

    const match = data.match(/\[FarmOverlay\] PROGRESS:(\d+)\/(\d+)/);
    if (match) {
        const current = parseInt(match[1]);
        const total = parseInt(match[2]);
        const percentage = total > 0 ? (current / total) * 100 : 0;
        io.emit('progress', { current, total, percentage });
    }
});

tail.on('error', (error) => {
    console.error('Tail Error:', error);
});

// ─── Start Server ────────────────────────────────────────────────────────────
const PORT = 5656;
server.listen(PORT, async () => {
    console.log(`Overlay Server running on http://localhost:${PORT}`);

    // Ping tracker on startup
    await pingTracker('server_start');

    // Heartbeat every 5 minutes
    setInterval(() => pingTracker('heartbeat'), 5 * 60 * 1000);
});
