# PWA Testing Strategy

**For:** Patrick Huston
**Purpose:** Ensure the app works correctly as an installed PWA on iOS/Android
**Created:** 2026-01-16

---

## Why PWA Testing is Different

Flutter unit tests run in a Dart VM, not a real browser. PWA-specific issues only appear when:
- App is installed to home screen
- Running in standalone/fullscreen mode
- Using service workers for offline
- Handling iOS Safari quirks

These cannot be caught by `flutter test`.

---

## iOS PWA Known Issues

### 1. Splash Screen Blocking (FIXED)
**Problem:** `flutter-first-frame` event may not fire in iOS standalone mode
**Symptom:** App loads but is completely unresponsive
**Fix:** Added 5-second fallback timeout in `web/index.html`

### 2. Safe Area Insets
**Problem:** Notch/home indicator areas need special handling
**Test:** Check content isn't hidden behind notch or home bar
**Status:** Using `viewport-fit=cover` + Flutter's SafeArea widget

### 3. Touch Event Handling
**Problem:** CSS `pointer-events`, `touch-action` can block interaction
**Test:** All buttons/inputs respond to taps in standalone mode

### 4. Back Navigation
**Problem:** No browser back button in standalone mode
**Test:** In-app navigation works, can return from all screens

### 5. Service Worker Caching
**Problem:** Old version served after deploy
**Test:** Force refresh gets new version
**Workaround:** Update banner shows when new version available

### 6. IndexedDB/Storage
**Problem:** Different storage limits in standalone vs browser
**Test:** Data persists after closing/reopening app

---

## Manual PWA Test Checklist

Run this checklist after any web deploy:

### Installation
- [ ] Safari: Share > Add to Home Screen works
- [ ] Icon appears correctly on home screen
- [ ] App name shows correctly

### Launch & Splash
- [ ] App opens in fullscreen (no Safari UI)
- [ ] Splash screen shows briefly
- [ ] Splash screen dismisses (within 5 seconds max)
- [ ] App becomes interactive

### Core Functionality
- [ ] Can tap login button
- [ ] Login flow completes
- [ ] Menu opens/closes
- [ ] Can navigate to all screens
- [ ] Can navigate back from all screens
- [ ] Data entry works (score plotting, etc.)

### Offline Mode
- [ ] Turn on airplane mode
- [ ] App still opens
- [ ] Can view existing data
- [ ] Can create new sessions (local)
- [ ] Changes sync when back online

### Update Flow
- [ ] Deploy new version
- [ ] Open app, see update banner
- [ ] Tap banner, app refreshes
- [ ] Running new version

---

## Automated PWA Testing (Future)

### Option 1: Playwright
Browser automation that can test PWA in standalone mode.

```javascript
// Example Playwright test
const { webkit } = require('playwright');

test('PWA loads and becomes interactive', async () => {
  const browser = await webkit.launch();
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 }, // iPhone 14
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)...'
  });

  const page = await context.newPage();
  await page.goto('https://archery-super.web.app');

  // Wait for splash to dismiss
  await page.waitForSelector('#loading-splash', { state: 'hidden', timeout: 10000 });

  // Check login button is clickable
  const loginButton = await page.waitForSelector('text=Login');
  await loginButton.click();

  // Verify navigation occurred
  await expect(page).toHaveURL(/login/);
});
```

### Option 2: BrowserStack/Sauce Labs
Real device testing in cloud. Can test actual iOS Safari PWA behavior.

### Option 3: Manual Test Protocol
Documented checklist (above) run before each release.

---

## Test Locations

| Test Type | Location | Runs |
|-----------|----------|------|
| Unit tests | `test/` | `flutter test` |
| Widget tests | `test/widgets/` | `flutter test` |
| Integration tests | `test/integration/` | `flutter test` |
| PWA manual tests | This document | Before release |
| PWA automated (future) | `test_pwa/` | Playwright |

---

## Quick Debug Steps

### App Unresponsive in PWA Mode
1. Open Safari > archery-super.web.app (in browser, not PWA)
2. Enable Web Inspector: Settings > Safari > Advanced > Web Inspector
3. Connect to Mac, open Safari > Develop > [device] > archery-super.web.app
4. Check Console for errors
5. Check Elements for overlays blocking content

### Stale Version
1. Delete PWA from home screen
2. Safari > Settings > Clear History and Website Data
3. Re-add to home screen

### Data Not Persisting
1. Check Safari > Settings > Privacy > Advanced > Website Data
2. Look for archery-super.web.app storage
3. Ensure sufficient storage available

---

## Release Checklist

Before announcing any web release:

1. [ ] `flutter build web --release`
2. [ ] Copy drift files to build/web
3. [ ] `firebase deploy --only hosting`
4. [ ] Test in Safari browser (quick sanity)
5. [ ] Delete old PWA, clear cache, reinstall
6. [ ] Run PWA manual test checklist (above)
7. [ ] Announce release

---

*Maintained by Claude Code. Created 2026-01-16.*
