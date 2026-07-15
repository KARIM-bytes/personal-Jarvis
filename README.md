# Jarvis — Your Personal Guide (Flutter)

A calm, goal-aware Android app. Instead of watching your screen in real time, it
reads the phone's own **aggregated usage** (the numbers Digital Wellbeing
already collects), compares each app you care about against a **daily budget**,
and — when you go over — has an **AI tutor** message you, tying the overuse back
to the goals you set. No overlay, no voice, no taking over your screen.

> Started as a real-time "nagger" (see history); reworked into a personal guide:
> your usage data + your life goals → a thoughtful nudge, delivered as a
> notification.

## The loop

```
Foreground service (background isolate)
  every 15 min ─► read today's usage totals (UsageStats / Digital Wellbeing)
              ─► GuideBrain: is any watched app over its daily budget?
              ─► if so: AI tutor writes a nudge (usage + your goals)
              ─► deliver as a notification  ─► report to the UI's message log
```

## What it does

- Reads **aggregated daily usage** per app via Android UsageStats — not live
  foreground spying.
- **Hybrid goals**: free-text life goals *plus* a list of "distraction" apps,
  each with a daily time budget.
- **Threshold-triggered**: the AI messages you when a flagged app crosses its
  budget (again, once, if you double it) — capped and cooled-down so it never
  spams.
- **Tutor voice**: messages reference *your* goals. Uses an Anthropic model if
  you add a key; otherwise built-in lines so it always works.
- **Delivery = a notification.** No TTS, no overlay, no screen control.
- In-app dashboard: today's usage vs budget per app, editable goals, and a
  message history.

## Project layout

```
lib/
  config/app_config.dart          # intervals, budgets, prompt, prefs keys
  models/                         # WatchedApp, AppUsage/UsageSnapshot,
                                  #   GuideMessage, AppMessageState
  services/
    usage_stats_service.dart      # Dart side of the UsageStats channel
    guide_brain.dart              # pure decision logic (unit tested)
    goals_repository.dart         # goals / apps / state / key persistence
    llm_client.dart               # Anthropic call + built-in fallback lines
    guide_task_handler.dart       # the 15-min check, in the background isolate
  state/app_controller.dart       # UI state, talks to the service
  ui/                             # dashboard, goals/apps/settings sheets, widgets
android/app/src/main/kotlin/.../
  UsageChannel.kt                 # aggregated daily UsageStats + app labels
  MainActivity.kt                 # registers the channel on the UI engine
  JarvisApplication.kt            # registers it on the background-task engine too
```

The background service runs in its **own FlutterEngine**, which doesn't
auto-register app plugins — `JarvisApplication` hooks `flutter_foreground_task`'s
lifecycle to install the `jarvis/usage` channel on that engine as well.

## Run it

```bash
flutter pub get
flutter run              # needs a real device with real usage history
```

Then in the app:

1. **Grant Usage access** + **Notifications**.
2. **Set your goals** (what you're working toward).
3. **Manage → add the apps** that distract you, each with a daily budget.
4. **Activate guide.** Use **Preview a guide message** to see its voice now.
5. *(optional)* Settings → add an Anthropic API key for freshly written nudges.

## Tests

```bash
flutter test        # GuideBrain: budget / escalation / cooldown / daily reset
flutter analyze
```

## Notes / limitations

- **Android only** (UsageStats is an Android capability).
- Uses `QUERY_ALL_PACKAGES` to resolve app names — fine for a personal
  sideloaded build, but Play Store restricts it.
- The optional API key is stored on-device; a production app should proxy LLM
  calls through a backend.
- Background checks run ~every 15 min (foreground-service interval), so a budget
  breach is noticed within that window rather than instantly — by design, this
  is a guide, not a real-time watchdog. `minSdk 24`.
