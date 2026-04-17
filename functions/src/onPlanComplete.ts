import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { checkAndAwardAchievements } from "./onAchievementCheck";
import { sendFcmToUsers } from "./utils/fcm";
import { XP } from "./utils/xp";

export const onPlanComplete = onDocumentWritten(
  { document: "userPlans/{userPlanId}", region: "us-central1" },
  async (event) => {
    const before = event.data?.before?.data() as Record<string, unknown> | undefined;
    const after = event.data?.after?.data() as Record<string, unknown> | undefined;

    // Only fire when isComplete changes from false/missing to true
    if (!after) return;
    if (after.isComplete !== true) return;
    if (before?.isComplete === true) return;

    const db = admin.firestore();
    const userId = after.userId as string;
    const planId = after.planId as string;
    const groupId = (after.groupId as string | null | undefined) ?? null;

    if (!userId) {
      console.error("onPlanComplete: missing userId");
      return;
    }

    // -----------------------------------------------------------------------
    // Award +500 XP
    // -----------------------------------------------------------------------
    const userRef = db.doc(`users/${userId}`);
    await userRef.update({
      xpTotal: admin.firestore.FieldValue.increment(XP.PLAN_COMPLETE),
      xpBalance: admin.firestore.FieldValue.increment(XP.PLAN_COMPLETE),
    });

    // -----------------------------------------------------------------------
    // Update weeklyXpBoard in group
    // -----------------------------------------------------------------------
    if (groupId) {
      try {
        await db.doc(`groups/${groupId}`).update({
          [`weeklyXpBoard.${userId}`]: admin.firestore.FieldValue.increment(XP.PLAN_COMPLETE),
        });
      } catch (err) {
        console.error(`onPlanComplete: failed to update weeklyXpBoard for group ${groupId}`, err);
      }

      // Check if ALL group members have completed this plan
      try {
        const groupSnap = await db.doc(`groups/${groupId}`).get();
        const groupData = groupSnap.data() as Record<string, unknown> | undefined;
        const memberIds = (groupData?.memberIds as string[]) ?? [];

        if (memberIds.length > 0) {
          // Query userPlans for this planId and groupId
          const planCompletionQuery = await db
            .collection("userPlans")
            .where("planId", "==", planId)
            .where("groupId", "==", groupId)
            .get();

          const completedUserIds = new Set(
            planCompletionQuery.docs
              .filter((d) => d.data().isComplete === true)
              .map((d) => d.data().userId as string)
          );

          const allComplete = memberIds.every((id) => completedUserIds.has(id));

          if (allComplete) {
            // Get plan name for celebration message
            let planName = "the reading plan";
            try {
              const planSnap = await db.doc(`plans/${planId}`).get();
              planName = (planSnap.data()?.name as string) || planName;
            } catch {
              // ignore
            }

            await sendFcmToUsers(db, memberIds, {
              title: "Your group finished! 🎉",
              body: `Your group finished ${planName}! Congratulations!`,
              data: { type: "plan_complete_group", groupId, planId },
            });
          }
        }
      } catch (err) {
        console.error("onPlanComplete: group completion check failed", err);
      }
    }

    // -----------------------------------------------------------------------
    // Achievement check
    // -----------------------------------------------------------------------
    try {
      await checkAndAwardAchievements(userId, db);
    } catch (err) {
      console.error("onPlanComplete: achievement check failed", err);
    }
  }
);
