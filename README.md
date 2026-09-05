# Soccer Substitution Tracker (6U Match Assistant)

A Flutter application designed for youth soccer coaches (specifically tailored for 6U 4v4 format) to effortlessly track player playing time, manage game clocks and break timers, receive substitution recommendations, and handle mid-game changes (injuries, late arrivals, departures).

---

## Key Features

1. **Configurable Game & Break Timers (Defaults for 6U Soccer)**:
   - **4 Quarters** of **10 minutes** each
   - **2-minute quarter breaks** (between Q1 & Q2, Q3 & Q4)
   - **4-minute halftime break** (between Q2 & Q3)
   - **4 on 4** format on the pitch
   - All rules (period count, minutes, break times, field size, sub shift target) are fully customizable prior to kickoff.

2. **Player Playing Time & Shift Tracking**:
   - Master game timer synchronized with individual player timers.
   - When a player is on the field, their **current continuous shift** and **total match playing time** increment second-by-second.
   - When a player is on the bench, their rest timer increments, and playing timers are paused.
   - Timers automatically freeze during quarter breaks and halftime.

3. **Tappable Substitution & Real-Time Smart Sorting**:
   - **Single-Tap Toggle**: Tap any player card to immediately move them between Field and Bench.
   - **On Field (In)**: Automatically sorted with the player who has been playing the longest in this shift at the top, clearly signaling who needs rest.
   - **Bench (Out)**: Automatically sorted with the player who has the least total match time at the top, clearly signaling who should be rotated in next to ensure equal playing time.
   - **1-Tap Quick Sub Banner**: Automatically detects the longest-running field player and the least-played bench player and presents a 1-tap "SWAP" button.

4. **Mid-Game Roster Management**:
   - **Injury / Sidelined Handling**: Mark a player as injured/sidelined with an optional note. Their shift timer stops and they are placed in a dedicated sidelined section so they aren't accidentally put in. One tap returns them to the bench when recovered.
   - **Late Arrivals**: Tap "+ Add Player Mid-Game" to add any roster player who arrived late, or create a guest player on the fly (placed directly on bench or field).
   - **Left Early**: Remove a player who had to leave early without losing their recorded playing time.
   - **Time Corrections**: Quick adjustments (+1 min, -1 min, +2 min, etc.) if a substitution was made earlier without tapping.

5. **Notifications & Alerts**:
   - Audio chime and haptic feedback when a quarter ends, when breaks end, and when sub shift targets are reached.
   - Visual alerts prompting the coach when it's time for breaks or when a period is about to resume.

6. **Post-Match Report & Fairness Distribution**:
   - Comprehensive playing time distribution breakdown per player with percentages and progress bars.
   - Match event timeline logging quarters, breaks, subs, and injury events.
   - Match history persistence using local storage (`shared_preferences`).

---

## Getting Started

```bash
cd soccersubstitutiontracker
flutter pub get
flutter run
```

To run tests:
```bash
flutter test
```