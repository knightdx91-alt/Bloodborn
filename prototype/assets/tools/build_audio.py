#!/usr/bin/env python3
"""Placeholder audio for Marrowmark, synthesised from nothing.

    python3 tools/build_audio.py          # writes ../audio/*.wav

WHY GENERATE RATHER THAN SOURCE
-------------------------------
`art-audio.md` §4 (L87) makes audio load-bearing rather than decorative:

    "Impact tells you what happened. A cut biting flesh, a cut skipping
     off plate, a mace finding mail -- these are different sounds, and
     THAT IS HOW THE DAMAGE TRIANGLE REACHES A PLAYER WHO IS NEVER SHOWN
     A NUMBER."

That is a testable claim about three sounds being distinguishable, and
it can be tested with placeholders. Waiting for a sound designer to find
out whether the design works is the wrong order, and this project
already generates its props, its quadrupeds and its enemies the same
way (`build_assets.py`, `build_quadrupeds.py`).

These are PLACEHOLDERS and are meant to be replaced. What they are for
is proving the channel carries the information.

NO DEPENDENCIES
---------------
Pure stdlib: `wave`, `array`, `math`, `random`. numpy is not available
in the build environment and is not worth requiring for this.

16-bit mono at 22050 Hz, which is plenty for placeholder impacts and
keeps the APK small -- the whole set is a few hundred kilobytes.
"""

import array
import math
import os
import random
import wave

RATE = 22050
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "audio"))


def write(name, samples):
    """Clamp, convert to 16-bit and write."""
    data = array.array("h")
    for s in samples:
        v = int(max(-1.0, min(1.0, s)) * 32000)
        data.append(v)
    path = os.path.join(OUT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data.tobytes())
    print("  %-22s %5.2fs" % (name, len(samples) / RATE))


def noise(n, seed):
    r = random.Random(seed)
    return [r.uniform(-1.0, 1.0) for _ in range(n)]


def lowpass(xs, cutoff):
    """One-pole. Crude and entirely adequate for a placeholder."""
    a = math.exp(-2.0 * math.pi * cutoff / RATE)
    out, y = [], 0.0
    for x in xs:
        y = (1.0 - a) * x + a * y
        out.append(y)
    return out


def highpass(xs, cutoff):
    low = lowpass(xs, cutoff)
    return [x - l for x, l in zip(xs, low)]


def decay(n, seconds, curve=1.0):
    """Exponential fall from 1 to ~0 over `seconds`."""
    out = []
    for i in range(n):
        t = i / RATE
        out.append(math.exp(-t / max(seconds, 1e-4)) ** curve)
    return out


def ring(n, freq, seconds, amp=1.0):
    """A damped sinusoid -- one metallic partial."""
    env = decay(n, seconds)
    return [amp * env[i] * math.sin(2.0 * math.pi * freq * i / RATE)
            for i in range(n)]


def mix(*layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for layer in layers:
        for i, v in enumerate(layer):
            out[i] += v
    return out


def impact_flesh():
    """Dull, low, over quickly. Nothing rings -- meat does not."""
    n = int(RATE * 0.28)
    body = lowpass(noise(n, 11), 320)
    env = decay(n, 0.055, 1.3)
    thump = ring(n, 78, 0.07, 0.55)
    return [1.6 * body[i] * env[i] + thump[i] for i in range(n)]


def impact_mail():
    """Mid-bright, a scatter of small rings -- links moving against each
    other. Busier than flesh, far shorter than plate."""
    n = int(RATE * 0.42)
    hiss = highpass(noise(n, 23), 1800)
    env = decay(n, 0.10, 1.0)
    links = mix(*[ring(n, f, 0.13, 0.14)
                  for f in (1420, 1870, 2310, 2760, 3180)])
    thud = lowpass(noise(n, 24), 240)
    thud_env = decay(n, 0.05)
    return [0.9 * hiss[i] * env[i] + links[i] + 0.8 * thud[i] * thud_env[i]
            for i in range(n)]


def impact_plate():
    """Bright and it RINGS. The long tail is the tell: a cut that skipped
    is still audible after the one that bit has finished."""
    n = int(RATE * 0.95)
    clang = mix(*[ring(n, f, s, a) for f, s, a in (
        (620, 0.55, 0.30), (940, 0.45, 0.22), (1580, 0.38, 0.18),
        (2430, 0.30, 0.12), (3720, 0.22, 0.08))])
    strike = highpass(noise(n, 37), 2400)
    strike_env = decay(n, 0.02, 1.4)
    return [clang[i] + 1.3 * strike[i] * strike_env[i] for i in range(n)]


def swing():
    """A whoosh: filtered noise whose band sweeps up then down."""
    n = int(RATE * 0.34)
    src = noise(n, 51)
    out = []
    y = 0.0
    for i in range(n):
        t = i / n
        # Sweep the cutoff through the middle of the stroke.
        cut = 400.0 + 2600.0 * math.sin(math.pi * t)
        a = math.exp(-2.0 * math.pi * cut / RATE)
        y = (1.0 - a) * src[i] + a * y
        env = math.sin(math.pi * t) ** 1.6
        out.append(0.55 * (src[i] - y) * env)
    return out


def footstep(seed):
    n = int(RATE * 0.16)
    body = lowpass(noise(n, seed), 700)
    env = decay(n, 0.035, 1.5)
    return [1.3 * body[i] * env[i] for i in range(n)]


def ambience(seconds, wind_cut, chirps, seed, cricket=False):
    """Looping room tone. Wind is filtered noise breathing slowly; the
    voices on top are what make it a PLACE rather than a hiss."""
    n = int(RATE * seconds)
    base = lowpass(noise(n, seed), wind_cut)
    out = []
    for i in range(n):
        # Two slow LFOs so the gusts do not obviously repeat.
        t = i / RATE
        gust = 0.55 + 0.3 * math.sin(2 * math.pi * t / 7.3) \
            + 0.15 * math.sin(2 * math.pi * t / 3.1)
        out.append(base[i] * gust * 0.5)

    r = random.Random(seed + 7)
    for _ in range(chirps):
        at = r.randrange(0, n - int(RATE * 0.5))
        if cricket:
            # A cricket: a short buzz of clicks, repeated.
            f = r.uniform(3400, 4200)
            length = int(RATE * 0.09)
            for k in range(6):
                start = at + k * int(RATE * 0.035)
                if start + length >= n:
                    break
                for i in range(length):
                    env = math.exp(-i / (RATE * 0.006))
                    out[start + i] += 0.05 * env * math.sin(
                        2 * math.pi * f * i / RATE)
        else:
            # A bird: two or three quick rising notes.
            for k in range(r.randint(2, 3)):
                f0 = r.uniform(1900, 3100)
                length = int(RATE * r.uniform(0.05, 0.10))
                start = at + k * int(RATE * 0.11)
                if start + length >= n:
                    break
                for i in range(length):
                    t2 = i / length
                    env = math.sin(math.pi * t2) ** 1.5
                    f = f0 * (1.0 + 0.35 * t2)
                    out[start + i] += 0.10 * env * math.sin(
                        2 * math.pi * f * i / RATE)

    # Make the ends meet, or the loop ticks every time it wraps.
    fade = int(RATE * 0.35)
    for i in range(fade):
        a = i / fade
        out[i] *= a
        out[n - 1 - i] *= a
    head = out[:fade]
    for i in range(fade):
        out[n - fade + i] += head[i] * (1.0 - i / fade)
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    print("writing to %s" % OUT)
    write("hit_flesh.wav", impact_flesh())
    write("hit_mail.wav", impact_mail())
    write("hit_plate.wav", impact_plate())
    write("swing.wav", swing())
    for i in range(3):
        write("step_%d.wav" % (i + 1), footstep(90 + i))
    write("ambience_day.wav", ambience(12.0, 900, 9, 300))
    write("ambience_night.wav", ambience(12.0, 420, 7, 400, cricket=True))


if __name__ == "__main__":
    main()
