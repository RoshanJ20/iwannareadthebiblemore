import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { sendFcm } from "./utils/fcm";

const MAX_NUDGES_TO_SAME_USER_PER_DAY = 1;
const MAX_NUDGES_FROM_USER_PER_DAY = 5;

export const onNudgeSent = onDocumentWritten(
  { document: "nudges/{nudgeId}", region: "us-central1" },
  async (event) => {
    // Only trigger on creation (before = no data)
    if (event.data?.before?.exists) return;
    if (!event.data?.after?.exists) return;

    const nudge = event.data.after.data() as Record<string, unknown>;
    const nudgeRef = event.data.after.ref;

    const fromUserId = nudge.fromUserId as string;
    const toUserId = nudge.toUserId as string;
    const sentAt = nudge.sentAt as admin.firestore.Timestamp;

    if (!fromUserId || !toUserId) {
      console.error("onNudgeSent: missing fromUserId or toUserId");
      await nudgeRef.delete();
      return;
    }

    const db = admin.firestore();
    const oneDayAgo = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    );

    // -----------------------------------------------------------------------
    // Rate limit 1: max 1 nudge from this user to the same recipient per 24h
    // -----------------------------------------------------------------------
    const toSameUserQuery = await db
      .collection("nudges")
      .where("fromUserId", "==", fromUserId)
      .where("toUserId", "==", toUserId)
      .where("sentAt", ">=", oneDayAgo)
      .get();

    // The current nudge is already written, so count > 1 means duplicate
    if (toSameUserQuery.size > MAX_NUDGES_TO_SAME_USER_PER_DAY) {
      console.log(`Rate limit: ${fromUserId} already nudged ${toUserId} in last 24h`);
      await nudgeRef.delete();
      return;
    }

    // -----------------------------------------------------------------------
    // Rate limit 2: max 5 nudges from this user total per 24h
    // -----------------------------------------------------------------------
    const totalFromUserQuery = await db
      .collection("nudges")
      .where("fromUserId", "==", fromUserId)
      .where("sentAt", ">=", oneDayAgo)
      .get();

    if (totalFromUserQuery.size > MAX_NUDGES_FROM_USER_PER_DAY) {
      console.log(`Rate limit: ${fromUserId} exceeded 5 nudges in last 24h`);
      await nudgeRef.delete();
      return;
    }

    // -----------------------------------------------------------------------
    // Mark xpAwarded = false (to be set true when toUserId reads)
    // Set TTL for cleanup (sentAt + 24h)
    // -----------------------------------------------------------------------
    const ttl = admin.firestore.Timestamp.fromDate(
      new Date((sentAt?.toMillis() ?? Date.now()) + 24 * 60 * 60 * 1000)
    );

    await nudgeRef.update({
      xpAwarded: false,
      opened: false,
      ttl,
    });

    // -----------------------------------------------------------------------
    // Send FCM to recipient
    // -----------------------------------------------------------------------
    const toUserSnap = await db.doc(`users/${toUserId}`).get();
    const toUser = toUserSnap.data() as Record<string, unknown> | undefined;
    const toUserFcmToken = toUser?.fcmToken as string | undefined;

    await sendFcm(toUserFcmToken, {
      title: "Someone wants you to read! 📖",
      body: "Tap to open today's reading.",
      data: {
        type: "nudge",
        nudgeId: nudgeRef.id,
        fromUserId,
        groupId: (nudge.groupId as string) ?? "",
      },
    });
  }
);
