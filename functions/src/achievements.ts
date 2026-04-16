import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function checkAchievements(userId: string): Promise<void> {
  const userRef = db.collection('users').doc(userId);
  const [userDoc, achievementsSnap, groupsSnap] = await Promise.all([
    userRef.get(),
    userRef.collection('achievements').get(),
    db.collection('groups').where('memberIds', 'array-contains', userId).limit(1).get(),
  ]);
  const user = userDoc.data() || {};
  const earned = new Set(achievementsSnap.docs.map((d) => d.id));
  const batch = db.batch();

  const grant = (id: string) => {
    if (!earned.has(id)) {
      batch.set(userRef.collection('achievements').doc(id), {
        achievementId: id,
        earnedAt: admin.firestore.Timestamp.now(),
      });
    }
  };

  if ((user.currentStreak || 0) >= 7) grant('first_flame');
  if ((user.currentStreak || 0) >= 30) grant('month_of_faith');
  if (!groupsSnap.empty) grant('better_together');

  const genesisProgress = await userRef.collection('bookProgress').doc('GEN').get();
  if (genesisProgress.exists && ((genesisProgress.data()?.chapters as unknown[]) || []).length >= 50) {
    grant('in_the_beginning');
  }

  await batch.commit();
}
