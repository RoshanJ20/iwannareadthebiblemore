import * as admin from 'firebase-admin';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';

const db = admin.firestore();

export const onNudgeSent = onDocumentCreated('nudges/{nudgeId}', async (event) => {
  const nudge = event.data?.data();
  if (!nudge) return;
  const { fromUserId, toUserId, groupId } = nudge;

  // Rate limit: 1 nudge per sender→recipient pair per 24h
  const dayAgo = new Date(Date.now() - 86400000);
  const pairSnap = await db.collection('nudges')
    .where('fromUserId', '==', fromUserId)
    .where('toUserId', '==', toUserId)
    .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(dayAgo))
    .get();
  if (pairSnap.docs.length > 1) {
    await event.data?.ref.delete();
    return;
  }

  // Rate limit: max 5 nudges per sender per day
  const totalSnap = await db.collection('nudges')
    .where('fromUserId', '==', fromUserId)
    .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(dayAgo))
    .get();
  if (totalSnap.docs.length > 5) {
    await event.data?.ref.delete();
    return;
  }

  // Deliver FCM notification
  const toUser = await db.collection('users').doc(toUserId).get();
  const fcmToken = toUser.data()?.fcmToken;
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: 'Someone nudged you! 👋',
        body: "Time to read today's passage.",
      },
      data: { type: 'nudge', groupId: groupId || '' },
    });
  }
});

export const onUserLeaveGroup = onCall(async (request) => {
  const userId = request.auth?.uid;
  if (!userId) throw new Error('Unauthenticated');
  const { groupId } = request.data as { groupId: string };

  const groupRef = db.collection('groups').doc(groupId);
  const batch = db.batch();
  batch.update(groupRef, {
    memberIds: admin.firestore.FieldValue.arrayRemove(userId),
  });
  batch.delete(groupRef.collection('members').doc(userId));
  batch.set(groupRef.collection('messages').doc(), {
    senderId: 'system',
    text: 'A member left the group.',
    type: 'system',
    timestamp: admin.firestore.Timestamp.now(),
  });
  await batch.commit();

  // Detach user's active plans from this group
  const plansSnap = await db.collection('userPlans')
    .where('userId', '==', userId)
    .where('groupId', '==', groupId)
    .get();
  const planBatch = db.batch();
  plansSnap.docs.forEach((doc) => planBatch.update(doc.ref, { groupId: null }));
  await planBatch.commit();

  return { success: true };
});
