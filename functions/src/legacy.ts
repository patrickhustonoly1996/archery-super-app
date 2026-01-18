import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// ===========================================================================
// TYPES
// ===========================================================================

interface LegacyAccessRequest {
  email: string;
}

interface LegacyAccessResponse {
  hasLegacyAccess: boolean;
  grantedProducts: string[];
  error?: string;
}

interface LegacyUser {
  email: string;
  products: string[];
  grantedAt?: FirebaseFirestore.Timestamp;
  notes?: string;
}

// ===========================================================================
// CLOUD FUNCTIONS
// ===========================================================================

/**
 * Check if an email has legacy access to products
 *
 * Legacy users are stored in Firestore collection `legacyUsers`
 * Each document has:
 * - email: string (lowercased)
 * - products: string[] (e.g., ["3d_aiming_course"])
 * - grantedAt: timestamp
 * - notes: optional string
 *
 * This is used for users who purchased the 3D Aiming course before
 * the new Stripe integration, or for promotional access.
 */
export const checkLegacyAccess = functions.https.onCall(
  async (data: LegacyAccessRequest, context): Promise<LegacyAccessResponse> => {
    const { email } = data;

    if (!email) {
      return {
        hasLegacyAccess: false,
        grantedProducts: [],
        error: "Email required",
      };
    }

    try {
      const db = admin.firestore();
      const normalizedEmail = email.toLowerCase().trim();

      // Query legacy users collection by email
      const legacyQuery = await db
        .collection("legacyUsers")
        .where("email", "==", normalizedEmail)
        .limit(1)
        .get();

      if (legacyQuery.empty) {
        return {
          hasLegacyAccess: false,
          grantedProducts: [],
        };
      }

      const legacyUser = legacyQuery.docs[0].data() as LegacyUser;

      // If authenticated, update user's entitlement
      if (context.auth && legacyUser.products.length > 0) {
        const userId = context.auth.uid;
        const entitlementRef = db
          .collection("users")
          .doc(userId)
          .collection("entitlement")
          .doc("current");

        // Check if 3D Aiming is in the legacy products
        const has3dAiming = legacyUser.products.includes("3d_aiming_course");

        await entitlementRef.set(
          {
            isLegacy3dAiming: has3dAiming,
            legacyEmail: normalizedEmail,
            legacyCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        console.log(`Legacy access granted to user ${userId}: ${legacyUser.products.join(", ")}`);
      }

      return {
        hasLegacyAccess: true,
        grantedProducts: legacyUser.products,
      };
    } catch (error) {
      console.error("Legacy access check error:", error);
      return {
        hasLegacyAccess: false,
        grantedProducts: [],
        error: error instanceof Error ? error.message : "Failed to check legacy access",
      };
    }
  }
);

/**
 * Admin function to add a legacy user
 * Only callable by authenticated admin users
 */
export const addLegacyUser = functions.https.onCall(
  async (data: { email: string; products: string[]; notes?: string }, context) => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    // Check if user is admin (you'll need to set up admin claims)
    const isAdmin = context.auth.token.admin === true;
    if (!isAdmin) {
      return { error: "Admin access required" };
    }

    const { email, products, notes } = data;

    if (!email || !products || products.length === 0) {
      return { error: "Email and products required" };
    }

    try {
      const db = admin.firestore();
      const normalizedEmail = email.toLowerCase().trim();

      // Create or update legacy user
      await db.collection("legacyUsers").doc(normalizedEmail).set({
        email: normalizedEmail,
        products,
        notes: notes || null,
        grantedAt: admin.firestore.FieldValue.serverTimestamp(),
        addedBy: context.auth.uid,
      });

      console.log(`Legacy user added: ${normalizedEmail} with products ${products.join(", ")}`);

      return { success: true };
    } catch (error) {
      console.error("Add legacy user error:", error);
      return { error: error instanceof Error ? error.message : "Failed to add legacy user" };
    }
  }
);

/**
 * Remove legacy access for a user
 * Only callable by authenticated admin users
 */
export const removeLegacyUser = functions.https.onCall(
  async (data: { email: string }, context) => {
    if (!context.auth) {
      return { error: "Authentication required" };
    }

    const isAdmin = context.auth.token.admin === true;
    if (!isAdmin) {
      return { error: "Admin access required" };
    }

    const { email } = data;

    if (!email) {
      return { error: "Email required" };
    }

    try {
      const db = admin.firestore();
      const normalizedEmail = email.toLowerCase().trim();

      await db.collection("legacyUsers").doc(normalizedEmail).delete();

      console.log(`Legacy user removed: ${normalizedEmail}`);

      return { success: true };
    } catch (error) {
      console.error("Remove legacy user error:", error);
      return { error: error instanceof Error ? error.message : "Failed to remove legacy user" };
    }
  }
);
