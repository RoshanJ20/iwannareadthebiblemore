import * as admin from "firebase-admin";

export interface FcmPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Sends a single FCM message to a specific device token.
 * Silently ignores missing/invalid tokens.
 */
export async function sendFcm(token: string | null | undefined, payload: FcmPayload): Promise<void> {
  if (!token) return;
  try {
    await admin.messaging().send({
      token,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data ?? {},
    });
  } catch (err) {
    // Log but do not propagate — FCM errors should not fail the function
    console.error(`FCM send failed for token ${token?.slice(0, 10)}...:`, err);
  }
}

/**
 * Sends FCM to multiple tokens concurrently. Ignores missing/invalid tokens.
 */
export async function sendFcmMulti(
  tokens: (string | null | undefined)[],
  payload: FcmPayload
): Promise<void> {
  const validTokens = tokens.filter((t): t is string => typeof t === "string" && t.length > 0);
  if (validTokens.length === 0) return;
  await Promise.all(validTokens.map((token) => sendFcm(token, payload)));
}

/**
 * Fetches FCM tokens for a list of userIds and sends the message to all of them.
 */
export async function sendFcmToUsers(
  db: admin.firestore.Firestore,
  userIds: string[],
  payload: FcmPayload
): Promise<void> {
  if (userIds.length === 0) return;
  const snapshots = await Promise.all(
    userIds.map((uid) => db.doc(`users/${uid}`).get())
  );
  const tokens = snapshots.map((snap) => snap.data()?.fcmToken as string | undefined);
  await sendFcmMulti(tokens, payload);
}
