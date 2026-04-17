import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { DateTime } from "luxon";
import { sendFcm } from "./utils/fcm";
import { firestoreTimestampToDateTime, isSameDay } from "./utils/timezone";

/**
 * Runs every minute. For each user:
 *  - If their local time is within 1 minute of 22:00 (10 PM) and they haven't read today:
 *      → Send "Your streak is at risk!" FCM
 *  - If their local time is within 1 minute of midnight (23:59) and they haven't read today:
 *      → Consume freeze OR reset streak, send "Your streak ended" FCM
 */
export const dailyStreakCheck = onSchedule(
  { schedule: "* * * * *", region: "us-central1", timeoutSeconds: 540 },
  async () => {
    const db = admin.firestore();

    // Fetch all users — paginate in production if > 5000 users
    const usersSnap = await db.collection("users").get();

    const now = DateTime.utc();

    const warningPromises: Promise<void>[] = [];
    const endOfDayPromises: Promise<void>[] = [];

    for (const userDoc of usersSnap.docs) {
      const user = userDoc.data() as Record<string, unknown>;
      const timezone: string = (user.timezone as string) || "UTC";
      const fcmToken = user.fcmToken as string | undefined;
      const userId = userDoc.id;

      let localNow: DateTime;
      try {
        localNow = now.setZone(timezone);
      } catch {
        localNow = now.setZone("UTC");
      }

      const lastReadTimestamp = user.lastReadDate as
        | { toDate?: () => Date; seconds?: number }
        | null
        | undefined;
      const lastRead = firestoreTimestampToDateTime(lastReadTimestamp, timezone);
      const hasReadToday = lastRead ? isSameDay(lastRead, localNow) : false;

      if (hasReadToday) continue; // Already read — nothing to do

      const localHour = localNow.hour;
      const localMinute = localNow.minute;

      // 22:00 warning window (22:00–22:00 inclusive, i.e. minute == 0 of hour 22)
      if (localHour === 22 && localMinute === 0) {
        warningPromises.push(
          sendFcm(fcmToken, {
            title: "Don't lose your streak! 🔥",
            body: "Your streak is at risk! You have 2 hours left to read today.",
            data: { type: "streak_warning", userId },
          })
        );
      }

      // End of day window (23:59)
      if (localHour === 23 && localMinute === 59) {
        endOfDayPromises.push(handleEndOfDay(db, userDoc.id, user, fcmToken));
      }
    }

    await Promise.all([...warningPromises, ...endOfDayPromises]);
  }
);

async function handleEndOfDay(
  db: admin.firestore.Firestore,
  userId: string,
  user: Record<string, unknown>,
  fcmToken: string | undefined
): Promise<void> {
  const streakFreezes = (user.streakFreezes as number) ?? 0;
  const userRef = db.doc(`users/${userId}`);

  try {
    if (streakFreezes > 0) {
      // Consume a freeze — streak continues
      await userRef.update({
        streakFreezes: admin.firestore.FieldValue.increment(-1),
      });
      await sendFcm(fcmToken, {
        title: "Streak freeze used! 🧊",
        body: "A streak freeze protected your streak today. Keep it up tomorrow!",
        data: { type: "streak_freeze_used", userId },
      });
    } else {
      // Break the streak
      await userRef.update({
        currentStreak: 0,
        streakBroken: true,
      });
      await sendFcm(fcmToken, {
        title: "Your streak ended 😢",
        body: "Don't give up — start a new streak today!",
        data: { type: "streak_broken", userId },
      });
    }
  } catch (err) {
    console.error(`dailyStreakCheck: failed to process user ${userId}`, err);
  }
}
