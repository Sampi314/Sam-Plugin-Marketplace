// ============================================================================
// app.js — Statusline Customizer SPA
// ============================================================================
//
// State:
//   state.variant       'Extended' | 'Classic'
//   state.palette       base palette name
//   state.customPalette {C_MODEL:'R G B', ...}  individual role overrides
//   state.widgets       Set<string> of enabled widget names
//   state.layout        {name: {line, position, priority, barWidth?}}  per-widget overrides
//   state.barWidth      Classic-variant single bar width
//   state.lines         Classic-variant line selector
//
// Persistence:
//   localStorage 'cs-web-customizer-v1' stores state.customPalette + state.layout + state.palette
//   so the user's tweaks survive a refresh.
// ============================================================================

const STORE_KEY = 'cs-web-customizer-v1';

// Roles shown in the custom-palette editor (the ones the override env vars accept)
const PALETTE_ROLES = [
    { key: 'C_MODEL',   label: 'model'   },
    { key: 'C_SKILL',   label: 'skill'   },
    { key: 'C_COST',    label: 'cost'    },
    { key: 'C_PROJCST', label: 'project' },
    { key: 'C_ADD',     label: 'added'   },
    { key: 'C_DEL',     label: 'removed' },
    { key: 'C_TIME',    label: 'time'    },
    { key: 'C_COUNT',   label: 'count'   },
    { key: 'C_CYAN',    label: 'cyan'    },
    { key: 'C_GOLD',    label: 'gold'    },
];

const BAR_WIDGETS = new Set(['core-ctx', 'core-rate-5h', 'core-rate-wk']);
const SPACER_WIDGETS = new Set(['spacer']);
const MAX_LINES = 9;
const POSITIONS = ['left', 'center', 'right'];

const state = {
    variant: 'Extended',
    palette: 'Sam',
    customPalette: {},         // role -> "R G B"
    widgets: new Set(),
    layout: {},                // name -> {line, position, priority, barWidth?}
    barWidth: 30,
    lines: 'all',
};

let manifest = null;
let previewTimer = null;
let dragInfo = null;           // {widgetName, sourceSlot}

// ----------------------------------------------------------------------------
// Widget grouping in the toggle list
// ----------------------------------------------------------------------------
const WIDGET_GROUPS = [
    { title: 'Core info',            names: ['core-header', 'core-ctx', 'core-work'] },
    { title: 'Rate limits',          names: ['core-rate-5h', 'core-rate-wk'] },
    { title: 'Sparklines & signals', names: ['sparkline-cost', 'sparkline-ctx', 'thinking', 'output-style', 'session-fingerprint'] },
    { title: 'Git & PRs',            names: ['git-status', 'pr-badge'] },
    { title: 'Clock & path',         names: ['clock', 'date', 'cwd', 'token-breakdown'] },
    { title: 'Custom text',          names: ['spacer'] },
    { title: 'Skill overlays',       names: ['skill-audit-general', 'skill-financial-modelling', 'skill-writing-tools'] },
];

function pickSwatchColors(palette) {
    return ['model', 'cost', 'added', 'removed'].map(k => palette.colors[k]);
}

// ----------------------------------------------------------------------------
// Boot
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

    // Default: all widgets enabled in their manifest-default positions
    for (const w of manifest.widgets) {
        if (w.name !== 'mode-aware') state.widgets.add(w.name);
        // Seed layout from manifest defaults so the board has a starting state
        state.layout[w.name] = {
            line: w.line || 1,
            position: w.position || 'left',
            priority: w.priority ?? 100,
        };
    }

    loadPersisted();      // overlay any saved customisations

    renderVariants();
    renderPalettes();
    renderCustomPaletteEditor();
    renderLayout();
    renderWidgets();
    renderLines();
    renderBarWidth();
    wireButtons();
    schedulePreview(0);
    setStatus('idle', 'idle');
}

// ----------------------------------------------------------------------------
// Persistence
// ----------------------------------------------------------------------------
function persist() {
    try {
        localStorage.setItem(STORE_KEY, JSON.stringify({
            palette: state.palette,
            customPalette: state.customPalette,
            layout: state.layout,
            widgets: Array.from(state.widgets),
            variant: state.variant,
            barWidth: state.barWidth,
            lines: state.lines,
        }));
    } catch {}
}

function loadPersisted() {
    try {
        const raw = localStorage.getItem(STORE_KEY);
        if (!raw) return;
        const saved = JSON.parse(raw);
        if (saved.variant)       state.variant       = saved.variant;
        if (saved.palette)       state.palette       = saved.palette;
        if (saved.customPalette) state.customPalette = saved.customPalette;
        if (saved.layout)        Object.assign(state.layout, saved.layout);   // merge, don't replace
        if (saved.widgets)       state.widgets       = new Set(saved.widgets);
        if (saved.barWidth)      state.barWidth      = saved.barWidth;
        if (saved.lines)         state.lines         = saved.lines;
    } catch {}
}

// ----------------------------------------------------------------------------
// Renderers
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
            persist();
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
        card.innerHTML = `
            <div class="palette-name">${p.name}</div>
            <div class="palette-swatch">${swatchColors.map(c => `<span style="background:${c}"></span>`).join('')}</div>
        `;
        card.addEventListener('click', () => {
            state.palette = p.name;
            // Switching base palette clears custom overrides — they were tied to the previous base
            state.customPalette = {};
            document.querySelectorAll('.palette-card').forEach(c => c.classList.remove('selected'));
            card.classList.add('selected');
            renderCustomPaletteEditor();
            updatePaletteModPill();
            persist();
            schedulePreview();
        });
        root.appendChild(card);
    }
}

function getBasePalette() {
    return manifest.palettes.find(p => p.name === state.palette) || manifest.palettes[0];
}

// Map role key (C_MODEL) -> the SPA-side colour name (model) used in palette manifest
function roleKeyToSpaKey(roleKey) {
    return {
        C_MODEL: 'model', C_SKILL: 'skill', C_COST: 'cost', C_PROJCST: 'project',
        C_ADD: 'added', C_DEL: 'removed', C_TIME: 'time', C_COUNT: 'count',
        C_CYAN: 'cyan', C_GOLD: 'gold',
    }[roleKey];
}

function effectiveRoleHex(roleKey) {
    if (state.customPalette[roleKey]) {
        return rgbTripleToHex(state.customPalette[roleKey]);
    }
    const base = getBasePalette();
    return base.colors[roleKeyToSpaKey(roleKey)] || '#ffffff';
}

function rgbTripleToHex(triple) {
    const parts = String(triple).trim().split(/\s+/).map(n => parseInt(n, 10));
    return '#' + parts.slice(0, 3).map(n => Math.max(0, Math.min(255, n)).toString(16).padStart(2, '0')).join('');
}

function hexToRgbTriple(hex) {
    const m = String(hex).match(/^#?([0-9a-f]{6})$/i);
    if (!m) return '255 255 255';
    const n = parseInt(m[1], 16);
    return `${(n >> 16) & 0xff} ${(n >> 8) & 0xff} ${n & 0xff}`;
}

function renderCustomPaletteEditor() {
    const root = document.getElementById('palette-editor');
    root.innerHTML = '';
    for (const role of PALETTE_ROLES) {
        const row = document.createElement('div');
        row.className = 'palette-role-row';
        const id = 'color-' + role.key;
        row.innerHTML = `
            <input type="color" id="${id}" value="${effectiveRoleHex(role.key)}" />
            <label for="${id}">${role.label}</label>
        `;
        row.querySelector('input').addEventListener('input', (e) => {
            state.customPalette[role.key] = hexToRgbTriple(e.target.value);
            updatePaletteModPill();
            persist();
            schedulePreview();
        });
        root.appendChild(row);
    }
    updatePaletteModPill();
}

function updatePaletteModPill() {
    const pill = document.getElementById('palette-mod-pill');
    pill.style.display = Object.keys(state.customPalette).length > 0 ? '' : 'none';
}

// ----------------------------------------------------------------------------
// Layout board with drag-drop
// ----------------------------------------------------------------------------
function renderLayout() {
    const board = document.getElementById('layout-board');
    board.innerHTML = '';

    // Bucket enabled widgets by line + position
    const buckets = {};   // 'L{n}-{pos}' -> [{name, ...}]
    for (const name of state.widgets) {
        const w = manifest.widgets.find(m => m.name === name);
        if (!w) continue;
        const ov = state.layout[name] || {};
        const line = ov.line ?? w.line ?? 1;
        const position = ov.position ?? w.position ?? 'left';
        const priority = ov.priority ?? w.priority ?? 100;
        const key = `L${line}-${position}`;
        (buckets[key] = buckets[key] || []).push({ name, line, position, priority });
    }
    // Sort each bucket by priority
    for (const key of Object.keys(buckets)) {
        buckets[key].sort((a, b) => a.priority - b.priority);
    }

    // Draw rows for lines 1..MAX_LINES with three slots each (left | center | right)
    for (let line = 1; line <= MAX_LINES; line++) {
        const row = document.createElement('div');
        row.className = 'layout-line-row';
        row.innerHTML = `<div class="layout-line-label">L${line}</div>`;
        for (const pos of POSITIONS) {
            row.appendChild(makeSlot(line, pos, buckets[`L${line}-${pos}`] || []));
        }
        board.appendChild(row);
    }
}

function makeSlot(line, position, items) {
    const slot = document.createElement('div');
    slot.className = 'layout-slot' + (items.length === 0 ? ' empty' : '');
    slot.dataset.line = line;
    slot.dataset.position = position;
    slot.dataset.emptyLabel = `L${line} · ${position}`;

    for (const item of items) {
        slot.appendChild(makeChip(item.name));
    }

    slot.addEventListener('dragover', (e) => {
        if (!dragInfo) return;
        e.preventDefault();
        slot.classList.add('dragover-active');
    });
    slot.addEventListener('dragleave', () => {
        slot.classList.remove('dragover-active');
    });
    slot.addEventListener('drop', (e) => {
        e.preventDefault();
        slot.classList.remove('dragover-active');
        if (!dragInfo) return;
        const name = dragInfo.widgetName;
        if (!name) return;
        const ov = state.layout[name] || {};
        ov.line = line;
        ov.position = position;
        // Drop at end -> priority = max+10 within new slot, so it sits last
        const others = Array.from(state.widgets)
            .filter(n => n !== name && (state.layout[n]?.line === line) && (state.layout[n]?.position === position))
            .map(n => state.layout[n].priority ?? 100);
        ov.priority = (others.length ? Math.max(...others) : 0) + 10;
        state.layout[name] = ov;
        persist();
        renderLayout();
        schedulePreview();
    });

    return slot;
}

function makeChip(widgetName) {
    const chip = document.createElement('div');
    const isBar = BAR_WIDGETS.has(widgetName);
    const isSpacer = SPACER_WIDGETS.has(widgetName);
    chip.className = 'layout-chip' + (isBar ? ' bar-chip' : '') + (isSpacer ? ' spacer-chip' : '');
    chip.draggable = true;
    chip.dataset.widget = widgetName;
    const ov = state.layout[widgetName] || {};

    let chipHtml = `<span class="chip-drag-handle" aria-hidden="true">⋮⋮</span><span class="chip-name">${widgetName}</span>`;
    if (isBar) {
        const barWidth = ov.barWidth ?? 24;
        chipHtml += `<input type="range" class="chip-bar-slider" min="6" max="50" step="1" value="${barWidth}" title="Bar width" />`;
        chipHtml += `<span class="chip-bar-val">${barWidth}</span>`;
    } else if (isSpacer) {
        const text = ov.text ?? '|';
        const color = ov.color ?? '#888888';
        chipHtml += `<input type="text" class="chip-spacer-text" maxlength="32" value="${escapeAttr(text)}" title="Text" />`;
        chipHtml += `<input type="color" class="chip-spacer-color" value="${color}" title="Colour" />`;
    }
    chip.innerHTML = chipHtml;

    chip.addEventListener('dragstart', (e) => {
        dragInfo = { widgetName };
        chip.classList.add('dragging');
        try { e.dataTransfer.setData('text/plain', widgetName); } catch {}
        e.dataTransfer.effectAllowed = 'move';
    });
    chip.addEventListener('dragend', () => {
        chip.classList.remove('dragging');
        document.querySelectorAll('.layout-slot.dragover-active').forEach(s => s.classList.remove('dragover-active'));
        dragInfo = null;
    });

    // Bar slider — drag stop + state update
    const slider = chip.querySelector('.chip-bar-slider');
    if (slider) {
        const valEl = chip.querySelector('.chip-bar-val');
        slider.addEventListener('input', (e) => {
            const v = parseInt(e.target.value, 10);
            valEl.textContent = v;
            const o = state.layout[widgetName] || {};
            o.barWidth = v;
            state.layout[widgetName] = o;
            persist();
            schedulePreview();
        });
        slider.addEventListener('mousedown', (e) => e.stopPropagation());
        slider.addEventListener('pointerdown', (e) => e.stopPropagation());
    }

    // Spacer text + colour — also stop drag so the inputs are usable
    const textInput = chip.querySelector('.chip-spacer-text');
    const colorInput = chip.querySelector('.chip-spacer-color');
    if (textInput) {
        textInput.addEventListener('input', (e) => {
            const o = state.layout[widgetName] || {};
            o.text = e.target.value;
            state.layout[widgetName] = o;
            persist();
            schedulePreview();
        });
        textInput.addEventListener('mousedown', (e) => e.stopPropagation());
        textInput.addEventListener('pointerdown', (e) => e.stopPropagation());
        textInput.addEventListener('dragstart', (e) => { e.stopPropagation(); e.preventDefault(); });
        // Prevent the chip drag from catching text-input drags entirely
        textInput.parentElement.addEventListener('dragstart', (e) => {
            if (e.target === textInput) e.preventDefault();
        });
    }
    if (colorInput) {
        colorInput.addEventListener('input', (e) => {
            const o = state.layout[widgetName] || {};
            o.color = e.target.value;
            state.layout[widgetName] = o;
            persist();
            schedulePreview();
        });
        colorInput.addEventListener('mousedown', (e) => e.stopPropagation());
        colorInput.addEventListener('pointerdown', (e) => e.stopPropagation());
    }

    return chip;
}

function escapeAttr(s) {
    return String(s).replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ----------------------------------------------------------------------------
// Widget toggles
// ----------------------------------------------------------------------------
function renderWidgets() {
    const root = document.getElementById('widget-groups');
    root.innerHTML = '';
    const allWidgets = manifest.widgets.filter(w => w.name !== 'mode-aware');
    const seen = new Set();
    for (const group of WIDGET_GROUPS) {
        const groupWidgets = group.names.map(n => allWidgets.find(w => w.name === n)).filter(Boolean);
        if (!groupWidgets.length) continue;
        groupWidgets.forEach(w => seen.add(w.name));
        root.appendChild(renderWidgetGroup(group.title, groupWidgets));
    }
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
            persist();
            renderLayout();
            schedulePreview();
        });
        list.appendChild(item);
    }
    wrap.appendChild(list);
    return wrap;
}

// ----------------------------------------------------------------------------
// Bar width (Classic) and Lines
// ----------------------------------------------------------------------------
function renderLines() {
    const root = document.getElementById('lines-picker');
    root.innerHTML = '';
    for (const opt of manifest.lineOpts) {
        const label = document.createElement('label');
        label.innerHTML = `<input type="radio" name="lines" value="${opt}" ${state.lines === opt ? 'checked' : ''} /> ${opt}`;
        label.querySelector('input').addEventListener('change', () => {
            state.lines = opt;
            persist();
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
        persist();
        schedulePreview();
    });
}

function wireButtons() {
    document.getElementById('btn-apply').addEventListener('click', onApply);
    document.getElementById('btn-cancel').addEventListener('click', onCancel);
    document.getElementById('btn-reset').addEventListener('click', onReset);
    document.getElementById('btn-palette-reset').addEventListener('click', onPaletteReset);
}

// ----------------------------------------------------------------------------
// Preview pipeline
// ----------------------------------------------------------------------------
function schedulePreview(delay = 180) {
    if (previewTimer) clearTimeout(previewTimer);
    previewTimer = setTimeout(runPreview, delay);
}

function buildBody() {
    // Layout: send the full per-widget override hash. The server forwards
    // every field through to $env:CS_LAYOUT_OVERRIDE, and the bundled script
    // copies non-reserved fields (anything but line/position/priority) into
    // the widget's $state — so this carries barWidth, text, color, format,
    // maxLen, etc. without per-field plumbing.
    const layoutPayload = {};
    for (const name of state.widgets) {
        const ov = state.layout[name];
        if (!ov) continue;
        layoutPayload[name] = { ...ov };
    }
    return {
        variant: state.variant,
        widgets: Array.from(state.widgets),
        palette: state.palette,
        barWidth: state.barWidth,
        lines: state.lines,
        layout: layoutPayload,
        customPalette: Object.keys(state.customPalette).length ? state.customPalette : null,
    };
}

async function runPreview() {
    setStatus('rendering', 'busy');
    try {
        const res = await fetch('/api/preview', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(buildBody()),
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
// Buttons
// ----------------------------------------------------------------------------
async function onApply() {
    if (!confirm('Write this configuration to ~/.claude/ and patch settings.json?\n\nYour previous statusline will be backed up.')) {
        return;
    }
    setStatus('applying', 'busy');
    try {
        const res = await fetch('/api/apply', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(buildBody()),
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

function onReset() {
    if (!confirm('Reset layout AND custom palette to defaults? Toggles and variant are kept.')) return;
    state.customPalette = {};
    state.layout = {};
    for (const w of manifest.widgets) {
        state.layout[w.name] = {
            line: w.line || 1,
            position: w.position || 'left',
            priority: w.priority ?? 100,
        };
    }
    persist();
    renderCustomPaletteEditor();
    renderLayout();
    schedulePreview();
}

function onPaletteReset() {
    state.customPalette = {};
    renderCustomPaletteEditor();
    persist();
    schedulePreview();
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
