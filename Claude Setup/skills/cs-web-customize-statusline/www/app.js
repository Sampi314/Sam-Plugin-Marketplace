// ============================================================================
// app.js — Statusline Customizer SPA (instance model)
// ============================================================================
//
// State:
//   state.variant        'Extended' | 'Classic'
//   state.palette        base palette name
//   state.customPalette  {C_MODEL:'R G B', ...} role overrides
//   state.instances      Array<{
//                            id,        unique chip id (name + '#' + n)
//                            name,      base widget name
//                            line,      1..MAX_LINES
//                            position,  'left' | 'center' | 'right'
//                            priority,  number; lower renders first within a slot
//                            barWidth?, for core-ctx/rate-5h/rate-wk
//                            text?,     for spacer
//                            color?,    for spacer
//                            format?,   for date
//                            maxLen?,   for cwd
//                            ...any other widget state field
//                          }>
//   state.barWidth       global Classic bar width
//   state.lines          Classic line selector
//
// Each chip in the layout board is one instance. Multiple instances can share
// the same `name` — that's how duplication works. Toggling a widget OFF
// removes every instance of that name; toggling ON re-creates one instance
// with the manifest defaults. The "+ Add another" link on a widget toggle
// makes a second instance.
// ============================================================================

const STORE_KEY = 'cs-web-customizer-v2';   // bumped from v1 (instance model)

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

const BAR_WIDGETS    = new Set(['core-ctx', 'core-rate-5h', 'core-rate-wk']);
const SPACER_WIDGETS = new Set(['spacer']);
const MAX_LINES = 9;
const MAX_COLUMNS = 12;

const state = {
    variant: 'Extended',
    palette: 'Sam',
    customPalette: {},
    instances: [],
    columns: 3,            // global column count (all lines share K)
    barWidth: 30,
    lines: 'all',
};

// Legacy position string -> column index when K=3 (backward-compat shim for
// loaded instances that pre-date the column model).
function positionToColumn(pos, K) {
    K = K || 3;
    switch (pos) {
        case 'left':   return 1;
        case 'center': return Math.ceil(K / 2);
        case 'right':  return K;
        default:       return 1;
    }
}

let manifest = null;
let previewTimer = null;
let dragInfo = null;

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

function widgetDef(name) {
    return manifest.widgets.find(w => w.name === name);
}

function instancesOf(name) {
    return state.instances.filter(i => i.name === name);
}

function nextInstanceId(name) {
    const existing = instancesOf(name).map(i => parseInt(i.id.split('#')[1] || '0', 10));
    const max = existing.length ? Math.max(...existing) : 0;
    return `${name}#${max + 1}`;
}

function makeInstance(name) {
    const def = widgetDef(name);
    if (!def) return null;
    const inst = {
        id: nextInstanceId(name),
        name,
        line: def.line || 1,
        column: positionToColumn(def.position || 'left', state.columns),
        priority: def.priority ?? 100,
    };
    if (SPACER_WIDGETS.has(name)) {
        inst.text = '|';
        inst.color = '#888888';
    }
    return inst;
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

    // Defaults: one instance per non-overlay widget at its manifest defaults
    for (const w of manifest.widgets) {
        if (w.name === 'mode-aware') continue;
        state.instances.push({
            id: `${w.name}#1`,
            name: w.name,
            line: w.line || 1,
            column: positionToColumn(w.position || 'left', state.columns),
            priority: w.priority ?? 100,
        });
    }

    loadPersisted();
    migratePositionsToColumns();

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
            variant: state.variant,
            palette: state.palette,
            customPalette: state.customPalette,
            instances: state.instances,
            columns: state.columns,
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
        if (Array.isArray(saved.instances)) state.instances = saved.instances;
        if (saved.columns)       state.columns       = saved.columns;
        if (saved.barWidth)      state.barWidth      = saved.barWidth;
        if (saved.lines)         state.lines         = saved.lines;
    } catch {}
}

function migratePositionsToColumns() {
    // Pre-column instances may have `position: 'left'|'center'|'right'` but no
    // `column`. Convert and drop the legacy field.
    let migrated = 0;
    for (const inst of state.instances) {
        if (inst.column == null && inst.position) {
            inst.column = positionToColumn(inst.position, state.columns);
            delete inst.position;
            migrated++;
        }
    }
    if (migrated) persist();
}

// ----------------------------------------------------------------------------
// Variants / palettes / custom palette
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

function roleKeyToSpaKey(roleKey) {
    return {
        C_MODEL: 'model', C_SKILL: 'skill', C_COST: 'cost', C_PROJCST: 'project',
        C_ADD: 'added', C_DEL: 'removed', C_TIME: 'time', C_COUNT: 'count',
        C_CYAN: 'cyan', C_GOLD: 'gold',
    }[roleKey];
}

function effectiveRoleHex(roleKey) {
    if (state.customPalette[roleKey]) return rgbTripleToHex(state.customPalette[roleKey]);
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
// Layout board (instance-aware)
// ----------------------------------------------------------------------------
function renderLayout() {
    const board = document.getElementById('layout-board');
    board.innerHTML = '';
    const K = state.columns;
    // Set the row's grid template based on K
    board.style.setProperty('--col-count', K);
    // Bucket instances by (line, column)
    const buckets = {};
    for (const inst of state.instances) {
        const col = inst.column ?? 1;
        const key = `L${inst.line}-C${col}`;
        (buckets[key] = buckets[key] || []).push(inst);
    }
    for (const key of Object.keys(buckets)) {
        buckets[key].sort((a, b) => (a.priority ?? 100) - (b.priority ?? 100));
    }
    for (let line = 1; line <= MAX_LINES; line++) {
        const row = document.createElement('div');
        row.className = 'layout-line-row';
        row.style.setProperty('--col-count', K);
        row.innerHTML = `<div class="layout-line-label">L${line}</div>`;
        for (let col = 1; col <= K; col++) {
            row.appendChild(makeSlot(line, col, buckets[`L${line}-C${col}`] || []));
        }
        board.appendChild(row);
    }
}

function makeSlot(line, column, items) {
    const slot = document.createElement('div');
    slot.className = 'layout-slot' + (items.length === 0 ? ' empty' : '');
    slot.dataset.line = line;
    slot.dataset.column = column;
    slot.dataset.emptyLabel = `L${line} · C${column}`;

    for (const inst of items) slot.appendChild(makeChip(inst));

    slot.addEventListener('dragover', (e) => {
        if (!dragInfo) return;
        e.preventDefault();
        slot.classList.add('dragover-active');
    });
    slot.addEventListener('dragleave', () => slot.classList.remove('dragover-active'));
    slot.addEventListener('drop', (e) => {
        e.preventDefault();
        slot.classList.remove('dragover-active');
        if (!dragInfo) return;
        const inst = state.instances.find(i => i.id === dragInfo.instanceId);
        if (!inst) return;
        inst.line = line;
        inst.column = column;
        const peers = state.instances.filter(o => o !== inst && o.line === line && (o.column ?? 1) === column).map(o => o.priority ?? 100);
        inst.priority = (peers.length ? Math.max(...peers) : 0) + 10;
        persist();
        renderLayout();
        schedulePreview();
    });

    return slot;
}

function makeChip(inst) {
    const chip = document.createElement('div');
    const isBar    = BAR_WIDGETS.has(inst.name);
    const isSpacer = SPACER_WIDGETS.has(inst.name);
    chip.className = 'layout-chip' + (isBar ? ' bar-chip' : '') + (isSpacer ? ' spacer-chip' : '');
    chip.draggable = true;
    chip.dataset.instanceId = inst.id;

    const dupCount = instancesOf(inst.name).length;
    const idTag = dupCount > 1 ? `<span class="chip-id">#${inst.id.split('#')[1]}</span>` : '';
    let chipHtml = `<span class="chip-drag-handle" aria-hidden="true">⋮⋮</span><span class="chip-name">${inst.name}</span>${idTag}`;

    if (isBar) {
        const barWidth = inst.barWidth ?? 24;
        chipHtml += `<input type="range" class="chip-bar-slider" min="6" max="50" step="1" value="${barWidth}" title="Bar width" />`;
        chipHtml += `<span class="chip-bar-val">${barWidth}</span>`;
    } else if (isSpacer) {
        const text  = inst.text  ?? '|';
        const color = inst.color ?? '#888888';
        chipHtml += `<input type="text" class="chip-spacer-text" maxlength="32" value="${escapeAttr(text)}" title="Text" />`;
        chipHtml += `<input type="color" class="chip-spacer-color" value="${color}" title="Colour" />`;
    }
    chipHtml += `<button class="chip-close" title="Remove this instance" aria-label="Remove">×</button>`;
    chip.innerHTML = chipHtml;

    chip.addEventListener('dragstart', (e) => {
        dragInfo = { instanceId: inst.id };
        chip.classList.add('dragging');
        try { e.dataTransfer.setData('text/plain', inst.id); } catch {}
        e.dataTransfer.effectAllowed = 'move';
    });
    chip.addEventListener('dragend', () => {
        chip.classList.remove('dragging');
        document.querySelectorAll('.layout-slot.dragover-active').forEach(s => s.classList.remove('dragover-active'));
        dragInfo = null;
    });

    // Bar slider
    const slider = chip.querySelector('.chip-bar-slider');
    if (slider) {
        const valEl = chip.querySelector('.chip-bar-val');
        slider.addEventListener('input', (e) => {
            inst.barWidth = parseInt(e.target.value, 10);
            valEl.textContent = inst.barWidth;
            persist();
            schedulePreview();
        });
        slider.addEventListener('mousedown',   (e) => e.stopPropagation());
        slider.addEventListener('pointerdown', (e) => e.stopPropagation());
    }

    // Spacer text + colour
    const textInput  = chip.querySelector('.chip-spacer-text');
    const colorInput = chip.querySelector('.chip-spacer-color');
    if (textInput) {
        textInput.addEventListener('input', (e) => {
            inst.text = e.target.value;
            persist();
            schedulePreview();
        });
        textInput.addEventListener('mousedown',   (e) => e.stopPropagation());
        textInput.addEventListener('pointerdown', (e) => e.stopPropagation());
        textInput.addEventListener('dragstart',   (e) => { e.stopPropagation(); e.preventDefault(); });
    }
    if (colorInput) {
        colorInput.addEventListener('input', (e) => {
            inst.color = e.target.value;
            persist();
            schedulePreview();
        });
        colorInput.addEventListener('mousedown',   (e) => e.stopPropagation());
        colorInput.addEventListener('pointerdown', (e) => e.stopPropagation());
    }

    // Remove × button
    const closeBtn = chip.querySelector('.chip-close');
    closeBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        const idx = state.instances.findIndex(i => i.id === inst.id);
        if (idx >= 0) state.instances.splice(idx, 1);
        persist();
        renderLayout();
        renderWidgets();
        schedulePreview();
    });
    closeBtn.addEventListener('mousedown',   (e) => e.stopPropagation());
    closeBtn.addEventListener('pointerdown', (e) => e.stopPropagation());
    closeBtn.addEventListener('dragstart',   (e) => { e.stopPropagation(); e.preventDefault(); });

    return chip;
}

// ----------------------------------------------------------------------------
// Widget toggles + duplicate button
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
        const count = instancesOf(w.name).length;
        const isOn = count > 0;
        const item = document.createElement('div');
        item.className = 'widget-item' + (isOn ? ' selected' : '');
        item.innerHTML = `
            <label class="widget-item-toggle">
                <input type="checkbox" ${isOn ? 'checked' : ''} />
                <div class="widget-meta">
                    <div class="widget-name">${w.name}${count > 1 ? ` <span class="widget-count">× ${count}</span>` : ''}</div>
                    <div class="widget-desc">${w.description || ''}</div>
                </div>
                <span class="widget-line">L${w.line ?? '?'}</span>
            </label>
            <button class="widget-add" title="Add another instance" ${isOn ? '' : 'disabled'}>+ duplicate</button>
        `;
        const checkbox = item.querySelector('input[type=checkbox]');
        checkbox.addEventListener('change', (e) => {
            if (e.target.checked) {
                const inst = makeInstance(w.name);
                if (inst) state.instances.push(inst);
            } else {
                state.instances = state.instances.filter(i => i.name !== w.name);
            }
            persist();
            renderLayout();
            renderWidgets();
            schedulePreview();
        });
        const addBtn = item.querySelector('.widget-add');
        addBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            const inst = makeInstance(w.name);
            if (inst) state.instances.push(inst);
            persist();
            renderLayout();
            renderWidgets();
            schedulePreview();
        });
        list.appendChild(item);
    }
    wrap.appendChild(list);
    return wrap;
}

// ----------------------------------------------------------------------------
// Classic options
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

    // Columns slider
    const colSlider = document.getElementById('columns-slider');
    const colValue  = document.getElementById('columns-value');
    colSlider.value = state.columns;
    colValue.textContent = state.columns;
    colSlider.addEventListener('input', (e) => {
        const k = parseInt(e.target.value, 10);
        state.columns = k;
        colValue.textContent = k;
        // Re-clamp every instance's column to the new K
        for (const inst of state.instances) {
            if (inst.column == null) inst.column = 1;
            if (inst.column > k) inst.column = k;
            if (inst.column < 1) inst.column = 1;
        }
        persist();
        renderLayout();
        schedulePreview();
    });
}

// ----------------------------------------------------------------------------
// Preview pipeline
// ----------------------------------------------------------------------------
function schedulePreview(delay = 180) {
    if (previewTimer) clearTimeout(previewTimer);
    previewTimer = setTimeout(runPreview, delay);
}

function buildBody() {
    return {
        variant: state.variant,
        instances: state.instances.map(i => ({ ...i })),
        palette: state.palette,
        columns: state.columns,
        barWidth: state.barWidth,
        lines: state.lines,
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
    if (!confirm('Reset everything (layout, custom palette, instances)? Variant kept.')) return;
    state.customPalette = {};
    state.instances = [];
    for (const w of manifest.widgets) {
        if (w.name === 'mode-aware') continue;
        state.instances.push({
            id: `${w.name}#1`,
            name: w.name,
            line: w.line || 1,
            position: w.position || 'left',
            priority: w.priority ?? 100,
        });
    }
    persist();
    renderCustomPaletteEditor();
    renderLayout();
    renderWidgets();
    schedulePreview();
}

function onPaletteReset() {
    state.customPalette = {};
    renderCustomPaletteEditor();
    persist();
    schedulePreview();
}

async function shutdown() {
    try { await fetch('/api/shutdown', { method: 'POST' }); } catch {}
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
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function escapeAttr(s) {
    return String(s).replace(/&/g,'&amp;').replace(/"/g,'&quot;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

init();
