# Key Balloons

[English](TODO.en.md) · [简体中文](TODO.md) · [繁體中文](TODO.zh-TW.md) · [Français](TODO.fr.md) · [日本語](TODO.ja.md) · [한국어](TODO.ko.md) · [Español](TODO.es.md)

## First release

- [x] Use C++ and Qt Quick for shared code. Keep system events and window behavior in the platform code.
- [x] Add automated tests for repeated key presses, independent expiry, and rapid input.
- [x] Build the translucent floating box and individual key labels that rise and fade within three seconds.
- [x] Add global keyboard monitoring, pause, and quit on macOS and Windows.
- [x] Build on macOS, run the animation tests, and check QML statically.
- [x] On macOS, check that the overlay stays on top, preserves the original window’s focus, and lets clicks reach the window underneath.
- [x] On macOS, simulate 20 inputs per second for 30 seconds. All 600 labels were created and reclaimed. At most 59 were active at once. The 95th percentile from label creation to the next Qt frame was 12 ms.
- [x] Sample idle CPU on macOS. Both samples read 0.0%.
- [x] Build and run animation tests in CI on macOS and Windows. [CI run](https://github.com/boomsi/key-balloons/actions/runs/45830723721)
- [ ] Use physical keyboards on both platforms to verify input across applications. On Windows, also verify always-on-top behavior, focus, and mouse click-through.
- [ ] Measure physical key-to-display latency and sustained animation frame intervals on Windows.
- [ ] Confirm the behavior for held-key repeats and the system-following option. The initial release shows physical key presses and places the box on the primary screen.
- [x] Commit the first release and push it to the new public repository.
