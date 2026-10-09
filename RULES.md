# Word Guess — Official Rules
_The Letterpress Printshop edition. This document is the authoritative source of truth. If the implementation conflicts with these rules, fix the implementation._

## 1. Objective
Guess the hidden word before your tries run out. Each guess earns letter-by-letter feedback: 🟩 green = right letter in the right spot, 🟨 amber = right letter in the wrong spot, ⬜ grey = the letter is not in the word at all. Solve the word to score points and grow your streak.

## 2. Setup
- Choose a difficulty: **Sprout** (4-letter words, 7 tries), **Classic** (5-letter words, 6 tries), **Master** (6-letter words, 6 tries — PRO).
- Choose a play mode: **Daily** (one date-seeded word per day), **Endless** (random words until one beats you), or **Versus** (pass-and-play, 2 players, 3 rounds each).
- The hidden word is drawn from the curated list for the chosen word length (`lib/engine/word_lists.dart`). Daily words are seeded by calendar date, so every player gets the same daily word.
- Each turn starts a **round timer** (3:00). The timer is visible in the header and turns red under 0:30.
- In Versus, each player gets their OWN hidden word each round (same difficulty, freshly drawn).

## 3. Turn order
- Solo (Daily / Endless): the single player takes every turn.
- Versus: players alternate — Player 1 round 1, Player 2 round 1, Player 1 round 2, Player 2 round 2, Player 1 round 3, Player 2 round 3. After a turn settles, the device is handed over with an explicit "Hand to {name}" step — turns never auto-advance.

## 4. Legal moves
- Type A–Z letters into the current row (on-screen keyboard or the letters row).
- Delete letters with ⌫ before submitting.
- Submit a guess with ⏎ / ENTER once the row is exactly the word length.
- **Any A–Z string of the correct length is a legal guess** — there is no dictionary check. Strategy, not vocabulary policing, decides the game.
- Pause at any time (pauses the round timer); resume, restart the word, or quit to the menu from the pause card.

## 5. Illegal moves
- Submitting a row shorter than the word length: rejected with a shake + invalid sound; no try is consumed.
- Typing more letters than the word length: extra keys are ignored.
- Typing during the letter-reveal animation or while paused: keys are ignored (the engine locks input until the reveal settles).
- Non A–Z input: ignored.

## 6. Captures
Not applicable — Word Guess has no pieces and no captures.

## 7. Special rules
- **Feedback marking** uses the standard two-pass rule: greens are assigned first (each consumes one occurrence of that letter in the target), then ambers are assigned from the remaining letter counts. Duplicate letters are handled correctly (e.g. target APPLE, guess APPLY → the second P is green, the Y is grey).
- **Keyboard memory**: once a letter's best-known mark is revealed, the on-screen key keeps the best mark (correct > present > absent) for the rest of the turn.
- **Round timer expiry** forfeits the turn: the word counts as failed, 0 points, streak resets (if the turn counted).
- **Daily claim**: only the FIRST daily attempt of the day per difficulty counts toward the streak and stats. Replays are allowed the same day but marked "replay for fun" and do not change the streak.
- **Reveal lock**: while letters are flipping, input is locked. The engine's watchdog guarantees the reveal always settles — even if a timer misfires, the watchdog force-applies the remaining marks and settles the turn.

## 8. Scoring
- Solved word: `(tries allowed − tries used + 1) × 10` points. A first-try solve on Classic scores 60; a last-try solve scores 10.
- Failed word (out of tries or timeout): 0 points.
- Endless: points accumulate across words until you fail or quit.
- Versus: points accumulate per player across their 3 rounds; the higher total wins.
- Streak: each counted solved word increments the win streak; a counted failed word resets it to 0. Best streak is remembered forever.

## 9. Winning conditions
- **Daily**: solve the word within the try limit and before the timer ends.
- **Endless**: every solved word is a win; the run ends on the first failed word (or when the player quits).
- **Versus**: after all 6 turns (3 rounds × 2 players), the player with the higher total score wins. A tie is a declared draw.

## 10. Draw conditions
- Versus can end in a tie when both players finish with equal total scores — shown as "It's a tie! 🤝".
- Solo modes have no draws.

## 11. AI strategy
Not applicable — Word Guess has no bots. All modes are human-played (Versus is pass-and-play).

## 12. Edge cases
- **Duplicate letters**: handled by two-pass marking (see §7); a guess can never show more greens+ambers for a letter than the target contains.
- **Timer expires mid-reveal**: the reveal always completes first (timer only forfeits during the `playing` phase); a solved-on-the-last-tick word still counts.
- **App backgrounded**: music pauses and the engine freezes (timer + reveal deadlines don't burn while paused); resume continues exactly where you left off.
- **App killed mid-turn**: the abandoned turn is discarded — no points, no streak change. The next launch starts fresh.
- **Pause during reveal**: the reveal animation freezes and resumes on unpause; the watchdog deadline is extended by the paused duration.
- **Both Versus players fail every round**: 0–0 is a valid tie.
- **Name editing**: names save on every keystroke and commit on focus loss; empty names fall back to defaults.
- **Store unconfigured**: Pro/tip buttons show "Available after store setup" — purchases are never faked.

## 13. Test cases
1. Type 5 letters on Classic, submit → tiles flip left-to-right with a tick per letter; input locks until all 5 marks show.
2. Target APPLE, guess APPLY → P,P green; A green; L green; Y grey (duplicate-letter rule).
3. Target APPLE, guess PEACH → P amber, E amber, A amber, C grey, H grey.
4. Submit with 3 letters → row shakes, invalid sound, no try consumed.
5. Solve on try 2 of 6 → 50 points, streak +1.
6. Fail all 6 tries → 0 points, streak reset, word revealed.
7. Timer hits 0:00 mid-typing → turn forfeits, timeout sound, word revealed.
8. Daily: play, win, replay same day → second run says "already claimed", streak unchanged.
9. Versus: 3 rounds each, handover cards show the correct next name; final card declares the right winner (and ties).
10. Pause mid-turn → timer frozen; resume → timer continues from the same second.
11. Kill the reveal (simulated): watchdog applies remaining marks within ~2.5s and settles — never stuck.
12. Rename players, restart app → names persist in the same slots and order.
13. Pro locked: Master difficulty, themes 5–12, tile styles 5–8, custom creator all route to the PRO screen; after unlock they apply immediately.
