// ============================================================================
// dashboard.js — read events.ndjson, render summary + canvas charts
// ============================================================================

const ACCENT_RGB = '255, 107, 0';

let currentWindow = 'week';

// --- Chrome (shared with the customizer) -----------------------------------
function initChrome() {
    const themeToggle = document.getElementById('theme-toggle');
    const saved = localStorage.getItem('theme')
        || (window.matchMedia('(prefers-color-scheme: light)').matches ? 'light' : 'dark');
    document.documentElement.setAttribute('data-theme', saved);
    themeToggle.innerHTML = saved === 'dark' ? '&#9790;' : '&#9728;';
    themeToggle.addEventListener('click', () => {
        const cur = document.documentElement.getAttribute('data-theme') || 'dark';
        const next = cur === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', next);
        localStorage.setItem('theme', next);
        themeToggle.innerHTML = next === 'dark' ? '&#9790;' : '&#9728;';
        renderAllCharts();   // recolour for the new theme
    });

    const navbar = document.querySelector('.navbar');
    const onScroll = () => navbar.classList.toggle('scrolled', window.scrollY > 20);
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();

    if ('IntersectionObserver' in window) {
        const io = new IntersectionObserver((entries) => {
            for (const e of entries) {
                if (e.isIntersecting) {
                    e.target.classList.add('visible');
                    io.unobserve(e.target);
                }
            }
        }, { threshold: 0.1 });
        document.querySelectorAll('.fade-in, .hero-reveal').forEach(el => io.observe(el));
    } else {
        document.querySelectorAll('.fade-in, .hero-reveal').forEach(el => el.classList.add('visible'));
    }

    // Particle canvas — reused from app.js
    initParticles();

    // Window switcher
    const windowPicker = document.getElementById('window-picker');
    windowPicker.addEventListener('click', (e) => {
        const btn = e.target.closest('[data-window]');
        if (!btn) return;
        currentWindow = btn.dataset.window;
        windowPicker.querySelectorAll('.btn').forEach(b => {
            b.classList.toggle('btn-primary', b === btn);
            b.classList.toggle('btn-outline', b !== btn);
        });
        loadAndRender();
    });
}

function initParticles() {
    const canvas = document.getElementById('hero-particles');
    if (!canvas || !canvas.getContext) return;
    const ctx = canvas.getContext('2d');
    const header = document.querySelector('header.hero');
    function resize() {
        if (!header) return;
        const r = header.getBoundingClientRect();
        const dpr = Math.min(window.devicePixelRatio || 1, 2);
        canvas.width  = r.width  * dpr;
        canvas.height = r.height * dpr;
        canvas.style.width  = r.width + 'px';
        canvas.style.height = r.height + 'px';
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.scale(dpr, dpr);
    }
    resize();
    window.addEventListener('resize', resize);
    const LAYERS = [
        { count: 18, speed: 0.12, sizeMin: 0.5, sizeMax: 1.2, alphaMin: 0.15, alphaMax: 0.3  },
        { count: 14, speed: 0.25, sizeMin: 1.0, sizeMax: 2.2, alphaMin: 0.35, alphaMax: 0.6  },
        { count:  8, speed: 0.45, sizeMin: 1.8, sizeMax: 3.5, alphaMin: 0.55, alphaMax: 0.85 },
    ];
    const particles = [];
    for (const layer of LAYERS) {
        for (let i = 0; i < layer.count; i++) {
            particles.push({
                x: Math.random() * canvas.width,
                y: Math.random() * canvas.height,
                vx: (Math.random() - 0.5) * layer.speed,
                vy: (Math.random() - 0.5) * layer.speed,
                size: layer.sizeMin + Math.random() * (layer.sizeMax - layer.sizeMin),
                alpha: layer.alphaMin + Math.random() * (layer.alphaMax - layer.alphaMin),
            });
        }
    }
    function tick() {
        const r = header.getBoundingClientRect();
        ctx.clearRect(0, 0, r.width, r.height);
        for (const p of particles) {
            p.x += p.vx; p.y += p.vy;
            if (p.x < 0) p.x = r.width;
            if (p.x > r.width) p.x = 0;
            if (p.y < 0) p.y = r.height;
            if (p.y > r.height) p.y = 0;
            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(${ACCENT_RGB}, ${p.alpha})`;
            ctx.fill();
        }
        for (let i = 0; i < particles.length; i++) {
            for (let j = i + 1; j < particles.length; j++) {
                const dx = particles[i].x - particles[j].x;
                const dy = particles[i].y - particles[j].y;
                const d2 = dx*dx + dy*dy;
                if (d2 < 14400) {
                    const a = 0.06 * (1 - d2 / 14400);
                    ctx.strokeStyle = `rgba(${ACCENT_RGB}, ${a})`;
                    ctx.lineWidth = 0.5;
                    ctx.beginPath();
                    ctx.moveTo(particles[i].x, particles[i].y);
                    ctx.lineTo(particles[j].x, particles[j].y);
                    ctx.stroke();
                }
            }
        }
        requestAnimationFrame(tick);
    }
    if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) requestAnimationFrame(tick);
}

// --- Data + charts ----------------------------------------------------------

let lastData = null;

async function loadAndRender() {
    setStatus('loading', 'busy');
    try {
        const res = await fetch('/api/events', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ window: currentWindow }),
        });
        lastData = await res.json();
    } catch (err) {
        setStatus('events fetch failed', 'err');
        return;
    }

    if (!lastData.summary || lastData.summary.available === false) {
        renderEmptyState();
        setStatus('no events yet', 'idle');
        return;
    }

    renderSummary(lastData.summary);
    renderSessions(lastData.sessions || []);
    renderAllCharts();
    setStatus('idle', 'ok');
}

function setStatus(text, kind) {
    const pill = document.getElementById('status-pill');
    pill.textContent = text;
    pill.className = 'status-pill ' + (kind || 'idle');
}

function fmtHM(secs) {
    const h = Math.floor(secs / 3600);
    const m = Math.floor((secs % 3600) / 60);
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
}

function fmtCost(d) {
    if (d >= 1) return '$' + d.toFixed(2);
    if (d > 0)  return '$' + d.toFixed(3);
    return '$0';
}

function renderSummary(s) {
    document.getElementById('stat-sessions').textContent = s.sessionCount || 0;
    document.getElementById('stat-active').textContent  = fmtHM(s.totalActiveSec || 0);
    document.getElementById('stat-peak').textContent    = fmtCost(s.peakCostPerMin || 0) + '/min';
    document.getElementById('stat-events').textContent  = (s.eventCount || 0).toLocaleString();
}

function renderSessions(sessions) {
    const root = document.getElementById('sessions-list');
    if (!sessions.length) {
        root.innerHTML = '<div class="empty">No sessions in this window.</div>';
        return;
    }
    root.innerHTML = sessions.map(s => {
        const start = new Date(s.start);
        const end   = new Date(s.end);
        const dur   = fmtHM(s.durationS);
        const dateLabel = start.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
        const startTime = start.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
        const endTime   = end.toLocaleTimeString(undefined, { hour: '2-digit', minute: '2-digit' });
        return `
            <div class="session-row">
                <div class="session-when">
                    <strong>${dateLabel}</strong>
                    <span class="meta">${startTime} → ${endTime}</span>
                </div>
                <div class="session-dur">${dur}</div>
                <div class="session-ctx">peak ctx ${Math.round(s.peakCtx)}%</div>
                <div class="session-id meta">${s.id.substring(0, 12)}</div>
            </div>
        `;
    }).join('');
}

function renderEmptyState() {
    document.getElementById('summary-grid').innerHTML = '<div class="empty" style="grid-column:1/-1">events.ndjson does not exist yet. Run Claude Code for a bit and refresh.</div>';
    document.getElementById('cost-chart').style.display = 'none';
    document.getElementById('ctx-chart').style.display = 'none';
    document.getElementById('sessions-list').innerHTML = '';
}

function renderAllCharts() {
    if (!lastData || !lastData.events) return;
    const events = lastData.events;
    renderLineChart('cost-chart',  events.map(e => ({ x: new Date(e.ts), y: e.costPerMin })), { label: '$/min', format: v => '$' + v.toFixed(3) });
    renderLineChart('ctx-chart',   events.map(e => ({ x: new Date(e.ts), y: e.ctxPct })),    { label: '%',    format: v => v.toFixed(0) + '%', yMax: 100 });
}

function renderLineChart(canvasId, points, opts) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    const rect = canvas.parentElement.getBoundingClientRect();
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    const w = rect.width;
    const h = canvas.height;            // attribute value
    canvas.width  = w * dpr;
    canvas.height = h * dpr;
    canvas.style.width  = w + 'px';
    canvas.style.height = h + 'px';
    const ctx = canvas.getContext('2d');
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.scale(dpr, dpr);
    ctx.clearRect(0, 0, w, h);

    if (!points.length) {
        ctx.fillStyle = readVar('--text-muted');
        ctx.font = '14px JetBrains Mono';
        ctx.textAlign = 'center';
        ctx.fillText('no data in this window', w/2, h/2);
        return;
    }

    const padding = { top: 16, right: 16, bottom: 32, left: 56 };
    const plotW = w - padding.left - padding.right;
    const plotH = h - padding.top - padding.bottom;

    const xMin = points[0].x.getTime();
    const xMax = points[points.length - 1].x.getTime() || (xMin + 1);
    const yMaxRaw = opts.yMax != null ? opts.yMax : Math.max(...points.map(p => p.y), 0.001);
    const yMax = yMaxRaw * 1.1;

    // grid lines (4 horizontals)
    ctx.strokeStyle = readVar('--border');
    ctx.lineWidth = 1;
    for (let i = 0; i <= 4; i++) {
        const yPx = padding.top + (plotH * i / 4);
        ctx.beginPath();
        ctx.moveTo(padding.left, yPx);
        ctx.lineTo(padding.left + plotW, yPx);
        ctx.stroke();
        // y-axis label
        const yVal = yMax - (yMax * i / 4);
        ctx.fillStyle = readVar('--text-muted');
        ctx.font = '11px JetBrains Mono';
        ctx.textAlign = 'right';
        ctx.fillText(opts.format(yVal), padding.left - 8, yPx + 3);
    }

    // x-axis labels — 3 ticks
    ctx.fillStyle = readVar('--text-muted');
    ctx.font = '11px JetBrains Mono';
    ctx.textAlign = 'center';
    for (let i = 0; i <= 3; i++) {
        const xPx = padding.left + (plotW * i / 3);
        const t = new Date(xMin + (xMax - xMin) * i / 3);
        ctx.fillText(t.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: '2-digit' }), xPx, h - 10);
    }

    // accent series
    const accent = readVar('--accent');
    const accentGlow = `rgba(${ACCENT_RGB}, 0.18)`;

    // filled area below line
    ctx.beginPath();
    points.forEach((p, idx) => {
        const xPx = padding.left + ((p.x.getTime() - xMin) / (xMax - xMin)) * plotW;
        const yPx = padding.top + (1 - p.y / yMax) * plotH;
        if (idx === 0) ctx.moveTo(xPx, yPx);
        else ctx.lineTo(xPx, yPx);
    });
    ctx.lineTo(padding.left + plotW, padding.top + plotH);
    ctx.lineTo(padding.left, padding.top + plotH);
    ctx.closePath();
    ctx.fillStyle = accentGlow;
    ctx.fill();

    // line on top
    ctx.beginPath();
    points.forEach((p, idx) => {
        const xPx = padding.left + ((p.x.getTime() - xMin) / (xMax - xMin)) * plotW;
        const yPx = padding.top + (1 - p.y / yMax) * plotH;
        if (idx === 0) ctx.moveTo(xPx, yPx);
        else ctx.lineTo(xPx, yPx);
    });
    ctx.strokeStyle = accent;
    ctx.lineWidth = 2;
    ctx.stroke();
}

function readVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || '#ffffff';
}

initChrome();
loadAndRender();
