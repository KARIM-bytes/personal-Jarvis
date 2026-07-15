# Jarvis — Digital Wellbeing Nagger (Flutter v1)

An Android app that watches which app is in the foreground and, when you break a
rule (v1: *"Instagram open for more than 2 continuous minutes"*), has an
AI-voiced Jarvis persona call you out — instantly, out loud.

This is the **first version**: a Flutter port of the PRD that proves the
end-to-end loop (detect → decide → generate line → speak → log) with a single
hardcoded rule.

## The loop

```
Foreground service (background isolate)
  every 5s ─► read foreground app (UsageStats)
           ─► MonitorEngine: continuous time on watched app ≥ threshold?
           ─► on breach: LLM (or built-in line) ─► TextToSpeech + notification
           ─► report NagEvent to the UI isolate  ─► shown in the Nag log
```

## What works in v1

- Real-time foreground-app detection via Android **UsageStats**.
- One hardcoded rule (Instagram, 2 min) evaluated by a pure, unit-tested
  `MonitorEngine`.
- Runs in a **foreground service** so it survives app switches / screen off.
- Spoken scold via the built-in **TextToSpeech** engine, mirrored to the
  persistent notification (backup if audio is muted).
- Scold lines from an **Anthropic** model if you add an API key, otherwise a
  built-in pool — so the loop always completes.
- In-app **Nag log** and a **"Test a nag now"** button to demo without waiting.

Deliberately cut from v1 (see PRD non-goals / post-MVP): settings for rules, rule
persistence, overlay popups, multiple rules, usage-trend awareness, custom voice.

## Project layout

```
lib/
  config/app_config.dart          # all the hardcoded knobs (rule, thresholds, LLM)
  models/                         # NagRule, NagEvent (isolate-safe JSON)
  services/
    foreground_app_service.dart   # Dart side of the UsageStats channel
    monitor_engine.dart           # pure rule state machine (unit tested)
    llm_client.dart               # Anthropic call + built-in fallback lines
    tts_service.dart              # flutter_tts wrapper
    jarvis_task_handler.dart      # the loop, running in the background isolate
  state/monitor_controller.dart   # UI state, talks to the service
  ui/                             # home screen, settings, widgets
android/app/src/main/kotlin/.../
  ForegroundAppChannel.kt         # UsageStats foreground detection
  MainActivity.kt                 # registers the channel on the UI engine
  JarvisApplication.kt            # registers it on the background-task engine too
```

The background service runs in its **own FlutterEngine**, which doesn't
auto-register app plugins — `JarvisApplication` hooks
`flutter_foreground_task`'s lifecycle to install the foreground-app channel on
that engine as well. Without it, the background loop couldn't read the
foreground app.

## Run it

```bash
flutter pub get
flutter run              # needs a real device (an emulator has no other apps to catch)
```

Then in the app:

1. **Grant Usage access** — opens the system screen; enable it for Jarvis.
2. **Grant Notifications** — required for the foreground service.
3. **Activate Jarvis**, or hit **Test a nag now** to hear it immediately.
4. *(optional)* Settings → paste an Anthropic API key for freshly written scolds.

### Verifying against the PRD success criteria (on device)

- Open Instagram, wait ~2 min → a spoken nag fires within a few seconds.
- Background the app / turn the screen off for 30 min → the service keeps
  running (persistent "Jarvis is watching" notification stays up).

## Tests

```bash
flutter test        # MonitorEngine: threshold, once-per-session, cooldown, reset
flutter analyze
```

## Notes / limitations

- **Android only** (foreground detection is an Android capability).
- The optional API key is stored on-device via `shared_preferences`. Fine for a
  personal build; a production app should proxy LLM calls through a backend
  rather than shipping a key.
- `minSdk 24`.
