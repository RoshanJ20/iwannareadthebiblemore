import * as admin from "firebase-admin";
import { onCall } from "firebase-functions/v2/https";
import { sendFcm } from "./utils/fcm";

// NT Gospel chapter counts
const NT_GOSPELS: Record<string, number> = {
  MAT: 28,
  MRK: 16,
  LUK: 24,
  JHN: 21,
};

const ACHIEVEMENT_TITLES: Record<string, string> = {
  first_flame: "First Flame",
  month_of_faith: "Month of Faith",
  better_together: "Better Together",
  keepers_nudge: "Keeper's Nudge",
  in_the_beginning: "In the Beginning",
  red_letters: "Red Letters",
  group_mvp: "Group MVP",
};

/**
 * Internal helper: evaluate and award any newly-earned achievements for a user.
 * Optionally pass `awardGroupMvp=true` to also check/award the group_mvp badge.
 */
export async function checkAndAwardAchievements(
  userId: string,
  db: admin.firestore.Firestore,
  options?: { awardGroupMvp?: boolean }
): Promise<void> {
  const userRef = db.doc(`users/${userId}`);
  const userSnap = await userRef.get();
  if (!userSnap.exists) {
    console.warn(`onAchievementCheck: user ${userId} not found`);
    return;
  }
  const user = userSnap.data() as Record<string, unknown>;
  const fcmToken = user.fcmToken as string | undefined;
  const currentStreak = (user.currentStreak as number) ?? 0;

  // Fetch already-earned achievements
  const earnedSnap = await userRef.collection("achievements").get();
  const already = new Set(earnedSnap.docs.map((d) => d.id));

  const toAward: string[] = [];

  // 1. first_flame: streak >= 7
  if (!already.has("first_flame") && currentStreak >= 7) {
    toAward.push("first_flame");
  }

  // 2. month_of_faith: streak >= 30
  if (!already.has("month_of_faith") && currentStreak >= 30) {
    toAward.push("month_of_faith");
  }

  // 3. better_together: user is in at least 1 group
  if (!already.has("better_together")) {
    const groupQuery = await db
      .collection("groups")
      .where("memberIds", "array-contains", userId)
      .limit(1)
      .get();
    if (!groupQuery.empty) {
      toAward.push("better_together");
    }
  }

  // 4. keepers_nudge: sent 10+ nudges that earned XP
  if (!already.has("keepers_nudge")) {
    const nudgeQuery = await db
      .collection("nudges")
      .where("fromUserId", "==", userId)
      .where("xpAwarded", "==", true)
      .get();
    if (nudgeQuery.size >= 10) {
      toAward.push("keepers_nudge");
    }
  }

  // 5. in_the_beginning: all 50 chapters of Genesis
  if (!already.has("in_the_beginning")) {
    const genSnap = await userRef.collection("bookProgress").doc("GEN").get();
    const chapters: number[] = (genSnap.data()?.chapters as number[]) ?? [];
    if (chapters.length >= 50) {
      toAward.push("in_the_beginning");
    }
  }

  // 6. red_letters: all 4 gospel books complete
  if (!already.has("red_letters")) {
    const gospelChecks = await Promise.all(
      Object.entries(NT_GOSPELS).map(async ([bookId, totalChapters]) => {
        const snap = await userRef.collection("bookProgress").doc(bookId).get();
        const chapters: number[] = (snap.data()?.chapters as number[]) ?? [];
        // Use unique chapter count
        const unique = new Set(chapters);
        return unique.size >= totalChapters;
      })
    );
    if (gospelChecks.every(Boolean)) {
      toAward.push("red_letters");
    }
  }

  // 7. group_mvp: only awarded externally (weeklyLeaderboardReset)
  if (options?.awardGroupMvp && !already.has("group_mvp")) {
    toAward.push("group_mvp");
  }

  if (toAward.length === 0) return;

  const now = admin.firestore.Timestamp.now();
  const batch = db.batch();

  for (const achievementId of toAward) {
    const ref = userRef.collection("achievements").doc(achievementId);
    batch.set(ref, { achievementId, earnedAt: now });
  }

  await batch.commit();

  // Send FCM notifications (best-effort, outside batch)
  for (const achievementId of toAward) {
    const title = ACHIEVEMENT_TITLES[achievementId] ?? achievementId;
    await sendFcm(fcmToken, {
      title: `Achievement unlocked: ${title}! 🏆`,
      body: "Open the app to see your new badge.",
      data: { type: "achievement", achievementId },
    });
  }
}

/**
 * Callable function: onAchievementCheck
 * Client can call this to manually trigger achievement evaluation.
 */
export const onAchievementCheck = onCall(
  { region: "us-central1" },
  async (request) => {
    const db = admin.firestore();
    const userId = request.auth?.uid;
    if (!userId) {
      throw new Error("Unauthenticated");
    }
    await checkAndAwardAchievements(userId, db);
    return { success: true };
  }
);
