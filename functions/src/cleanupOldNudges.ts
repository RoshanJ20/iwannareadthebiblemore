import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";

/**
 * Runs every hour. Deletes all nudge documents older than 24 hours.
 */
export const cleanupOldNudges = onSchedule(
  { schedule: "0 * * * *", region: "us-central1", timeoutSeconds: 300 },
  async () => {
    const db = admin.firestore();
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 24 * 60 * 60 * 1000)
    );

    const oldNudgesSnap = await db
      .collection("nudges")
      .where("sentAt", "<", cutoff)
      .get();

    if (oldNudgesSnap.empty) {
      console.log("cleanupOldNudges: no stale nudges to delete");
      return;
    }

    // Firestore batch supports up to 500 operations
    const BATCH_SIZE = 499;
    const docs = oldNudgesSnap.docs;
    let deleted = 0;

    for (let i = 0; i < docs.length; i += BATCH_SIZE) {
      const batch = db.batch();
      const chunk = docs.slice(i, i + BATCH_SIZE);
      for (const doc of chunk) {
        batch.delete(doc.ref);
      }
      await batch.commit();
      deleted += chunk.length;
    }

    console.log(`cleanupOldNudges: deleted ${deleted} stale nudges`);
  }
);
