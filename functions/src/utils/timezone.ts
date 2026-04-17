import { DateTime } from "luxon";

/**
 * Returns today's date string (YYYY-MM-DD) in the given IANA timezone.
 */
export function todayDateStr(timezone: string): string {
  return DateTime.now().setZone(timezone).toISODate() ?? DateTime.now().toISODate() ?? "";
}

/**
 * Returns a DateTime for today (start of day) in the given IANA timezone.
 */
export function todayInZone(timezone: string): DateTime {
  return DateTime.now().setZone(timezone).startOf("day");
}

/**
 * Returns the current DateTime in the given IANA timezone.
 */
export function nowInZone(timezone: string): DateTime {
  return DateTime.now().setZone(timezone);
}

/**
 * Parse a Firestore Timestamp or Date-like value into a Luxon DateTime in the given timezone.
 */
export function firestoreTimestampToDateTime(
  ts: { toDate?: () => Date; seconds?: number } | null | undefined,
  timezone: string
): DateTime | null {
  if (!ts) return null;
  let date: Date;
  if (typeof ts.toDate === "function") {
    date = ts.toDate();
  } else if (typeof ts.seconds === "number") {
    date = new Date(ts.seconds * 1000);
  } else {
    return null;
  }
  return DateTime.fromJSDate(date).setZone(timezone);
}

/**
 * Returns true if two DateTime objects represent the same calendar day.
 */
export function isSameDay(a: DateTime, b: DateTime): boolean {
  return a.hasSame(b, "day") && a.hasSame(b, "month") && a.hasSame(b, "year");
}

/**
 * Returns true if `a` is exactly one calendar day before `b`.
 */
export function isYesterday(a: DateTime, b: DateTime): boolean {
  const bMinus1 = b.minus({ days: 1 }).startOf("day");
  const aDay = a.startOf("day");
  return aDay.toMillis() === bMinus1.toMillis();
}
