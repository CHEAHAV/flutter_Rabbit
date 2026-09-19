"""Synthesises the app's UI sound effects into assets/sounds/*.wav.

Run from the project root:  python tool/generate_sounds.py

Every sound is built from sine partials with an exponential decay envelope,
a short linear attack and release (so there is never a click at the start or
end), and is peak-normalised to the same level so a single volume setting
feels consistent across all of them. Requires numpy.
"""

import wave
from pathlib import Path

import numpy as np

SR = 44100
PEAK = 0.85  # leave headroom below full scale
OUT = Path(__file__).resolve().parent.parent / "assets" / "sounds"


def note(freq, dur, partials=((1, 1.0),), decay=8.0, attack=0.004, glide_to=None):
    """One decaying tone. `partials` is [(harmonic multiple, amplitude)]."""
    n = int(SR * dur)
    t = np.arange(n) / SR
    if glide_to is None:
        phase = 2 * np.pi * freq * t
    else:  # exponential pitch glide for "pop"/"bonk" style sounds
        f = freq * (glide_to / freq) ** (t / dur)
        phase = 2 * np.pi * np.cumsum(f) / SR
    wave_ = sum(a * np.sin(phase * m) for m, a in partials)
    env = np.exp(-decay * t)
    env *= np.minimum(1.0, t / attack)  # attack ramp
    release = int(SR * 0.012)  # 12 ms fade-out avoids an end click
    env[-release:] *= np.linspace(1, 0, release)
    return wave_ * env


def place(total, *events):
    """Mix (start_seconds, samples) events into a buffer of `total` seconds."""
    buf = np.zeros(int(SR * total))
    for start, samples in events:
        i = int(SR * start)
        buf[i : i + len(samples)] += samples[: len(buf) - i]
    return buf


BELL = ((1, 1.0), (2, 0.35), (3, 0.12))  # soft bell timbre
SOFT = ((1, 1.0), (2, 0.15))

SOUNDS = {
    # Generic button press: a short, soft, dry "pop".
    "tap": note(900, 0.07, SOFT, decay=45, glide_to=620),
    # Choosing an option / ticking a subject: a slightly brighter tick.
    "select": note(1250, 0.08, SOFT, decay=40, glide_to=980),
    # Switch turned on / off: rising vs falling two-tone blip.
    "toggle_on": place(
        0.16,
        (0.0, note(700, 0.07, SOFT, decay=35)),
        (0.055, note(1050, 0.10, SOFT, decay=30)),
    ),
    "toggle_off": place(
        0.16,
        (0.0, note(1050, 0.07, SOFT, decay=35)),
        (0.055, note(700, 0.10, SOFT, decay=30)),
    ),
    # Correct answer: bright rising two-note chime (G5 -> C6).
    "correct": place(
        0.65,
        (0.0, note(784, 0.40, BELL, decay=7)),
        (0.11, note(1047, 0.54, BELL, decay=6)),
    ),
    # Wrong answer: soft, low, falling "bonk" - clear but not harsh.
    "wrong": place(
        0.5,
        (0.0, note(311, 0.22, ((1, 1.0), (2, 0.25), (3, 0.08)), decay=9)),
        (0.13, note(233, 0.37, ((1, 1.0), (2, 0.25), (3, 0.08)), decay=8)),
    ),
    # Passed the exam: rising major arpeggio (C5 E5 G5 C6) + held chord.
    "success": place(
        1.6,
        (0.00, note(523, 0.9, BELL, decay=4)),
        (0.12, note(659, 0.9, BELL, decay=4)),
        (0.24, note(784, 0.9, BELL, decay=4)),
        (0.36, note(1047, 1.2, BELL, decay=3.2)),
    ),
    # Did not pass: gentle falling minor figure (E5 D5 A4) - encouraging, not sad.
    "fail": place(
        1.2,
        (0.00, note(659, 0.6, SOFT, decay=5)),
        (0.18, note(587, 0.6, SOFT, decay=5)),
        (0.36, note(440, 0.8, SOFT, decay=4.5)),
    ),
    # Low-time warning: two quick soft beeps.
    "warning": place(
        0.4,
        (0.00, note(880, 0.12, SOFT, decay=14)),
        (0.18, note(880, 0.12, SOFT, decay=14)),
    ),
}


def write_wav(path, samples):
    peak = float(np.max(np.abs(samples))) or 1.0
    pcm = np.int16(samples / peak * PEAK * 32767)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, samples in SOUNDS.items():
        write_wav(OUT / f"{name}.wav", samples)
        print(f"{name}.wav  {len(samples) / SR * 1000:.0f} ms")
