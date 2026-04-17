import * as admin from "firebase-admin";

export const XP = {
  PLAN_READ: 50,
  EXTRA_READ: 20,
  ADD_NOTE: 10,
  HIGHLIGHT: 5,
  NUDGE_SUCCESS: 15,
  STREAK_7: 100,
  STREAK_30: 400,
  STREAK_100: 1500,
  PLAN_COMPLETE: 500,
  BOOK_COMPLETE: 200,
} as const;

/**
 * Awards XP to a user inside a Firestore transaction.
 * Updates both xpTotal (lifetime, never decreases) and xpBalance (spendable).
 */
export async function awardXpTransaction(
  t: admin.firestore.Transaction,
  userRef: admin.firestore.DocumentReference,
  amount: number
): Promise<void> {
  t.update(userRef, {
    xpTotal: admin.firestore.FieldValue.increment(amount),
    xpBalance: admin.firestore.FieldValue.increment(amount),
  });
}

/**
 * Awards XP to a user atomically (outside an existing transaction).
 */
export async function awardXp(
  db: admin.firestore.Firestore,
  userId: string,
  amount: number
): Promise<void> {
  await db.doc(`users/${userId}`).update({
    xpTotal: admin.firestore.FieldValue.increment(amount),
    xpBalance: admin.firestore.FieldValue.increment(amount),
  });
}

/**
 * Returns any streak milestone bonus XP for the given streak value.
 * Returns 0 if no milestone applies.
 */
export function streakMilestoneBonus(streak: number): number {
  if (streak === 100) return XP.STREAK_100;
  if (streak === 30) return XP.STREAK_30;
  if (streak === 7) return XP.STREAK_7;
  return 0;
}
