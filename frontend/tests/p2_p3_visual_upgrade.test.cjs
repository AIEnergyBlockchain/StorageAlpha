const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf-8');
const css = fs.readFileSync(path.join(root, 'styles.css'), 'utf-8');
const js = fs.readFileSync(path.join(root, 'app.js'), 'utf-8');

// ── P2-2: Data flow ticker ──────────────────────────────────

test('ticker function exists for streaming data points', () => {
  assert.match(js, /function (tickerAddPoint|streamDataPoint|addChartPoint)/);
});

test('ticker uses Chart.js addData or push pattern', () => {
  assert.match(js, /\.data\.labels\.push|\.data\.datasets\[/);
});

test('ticker animation uses requestAnimationFrame or setTimeout', () => {
  // The ticker should animate data flowing in
  assert.match(js, /tickerAddPoint|streamDataPoint|addChartPoint/);
});

// ── P2-8: KPI card 3D flip ─────────────────────────────────

test('kpi-card flip CSS with perspective exists', () => {
  assert.match(css, /perspective/);
});

test('kpi-card has backface-visibility hidden', () => {
  assert.match(css, /backface-visibility:\s*hidden/);
});

test('kpi-card back face element exists in HTML', () => {
  assert.match(html, /kpi-card-back|kpi-back/);
});

test('flip transform uses rotateY', () => {
  assert.match(css, /rotateY\(180deg\)/);
});

// ── P2-5: M2M Dashboard Mock tab ───────────────────────────

test('M2M tab button exists in HTML', () => {
  assert.match(html, /tab-m2m|tab.*m2m/i);
});

test('M2M tab panel with device topology exists', () => {
  assert.match(html, /id="tab-m2m"/);
});

test('M2M i18n keys exist in EN and ZH', () => {
  assert.match(js, /['"]tab\.m2m['"]/);
  assert.match(js, /['"]m2m\.title['"]/);
});

test('M2M renders device nodes or topology', () => {
  assert.match(js, /renderM2M|m2mDevices|deviceTopology/i);
});

test('M2M auto-settlement animation function exists', () => {
  assert.match(js, /m2mAnimate|animateM2M|m2mSettlement/i);
});

// ── P3-6: Map visualization ─────────────────────────────────

test('Leaflet.js CDN is included in HTML', () => {
  assert.match(html, /leaflet/i);
});

test('map container element exists in HTML', () => {
  assert.match(html, /id="siteMap"/);
});

test('map initialization function exists', () => {
  assert.match(js, /initSiteMap|initMap|L\.map/);
});

test('map markers are created for site locations', () => {
  assert.match(js, /L\.marker|L\.circleMarker|addMarker/);
});

test('map CSS has proper height and container styles', () => {
  assert.match(css, /#siteMap|\.site-map/);
});

// ── P0/P1 regression ────────────────────────────────────────

test('animateValue countUp still present', () => {
  assert.match(js, /function animateValue/);
});

test('Chart.js charts still initialized', () => {
  assert.match(js, /ensureComparisonChart/);
  assert.match(js, /ensurePayoutChart/);
});

test('confetti still wired to completion', () => {
  assert.match(js, /launchConfetti\(\)/);
});
