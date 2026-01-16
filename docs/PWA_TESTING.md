# PWA Testing Strategy

**For:** Patrick Huston
**Purpose:** Ensure the app works correctly as an installed PWA on all platforms
**Created:** 2026-01-16

---

## Why PWA Testing is Different

Flutter unit tests run in a Dart VM, not a real browser. PWA-specific issues only appear when:
- App is installed to home screen/desktop
- Running in standalone/fullscreen mode
- Using service workers for offline
- Handling platform-specific browser quirks

These cannot be caught by `flutter test`.

---

## Platform-Specific Known Issues

### iOS Safari (iPhone/iPad)

| Issue | Problem | Fix/Status |
|-------|---------|------------|
| Splash blocking | `flutter-first-frame` may not fire | 5s fallback timeout added |
| Safe area insets | Notch/home bar coverage | `viewport-fit=cover` + SafeArea |
| Touch events | CSS can block interaction | Avoid `pointer-events: none` on body |
| Back navigation | No browser back button | In-app navigation required |
| Storage limits | 50MB quota in standalone | Monitor usage |
| Audio autoplay | Blocked until user interaction | Require tap to start audio |

### Android Chrome

| Issue | Problem | Fix/Status |
|-------|---------|------------|
| Install prompt | `beforeinstallprompt` timing | Captured and deferred |
| Splash screen | May flash white | Dark background set in manifest |
| Back button | Hardware back exits app | Handle via Navigator |
| Storage | More generous than iOS | Usually not an issue |
| Notifications | Requires permission | Not yet implemented |

### Desktop (Chrome/Edge/Firefox)

| Issue | Problem | Fix/Status |
|-------|---------|------------|
| Window size | Opens at default size | Set preferred in manifest |
| Keyboard nav | Tab order important | Focus management needed |
| Right-click | Context menu expectations | Default browser behavior |
| Multi-window | Can open multiple instances | `client_mode: navigate-existing` |

### Firefox (All platforms)

| Issue | Problem | Fix/Status |
|-------|---------|------------|
| PWA support | Limited/no install prompt | Works as regular web app |
| Service worker | Different caching behavior | Test offline separately |

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
