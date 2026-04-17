import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

const MAX_STREAK_FREEZES = 3;

// XP cost of each item
const ITEM_COSTS: Record<string, number> = {
  freeze: 200,
  mascotOutfit: 500,
};

interface PurchaseRequest {
  itemType: string;
  itemId?: string; // required for mascotOutfit
}

interface PurchaseResponse {
  success: true;
  newBalance: number;
}

export const xpStorePurchase = onCall<PurchaseRequest, Promise<PurchaseResponse>>(
  { region: "us-central1" },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "You must be signed in to make a purchase.");
    }

    const { itemType, itemId } = request.data;

    if (!itemType || !ITEM_COSTS[itemType]) {
      throw new HttpsError("invalid-argument", `Unknown item type: ${itemType}`);
    }

    const cost = ITEM_COSTS[itemType];
    const db = admin.firestore();
    const userRef = db.doc(`users/${userId}`);

    let newBalance = 0;

    await db.runTransaction(async (t) => {
      const userSnap = await t.get(userRef);
      if (!userSnap.exists) {
        throw new HttpsError("not-found", "User not found.");
      }

      const user = userSnap.data() as Record<string, unknown>;
      const xpBalance = (user.xpBalance as number) ?? 0;

      if (xpBalance < cost) {
        throw new HttpsError(
          "failed-precondition",
          `Insufficient XP balance. Need ${cost}, have ${xpBalance}.`
        );
      }

      newBalance = xpBalance - cost;

      if (itemType === "freeze") {
        const currentFreezes = (user.streakFreezes as number) ?? 0;
        if (currentFreezes >= MAX_STREAK_FREEZES) {
          throw new HttpsError(
            "failed-precondition",
            `You already have the maximum number of streak freezes (${MAX_STREAK_FREEZES}).`
          );
        }
        t.update(userRef, {
          xpBalance: admin.firestore.FieldValue.increment(-cost),
          streakFreezes: admin.firestore.FieldValue.increment(1),
        });
      } else if (itemType === "mascotOutfit") {
        if (!itemId) {
          throw new HttpsError("invalid-argument", "itemId is required for mascotOutfit purchases.");
        }
        const equippedItems = (user.equippedItems as string[]) ?? [];
        if (equippedItems.includes(itemId)) {
          throw new HttpsError("already-exists", "You already own this outfit.");
        }
        t.update(userRef, {
          xpBalance: admin.firestore.FieldValue.increment(-cost),
          equippedItems: admin.firestore.FieldValue.arrayUnion(itemId),
        });
      }
    });

    return { success: true, newBalance };
  }
);
