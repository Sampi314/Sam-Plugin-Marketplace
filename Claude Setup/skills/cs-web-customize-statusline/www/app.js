// ============================================================================
// app.js — Statusline Customizer SPA
// ============================================================================
//
// State flow:
//   1. fetch /api/manifest             -> widgets, palettes, line opts
//   2. render UI                       -> palette grid, widget toggles, sliders
//   3. user change -> debounce 200ms   -> POST /api/preview
//   4. preview HTML rendered into #preview-area
//   5. Apply  -> POST /api/apply       -> show result, then /api/shutdown
//   6. Cancel -> POST /api/shutdown
// ============================================================================

const state = {
    variant: 'Extended',
    palette: 'Sam',
    widgets: new Set(),       // populated after manifest loads
    barWidth: 30,
    lines: 'all',
};

let manifest = null;
let previewTimer = null;

// ----------------------------------------------------------------------------
// Widget grouping — drives the order and labelling of widget toggles in the UI.
// The host always adds 'mode-aware' implicitly, so it's not surfaced here.
// Reorder / regroup freely; widgets not listed here fall through to "Other".
// ----------------------------------------------------------------------------
const WIDGET_GROUPS = [
    {
        title: 'Core info',
        names: ['core-header', 'core-ctx', 'core-work'],
    },
    {
        title: 'Rate limits',
        names: ['core-rate-5h', 'core-rate-wk'],
    },
    {
        title: 'Sparklines & signals',
        names: ['sparkline-cost', 'sparkline-ctx', 'thinking', 'output-style', 'session-fingerprint'],
    },
    {
        title: 'Git & PRs',
        names: ['git-status', 'pr-badge'],
    },
    {
        title: 'Skill overlays',
        names: ['skill-audit-general', 'skill-financial-modelling', 'skill-writing-tools'],
    },
];

// ----------------------------------------------------------------------------
// pickSwatchColors(palette)
//   Decide which colour roles from a palette to surface as the 4-chip strip
//   shown on each palette card. A palette has 10 named roles; this picks the
//   subset that best communicates the palette's character at a glance.
//
//   TODO[design-decision]: tweak the role list below — it shapes how the
//   palette picker reads. Possible variants:
//     • Identity-first:  model, skill, cost, project   (shows headline colours)
//     • State-first:     added, removed, time, gold     (shows status colours)
//     • Mixed (current): model, cost, added, removed   (mixes both)
//   Returns the role keys in left-to-right order on the swatch strip.
// ----------------------------------------------------------------------------
function pickSwatchColors(palette) {
    return ['model', 'cost', 'added', 'removed'].map(key => palette.colors[key]);
}

// ----------------------------------------------------------------------------
// Init
// ----------------------------------------------------------------------------
async function init() {
    setStatus('loading manifest', 'busy');
    try {
        const res = await fetch('/api/manifest');
        manifest = await res.json();
    } catch (err) {
        setStatus('manifest failed', 'err');
        renderPreview('<pre class="statusline error">Could not reach the local server.</pre>');
        return;
    }

    // Default: all widgets selected (so the user starts from the full statusline)
    for (const w of manifest.widgets) {
        if (w.name !== 'mode-aware') state.widgets.add(w.name);
    }

    renderVariants();
    renderPalettes();
    renderWidgets();
    renderLines();
    renderBarWidth();
    wireButtons();
    schedulePreview(0);
    setStatus('idle', 'idle');
}

// ----------------------------------------------------------------------------
// Render helpers
// ----------------------------------------------------------------------------
function renderVariants() {
    const root = document.getElementById('variant-picker');
    root.innerHTML = '';
    for (const v of manifest.variants) {
        const label = document.createElement('label');
        const meta = v === 'Extended'
            ? 'Widget host with sparklines, mode-aware layout, skill overlays.'
            : 'Original monolithic script. Apply works; live preview not available.';
        label.innerHTML = `
            <input type="radio" name="variant" value="${v}" ${state.variant === v ? 'checked' : ''} />
            <strong>${v}</strong>
            <span class="variant-meta">${meta}</span>
        `;
        if (state.variant === v) label.classList.add('selected');
        label.querySelector('input').addEventListener('change', (e) => {
            state.variant = e.target.value;
            document.querySelectorAll('#variant-picker label').forEach(l => l.classList.remove('selected'));
            label.classList.add('selected');
            schedulePreview();
        });
        root.appendChild(label);
    }
}

function renderPalettes() {
    const root = document.getElementById('palette-grid');
    root.innerHTML = '';
    for (const p of manifest.palettes) {
        const card = document.createElement('div');
        card.className = 'palette-card' + (state.palette === p.name ? ' selected' : '');
        const swatchColors = pickSwatchColors(p);
        const swatchHtml = swatchColors.map(c => `<span style="background:${c}"></span>`).join('');
        card.innerHTML = `
            <div class="palette-name">${p.name}</div>
            <div class="palette-swatch">${swatchHtml}</div>
        `;
        card.addEventListener('click', () => {
            state.palette = p.name;
            document.querySelectorAll('.palette-card').forEach(c => c.classList.remove('selected'));
            card.classList.add('selected');
            schedulePreview();
        });
        root.appendChild(card);
    }
}

function renderWidgets() {
    const root = document.getElementById('widget-groups');
    root.innerHTML = '';
    const allWidgets = manifest.widgets.filter(w => w.name !== 'mode-aware');
    const seen = new Set();
    for (const group of WIDGET_GROUPS) {
        const groupWidgets = group.names
            .map(n => allWidgets.find(w => w.name === n))
            .filter(Boolean);
        if (!groupWidgets.length) continue;
        groupWidgets.forEach(w => seen.add(w.name));
        root.appendChild(renderWidgetGroup(group.title, groupWidgets));
    }
    // Fall-through "Other" group for any widgets WIDGET_GROUPS missed
    const orphans = allWidgets.filter(w => !seen.has(w.name));
    if (orphans.length) root.appendChild(renderWidgetGroup('Other', orphans));
}

function renderWidgetGroup(title, widgets) {
    const wrap = document.createElement('div');
    wrap.className = 'widget-group';
    const h = document.createElement('h4');
    h.textContent = title;
    wrap.appendChild(h);
    const list = document.createElement('div');
    list.className = 'widget-list';
    for (const w of widgets) {
        const item = document.createElement('label');
        item.className = 'widget-item' + (state.widgets.has(w.name) ? ' selected' : '');
        item.innerHTML = `
            <input type="checkbox" ${state.widgets.has(w.name) ? 'checked' : ''} />
            <div class="widget-meta">
                <div class="widget-name">${w.name}</div>
                <div class="widget-desc">${w.description || ''}</div>
            </div>
            <span class="widget-line">L${w.line ?? '?'}</span>
        `;
        item.querySelector('input').addEventListener('change', (e) => {
            if (e.target.checked) state.widgets.add(w.name);
            else state.widgets.delete(w.name);
            item.classList.toggle('selected', e.target.checked);
            schedulePreview();
        });
        list.appendChild(item);
    }
    wrap.appendChild(list);
    return wrap;
}

function renderLines() {
    const root = document.getElementById('lines-picker');
    root.innerHTML = '';
    for (const opt of manifest.lineOpts) {
        const label = document.createElement('label');
        label.innerHTML = `<input type="radio" name="lines" value="${opt}" ${state.lines === opt ? 'checked' : ''} /> ${opt}`;
        label.querySelector('input').addEventListener('change', () => {
            state.lines = opt;
            schedulePreview();
        });
        root.appendChild(label);
    }
}

function renderBarWidth() {
    const slider = document.getElementById('bar-width');
    const display = document.getElementById('bar-width-value');
    slider.value = state.barWidth;
    display.textContent = state.barWidth;
    slider.addEventListener('input', (e) => {
        state.barWidth = parseInt(e.target.value, 10);
        display.textContent = state.barWidth;
        schedulePreview();
    });
}

function wireButtons() {
    document.getElementById('btn-apply').addEventListener('click', onApply);
    document.getElementById('btn-cancel').addEventListener('click', onCancel);
}

// ----------------------------------------------------------------------------
// Preview pipeline (debounced)
// ----------------------------------------------------------------------------
function schedulePreview(delay = 220) {
    if (previewTimer) clearTimeout(previewTimer);
    previewTimer = setTimeout(runPreview, delay);
}

async function runPreview() {
    setStatus('rendering', 'busy');
    const body = {
        variant: state.variant,
        widgets: Array.from(state.widgets),
        palette: state.palette,
        barWidth: state.barWidth,
        lines: state.lines,
    };
    try {
        const res = await fetch('/api/preview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
        });
        const json = await res.json();
        renderPreview(json.html || '<pre class="statusline error">Empty preview</pre>');
        setStatus('idle', 'ok');
    } catch (err) {
        renderPreview('<pre class="statusline error">' + escapeHtml(String(err)) + '</pre>');
        setStatus('preview error', 'err');
    }
}

function renderPreview(html) {
    document.getElementById('preview-area').innerHTML = html;
}

// ----------------------------------------------------------------------------
// Apply / Cancel
// ----------------------------------------------------------------------------
async function onApply() {
    if (!confirm('Write this configuration to ~/.claude/ and patch settings.json?\n\nYour previous statusline will be backed up.')) {
        return;
    }
    setStatus('applying', 'busy');
    const body = {
        variant: state.variant,
        widgets: Array.from(state.widgets),
        palette: state.palette,
        barWidth: state.barWidth,
        lines: state.lines,
    };
    try {
        const res = await fetch('/api/apply', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body),
        });
        const json = await res.json();
        if (json.ok) {
            setStatus('applied — restart Claude Code', 'ok');
            renderPreview('<pre class="statusline">' + escapeHtml(json.output || 'Done.') + '</pre>');
            setTimeout(shutdown, 1500);
        } else {
            setStatus('apply failed', 'err');
            renderPreview('<pre class="statusline error">' + escapeHtml(json.output || 'Unknown error') + '</pre>');
        }
    } catch (err) {
        setStatus('apply error', 'err');
        renderPreview('<pre class="statusline error">' + escapeHtml(String(err)) + '</pre>');
    }
}

async function onCancel() {
    if (!confirm('Close the customizer without applying?')) return;
    await shutdown();
}

async function shutdown() {
    try {
        await fetch('/api/shutdown', { method: 'POST' });
    } catch {}
    document.body.innerHTML = '<div style="padding:40px;text-align:center;font-family:sans-serif;color:#b8bcc7;">Customizer closed. You can close this tab.</div>';
}

// ----------------------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------------------
function setStatus(text, kind) {
    const pill = document.getElementById('status-pill');
    pill.textContent = text;
    pill.className = 'status-pill ' + (kind || 'idle');
}

function escapeHtml(s) {
    return String(s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

init();
