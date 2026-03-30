# iwannareadthebiblemore — App Design Spec
**Date:** 2026-03-30
**Status:** Approved

---

## 1. Vision

A gamified Bible reading app for iOS and Android built with Flutter. The core bet: streaks, group accountability, and a lamb mascot combine to make daily Bible reading feel like something you genuinely don't want to miss. Inspired by Duolingo's engagement mechanics. Free forever, mission-driven.

Primary audience: yourself and your close circle first, then broad Christian audience over time.

---

## 2. The Three Pillars

The app only works because all three exist together:

1. **Streak + XP loop** — reading every day earns XP and keeps a streak. Missing hurts. The lamb reacts.
2. **Group plans** — you read *with* people. Your group can see who's done and who hasn't. One-tap nudge.
3. **Community over clout** — no public feed, no followers. Accountability groups of 2–20, doing plans together.

---

## 3. Tech Stack

| Layer | Choice | Reason |
|---|---|---|
| Mobile framework | Flutter | Single codebase for iOS + Android |
| State management | Riverpod | Reactive, testable, clean provider pattern |
| Navigation | go_router | Deep link support, notification routing |
| Local storage | Hive | Offline Bible text, notes, highlights cache |
| Backend | Firebase | Auth, Firestore, Cloud Functions, FCM, Storage |
| Bible content | API.Bible (American Bible Society) | 2,500+ translations, free tier (5k req/day) |
| Bible fallback | YouVersion deep link | For translations not in API.Bible |
| Bundled offline | KJV + WEB | Included in app binary, zero network needed |
| Mascot animations | Lottie | Smooth 60fps animations for mascot states |
| Verse sharing | share_plus + custom renderer | Auto-generated verse card images |

---

## 4. App Architecture

Feature-first clean architecture. Five feature modules, each with `presentation/`, `domain/`, and `data/` layers. Features communicate only through domain interfaces — no cross-feature direct calls.

```
lib/
  features/
    bible/          # reader, search, notes, bookmarks, audio
    gamification/   # streak, xp, mascot, achievements, xp store
    groups/         # plans, check-in, chat, nudge, leaderboard
    profile/        # auth, stats, friends, settings, history
    notifications/  # FCM, local, widgets, deep links
  core/
    firebase/       # shared Firebase clients
    bible_content/  # API.Bible client + Hive cache layer
    design_system/  # shared widgets, theme, haptics, animations
```

---

## 5. Firestore Data Model

### `/users/{userId}`
```
displayName, photoUrl, fcmToken
xpTotal: number          // lifetime XP — used for leaderboard, never decreases
xpBalance: number        // spendable XP — decreases when buying from XP store
currentStreak: number
longestStreak: number
lastReadDate: timestamp
streakFreezes: number    // 0–3 held at a time
defaultTranslation: string
dailyGoalMinutes: number
reminderTime: string     // "07:30"
theme: string
friendIds: string[]
pendingFriendIds: string[]
createdAt: timestamp

subcollections:
  /annotations/{id}     // highlights + notes: bookId, chapterId, verseNumber, type, color, text
  /readingLog/{dateStr} // one doc per day read: date, bookId, chapterId, planId, xpEarned
  /achievements/{id}    // earned badges: achievementId, earnedAt
```

### `/groups/{groupId}`
```
name, description, creatorId
inviteCode: string       // 6-char unique code
memberIds: string[]      // max 20
activePlanId: string
groupStreak: number
lastAllReadDate: timestamp
weeklyXpBoard: map       // {userId: weeklyXp} — reset every Sunday
createdAt: timestamp

subcollections:
  /members/{userId}       // denormalized: displayName, photoUrl, todayRead: bool, streak
  /messages/{id}          // chat: senderId, text, type (message|reaction|system), timestamp
  /dailyStatus/{dateStr}  // snapshot of who read on each day
```

### `/plans/{planId}`
```
name, description, isCustom, creatorId  // creatorId null = official plan
totalDays: number
tags: string[]           // ["gospels", "30-day", "psalms"]
coverEmoji: string
readings: [{day, book, chapter, title}]
createdAt: timestamp
```

### `/userPlans/{userPlanId}`
```
userId, planId, groupId  // groupId null = solo plan
startDate: timestamp
currentDay: number
completedDays: number[]
isComplete: bool
completedAt: timestamp
todayChapter: string     // denormalized for home screen
todayRead: bool
```

### `/nudges/{nudgeId}`
```
fromUserId, toUserId, groupId
sentAt: timestamp
opened: bool
// TTL: auto-deleted after 24h via Cloud Function
```

### `/verseOfDay/{dateStr}`
```
date, book, chapter, verse, text, reference
// Pre-populated 1 year ahead
```

### `/announcements/{id}`
```
title, body, targetAll: bool, activeFrom, activeTo
```

---

## 6. Cloud Functions

| Function | Trigger | What it does |
|---|---|---|
| `onReadingComplete` | Firestore write: `userPlans.todayRead = true` | Updates streak, awards XP (xpTotal + xpBalance), checks achievements, updates group/members daily status, triggers group activity FCM |
| `dailyStreakCheck` | Scheduled: midnight per user timezone | Users who haven't read → consume streak freeze if available → else reset streak to 0. Sends at-risk push 2hrs before midnight. |
| `onNudgeSent` | Firestore write: new nudge doc | Delivers FCM to nudged user. If they read within 24h → awards +15 XP to sender. Auto-deletes nudge after 24h. |
| `onAchievementCheck` | Called by `onReadingComplete` | Evaluates all achievement conditions against user state. Writes to `/achievements` if newly earned. Sends celebration FCM. |
| `weeklyLeaderboardReset` | Scheduled: Sunday midnight | Snapshots `weeklyXpBoard`, resets to 0, sends "this week's top reader" notification to each group. |
| `onPlanComplete` | Firestore write: `userPlans.isComplete = true` | Awards +500 XP to all group members. Triggers group celebration. Checks plan-complete achievements. |
| `xpStorePurchase` | Callable function | Validates purchase (sufficient xpBalance), deducts xpBalance, grants item (freeze or cosmetic). Atomic transaction. |

---

## 7. Gamification System

### XP Economy

| Action | XP Earned |
|---|---|
| Read today's plan passage | +50 |
| Read extra (beyond plan) | +20 |
| Add a verse note | +10 |
| Highlight a verse | +5 |
| Nudge someone who then reads | +15 |
| 7-day streak milestone | +100 |
| 30-day streak milestone | +400 |
| 100-day streak milestone | +1,500 |
| Complete a reading plan | +500 |
| Complete a full Bible book | +200 |

**Two XP values:**
- `xpTotal` — lifetime accumulated, used for leaderboard ranking and displayed on profile. Never decreases.
- `xpBalance` — current spendable balance. Decreases on XP store purchases.

### XP Store

| Item | XP Cost |
|---|---|
| Streak freeze (1x) | 200 XP |
| Mascot outfit — basic (3 available) | 500 XP |
| Mascot outfit — rare (3 available) | 1,000 XP |
| Mascot outfit — legendary (2 available) | 2,000 XP |

### Streak Mechanics
- Read today's plan passage before midnight (user's timezone) = +1 day
- Streak freeze: max 3 held. Auto-consumes if you miss a day. Earned by purchasing with XP.
- At-risk push notification: 2 hours before midnight if unread.
- Streak visual tiers: grey (0) → orange (1–6) → red (7–29) → gold (30–99) → diamond blue (100+)
- No levels or titles. Streak + XP total are the sole progression indicators.

### The Lamb Mascot
Character: a small, expressive lamb. Animated via Lottie.

| State | Trigger |
|---|---|
| Idle | Default, app open |
| Excited | Streak is 7+ days and you've read today |
| Celebrating | Milestone reached (streak/plan/achievement) |
| Worried | Streak at risk (< 2hrs until midnight, unread) |
| Sad | Streak just broken |
| Sleeping | App not opened in 3+ days |
| On fire | Streak 100+ days |
| Outfit displayed | Active cosmetic from XP store |

### Achievements (Phase 1 — 8 badges)
| Badge | Trigger |
|---|---|
| First Flame | 7-day streak |
| Month of Faith | 30-day streak |
| Better Together | Join first group |
| Keeper's Nudge | Nudge 10 friends (who read) |
| In The Beginning | Read all of Genesis |
| Red Letters | Read all 4 Gospels |
| Group MVP | Top reader in a group for 1 week |
| Multiplier | Invite 3 friends who join |

---

## 8. Navigation & Screen Map

### Onboarding (first-time only)
Meet the Lamb → Set daily goal → Pick first plan → Find friends (invite/skip) → Set reminder time → Home

### Bottom Navigation (5 tabs)

**Home**
- Mascot + streak count
- Today's reading card (plan, day, chapter, CTA)
- Group check-in status (who read / who hasn't → tap to nudge)
- Verse of the day
- Recent achievement toast

**Read**
- Bible browser (book → chapter list)
- Chapter reader (full screen, haptic on verse long-press)
- Verse detail sheet (highlight, note, share)
- Search
- Bookmarks list
- Audio mode toggle

**Groups**
- My groups list
- Group detail (members, progress, today's check-in feed)
- Daily check-in view
- Group chat + reactions
- Weekly XP leaderboard
- Create group / Join by code

**Plans**
- Pre-built plan library (5 in Phase 1, 20 in Phase 2)
- Plan detail + preview
- Create custom plan (Phase 2)
- My active plans + progress
- Plan completion celebration screen

**Profile**
- Stats (total XP, current streak, longest streak, chapters read)
- Year heatmap (GitHub-style reading calendar)
- Achievement gallery
- Friends list + add friends
- Lamb cosmetics (XP store + equipped outfit)
- Settings

### Settings
- Notifications: reminder time, streak alerts, group activity, milestones
- Reading: default translation, font size, font family, theme
- Privacy: profile visibility, who can nudge me, show streak to friends
- Account: sign in/out, export notes, delete account, licenses

---

## 9. Notifications & Widgets

### Push Notifications (FCM)
| Type | Trigger |
|---|---|
| Daily reminder | User-set time, if unread |
| Streak at-risk | 2hrs before midnight, if unread |
| Friend nudge | When someone taps nudge on you |
| Group activity | "James just finished today's reading" |
| Milestone | "You hit 30 days! 🎉" |
| Plan completion | Group finishes a plan together |
| Weekly leaderboard | Sunday — "You're #1 in your group this week!" |

### Widgets
- **Home screen widget (iOS + Android):** Streak count + today's verse + "Read" CTA button
- **Lock screen widget (iOS 16+):** Streak count + flame icon

All deep links open to the correct screen (today's chapter, group, profile).

---

## 10. Bible Content Strategy

1. **Bundled in binary:** KJV + WEB (public domain). Zero network dependency for these.
2. **API.Bible:** Primary source for all other translations. Fetch on first request, cache in Hive for offline use. Free tier: 5k req/day. Paid tier for scale.
3. **YouVersion deep link:** Fallback for any translation not available in API.Bible. Opens in YouVersion app (if installed) or browser.
4. **User notes/highlights:** Stored in Firestore under `users/{id}/annotations`. Sync across devices.

---

## 11. Offline Strategy

The app must work with no internet connection for core reading functionality.

- KJV + WEB: always available (bundled)
- Other translations: cached in Hive after first fetch, available offline thereafter
- User annotations: written to Hive first (optimistic), synced to Firestore when online
- Streak + XP: calculated client-side optimistically, confirmed by Cloud Function on next sync
- Group check-in: queued locally, synced on reconnect

---

## 12. Verse Image Sharing

Tapping "share" on any verse generates a branded image card:
- Verse text + reference
- App name / logo
- Selectable background (light, dark, gradient)
- Optimised for Instagram Stories (9:16) and square (1:1)
- Exported via `share_plus` to any app (WhatsApp, Instagram, Messages, etc.)

---

## 13. Haptic Feedback

Every meaningful action triggers a haptic pulse calibrated to action weight:

| Action | Haptic |
|---|---|
| Tap "Read Now" CTA | Medium impact |
| Check-in / mark read | Heavy impact + success pattern |
| Nudge a friend | Light impact |
| Achievement unlocked | Custom pattern (3 beats) |
| Streak milestone | Heavy + vibration pattern |
| Streak broken | Single dull impact |
| XP store purchase | Medium impact |

---

## 14. Delivery Phases

### Phase 1 — The Core Loop
Everything needed for the daily habit: Bible reader (KJV + WEB offline, API.Bible for others), chapter reader with highlights + notes, streaks, XP (earn + spend), streak freezes, Lamb mascot with 6 states + 2 outfits, 5 pre-built plans, groups (create/join), daily check-in feed, one-tap nudge, weekly friends leaderboard, group streak, all push notifications, home + lock screen widgets, Duolingo-style onboarding, Sign in with Apple + Google, profile with stats + heatmap, 8 achievements, verse image sharing, offline-first, deep links, haptics throughout.

### Phase 2 — Depth
Custom plan creation, audio Bible (TTS + recorded), full group chat, 20 pre-built plans, full achievement set (12 badges), 10 mascot outfits in XP store, reading history per book, iPad two-panel layout, accessibility (dynamic type, VoiceOver/TalkBack), rich verse-of-day notification, multiple simultaneous plans, export notes, Lottie-animated mascot celebrations, App Store + Play Store launch.

### Phase 3 — Scale
Public plan discovery, community challenges (church-wide), devotionals + reflection prompts, Apple Watch companion, cross-reference viewer, Bible dictionary.

### Explicitly Out of Scope
Paid tiers, devotional content licensing, public social feed, user-generated commentary, web app, denomination-specific content, live streaming, admin/church dashboard.

---

## 15. Key Design Decisions & Rationale

| Decision | Rationale |
|---|---|
| No levels or progression titles | Felt gamey and religious-title names were divisive. XP total + streak are cleaner signals of dedication. |
| XP is a currency, not just a score | Buying streak freezes + mascot outfits gives XP purpose and creates meaningful spending decisions. |
| Groups max 20 people | Accountability works at small scale. Large groups dilute the "my friends can see me" pressure. |
| Community-first (not public feed) | Avoids toxic social media patterns. Intimacy drives accountability. |
| Streak logic server-side only | Prevents device clock manipulation. Trust must be maintained for leaderboards to feel fair. |
| KJV + WEB bundled | Guarantees offline reading from day 1 with no API costs. |
| Lamb mascot | Universal, gentle, biblically resonant. Cries when you break streak — more emotionally effective than a neutral character. |
| Free forever | Mission-driven. Removes paywall friction from forming habits. |
