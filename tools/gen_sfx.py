"""Placeholder diegetic sound effects for Space Game.

THE AUDIO RULE: no music, ever. Every sound belongs to a task or a thing -
the airlock's TSHHHH, a breaker's thunk, the scanner's sweep. EVA is total
silence (enforced in code, not here). These are synthesised placeholders
in the right SHAPE so real foley can replace them file-for-file.

Run from anywhere:  python tools/gen_sfx.py
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "sfx")
RATE = 22050

random.seed(7)


def write_wav(name, samples):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
        w.writeframes(frames)
    print("wrote", path)


def env(i, n, attack=0.02, release=0.3):
    t = i / n
    a = min(1.0, t / attack) if attack > 0 else 1.0
    r = min(1.0, (1.0 - t) / release) if release > 0 else 1.0
    return a * r


def noise_burst(dur, lowpass=0.2, vol=0.6, attack=0.02, release=0.5):
    n = int(RATE * dur)
    out = []
    last = 0.0
    for i in range(n):
        last += (random.uniform(-1, 1) - last) * lowpass
        out.append(last * vol * env(i, n, attack, release))
    return out


def tone(dur, freq, vol=0.4, shape="sine", attack=0.01, release=0.3, slide=0.0):
    n = int(RATE * dur)
    out = []
    phase = 0.0
    for i in range(n):
        f = freq + slide * (i / n)
        phase += 2 * math.pi * f / RATE
        if shape == "sine":
            v = math.sin(phase)
        elif shape == "square":
            v = 1.0 if math.sin(phase) > 0 else -1.0
        else:
            v = 2.0 * ((phase / (2 * math.pi)) % 1.0) - 1.0
        out.append(v * vol * env(i, n, attack, release))
    return out


def mix(*layers):
    n = max(len(l) for l in layers)
    out = [0.0] * n
    for l in layers:
        for i, s in enumerate(l):
            out[i] += s
    peak = max(1.0, max(abs(s) for s in out))
    return [s / peak for s in out]


# The airlock: a long pressurised TSHHHH with a mechanical clunk at the end.
write_wav("airlock_hiss", mix(
    noise_burst(1.6, lowpass=0.35, vol=0.8, attack=0.01, release=0.25),
    tone(1.6, 90, vol=0.06, shape="sine", release=0.2)))
write_wav("airlock_clunk", mix(
    tone(0.16, 70, vol=0.9, shape="sine", release=0.9),
    noise_burst(0.12, lowpass=0.6, vol=0.4, release=0.9)))
write_wav("door_slide", noise_burst(0.5, lowpass=0.15, vol=0.5, attack=0.05, release=0.4))
write_wav("elevator_hum", mix(
    tone(1.2, 55, vol=0.35, shape="sine", release=0.15),
    tone(1.2, 110, vol=0.12, shape="sine", release=0.15)))
write_wav("switch_click", tone(0.05, 900, vol=0.5, shape="square", release=0.8))
write_wav("breaker_thunk", mix(
    tone(0.12, 60, vol=0.9, release=0.9),
    tone(0.05, 400, vol=0.2, shape="square", release=0.9)))
write_wav("valve_turn", noise_burst(0.35, lowpass=0.5, vol=0.35, attack=0.1, release=0.3))
write_wav("wire_spark", mix(
    noise_burst(0.09, lowpass=0.9, vol=0.9, attack=0.0, release=0.7),
    tone(0.09, 1800, vol=0.3, shape="square", release=0.8)))
write_wav("wire_connect", tone(0.12, 520, vol=0.4, shape="sine", release=0.5))
write_wav("scanner_sweep", tone(1.1, 300, vol=0.3, shape="sine", release=0.2, slide=500))
write_wav("scanner_done", mix(tone(0.14, 660, vol=0.4), tone(0.14, 880, vol=0.3, attack=0.5)))
write_wav("pickup", tone(0.1, 440, vol=0.35, shape="sine", release=0.6, slide=220))
write_wav("paper", noise_burst(0.18, lowpass=0.25, vol=0.25, attack=0.05, release=0.5))
write_wav("console_boot", mix(
    tone(0.5, 220, vol=0.2, slide=110),
    tone(0.5, 330, vol=0.12, attack=0.4)))
write_wav("computer_blip", tone(0.07, 750, vol=0.3, shape="square", release=0.6))
write_wav("death_thud", mix(
    tone(0.5, 50, vol=1.0, release=0.6),
    noise_burst(0.25, lowpass=0.3, vol=0.4, release=0.8)))
write_wav("eat", noise_burst(0.25, lowpass=0.45, vol=0.35, attack=0.15, release=0.4))
write_wav("footstep", noise_burst(0.06, lowpass=0.4, vol=0.25, release=0.7))
write_wav("suit_equip", mix(
    noise_burst(0.4, lowpass=0.3, vol=0.4, attack=0.1, release=0.4),
    tone(0.15, 200, vol=0.2, release=0.6)))
write_wav("helmet_seal", mix(
    noise_burst(0.2, lowpass=0.35, vol=0.35, release=0.5),
    tone(0.12, 150, vol=0.3, release=0.7)))
write_wav("alarm_short", tone(0.4, 880, vol=0.25, shape="square", attack=0.02, release=0.1))
write_wav("thruster_puff", noise_burst(0.3, lowpass=0.25, vol=0.5, attack=0.02, release=0.5))
write_wav("tether_latch", mix(
    tone(0.08, 300, vol=0.5, shape="square", release=0.7),
    tone(0.2, 120, vol=0.3, release=0.6)))
print("done")
