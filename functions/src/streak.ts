import * as admin from 'firebase-admin';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { checkAchievements } from './achievements';

const db = admin.firestore();

export const onReadingComplete = onDocumentUpdated('userPlans/{userPlanId}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;
  if (before.todayRead === after.todayRead || !after.todayRead) return;

  const userId = after.userId as string;
  const userRef = db.collection('users').doc(userId);
  const groupId = (after.groupId as string | null) ?? null;

  await db.runTransaction(async (tx) => {
    const userDoc = await tx.get(userRef);
    const user = userDoc.data() || {};
    const today = new Date().toISOString().split('T')[0];
    const lastReadDate = (user.lastReadDate as admin.firestore.Timestamp | undefined)
      ?.toDate()?.toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];

    let currentStreak: number = user.currentStreak || 0;
    let longestStreak: number = user.longestStreak || 0;
    const isExtra = lastReadDate === today;

    if (!isExtra) {
      if (lastReadDate === yesterday) {
        currentStreak += 1;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > longestStreak) longestStreak = currentStreak;
    }

    const xpEarned = isExtra ? 20 : 50;
    tx.update(userRef, {
      currentStreak,
      longestStreak,
      lastReadDate: admin.firestore.Timestamp.now(),
      xpTotal: admin.firestore.FieldValue.increment(xpEarned),
      xpBalance: admin.firestore.FieldValue.increment(xpEarned),
    });
    tx.set(userRef.collection('readingLog').doc(today), {
      date: today,
      bookId: after.bookId || '',
      xpEarned,
    });

    const milestoneXp =
      currentStreak === 7 ? 100 :
      currentStreak === 30 ? 400 :
      currentStreak === 100 ? 1500 : 0;

    if (milestoneXp > 0) {
      tx.update(userRef, {
        xpTotal: admin.firestore.FieldValue.increment(milestoneXp),
        xpBalance: admin.firestore.FieldValue.increment(milestoneXp),
      });
    }
  });

  await checkAchievements(userId);

  if (groupId) {
    await db.collection('groups').doc(groupId)
      .collection('members').doc(userId)
      .update({ todayRead: true });
  }
});

export const dailyStreakCheck = onSchedule('every 1 minutes', async () => {
  const now = new Date();
  const users = await db.collection('users').get();
  const batch = db.batch();

  for (const doc of users.docs) {
    const user = doc.data();
    const timezone: string = user.timezone || 'UTC';
    const userTime = new Date(now.toLocaleString('en-US', { timeZone: timezone }));
    if (userTime.getHours() !== 0 || userTime.getMinutes() > 1) continue;

    const lastRead = (user.lastReadDate as admin.firestore.Timestamp | undefined)
      ?.toDate()?.toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    const today = new Date().toISOString().split('T')[0];

    if (lastRead === yesterday || lastRead === today) continue;

    if ((user.streakFreezes || 0) > 0) {
      batch.update(doc.ref, { streakFreezes: admin.firestore.FieldValue.increment(-1) });
    } else if ((user.currentStreak || 0) > 0) {
      batch.update(doc.ref, { currentStreak: 0 });
    }
  }
  await batch.commit();
});
