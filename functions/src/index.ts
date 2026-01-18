import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Anthropic from "@anthropic-ai/sdk";

admin.initializeApp();

// Initialize Anthropic client with API key from environment
const getAnthropicClient = () => {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error("ANTHROPIC_API_KEY not configured");
  }
  return new Anthropic({ apiKey });
};

interface DetectedArrow {
  x: number;
  y: number;
  face?: number;
  confidence?: number; // 0.0-1.0, lower for line cutters
  isLineCutter?: boolean; // true if arrow is on/near a ring line
}

interface DetectArrowsRequest {
  shotImage: string; // base64
  referenceImage?: string; // base64 (optional)
  targetType: string;
  isTripleSpot: boolean;
  userId: string;
}

interface DetectArrowsResponse {
  success: boolean;
  arrows?: DetectedArrow[];
  error?: string;
}

/**
 * Auto-Plot: Detect arrows on a target image using Claude Vision
 */
export const detectArrows = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "512MB",
  })
  .https.onCall(async (data: DetectArrowsRequest, context): Promise<DetectArrowsResponse> => {
    // Verify authentication
    if (!context.auth) {
      return { success: false, error: "Authentication required" };
    }

    const { shotImage, referenceImage, targetType, isTripleSpot, userId } = data;

    if (!shotImage || !targetType) {
      return { success: false, error: "Missing required fields" };
    }

    // Check usage limits (could be extended to check Firestore for subscription status)
    const usageRef = admin.firestore()
      .collection("autoPlotUsage")
      .doc(`${userId}_${getCurrentYearMonth()}`);

    const usageDoc = await usageRef.get();
    const currentCount = usageDoc.exists ? (usageDoc.data()?.scanCount || 0) : 0;

    // TODO: Check subscription tier - for now, enforce 50 free scans
    const FREE_LIMIT = 50;
    if (currentCount >= FREE_LIMIT) {
      // Check if user has pro subscription
      const userDoc = await admin.firestore().collection("users").doc(userId).get();
      const isPro = userDoc.exists && userDoc.data()?.autoPlotPro === true;

      if (!isPro) {
        return {
          success: false,
          error: "Monthly scan limit reached. Upgrade to Auto-Plot Pro for unlimited scans."
        };
      }
    }

    try {
      const anthropic = getAnthropicClient();
      const prompt = buildPrompt(targetType, isTripleSpot);
      const content = buildContent(shotImage, referenceImage, prompt);

      const response = await anthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048, // Increased for up to 24 arrows
        messages: [{ role: "user", content }],
      });

      // Extract text response
      const textBlock = response.content.find((block) => block.type === "text");
      if (!textBlock || textBlock.type !== "text") {
        return { success: false, error: "Empty response from API" };
      }

      const result = parseResponse(textBlock.text);

      if (result.success) {
        // Increment usage count
        await usageRef.set({
          userId,
          yearMonth: getCurrentYearMonth(),
          scanCount: admin.firestore.FieldValue.increment(1),
          lastUsed: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      return result;
    } catch (error) {
      console.error("Auto-Plot error:", error);
      return {
        success: false,
        error: error instanceof Error ? error.message : "Unknown error"
      };
    }
  });

function getCurrentYearMonth(): string {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
}

function buildPrompt(targetType: string, isTripleSpot: boolean): string {
  const targetDesc = getTargetDescription(targetType);

  if (isTripleSpot) {
    return `You are analyzing an archery target image with 3 vertical target faces (triple-spot layout).

TARGET: ${targetDesc} - three faces arranged vertically

IMPORTANT: This may be a tournament scenario with up to 4 archers shooting at the same target.
There could be up to 24 arrows total (6 arrows × 4 archers). Arrows may:
- Overlap or cross each other
- Be tightly clustered in scoring zones
- Have different colored fletches/nocks (ignore colors, just detect positions)
- Partially obscure other arrows

Task: Identify ALL arrow positions on the target. Count carefully - missing arrows is worse than slight position errors.

For each arrow, return:
- "face": 0 (top), 1 (middle), or 2 (bottom)
- "x": normalized from -1.0 (left edge of that face) to +1.0 (right edge)
- "y": normalized from -1.0 (top of that face) to +1.0 (bottom)
- (0, 0) = center of that face (X ring)
- "confidence": 0.0-1.0 how certain you are of the exact position
- "isLineCutter": true if arrow appears to be touching or very close to a ring line

LINE CUTTERS: If an arrow shaft touches a ring line, it scores the higher value. Flag these with low confidence (0.3-0.5) and isLineCutter:true so the archer can verify.

Return ONLY a JSON array, no other text:
[{"face": 0, "x": 0.12, "y": -0.05, "confidence": 0.95}, {"face": 1, "x": -0.23, "y": 0.18, "confidence": 0.4, "isLineCutter": true}]

If no arrows are visible or you cannot reliably detect them, return:
{"error": "reason"}`;
  }

  return `You are analyzing an archery target image.

TARGET: ${targetDesc}

IMPORTANT: This may be a tournament scenario with up to 4 archers shooting at the same target.
There could be up to 24 arrows total (6 arrows × 4 archers). Arrows may:
- Overlap or cross each other
- Be tightly clustered in scoring zones
- Have different colored fletches/nocks (ignore colors, just detect positions)
- Partially obscure other arrows

Task: Identify ALL arrow positions on the target. Count carefully - missing arrows is worse than slight position errors.

For each arrow, return:
- "x": normalized from -1.0 (left edge) to +1.0 (right edge)
- "y": normalized from -1.0 (top edge) to +1.0 (bottom edge)
- (0, 0) = center of target (X ring)
- "confidence": 0.0-1.0 how certain you are of the exact position
- "isLineCutter": true if arrow appears to be touching or very close to a ring line

LINE CUTTERS: If an arrow shaft touches a ring line, it scores the higher value. Flag these with low confidence (0.3-0.5) and isLineCutter:true so the archer can verify.

Return ONLY a JSON array, no other text:
[{"x": 0.12, "y": -0.05, "confidence": 0.95}, {"x": -0.23, "y": 0.18, "confidence": 0.4, "isLineCutter": true}]

If no arrows are visible or you cannot reliably detect them, return:
{"error": "reason"}`;
}

function getTargetDescription(targetType: string): string {
  switch (targetType) {
    case "40cm":
      return "40cm indoor target face (10 rings, gold center)";
    case "60cm":
      return "60cm target face (10 rings, gold center)";
    case "80cm":
      return "80cm target face (10 rings, gold center)";
    case "122cm":
      return "122cm outdoor target face (10 rings, gold center)";
    case "triple_40cm":
      return "40cm triple-spot (3 vertical 40cm faces)";
    default:
      return `${targetType} archery target face`;
  }
}

function buildContent(
  shotImage: string,
  referenceImage: string | undefined,
  prompt: string
): Anthropic.MessageParam["content"] {
  const content: Anthropic.MessageParam["content"] = [];

  // Add reference image if provided
  if (referenceImage) {
    content.push({
      type: "text",
      text: "REFERENCE IMAGE (clean target, no arrows):",
    });
    content.push({
      type: "image",
      source: {
        type: "base64",
        media_type: "image/jpeg",
        data: referenceImage,
      },
    });
  }

  // Add shot image
  content.push({
    type: "text",
    text: "SHOT IMAGE (target with arrows to analyze):",
  });
  content.push({
    type: "image",
    source: {
      type: "base64",
      media_type: "image/jpeg",
      data: shotImage,
    },
  });

  // Add prompt
  content.push({
    type: "text",
    text: prompt,
  });

  return content;
}

function parseResponse(text: string): DetectArrowsResponse {
  let jsonStr = text.trim();

  // Try to extract JSON from markdown code blocks
  const codeBlockMatch = /```(?:json)?\s*([\s\S]*?)\s*```/.exec(jsonStr);
  if (codeBlockMatch) {
    jsonStr = codeBlockMatch[1].trim();
  }

  try {
    const decoded = JSON.parse(jsonStr);

    // Check if it's an error response
    if (decoded && typeof decoded === "object" && "error" in decoded) {
      return { success: false, error: decoded.error as string };
    }

    // Parse arrow array
    if (Array.isArray(decoded)) {
      const arrows: DetectedArrow[] = decoded.map((item: Record<string, unknown>) => ({
        x: Number(item.x),
        y: Number(item.y),
        face: item.face !== undefined ? Number(item.face) : undefined,
        confidence: item.confidence !== undefined ? Number(item.confidence) : 1.0,
        isLineCutter: item.isLineCutter === true,
      }));
      return { success: true, arrows };
    }

    return { success: false, error: "Invalid response format" };
  } catch (e) {
    return { success: false, error: `Failed to parse response: ${e}` };
  }
}

/**
 * Check user's Auto-Plot subscription status
 */
export const getAutoPlotStatus = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    return { error: "Authentication required" };
  }

  const userId = context.auth.uid;
  const yearMonth = getCurrentYearMonth();

  // Get usage
  const usageRef = admin.firestore()
    .collection("autoPlotUsage")
    .doc(`${userId}_${yearMonth}`);
  const usageDoc = await usageRef.get();
  const scanCount = usageDoc.exists ? (usageDoc.data()?.scanCount || 0) : 0;

  // Get subscription status
  const userDoc = await admin.firestore().collection("users").doc(userId).get();
  const isPro = userDoc.exists && userDoc.data()?.autoPlotPro === true;

  return {
    scanCount,
    isPro,
    limit: isPro ? -1 : 50,
    remaining: isPro ? -1 : Math.max(0, 50 - scanCount),
  };
});
