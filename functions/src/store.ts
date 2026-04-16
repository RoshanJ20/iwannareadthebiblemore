import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';

const db = admin.firestore();

export const onPlanComplete = onDocumentUpdated('userPlans/{userPlanId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.isComplete === after.isComplete || !after.isComplete) return;

  const userId = after.userId as string;
  await db.collection('users').doc(userId).update({
    xpTotal: admin.firestore.FieldValue.increment(500),
    xpBalance: admin.firestore.FieldValue.increment(500),
  });
});

export const xpStorePurchase = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new Error('Unauthenticated');

  const { itemId } = request.data as { itemId: string };
  const itemCosts: Record<string, number> = {
    freeze_1: 200,
    outfit_basic_1: 500,
    outfit_basic_2: 500,
    outfit_basic_3: 500,
    outfit_rare_1: 1000,
    outfit_rare_2: 1000,
    outfit_rare_3: 1000,
    outfit_legendary_1: 2000,
    outfit_legendary_2: 2000,
  };

  const cost = itemCosts[itemId];
  if (!cost) throw new Error('Unknown item');

  const userRef = db.collection('users').doc(userId);
  await db.runTransaction(async (tx) => {
    const user = (await tx.get(userRef)).data() || {};
    if ((user.xpBalance || 0) < cost) throw new Error('Insufficient XP');
    tx.update(userRef, { xpBalance: admin.firestore.FieldValue.increment(-cost) });
    if (itemId === 'freeze_1') {
      tx.update(userRef, { streakFreezes: admin.firestore.FieldValue.increment(1) });
    } else {
      tx.update(userRef, { activeOutfitId: itemId });
    }
  });

  return { success: true };
});
