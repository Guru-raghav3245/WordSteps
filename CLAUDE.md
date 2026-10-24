# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

WordSteps (package name `word_app`) is a Flutter mobile app (portrait-only) for word/sentence practice. A quiz presents a word or sentence and the user answers via **Read mode** (speech recognition) or **Listen mode** (TTS plays it, user picks from options).

## Commands

```
flutter pub get
flutter run
flutter analyze            # lints: flutter_lints (see analysis_options.yaml)
flutter test               # single file: flutter test test/widget_test.dart
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`test/widget_test.dart` is the stock counter template and is stale (it pumps `MyApp()` without `ProviderScope` and expects a counter) — it will fail; there are no real tests.

## Architecture

- **State**: Riverpod 3 (`flutter_riverpod`). `StateProvider`/`StateNotifier` come from `package:flutter_riverpod/legacy.dart`, so import that for those types. Global settings providers (`volumeProvider`, `pitchProvider`, `speechRateProvider`) live in `lib/providers/voice_providers.dart`; theme in `theme_provider.dart` (also defines `AppTheme`).
- **Question content** (`lib/questions/`): `ContentType` enum (sentence categories + `wordLength3..14`) maps to string keys via `ContentType.fromName`. `sentence_list.dart` holds the static sentence banks; word-length content comes from the `english_words` package filtered by a banned-word list in `word_generator.dart`.
- **Game loop**: `WordGameService` (`word_generator.dart`) generates questions/options and exposes the `wordGameStateProvider` notifier holding the immutable `WordGameState` (`lib/models/`). It also injects **WAQs** (Wrong Answer Questions): previously missed questions for the current category (`ContentType` name as category) are replayed first in a session, flagged via `isWAQ`.
- **Persistence**: everything is `shared_preferences` JSON — quiz history (`QuizHistoryService`, static methods) and missed answers (`WrongAnswerService`, key `wordsteps_wrong_answers`). No backend/database.
- **Screens** (`lib/screens/`): `splash_screen` → `home_screen` (content/mode/timer selection, drawer) → `practice_screen` (shared shell + modals for pause/quit/inactivity; `read_screen.dart` and `listen_screen.dart` are the two modes, with `confetti_helper.dart` for feedback) → `result_screen` (also `pdf_generator.dart` for sharing results via `pdf` + `share_plus`). History screens are in `lib/quiz_history/` and `wrong_answer_history_screen.dart`.
- **Speech**: `speech_recog.dart` for Read mode (on `main`: `speech_to_text`; on `feature/transcribe-cpp-stt`: `transcribe_cpp`, model preloaded from `SplashScreen` via `prepare()`, status in `modelState`; answer matching in `read_screen.dart` via `string_similarity`, unchanged); `tts_translator.dart` (`flutter_tts`) for Listen mode.
- Platform folders (android/ios/macos/linux/windows/web) are standard Flutter scaffolding; `upload_certificate.pem` is an Android upload cert at repo root.

## STT accuracy testing (Oct 2026)

### Status and direction

- **Branch `feature/transcribe-cpp-stt`** swaps the engine: `lib/questions/speech_recog.dart` now wraps `transcribe_cpp` + `moonshine-streaming-tiny-Q8_0` (whole-clip-quality model, **no key-term biasing** in this plugin). `main` still uses `speech_to_text`. The benchmark numbers below come from throwaway harnesses, not app code. A standalone POC lives outside the repo at `../transcribe_poc`.
- **Problem**: the OS recognizer is inaccurate on Indian-accented speech (31.9% WER, 5/30 sentences exact; setting `en-IN` did not help).
- **Proposed approach**: replace it with Moonshine (official `moonshine-voice` runtime, a **streaming** model) and bias it toward the on-screen target with `set_keyterms(words of the target)`. Best size/accuracy trade-off measured: `tiny_streaming` (45 MB) with `keyterm_boost=3` at 4.3% WER, 27/30 exact. `medium_streaming` (269 MB) reaches 0.5% with default biasing but is large.
- **Why streaming**: key-term biasing only works on streaming archs, and the streaming API fits the existing continuous-listen design in `speech_recog.dart`.
- **Guardrails that do not pay off**: silence trim/normalise, repetition stripping, and any fuzzy matching beyond strict equality (details in the guardrail section below).
- **Flutter support (checked 2026-10-24)**:
  - Official `moonshine-ai/moonshine` (MIT code; English and all streaming models MIT, only non-English legacy models are non-commercial) has native Swift/iOS and Android bindings and examples, but **no Flutter/Dart binding** and no `moonshine*` package on pub.dev. Using it from Flutter means writing a platform-channel or FFI wrapper per platform.
  - pub.dev `transcribe_cpp` (v0.1.3, third-party, MIT, published 2026-10-21, 0 likes, ~160 downloads/30d, repo created 2026-09-11) is a Flutter FFI plugin for iOS 16+/Android 7+ (64-bit) that downloads models at runtime. It lists `moonshine-streaming-tiny-Q8_0` (50 MB, 4.5% LibriSpeech WER) and says tiny has been run on a phone through it. It needs Dart `^3.12.2` (installed Dart 3.13.3 is fine). Its high-level Dart API does **not** expose key-term biasing (only the raw FFI bindings carry a `vocabulary` field), and that is a different engine (ggml) from the official runtime used in the measurements above, so the `keyterm_boost` results are unconfirmed there.
- **`transcribe_cpp` check (2026-10-24)**: ran the same 30 clips through `moonshine-streaming-tiny-Q8_0.gguf` (50 MB, from `handy-computer/moonshine-streaming-tiny-gguf` on Hugging Face, sha256 verified) using the Python `transcribe_cpp` 0.4.1 bindings, i.e. the same ggml engine the Flutter plugin wraps (the plugin's pinned engine release may differ).

  | Mode | WER | Exact | RTF (M5 Pro, Metal) |
  |---|---|---|---|
  | Whole clip, `session.run` | 6.3% | 23/30 | 0.021 |
  | `session.stream()`, 100 ms chunks | 120.8% | 0/30 | 0.127 |

  Whole-clip accuracy is in the same range as the official runtime (4.8% non-streaming tiny, 9.2% tiny_streaming without biasing). The streaming run failed with runaway repeated tokens (`output truncated ... dropped N tokens of a repeating block`); this may be misuse of the stream API in the test script rather than an engine bug, so treat streaming through this engine as **unverified**. `model.supports('vocabulary')` and `'context_prompt'` are both **False** for this model, so no key-term biasing is available through `transcribe_cpp`; biasing needs the official runtime's streaming archs. Whole-clip errors looked like the others: "cow" -> "cows", "walk" -> "walked", "we chase a kite" -> "we chase a fight".
- **UX on the branch**: picking Read Mode on the home screen (`gameModeProvider` value `'listen'`; the app's mode names are swapped vs. labels) opens a download-consent dialog if the model is not installed (`stt_download_dialog.dart`), then a progress dialog with a Hide button and a success/failure snackbar. Read screen shows an inline bar and a Download/Retry button, and Start is disabled until the model is ready.
- **Still open before building**: measure on-device speed on a real phone (only Mac timings exist); test with real recordings of children (all clips here are synthetic); decide between the `transcribe_cpp` plugin (easy integration, young, record-then-transcribe works, no biasing) and a custom wrapper over the official runtime (biasing, more work).
- **Single words (2026-10-24)**: 60 nouns from the `english_words` list (10 each for lengths 3-8, banned words excluded), Indian `say` voices + pink noise, same setup as sentences (`scratchpad/words/{gen,run,bias}.py`, not checked in). `moonshine-streaming-tiny-Q8_0` via `transcribe_cpp`: 41/60 exact (3-letter 4/10, 4-letter 5/10, 5: 6/10, 6: 8/10, 7-8: 9/10). Words are harder than sentences for short lengths (3-5 letters: 15/30 exact); typical errors top->talk, bus->boss, cop->go, chip->cheers, wheel->real, tour->sure. The app's current match (`contains` or similarity > 0.6) accepts 48/60 but also accepts wrong words (van->man, cast->cost, medal->metal, doll->dole); word types probably need an exact match.
- **Key-term biasing does not help single words** (official runtime, streaming, `set_keyterms([target])`): exact /60 tiny 44 -> 43 (boost 3: 42), small 48 -> 48, medium 50 -> 49 (boost 3: 47); app-rule accepts barely move. Biasing toward a wrong word never produced it (0/60), so it is safe but pointless for words, and a native wrapper around the official runtime is **not** justified on this evidence. Model size helps modestly: 44 / 48 / 50 exact for tiny / small / medium (45 / 142 / 269 MB). Untested for words: silence padding, voice-recognition mic source, `base` non-streaming, real children's speech.
- **How to read the tables**: WER is the word error rate, so lower is better; exact is the count of sentences with every word right, so higher is better.

### Test process

Goal: compare `speech_to_text` (the OS recognizer) against bundled models without manual speaking. The throwaway harness lived outside the repo (session scratchpad) and is not checked in; recreate it from this recipe.

**Test set**: 30 sentences sampled from `sentence_list.dart` (`random.seed(1)`), spoken by macOS `say` with Indian-English voices (Rishi, Aman, Tara), mixed with pink noise (`ffmpeg anoisesrc a=0.02`). Score = jiwer WER + exact-sentence matches after lowercasing and stripping punctuation.

**Bundled models (host-side)**: Python venv with `faster-whisper` (`tiny.en`, `base.en`, int8) and `vosk` (small-en). Run on the WAVs directly.

**Android system recognizer (no mic)**: a throwaway Flutter app with native Kotlin that calls `SpeechRecognizer` with `RecognizerIntent.EXTRA_AUDIO_SOURCE` fed from a `ParcelFileDescriptor` pipe (16 kHz mono PCM16, `EXTRA_AUDIO_SOURCE_*` extras set). Push PCM files with `adb push` to `/sdcard/Android/data/<pkg>/files/`, drive via `adb shell am start ... --ez prefer_offline ... --es lang ...`, read `logcat` for results.

Gotchas that cost time:
- **Do not route audio through the emulator mic** (BlackHole + `-allow-host-audio`). It works for 1-2 utterances, then the emulator HAL logs `failed to create alsa source for 'AUDIO_DEVICE_IN_BUILTIN_MIC'; creating a tone source instead` and recognizes noise. Use `EXTRA_AUDIO_SOURCE` instead.
- Feed the pipe like a live mic: ~1 s lead silence, 100 ms real-time chunks, ~1.5 s tail silence. Dumping the whole file at once yields empty results.
- The final `onResults` bundle's `RESULTS_RECOGNITION` is null with `EXTRA_AUDIO_SOURCE`; score the **last partial result** (`EXTRA_PARTIAL_RESULTS=true`).
- Error 11 (service disconnected) hits roughly every other file; retry once.
- Error 13 with `EXTRA_PREFER_OFFLINE`: the emulator has no offline en-US language pack, so the app's `onDevice: true` path could not be tested.
- `permission_handler` needs `compileSdk = 37` in the harness `build.gradle.kts`.
- Switching the Mac's default audio input mid-test (SwitchAudioSource) disturbs the emulator; restore it to "External Microphone" afterwards.

**Results** (same 30 sentences, Indian voices + noise; synthetic speech, so optimistic):

| Engine | WER | Exact |
|---|---|---|
| Android recognizer, online, default locale | 31.9% | 5/30 |
| Android recognizer, online, `en-IN` | 31.9% | 5/30 |
| Whisper tiny.en (~75 MB) | 11.6% | 19/30 |
| Whisper base.en (~150 MB) | 2.9% | 27/30 |
| Vosk small-en (~40 MB), mixed US/UK/IN voices | 15.9% | 13/30 |
| Moonshine tiny, official `moonshine-voice` runtime (44 MB) | 4.8% | 23/30 |
| Moonshine base, same runtime (141 MB) | 6.8% | 24/30 |

Moonshine ran via `pip install moonshine-voice` (needs Python >= 3.10; models from `moonshine_voice.download.get_model_for_language('en', arch)`, `Transcriber.transcribe_without_streaming`), ~65x real-time on an M5 Pro (RTF 0.015). The *_streaming archs must be driven through the streaming API (`create_stream`, 100 ms `add_audio` chunks, `stop`, `update_transcription`); the first numbers (15-29% WER) used the non-streaming call and were unfair. The one repeated-sentence hallucination seen ("...bright colors the girl drew a") came from Moonshine **base**, not tiny. `transcribe_cpp` (ggml; needs GGUF models) was not tested with Moonshine.

Android typical errors: "she drew a picture" -> "shitrew picture", "i draw a star" -> "i drop star", "a dog barked" -> "adobe back". Setting `en-IN` changed nothing.

### Guardrail experiments (same 30 clips, Moonshine streaming API)

`scratchpad/guard*.py` (not checked in). WER / strict-exact; baseline -> with key-term biasing (`set_keyterms(words of the target sentence)`):

| Arch | Size | Baseline | Keyterms default | Keyterms `keyterm_boost=3` |
|---|---|---|---|---|
| tiny_streaming | 45 MB | 9.2% / 20 | 5.3% / 25 | 4.3% / 27 |
| small_streaming | 142 MB | 6.8% / 24 | 4.8% / 26 | 4.3% / 27 |
| medium_streaming | 269 MB | 1.4% / 27 | 0.5% / 29 | 9.2% / 26 |

- `set_keyterms` **only works on streaming archs** (tiny/base non-streaming raise "Key-term biasing requires one of the streaming model architectures").
- `keyterm_boost` is touchy: 8 breaks every arch (WER 53-100%), 3 helps tiny/small but hurts medium. Tune per model; default is safest.
- Safety check: biasing toward a sentence one word different from what was said never produced that wrong sentence (0/30), so biasing did not turn mistakes into passes.
- Silence trim + peak normalise and repetition stripping: no consistent effect on this data.
- Sentence-level fuzzy match (SequenceMatcher >= 0.90) is NOT a usable guardrail: accepts 12/30 swapped-word and 27/30 inflection-changed wrong targets. Word-level fuzzy (<=1 differing word with char similarity >= 0.75) rejects swapped words (0/30) but by design also accepts inflection changes (bark/barked) and gains only 1-4 sentences over strict match. Whether to accept inflection errors is a product decision.
