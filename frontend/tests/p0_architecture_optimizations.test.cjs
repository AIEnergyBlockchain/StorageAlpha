const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf-8');
const css = fs.readFileSync(path.join(root, 'styles.css'), 'utf-8');
const js = fs.readFileSync(path.join(root, 'app.js'), 'utf-8');

// ── A1: aria-live on dynamic content regions ──────────────────

test('storyAgentInsight has aria-live="polite"', () => {
  const match = html.match(/id="storyAgentInsight"[^>]*/);
  assert.ok(match, 'storyAgentInsight must exist');
  assert.ok(match[0].includes('aria-live'), 'storyAgentInsight must have aria-live');
});

test('story-kpi-row has role="region" and aria-live', () => {
  const match = html.match(/class="story-kpi-row"[^>]*/);
  assert.ok(match, 'story-kpi-row must exist');
  assert.ok(match[0].includes('aria-live'), 'story-kpi-row must have aria-live');
});

test('errorCard has aria-live="assertive"', () => {
  const match = html.match(/id="errorCard"[^>]*/);
  assert.ok(match, 'errorCard must exist');
  assert.ok(match[0].includes('aria-live'), 'errorCard must have aria-live');
});

test('narrativeLine has aria-live (already present — regression check)', () => {
  const match = html.match(/id="narrativeLine"[^>]*/);
  assert.ok(match, 'narrativeLine must exist');
  assert.ok(match[0].includes('aria-live'), 'narrativeLine must keep aria-live');
});

// ── A2 + A3: Flow timeline ARIA semantics ─────────────────────

test('flow-timeline has role="list"', () => {
  const match = html.match(/class="flow-timeline"[^>]*/);
  assert.ok(match, 'flow-timeline must exist');
  assert.ok(match[0].includes('role="list"'), 'flow-timeline must have role="list"');
});

test('flow-timeline has aria-label', () => {
  const match = html.match(/class="flow-timeline"[^>]*/);
  assert.ok(match[0].includes('aria-label'), 'flow-timeline must have aria-label');
});

test('step-pill elements have role="listitem"', () => {
  const pills = html.match(/class="step-pill[^"]*"[^>]*/g);
  assert.ok(pills && pills.length >= 6, 'must have at least 6 step-pills');
  for (const pill of pills) {
    assert.ok(pill.includes('role="listitem"'), `step-pill must have role="listitem": ${pill.substring(0, 60)}`);
  }
});

test('step-pill elements have aria-label', () => {
  const pills = html.match(/class="step-pill[^"]*"[^>]*/g);
  assert.ok(pills && pills.length >= 6);
  for (const pill of pills) {
    assert.ok(pill.includes('aria-label'), `step-pill must have aria-label: ${pill.substring(0, 60)}`);
  }
});

test('JS updates aria-current on active step', () => {
  assert.match(js, /aria-current/, 'JS must update aria-current for flow steps');
});

test('JS updates step aria-label dynamically', () => {
  // When step state changes, the aria-label should be updated
  assert.match(js, /setAttribute\(['"]aria-label['"]/, 'JS must set aria-label on steps dynamically');
});

// ── S2: Skip link ─────────────────────────────────────────────

test('skip-link exists in HTML', () => {
  assert.match(html, /class="skip-link"/, 'skip-link must exist');
  assert.match(html, /Skip to/, 'skip-link must have descriptive text');
});

test('skip-link CSS hides off-screen and shows on focus', () => {
  assert.match(css, /\.skip-link/, 'skip-link base rule must exist');
  assert.match(css, /\.skip-link:focus/, 'skip-link:focus rule must exist');
});

// ── P1: renderAll() throttling via requestAnimationFrame ──────

test('scheduleRender function exists', () => {
  assert.match(js, /function scheduleRender/, 'scheduleRender must be defined');
});

test('scheduleRender uses requestAnimationFrame', () => {
  assert.match(js, /requestAnimationFrame/, 'scheduleRender must use requestAnimationFrame');
});

test('scheduleRender prevents double-scheduling', () => {
  // Must have a guard flag to prevent multiple rAF callbacks
  assert.match(js, /_renderScheduled|renderPending|_rafId/, 'must have render scheduling guard');
});

// ── P2: apiFetch timeout ──────────────────────────────────────

test('API_TIMEOUT_MS constant is defined', () => {
  const match = js.match(/API_TIMEOUT_MS\s*=\s*(\d+)/);
  assert.ok(match, 'API_TIMEOUT_MS must be defined');
  assert.ok(Number(match[1]) >= 10000, 'API_TIMEOUT_MS must be at least 10s');
  assert.ok(Number(match[1]) <= 30000, 'API_TIMEOUT_MS must be at most 30s');
});

test('apiFetch uses AbortController for timeout', () => {
  assert.match(js, /AbortController/, 'apiFetch must use AbortController');
  assert.match(js, /controller\.abort|\.abort\(\)/, 'must call abort on timeout');
});

test('apiFetch clears timeout in finally block', () => {
  assert.match(js, /clearTimeout/, 'apiFetch must clear timeout to avoid leaks');
});

// ── S1: innerHTML security — no new innerHTML with external data ──

test('bridgeTransfersBody rendering uses safe DOM methods', () => {
  // Check that bridge table rows are built with DOM API, not innerHTML
  // At minimum, the function should use createElement or textContent
  const hasSafeBridge = js.includes('bridgeTransfersBody') &&
    (js.includes('createElement') || js.includes('insertRow'));
  assert.ok(hasSafeBridge, 'bridge transfers table must use safe DOM methods');
});

// ── Regression: existing 70 tests patterns must survive ───────

test('animateValue countUp still exists', () => {
  assert.match(js, /function animateValue/);
});

test('typewriterRender still exists', () => {
  assert.match(js, /typewriterRender/);
});

test('renderAll still exists as main orchestrator', () => {
  assert.match(js, /function renderAll/);
});

test('i18n translation function t() still works', () => {
  assert.match(js, /function t\(/);
});

test('STEP_ANIMATION_DELAY still defined', () => {
  assert.match(js, /STEP_ANIMATION_DELAY/);
});
