import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { DateTime } from "luxon";
import { checkAndAwardAchievements } from "./onAchievementCheck";
import { sendFcm, sendFcmToUsers } from "./utils/fcm";
import { todayDateStr, firestoreTimestampToDateTime, isSameDay, isYesterday } from "./utils/timezone";
import { XP, streakMilestoneBonus } from "./utils/xp";

export const onReadingComplete = onDocumentWritten(
  { document: "userPlans/{userPlanId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before?.data() as Record<string, unknown> | undefined;
    const after = event.data?.after?.data() as Record<string, unknown> | undefined;

    // Only fire when todayRead changes from false/missing to true
    if (!after) return;
    if (after.todayRead !== true) return;
    if (before?.todayRead === true) return;

    const db = admin.firestore();
    const userId = after.userId as string;
    const planId = after.planId as string;
    const groupId = (after.groupId as string | null | undefined) ?? null;
    const todayChapter = (after.todayChapter as string) ?? "";
    const currentDay = (after.currentDay as number) ?? 1;

    if (!userId) {
      console.error("onReadingComplete: missing userId in userPlan");
      return;
    }

    // -----------------------------------------------------------------------
    // Resolve bookId and chapterId from todayChapter via plan readings
    // todayChapter format: "Genesis 1"
    // -----------------------------------------------------------------------
    let bookId = "";
    let chapterId = 1;

    try {
      const planSnap = await db.doc(`plans/${planId}`).get();
      const planData = planSnap.data() as Record<string, unknown> | undefined;
      const readings = (planData?.readings as Array<Record<string, unknown>>) ?? [];
      // Find the reading for the current day
      const reading = readings.find((r) => Number(r.day) === currentDay);
      if (reading) {
        bookId = (reading.book as string) ?? "";
        chapterId = Number(reading.chapter) ?? 1;
      } else {
        // Fallback: parse from todayChapter string "Genesis 1"
        const parts = todayChapter.split(" ");
        chapterId = parseInt(parts[parts.length - 1], 10) || 1;
        bookId = parts.slice(0, -1).join("_").toUpperCase();
      }
    } catch (err) {
      console.error("onReadingComplete: failed to resolve plan readings", err);
      // Best-effort parse from string
      const parts = todayChapter.split(" ");
      chapterId = parseInt(parts[parts.length - 1], 10) || 1;
      bookId = parts.slice(0, -1).join("_").toUpperCase();
    }

    // -----------------------------------------------------------------------
    // Fetch user doc for streak math and defaults
    // -----------------------------------------------------------------------
    const userRef = db.doc(`users/${userId}`);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      console.error(`onReadingComplete: user ${userId} not found`);
      return;
    }
    const user = userSnap.data() as Record<string, unknown>;
    const timezone: string = (user.timezone as string) || "UTC";
    const defaultTranslation: string = (user.defaultTranslation as string) || "NIV";
    const fcmToken = user.fcmToken as string | undefined;
    const displayName = (user.displayName as string) || "A friend";

    const dateStr = todayDateStr(timezone);
    const now = DateTime.now().setZone(timezone);

    // -----------------------------------------------------------------------
    // Streak computation (authoritative)
    // -----------------------------------------------------------------------
    const lastReadTimestamp = user.lastReadDate as
      | { toDate?: () => Date; seconds?: number }
      | null
      | undefined;
    const lastRead = firestoreTimestampToDateTime(lastReadTimestamp, timezone);
    const currentStreak = (user.currentStreak as number) ?? 0;
    const longestStreak = (user.longestStreak as number) ?? 0;
    const streakFreezes = (user.streakFreezes as number) ?? 0;

    let newStreak = currentStreak;
    let consumedFreeze = false;
    let alreadyReadToday = false;

    if (!lastRead) {
      newStreak = 1;
    } else if (isSameDay(lastRead, now)) {
      alreadyReadToday = true;
      newStreak = currentStreak; // already read today, no change
    } else if (isYesterday(lastRead, now)) {
      newStreak = currentStreak + 1;
    } else {
      // Missed one or more days
      if (streakFreezes > 0) {
        consumedFreeze = true;
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
    }

    const newLongest = Math.max(longestStreak, newStreak);
    const milestoneBonus = alreadyReadToday ? 0 : streakMilestoneBonus(newStreak);
    const totalXp = XP.PLAN_READ + milestoneBonus;

    // -----------------------------------------------------------------------
    // Check for pending nudges from other users (award +15 XP to senders)
    // -----------------------------------------------------------------------
    const twentyFourHoursAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    );
    const nudgesSnap = await db
      .collection("nudges")
      .where("toUserId", "==", userId)
      .where("sentAt", ">=", twentyFourHoursAgo)
      .where("xpAwarded", "==", false)
      .get();

    // -----------------------------------------------------------------------
    // Firestore transaction: atomic XP + streak + readingLog + bookProgress
    // -----------------------------------------------------------------------
    await db.runTransaction(async (t) => {
      const userDoc = await t.get(userRef);
      if (!userDoc.exists) throw new Error("User not found");

      // ReadingLog
      const logRef = userRef.collection("readingLog").doc(dateStr);
      t.set(logRef, {
        date: dateStr,
        bookId,
        chapterId,
        planId,
        xpEarned: totalXp,
        translation: defaultTranslation,
      });

      // BookProgress: add chapterId to chapters array
      const bookProgressRef = userRef.collection("bookProgress").doc(bookId);
      t.set(
        bookProgressRef,
        { chapters: admin.firestore.FieldValue.arrayUnion(chapterId) },
        { merge: true }
      );

      // User: XP + streak
      const streakUpdate: Record<string, unknown> = {
        xpTotal: admin.firestore.FieldValue.increment(totalXp),
        xpBalance: admin.firestore.FieldValue.increment(totalXp),
        lastReadDate: admin.firestore.Timestamp.now(),
      };

      if (!alreadyReadToday) {
        streakUpdate.currentStreak = newStreak;
        streakUpdate.longestStreak = newLongest;
        if (consumedFreeze) {
          streakUpdate.streakFreezes = admin.firestore.FieldValue.increment(-1);
        }
      }

      t.update(userRef, streakUpdate);

      // Award nudge XP to senders (inside transaction)
      for (const nudgeDoc of nudgesSnap.docs) {
        const nudgeData = nudgeDoc.data() as Record<string, unknown>;
        const fromUserId = nudgeData.fromUserId as string;
        if (fromUserId) {
          const senderRef = db.doc(`users/${fromUserId}`);
          t.update(senderRef, {
            xpTotal: admin.firestore.FieldValue.increment(XP.NUDGE_SUCCESS),
            xpBalance: admin.firestore.FieldValue.increment(XP.NUDGE_SUCCESS),
          });
        }
        t.update(nudgeDoc.ref, { xpAwarded: true, opened: true });
      }
    });

    // -----------------------------------------------------------------------
    // Group updates (outside transaction — best effort)
    // -----------------------------------------------------------------------
    if (groupId) {
      const groupRef = db.doc(`groups/${groupId}`);

      // Update member todayRead
      await groupRef.collection("members").doc(userId).update({ todayRead: true });

      // Write dailyStatus
      await groupRef
        .collection("dailyStatus")
        .doc(dateStr)
        .set({ [userId]: true }, { merge: true });

      // Check if all group members have read
      try {
        const groupSnap = await groupRef.get();
        const groupData = groupSnap.data() as Record<string, unknown> | undefined;
        const memberIds = (groupData?.memberIds as string[]) ?? [];

        if (memberIds.length > 0) {
          const memberDocs = await groupRef.collection("members").get();
          const allRead = memberDocs.docs.every((d) => d.data().todayRead === true);

          if (allRead) {
            await groupRef.update({
              groupStreak: admin.firestore.FieldValue.increment(1),
              lastAllReadDate: admin.firestore.Timestamp.now(),
            });
          }
        }

        // Notify other group members
        const otherMemberIds = (groupData?.memberIds as string[] ?? []).filter(
          (id) => id !== userId
        );
        if (otherMemberIds.length > 0) {
          await sendFcmToUsers(db, otherMemberIds, {
            title: "Group activity",
            body: `${displayName} finished today's reading 📖`,
            data: { type: "group_read", groupId: groupId ?? "", userId },
          });
        }
      } catch (err) {
        console.error("onReadingComplete: group update failed", err);
      }
    }

    // Milestone FCM to user (if any)
    if (milestoneBonus > 0) {
      const label =
        newStreak === 7 ? "7-day" : newStreak === 30 ? "30-day" : "100-day";
      await sendFcm(fcmToken, {
        title: `${label} streak! 🔥`,
        body: `You earned a ${milestoneBonus} XP bonus for your ${label} streak!`,
        data: { type: "streak_milestone", streak: String(newStreak) },
      });
    }

    // Achievement check
    try {
      await checkAndAwardAchievements(userId, db);
    } catch (err) {
      console.error("onReadingComplete: achievement check failed", err);
    }
  }
);
