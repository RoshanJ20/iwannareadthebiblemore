import { DateTime } from "luxon";
import { firestoreTimestampToDateTime, isSameDay, isYesterday } from "./timezone";

export type StreakTimestamp = { toDate?: () => Date; seconds?: number } | null | undefined;

export interface StreakUpdateResult {
  newStreak: number;
  longestStreak: number;
  frozeUsed: boolean;
  streakBroken: boolean;
  /** XP bonus earned from milestone, 0 if none */
  milestoneBonus: number;
}

/**
 * Computes the new streak value based on lastReadDate and current state.
 *
 * Rules:
 *  - lastReadDate was today  → no change (already counted)
 *  - lastReadDate was yesterday → streak + 1
 *  - lastReadDate was 2+ days ago (or null):
 *      - if streakFreezes > 0 → consume one freeze, streak continues (streak + 1)
 *      - else → reset to 1, streakBroken = true
 */
export function computeStreakUpdate(
  lastReadTimestamp: StreakTimestamp,
  currentStreak: number,
  longestStreak: number,
  streakFreezes: number,
  timezone: string
): StreakUpdateResult {
  const now = DateTime.now().setZone(timezone);
  const lastRead = firestoreTimestampToDateTime(lastReadTimestamp, timezone);

  let newStreak = currentStreak;
  let frozeUsed = false;
  let streakBroken = false;

  if (!lastRead) {
    // First ever read
    newStreak = 1;
  } else if (isSameDay(lastRead, now)) {
    // Already read today — no streak change
    newStreak = currentStreak;
  } else if (isYesterday(lastRead, now)) {
    // Consecutive day
    newStreak = currentStreak + 1;
  } else {
    // Missed at least one day
    if (streakFreezes > 0) {
      // Consume a freeze, streak continues
      frozeUsed = true;
      newStreak = currentStreak + 1;
    } else {
      newStreak = 1;
      streakBroken = true;
    }
  }

  const newLongest = Math.max(longestStreak, newStreak);

  // Milestone bonuses only trigger when the streak reaches exactly these values
  const { streakMilestoneBonus } = require("./xp");
  const milestoneBonus: number = streakMilestoneBonus(newStreak);

  return {
    newStreak,
    longestStreak: newLongest,
    frozeUsed,
    streakBroken,
    milestoneBonus,
  };
}
