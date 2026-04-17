import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

interface LeaveGroupRequest {
  groupId: string;
}

interface LeaveGroupResponse {
  success: true;
}

export const onUserLeaveGroup = onCall<LeaveGroupRequest, Promise<LeaveGroupResponse>>(
  { region: "us-central1" },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "You must be signed in to leave a group.");
    }

    const { groupId } = request.data;
    if (!groupId) {
      throw new HttpsError("invalid-argument", "groupId is required.");
    }

    const db = admin.firestore();
    const groupRef = db.doc(`groups/${groupId}`);

    // Validate group exists and user is a member
    const groupSnap = await groupRef.get();
    if (!groupSnap.exists) {
      throw new HttpsError("not-found", "Group not found.");
    }
    const groupData = groupSnap.data() as Record<string, unknown>;
    const memberIds = (groupData.memberIds as string[]) ?? [];

    if (!memberIds.includes(userId)) {
      throw new HttpsError("failed-precondition", "You are not a member of this group.");
    }

    // Get user's display name for system message
    const userSnap = await db.doc(`users/${userId}`).get();
    const displayName = (userSnap.data()?.displayName as string) || "A member";

    // -----------------------------------------------------------------------
    // Remove from group.memberIds and delete member sub-doc
    // -----------------------------------------------------------------------
    const batch = db.batch();

    batch.update(groupRef, {
      memberIds: admin.firestore.FieldValue.arrayRemove(userId),
    });

    batch.delete(groupRef.collection("members").doc(userId));

    // System message
    batch.set(groupRef.collection("messages").doc(), {
      senderId: "system",
      text: `${displayName} left the group`,
      type: "system",
      timestamp: admin.firestore.Timestamp.now(),
    });

    await batch.commit();

    // -----------------------------------------------------------------------
    // Detach user's active plan(s) from this group (set groupId = null)
    // Keep the plan active so they can continue solo
    // -----------------------------------------------------------------------
    const userPlansQuery = await db
      .collection("userPlans")
      .where("userId", "==", userId)
      .where("groupId", "==", groupId)
      .where("isComplete", "==", false)
      .get();

    if (!userPlansQuery.empty) {
      const planBatch = db.batch();
      for (const doc of userPlansQuery.docs) {
        planBatch.update(doc.ref, { groupId: null });
      }
      await planBatch.commit();
    }

    return { success: true };
  }
);
