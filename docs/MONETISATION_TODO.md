# Monetisation To-Do List

Complete checklist for launching the subscription and payment system.

---

## Progress Summary

| Area | Status |
|------|--------|
| Stripe products | Done |
| Stripe webhook | Done |
| Code updated | Done |
| Firebase secrets | Done (locally) - needs Blaze plan to deploy |
| Firebase deploy | Blocked - needs Blaze plan upgrade |
| Bunny.net videos | Not started |
| Email migration | Not started |
| Email list system | Not started |

---

## 1. Stripe Dashboard Setup - DONE

### Products Created

- [x] **Competitor Subscription** (£2/month)
  - Price ID: `price_1SqztNRpdm3uvDfu5wcHwFum`

- [x] **Professional Subscription** (£7.20/month)
  - Price ID: `price_1SqzuiRpdm3uvDfuzehsoDZt`

- [x] **Huston School Subscription** (£40/month)
  - Price ID: `price_1Sr3ETRpdm3uvDfuEEfNt7P1`

- [x] **3D Aiming Course** (£12 one-time)
  - Price ID: `price_1Sr3GJRpdm3uvDfuhGWLxEx3`
  - Product ID: `prod_SM4VhVapcll6nZ`

### Webhook Configured

- [x] Endpoint: `https://us-central1-archery-super.cloudfunctions.net/stripeWebhook`
- [x] Events: 6 events configured (checkout, subscription, invoice)
- [x] Webhook secret stored in `functions/.env` (gitignored)

### Customer Portal

- [x] Enabled in Stripe settings

---

## 2. Code Updated - DONE

- [x] `lib/services/stripe_service.dart` - All price IDs added
- [x] `functions/src/stripe.ts` - Price-to-tier mapping + product ID added
- [x] `functions/.env` - Stripe secrets configured (gitignored, safe)
- [x] `functions/.gitignore` - Updated to exclude `.env`

---

## 3. Firebase Configuration - BLOCKED (needs Blaze plan)

### Secrets Configuration - DONE

The Stripe secrets are stored in `functions/.env`:
- `STRIPE_SECRET_KEY` - Live API key (set 23 Jan 2026)
- `STRIPE_WEBHOOK_SECRET` - Webhook signing secret

**IMPORTANT:** The `.env` file is gitignored and will NOT be committed. It lives only on this machine.

### Deploy Functions - BLOCKED

Firebase requires Blaze (pay-as-you-go) plan to deploy Cloud Functions.

**Action required:**
1. Go to: https://console.firebase.google.com/project/archery-super/usage/details
2. Upgrade to Blaze plan (pay-as-you-go)
3. Then run: `firebase deploy --only functions`

Functions are built and ready - just need the plan upgrade.

### Firestore Security Rules

- [ ] Add entitlement read rules (users can only read their own)

### Legacy Users Collection

- [ ] Create `legacyUsers` collection for existing 3D Aiming purchasers
- [ ] Add documents for grandfathered users

---

## 4. Email Migration (from GHL)

### Get Email List from GoHighLevel

- [ ] Export contacts/subscribers from GHL
- [ ] Clean list (remove bounces, unsubscribes)
- [ ] Note: Need hosting guy's help (waiting until Monday)

### Choose Email Service

Pick ONE of these (don't build custom):

| Service | Free Tier | Notes |
|---------|-----------|-------|
| **Buttondown** | 100 subs | Simple, markdown-friendly, cheap |
| **MailerLite** | 1,000 subs | Good free tier, visual builder |
| **ConvertKit** | 1,000 subs | Creator-focused, automation |
| **Loops** | 1,000 subs | Modern, developer-friendly |

- [ ] Create account with chosen service
- [ ] Import email list
- [ ] Set up domain authentication (SPF/DKIM)
- [ ] Create welcome sequence

### Connect to App (optional)

- [ ] Add newsletter signup to app settings
- [ ] API integration for new user welcome emails

---

## 5. Bunny.net Video Hosting

### Account Setup

- [ ] Log into Bunny.net
- [ ] Create Stream library for "Huston School" videos
- [ ] Note the **API key** and **Library ID**

### Upload Huston School Videos

- [ ] Upload all coaching/analysis videos
- [ ] Organize into folders by topic
- [ ] Note each **Video ID** for the app

### Upload Course Videos

- [ ] 3D Aiming Course videos
- [ ] Plotting Course videos (free)

### Update App Code

- [ ] Add Bunny config to `functions/.env`:
  ```
  BUNNY_API_KEY=XXXXX
  BUNNY_LIBRARY_ID=XXXXX
  ```

- [ ] Update `lib/data/courses.dart` with real Bunny video IDs:
  ```dart
  Lesson(
    id: 'lesson_1',
    title: 'Introduction',
    bunnyVideoId: 'XXXXX-XXXXX-XXXXX',
  ),
  ```

---

## 6. Testing Checklist

### Stripe Test Mode

- [ ] Test checkout with card `4242 4242 4242 4242`
- [ ] Verify subscription creates correctly
- [ ] Verify webhook updates Firestore
- [ ] Test subscription cancellation
- [ ] Test one-time purchase (3D Aiming)

### App Testing

- [ ] Free tier features work
- [ ] Locked features show upgrade prompt
- [ ] Competitor unlocks correct features
- [ ] Professional unlocks unlimited Auto-Plot
- [ ] 3D Aiming purchase unlocks content
- [ ] Grace period (72hr after expiry)

---

## 7. Go Live

### Switch to Live Mode

- [x] Live API keys configured (23 Jan 2026)
- [ ] Deploy functions (after Blaze upgrade)
- [ ] Verify webhook receiving events

### Legal

- [ ] Subscription terms disclosed
- [ ] Privacy policy linked
- [ ] Terms of service linked

---

## Next Actions (in order)

1. **Upgrade Firebase to Blaze plan**: https://console.firebase.google.com/project/archery-super/usage/details
2. **Deploy functions**: `firebase deploy --only functions`
3. **Test Stripe** with test card in app
4. **Set up Bunny.net** - upload videos, get IDs
5. **Export emails from GHL** and import to chosen email service
6. **Final testing** of all payment flows
7. **Go live** when all tested

---

## Quick Reference: Tier Features

| Feature | Archer (Free) | Competitor (£2) | Professional (£7.20) | Huston School (£40) |
|---------|---------------|-----------------|----------------------|---------------------|
| Equipment tracking | Yes | Yes | Yes | Yes |
| Volume/scores | Yes | Yes | Yes | Yes |
| Breathing/bow training | Yes | Yes | Yes | Yes |
| Plotting course | Yes | Yes | Yes | Yes |
| Shaft analysis | No | Yes | Yes | Yes |
| OLY training | No | Yes | Yes | Yes |
| Auto-Plot | No | 50/month | Unlimited | Unlimited |
| Huston School videos | No | No | No | Yes |
| 3D Aiming course | £12 | £12 | £12 | £12 |

---

## Session Notes

### 23 Jan 2026
- Stripe live secret key configured in `functions/.env`
- Webhook secret configured in `functions/.env`
- Functions built successfully
- **Blocker:** Firebase needs Blaze plan upgrade to deploy functions
- Tomorrow: Discuss paywall feature visibility in detail

---

*Last updated: 23 Jan 2026*
