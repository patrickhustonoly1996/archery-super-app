# Monetisation To-Do List

Complete checklist for launching the subscription and payment system.

---

## 1. Stripe Dashboard Setup

### Create Products

- [ ] **Competitor Subscription** (£2/month)
  - Go to Stripe Dashboard > Products > Add Product
  - Name: "Competitor"
  - Description: "Shaft analysis, OLY training, Auto-Plot (50/mo)"
  - Pricing: £2.00 GBP, Recurring monthly
  - Copy the **Price ID** (starts with `price_`)

- [ ] **Professional Subscription** (£7.20/month)
  - Name: "Professional"
  - Description: "Everything in Competitor + Unlimited Auto-Plot"
  - Pricing: £7.20 GBP, Recurring monthly
  - Copy the **Price ID**

- [ ] **Huston School Subscription** (£40/month) - Future
  - Name: "Huston School"
  - Description: "Everything in Professional + Video coaching library"
  - Pricing: £40.00 GBP, Recurring monthly
  - Copy the **Price ID**

- [ ] **3D Aiming Course** (£12 one-time)
  - Name: "3D Aiming Course"
  - Description: "Visual aiming system mastery"
  - Pricing: £12.00 GBP, One-time
  - Copy the **Price ID**

### Configure Webhook

- [ ] Go to Stripe Dashboard > Developers > Webhooks
- [ ] Add endpoint: `https://[region]-[project-id].cloudfunctions.net/stripeWebhook`
- [ ] Select events to listen for:
  - `checkout.session.completed`
  - `customer.subscription.updated`
  - `customer.subscription.deleted`
  - `invoice.payment_succeeded`
  - `invoice.payment_failed`
- [ ] Copy the **Webhook Signing Secret** (starts with `whsec_`)

### Configure Customer Portal

- [ ] Go to Stripe Dashboard > Settings > Billing > Customer portal
- [ ] Enable: Cancel subscriptions
- [ ] Enable: Switch plans
- [ ] Enable: Update payment methods
- [ ] Save changes

---

## 2. Update Code with Stripe IDs

### Flutter (`lib/services/stripe_service.dart`)

- [ ] Replace placeholder price IDs:
  ```dart
  static const String competitorPriceId = 'price_XXXXX'; // Your real ID
  static const String professionalPriceId = 'price_XXXXX'; // Your real ID
  static const String aiming3dPriceId = 'price_XXXXX'; // Your real ID
  ```

### Firebase Functions (`functions/src/stripe.ts`)

- [ ] Replace placeholder price IDs in `PRICE_TO_TIER` mapping:
  ```typescript
  const PRICE_TO_TIER: PriceToTierMap = {
    "price_XXXXX": "competitor",      // Your real Competitor price ID
    "price_XXXXX": "professional",    // Your real Professional price ID
    "price_XXXXX": "hustonSchool",    // Your real Huston School price ID
  };
  ```

- [ ] Update `PRODUCT_3D_AIMING` with real product ID:
  ```typescript
  const PRODUCT_3D_AIMING = "prod_XXXXX"; // Your real product ID
  ```

---

## 3. Firebase Configuration

### Set Environment Variables

- [ ] Set Stripe secret key:
  ```bash
  firebase functions:config:set stripe.secret_key="sk_live_XXXXX"
  ```

- [ ] Set webhook secret:
  ```bash
  firebase functions:config:set stripe.webhook_secret="whsec_XXXXX"
  ```

- [ ] Deploy config:
  ```bash
  firebase deploy --only functions
  ```

### Firestore Security Rules

- [ ] Ensure users can only read their own entitlements:
  ```javascript
  match /users/{userId}/entitlement/{doc} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false; // Only Cloud Functions can write
  }

  match /users/{userId}/purchases/{doc} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false;
  }
  ```

### Legacy Users Collection

- [ ] Create `legacyUsers` collection in Firestore for existing 3D Aiming purchasers
- [ ] Add documents with format:
  ```json
  {
    "email": "user@example.com",
    "products": ["3d_aiming_course"],
    "grantedAt": <timestamp>,
    "notes": "Original purchaser"
  }
  ```

---

## 4. Bunny Stream Setup

### Upload Videos

- [ ] Create Bunny Stream library for course videos
- [ ] Upload 3D Aiming Course videos
- [ ] Upload Plotting Course videos (free)
- [ ] Note the **Video IDs** for each lesson

### Update Course Data

- [ ] Edit `lib/data/courses.dart` with real Bunny video IDs:
  ```dart
  Lesson(
    id: 'lesson_1',
    title: 'Introduction',
    bunnyVideoId: 'XXXXX-XXXXX-XXXXX', // Real Bunny video ID
    // ...
  ),
  ```

---

## 5. Testing Checklist

### Stripe Test Mode

- [ ] Use Stripe test mode first (test API keys)
- [ ] Test checkout flow with card `4242 4242 4242 4242`
- [ ] Verify subscription creates correctly
- [ ] Verify webhook updates Firestore entitlement
- [ ] Test subscription cancellation
- [ ] Test one-time purchase (3D Aiming)

### App Testing

- [ ] Verify free tier (Archer) features work
- [ ] Verify locked features show upgrade prompt
- [ ] Verify Competitor tier unlocks correct features
- [ ] Verify Professional tier unlocks unlimited Auto-Plot
- [ ] Verify 3D Aiming course purchase unlocks content
- [ ] Test grace period behavior (72 hours after expiry)
- [ ] Test legacy user email check

### Edge Cases

- [ ] Test offline behavior
- [ ] Test expired subscription → read-only mode
- [ ] Test payment failure handling

---

## 6. Go Live

### Switch to Live Mode

- [ ] Replace test API keys with live keys in Firebase config
- [ ] Update webhook endpoint to use live webhook secret
- [ ] Deploy functions with live config

### App Store / Play Store

- [ ] Ensure subscription terms are disclosed
- [ ] Link to privacy policy
- [ ] Link to terms of service

### Monitor

- [ ] Set up Stripe webhook failure alerts
- [ ] Monitor Firebase Functions logs for errors
- [ ] Set up revenue dashboard in Stripe

---

## Quick Reference: Tier Features

| Feature | Archer (Free) | Competitor (£2) | Professional (£7.20) | Huston School (£40) |
|---------|---------------|-----------------|----------------------|---------------------|
| Equipment tracking | Yes | Yes | Yes | Yes |
| Volume/scores | Yes | Yes | Yes | Yes |
| Breathing training | Yes | Yes | Yes | Yes |
| Bow training | Yes | Yes | Yes | Yes |
| Plotting course | Yes | Yes | Yes | Yes |
| Shaft analysis | No | Yes | Yes | Yes |
| OLY training | No | Yes | Yes | Yes |
| Auto-Plot | No | 50/month | Unlimited | Unlimited |
| Huston School videos | No | No | No | Yes |
| 3D Aiming course | Purchase £12 | Purchase £12 | Purchase £12 | Purchase £12 |

---

## Files Modified

These files contain placeholder IDs that need updating:

1. `lib/services/stripe_service.dart` - Flutter price IDs
2. `functions/src/stripe.ts` - Firebase price ID mapping
3. `lib/data/courses.dart` - Bunny video IDs

---

*Last updated: Session implementing Education + Payment System*
