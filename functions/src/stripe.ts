import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

// Initialize Stripe with API key from environment
const getStripe = (): Stripe => {
  const apiKey = process.env.STRIPE_SECRET_KEY;
  if (!apiKey) {
    throw new Error("STRIPE_SECRET_KEY not configured");
  }
  return new Stripe(apiKey);
};

// Subscription tier mapping
type SubscriptionTier = "archer" | "competitor" | "professional" | "hustonSchool";

interface PriceToTierMap {
  [priceId: string]: SubscriptionTier;
}

// Map Stripe price IDs to subscription tiers
const PRICE_TO_TIER: PriceToTierMap = {
  "price_1SqztNRpdm3uvDfu5wcHwFum": "competitor",      // £2/mo
  "price_1SqzuiRpdm3uvDfuzehsoDZt": "professional",    // £7.20/mo
  "price_1Sr3ETRpdm3uvDfuEEfNt7P1": "hustonSchool",    // £40/mo
};

// One-time product IDs
const PRODUCT_3D_AIMING = "prod_SM4VhVapcll6nZ"; // £12 one-time

// Grace period after subscription expires (72 hours)
const GRACE_PERIOD_MS = 72 * 60 * 60 * 1000;

// ===========================================================================
// TYPES
// ===========================================================================

interface CheckoutSessionRequest {
  priceId: string;
  mode: "subscription" | "payment";
  successUrl: string;
  cancelUrl: string;
}

interface CheckoutSessionResponse {
  url?: string;
  error?: string;
}

interface EntitlementStatus {
  tier: SubscriptionTier;
  stripeCustomerId?: string;
  stripeSubscriptionId?: string;
  expiresAt?: string;
  graceEndsAt?: string;
  isLegacy3dAiming: boolean;
  has3dAimingCourse: boolean;
}

interface PortalSessionResponse {
  url?: string;
  error?: string;
}

// ===========================================================================
// HELPER FUNCTIONS
// ===========================================================================

/**
 * Get or create Stripe customer for a Firebase user
 */
async function getOrCreateStripeCustomer(
  stripe: Stripe,
  userId: string,
  email?: string
): Promise<string> {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (userDoc.exists && userDoc.data()?.stripeCustomerId) {
    return userDoc.data()!.stripeCustomerId;
  }

  // Create new Stripe customer
  const customer = await stripe.customers.create({
    email: email || undefined,
    metadata: { firebaseUserId: userId },
  });

  // Store customer ID in Firestore
  await userRef.set({ stripeCustomerId: customer.id }, { merge: true });

  return customer.id;
}

/**
 * Update user entitlement in Firestore based on subscription
 */
async function updateEntitlement(
  userId: string,
  tier: SubscriptionTier,
  stripeCustomerId: string,
  stripeSubscriptionId: string,
  currentPeriodEnd?: Date
): Promise<void> {
  const db = admin.firestore();
  const entitlementRef = db.collection("users").doc(userId).collection("entitlement").doc("current");

  const expiresAt = currentPeriodEnd || null;
  const graceEndsAt = currentPeriodEnd
    ? new Date(currentPeriodEnd.getTime() + GRACE_PERIOD_MS)
    : null;

  await entitlementRef.set({
    tier,
    stripeCustomerId,
    stripeSubscriptionId,
    expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
    graceEndsAt: graceEndsAt ? admin.firestore.Timestamp.fromDate(graceEndsAt) : null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // Also update the main user doc for quick access
  await db.collection("users").doc(userId).set({
    subscriptionTier: tier,
    stripeCustomerId,
    stripeSubscriptionId,
  }, { merge: true });
}

/**
 * Downgrade user to free tier
 */
async function downgradeToFreeTier(userId: string): Promise<void> {
  const db = admin.firestore();
  const entitlementRef = db.collection("users").doc(userId).collection("entitlement").doc("current");

  await entitlementRef.set({
    tier: "archer",
    stripeSubscriptionId: null,
    expiresAt: null,
    graceEndsAt: null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection("users").doc(userId).set({
    subscriptionTier: "archer",
    stripeSubscriptionId: null,
  }, { merge: true });
}

/**
 * Record a one-time purchase
 */
async function recordPurchase(
  userId: string,
  productId: string,
  stripePaymentId: string,
  amount: number
): Promise<void> {
  const db = admin.firestore();

  // Record in purchases collection
  await db.collection("users").doc(userId).collection("purchases").add({
    productId,
    stripePaymentId,
    amountPaid: amount / 100, // Convert cents to currency
    purchasedAt: admin.firestore.FieldValue.serverTimestamp(),
    source: "stripe",
  });

  // If it's the 3D Aiming course, update entitlement
  if (productId === PRODUCT_3D_AIMING || productId === "3d_aiming_course") {
    const entitlementRef = db.collection("users").doc(userId).collection("entitlement").doc("current");
    await entitlementRef.set({
      has3dAimingCourse: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
}

/**
 * Get Firebase user ID from Stripe customer ID
 */
async function getUserIdFromCustomer(customerId: string): Promise<string | null> {
  const db = admin.firestore();
  const usersQuery = await db.collection("users")
    .where("stripeCustomerId", "==", customerId)
    .limit(1)
    .get();

  if (usersQuery.empty) {
    console.warn(`No user found for Stripe customer: ${customerId}`);
    return null;
  }

  return usersQuery.docs[0].id;
}

// ===========================================================================
// CLOUD FUNCTIONS
// ===========================================================================

/**
 * Create a Stripe Checkout session for subscription or one-time payment
 */
export const createCheckoutSession = functions.https.onCall(
  async (data: CheckoutSessionRequest, context): Promise<CheckoutSessionResponse> => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const { priceId, mode, successUrl, cancelUrl } = data;

    if (!priceId || !mode || !successUrl || !cancelUrl) {
      return { error: "Missing required fields" };
    }

    try {
      const stripe = getStripe();
      const userId = context.auth.uid;
      const email = context.auth.token.email;

      // Get or create Stripe customer
      const customerId = await getOrCreateStripeCustomer(stripe, userId, email);

      // Create checkout session
      const session = await stripe.checkout.sessions.create({
        customer: customerId,
        mode,
        line_items: [{ price: priceId, quantity: 1 }],
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: {
          firebaseUserId: userId,
        },
        // For subscriptions, allow promotion codes
        ...(mode === "subscription" && { allow_promotion_codes: true }),
      });

      return { url: session.url || undefined };
    } catch (error) {
      console.error("Checkout session error:", error);
      return {
        error: error instanceof Error ? error.message : "Failed to create checkout session"
      };
    }
  }
);

/**
 * Create a Stripe Customer Portal session for managing subscriptions
 */
export const createCustomerPortalSession = functions.https.onCall(
  async (data: { returnUrl: string }, context): Promise<PortalSessionResponse> => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const { returnUrl } = data;
    if (!returnUrl) {
      return { error: "Return URL required" };
    }

    try {
      const stripe = getStripe();
      const userId = context.auth.uid;

      // Get customer ID from Firestore
      const db = admin.firestore();
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists || !userDoc.data()?.stripeCustomerId) {
        return { error: "No subscription found" };
      }

      const customerId = userDoc.data()!.stripeCustomerId;

      // Create portal session
      const session = await stripe.billingPortal.sessions.create({
        customer: customerId,
        return_url: returnUrl,
      });

      return { url: session.url };
    } catch (error) {
      console.error("Portal session error:", error);
      return {
        error: error instanceof Error ? error.message : "Failed to create portal session"
      };
    }
  }
);

/**
 * Get user's current entitlement status
 */
export const getEntitlementStatus = functions.https.onCall(
  async (_data, context): Promise<EntitlementStatus | { error: string }> => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const userId = context.auth.uid;
    const db = admin.firestore();

    try {
      const entitlementDoc = await db
        .collection("users")
        .doc(userId)
        .collection("entitlement")
        .doc("current")
        .get();

      if (!entitlementDoc.exists) {
        return {
          tier: "archer",
          isLegacy3dAiming: false,
          has3dAimingCourse: false,
        };
      }

      const data = entitlementDoc.data()!;

      return {
        tier: data.tier || "archer",
        stripeCustomerId: data.stripeCustomerId,
        stripeSubscriptionId: data.stripeSubscriptionId,
        expiresAt: data.expiresAt?.toDate()?.toISOString(),
        graceEndsAt: data.graceEndsAt?.toDate()?.toISOString(),
        isLegacy3dAiming: data.isLegacy3dAiming || false,
        has3dAimingCourse: data.has3dAimingCourse || false,
      };
    } catch (error) {
      console.error("Get entitlement error:", error);
      return { error: "Failed to get entitlement status" };
    }
  }
);

/**
 * Stripe Webhook handler for subscription events
 *
 * Configure this endpoint URL in Stripe Dashboard:
 * https://[region]-[project-id].cloudfunctions.net/stripeWebhook
 *
 * Events to listen for:
 * - checkout.session.completed
 * - customer.subscription.updated
 * - customer.subscription.deleted
 * - invoice.payment_succeeded
 * - invoice.payment_failed
 */
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!webhookSecret) {
    console.error("STRIPE_WEBHOOK_SECRET not configured");
    res.status(500).send("Webhook secret not configured");
    return;
  }

  const signature = req.headers["stripe-signature"];
  if (!signature) {
    res.status(400).send("Missing signature");
    return;
  }

  let event: Stripe.Event;

  try {
    const stripe = getStripe();
    // Use rawBody for signature verification
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      signature,
      webhookSecret
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    res.status(400).send(`Webhook Error: ${err instanceof Error ? err.message : "Unknown"}`);
    return;
  }

  console.log(`Processing Stripe event: ${event.type}`);

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const userId = session.metadata?.firebaseUserId;

        if (!userId) {
          console.error("No Firebase user ID in session metadata");
          break;
        }

        if (session.mode === "subscription" && session.subscription) {
          // Subscription checkout completed
          const stripe = getStripe();
          const subscription = await stripe.subscriptions.retrieve(
            session.subscription as string
          );

          const priceId = subscription.items.data[0]?.price.id;
          const tier = PRICE_TO_TIER[priceId] || "archer";

          await updateEntitlement(
            userId,
            tier,
            session.customer as string,
            subscription.id,
            new Date(subscription.current_period_end * 1000)
          );

          console.log(`Subscription created for user ${userId}: ${tier}`);
        } else if (session.mode === "payment") {
          // One-time payment completed
          const lineItems = await getStripe().checkout.sessions.listLineItems(session.id);
          const productId = lineItems.data[0]?.price?.product as string;

          await recordPurchase(
            userId,
            productId,
            session.payment_intent as string,
            session.amount_total || 0
          );

          console.log(`Purchase recorded for user ${userId}: ${productId}`);
        }
        break;
      }

      case "customer.subscription.updated": {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = await getUserIdFromCustomer(subscription.customer as string);

        if (!userId) break;

        const priceId = subscription.items.data[0]?.price.id;
        const tier = PRICE_TO_TIER[priceId] || "archer";

        // Check if subscription is still active
        if (subscription.status === "active" || subscription.status === "trialing") {
          await updateEntitlement(
            userId,
            tier,
            subscription.customer as string,
            subscription.id,
            new Date(subscription.current_period_end * 1000)
          );
          console.log(`Subscription updated for user ${userId}: ${tier}`);
        } else if (subscription.status === "past_due" || subscription.status === "unpaid") {
          // Keep access during grace period, but log warning
          console.warn(`Subscription ${subscription.id} is ${subscription.status}`);
        }
        break;
      }

      case "customer.subscription.deleted": {
        const subscription = event.data.object as Stripe.Subscription;
        const userId = await getUserIdFromCustomer(subscription.customer as string);

        if (!userId) break;

        // Downgrade to free tier
        await downgradeToFreeTier(userId);
        console.log(`Subscription cancelled for user ${userId}`);
        break;
      }

      case "invoice.payment_failed": {
        const invoice = event.data.object as Stripe.Invoice;
        const userId = await getUserIdFromCustomer(invoice.customer as string);

        if (!userId) break;

        // Log payment failure - grace period will handle access
        console.warn(`Payment failed for user ${userId}, invoice ${invoice.id}`);
        break;
      }

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    res.status(200).json({ received: true });
  } catch (error) {
    console.error("Webhook processing error:", error);
    res.status(500).send("Webhook processing failed");
  }
});
