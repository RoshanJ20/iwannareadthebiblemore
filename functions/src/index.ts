import * as admin from "firebase-admin";

// Initialize Firebase Admin SDK once
admin.initializeApp();

// ─── Firestore triggers ───────────────────────────────────────────────────────
export { onReadingComplete } from "./onReadingComplete";
export { onNudgeSent } from "./onNudgeSent";
export { onPlanComplete } from "./onPlanComplete";

// ─── Scheduled functions ──────────────────────────────────────────────────────
export { dailyStreakCheck } from "./dailyStreakCheck";
export { weeklyLeaderboardReset } from "./weeklyLeaderboardReset";
export { cleanupOldNudges } from "./cleanupOldNudges";

// ─── Callable functions ───────────────────────────────────────────────────────
export { onAchievementCheck } from "./onAchievementCheck";
export { xpStorePurchase } from "./xpStorePurchase";
export { onUserLeaveGroup } from "./onUserLeaveGroup";
