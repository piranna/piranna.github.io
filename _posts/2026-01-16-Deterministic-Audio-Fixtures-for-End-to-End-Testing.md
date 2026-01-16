---
lang: en
layout: post
tags: ai-coauthored, audio, testing, fft, fixtures, end-to-end-testing, ci, validation, lossy-codecs, spectral-analysis, deterministic, audio-pipelines
title: Deterministic Audio Fixtures for End-to-End Testing
---

## Designing Robust Spectral Validation for Audio Pipelines

Testing audio systems is deceptively hard.

Unlike text or structured data, audio pipelines are often
**lossy, time-sensitive, and highly stateful**. Codecs introduce quantization
noise, transports introduce jitter, buffers may reorder or drop frames, and
decoders may subtly alter timing or amplitude. Traditional byte-level
comparisons or waveform diffs are therefore brittle and misleading.

In this article, I present
[audio-test-fixtures](https://github.com/piranna/audio-test-fixtures), a
**deterministic, spectral-based approach** to testing audio pipelines
end-to-end. The result is a small but robust toolkit that generates
**known audio fixtures** and validates decoded output using
**FFT-based frequency analysis**, designed to work reliably even with lossy
codecs and imperfect transports.

## The Core Problem

Let’s define the problem precisely:

> *How can we mechanically and reliably verify that an audio signal survives encoding, transmission, and decoding without unacceptable distortion?*

Key constraints:

* Bitwise equality is impossible with lossy codecs
* Waveform comparison is extremely sensitive to phase, gain, and timing
* Perceptual metrics (PESQ, POLQA) are heavyweight and opaque
* Manual listening does not scale and is not CI-friendly

What we need instead is:

* Deterministic input
* Known ground truth
* A validation method tolerant to amplitude and phase drift
* Machine-verifiable results
* Clear pass/fail semantics

## Design Overview

The solution is split into **two clearly separated components**:

1. **Audio Fixture Generator**
   Generates a deterministic WAV file containing a known sequence of pure tones.

2. **Audio Transmission Validator**
   Compares a reference WAV with a decoded WAV using spectral analysis.

This separation of responsibilities is critical:

* Fixtures are generated once
* Validation can be run repeatedly in CI, on-device, or in regression tests

## Why Pure Tones?

Human voice spans roughly **80 Hz to 1.1 kHz**. Instead of attempting to
simulate speech, we use **pure sinusoidal tones** because:

* Their frequency is mathematically unambiguous
* FFT peak detection is reliable
* Harmonics and distortion are easy to observe
* They are codec-agnostic

Each tone becomes a **spectral marker** that we can later detect.

## Audio Fixture Design

### Format

The generated file has strict, predictable properties:

* **PCM WAV**
* **16-bit**
* **Mono**
* **16 kHz**
* **Exactly 10 seconds**
* **160,000 samples**

This makes it compatible with:

* Embedded systems
* Mobile platforms
* Voice codecs
* Low-latency transports

### Frequency Content

The file contains **27 ascending notes**, from **E2 (82 Hz)** to
**C6 (1046 Hz)**, covering the full vocal range.

Each note consists of:

* ~350 ms pure sine wave
* 20 ms silence between notes
* Short fade-in/out to avoid clicks

## Generator Implementation

Below is a simplified excerpt of the tone generation logic:

```python
def generate_tone(frequency, duration, sample_rate, amplitude=0.3):
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    return amplitude * np.sin(2 * np.pi * frequency * t)
```

Each tone is placed at a deterministic position in the final buffer, allowing us
to later compute **exact analysis windows**.

The resulting WAV file is fully deterministic: generating it twice produces the
same signal (modulo floating-point rounding).

## Why Determinism Matters

Determinism enables:

* Stable CI tests
* Meaningful regression comparisons
* Long-term maintainability
* Debuggable failures

If your input changes every run, your test results become meaningless.

## Validation Strategy

### What We Validate

The validator checks multiple orthogonal dimensions:

1. **WAV Metadata**

   * Sample rate
   * Bit depth
   * Channel count
   * Duration (with tolerance)

2. **Spectral Integrity**

   * Dominant frequency per segment
   * Frequency deviation (Hz and %)
   * Accuracy ratio (% within tolerance)

3. **Signal Quality**

   * Signal-to-Noise Ratio (SNR)

Each metric answers a different question:

* *Is the format correct?*
* *Are frequencies preserved?*
* *Is noise within acceptable bounds?*

## FFT-Based Frequency Detection

Instead of comparing waveforms, we extract the **dominant frequency** of each
segment using FFT:

```python
fft_result = np.fft.rfft(windowed_segment)
fft_freqs = np.fft.rfftfreq(len(segment), 1.0 / sample_rate)
dominant_freq = fft_freqs[np.argmax(np.abs(fft_result))]
```

Important implementation details:

* Hann windowing to reduce spectral leakage
* Frequency band filtering (50 Hz – 1200 Hz)
* Analysis window centered on tone (avoids silence)

This approach is:

* Phase-invariant
* Gain-invariant
* Robust to small timing drift

## Frequency Tolerance

Lossy codecs *will* introduce frequency smearing. Therefore, validation uses a
configurable tolerance:

```bash
--tolerance 5.0   # Hz
```

Typical values:

| Scenario          | Tolerance |
| ----------------- | --------- |
| Lossless          | ±2 Hz     |
| Light compression | ±5 Hz     |
| Heavy compression | ±10 Hz    |

A note is considered **valid** if:

```
|detected_freq - expected_freq| ≤ tolerance
```

## Aggregated Metrics

After analyzing all segments, we compute:

* **Frequency accuracy**
  Percentage of notes within tolerance

* **Mean frequency error**

* **SNR (dB)**
  Based on power ratio between reference and decoded signals

Example output:

```
Frequencies correct: 27/27 (100.0%)
Mean frequency error: 0.82 Hz
SNR: 38.7 dB
```

## CI-Friendly Results

The validator is explicitly designed for automation:

* Exit code `0`: validation passed
* Exit code `1`: validation failed
* No human interpretation required

Example:

```bash
validate-audio reference.wav decoded.wav --tolerance 10.0 \
  && echo "PASS" || echo "FAIL"
```

This allows seamless integration into:

* GitHub Actions
* GitLab CI
* Jenkins
* Embedded test harnesses

## Why Not Waveform Comparison?

Waveform diffs fail because:

* Phase shifts invalidate comparisons
* Gain normalization breaks equality
* Minor resampling introduces drift
* Codecs reorder samples internally

Spectral comparison answers the *right* question:

> *Is the information content preserved within acceptable limits?*

## Why Not Perceptual Metrics?

Perceptual metrics (PESQ, POLQA):

* Are complex and opaque
* Often require licenses
* Are hard to debug
* Are slow and heavyweight

This approach is:

* Transparent
* Deterministic
* Explainable
* Fast

## Typical Use Cases

This methodology works well for:

* Audio codec validation
* Transport integrity tests (UDP, BLE, RTP)
* Embedded and mobile pipelines
* Regression testing
* Hardware-in-the-loop testing
* DSP algorithm validation

## Final Thoughts

This project demonstrates that
**audio testing does not need to be fuzzy or subjective**.

By:

* Using deterministic fixtures
* Focusing on spectral correctness
* Accepting controlled loss
* Producing machine-verifiable results

we can build **robust, maintainable, and scalable audio tests** that survive
real-world conditions.

If you are testing audio pipelines and still relying on manual listening or
fragile waveform diffs, it may be time to rethink your approach.

> **Note**
>
> Code was developed by
> [Claude Sonnet 4.5](https://www.anthropic.com/news/claude-sonnet-4-5), an AI
> language model by [Anthropic](https://anthropic.com/), from an original idea
> of mine. Post was written by [ChatGPT GPT-5.2](https://chatgpt.com/), an AI
> language model by [OpenAI](https://openai.com/). Final formatting and text
> edition was done by hand. You can
> [download]({{ site.baseurl }}/chatgpt-conversations/2026-01-16-Deterministic-Audio-Fixtures-for-End-to-End-Testing.md)
> a detailed discussion of the process.
>
> `#human-ai-collaboration`
