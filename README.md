# Fajr Alarm

A prayer alarm app that calculates accurate Fajr prayer times based on your location and wakes you up with an alarm you can't easily dismiss.

## Features

- **Accurate Fajr times** — Uses the Adhan library with the Muslim World League calculation method
- **Auto-detect location** — GPS-based or manual latitude/longitude input
- **All 6 prayer times** — Displays Fajr, Sunrise, Dhuhr, Asr, Maghrib, and Isha with countdown to Fajr
- **Hard-to-stop alarm** — Once triggered, the alarm plays until the adhan audio ends; no stop or snooze button on real alarms
- **Persistent notification** — Alarm runs as a foreground service, so it works even when the app is fully closed
- **Custom sounds** — Choose from preset adhans or pick any audio file from your device
- **Test mode** — Preview your alarm with a simple stop button from the settings page
- **Adjustable settings** — Volume control, vibration toggle, and reminder timing

## Tech Stack

- **Flutter** — Cross-platform UI framework
- **Adhan** — Islamic prayer time calculation
- **Geolocator + Geocoding** — Location services
- **Native Android** — Foreground service, MediaPlayer, RingtoneManager (Kotlin)

## Getting Started

```bash
flutter pub get
flutter run
```

Requires Android SDK 36+ and a connected device or emulator.

## Permissions

- Location (GPS or manual)
- Alarm scheduling
- Notifications
- Foreground service
- Vibration
- Boot completed (to reschedule alarms)

## License

Private project — not published to pub.dev.
