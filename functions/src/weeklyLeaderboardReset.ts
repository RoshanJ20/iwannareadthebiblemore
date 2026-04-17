import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { DateTime } from "luxon";
import { checkAndAwardAchievements } from "./onAchievementCheck";
import { sendFcmToUsers } from "./utils/fcm";

export const weeklyLeaderboardReset = onSchedule(
  { schedule: "0 0 * * 0", region: "us-central1", timeoutSeconds: 540 },
  async () => {
    const db = admin.firestore();
    const groupsSnap = await db.collection("groups").get();

    // ISO week string for archiving e.g. "2024-W03"
    const weekLabel = DateTime.utc().toFormat("kkkk-'W'WW");

    for (const groupDoc of groupsSnap.docs) {
      const groupId = groupDoc.id;
      const groupData = groupDoc.data() as Record<string, unknown>;
      const weeklyXpBoard = (groupData.weeklyXpBoard as Record<string, number>) ?? {};
      const memberIds = (groupData.memberIds as string[]) ?? [];

      // Find top scorer
      let topScorerUid = "";
      let topScore = -1;
      for (const [uid, xp] of Object.entries(weeklyXpBoard)) {
        if (xp > topScore) {
          topScore = xp;
          topScorerUid = uid;
        }
      }

      try {
        if (topScorerUid && topScore >= 0) {
          // Get top scorer display name
          const topScorerSnap = await db.doc(`users/${topScorerUid}`).get();
          const topScorerName =
            (topScorerSnap.data()?.displayName as string) || "A group member";

          // Send FCM to all group members
          if (memberIds.length > 0) {
            await sendFcmToUsers(db, memberIds, {
              title: "Weekly leaderboard reset! 🏆",
              body: `${topScorerName} is this week's top reader!`,
              data: { type: "weekly_reset", groupId, topScorerUid },
            });
          }

          // Award Group MVP achievement
          await checkAndAwardAchievements(topScorerUid, db, { awardGroupMvp: true });
        }

        // Archive weekly XP snapshot (optional)
        if (Object.keys(weeklyXpBoard).length > 0) {
          await groupDoc.ref
            .collection("weeklyXpHistory")
            .doc(weekLabel)
            .set({
              week: weekLabel,
              board: weeklyXpBoard,
              topScorerUid: topScorerUid || null,
              topScore,
              snapshotAt: admin.firestore.Timestamp.now(),
            });
        }

        // Reset weeklyXpBoard: set all values to 0
        const resetBoard: Record<string, number> = {};
        for (const uid of Object.keys(weeklyXpBoard)) {
          resetBoard[uid] = 0;
        }

        await groupDoc.ref.update({ weeklyXpBoard: resetBoard });
      } catch (err) {
        console.error(`weeklyLeaderboardReset: failed for group ${groupId}`, err);
      }
    }
  }
);
