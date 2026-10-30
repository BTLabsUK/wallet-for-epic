# SPDX-License-Identifier: Apache-2.0
"""The machine's load while a run's steps run, for metrics.jsonl: per step its CPU (average and
peak), memory in use (peak), load average (peak) and the steps that ran beside it; per set of
steps that ran at the same time the same peaks (e.g. the Android and Linux builds together).

The numbers are machine-wide (/proc), not per process: they say how busy the machine was while a
step ran, which is what deciding what may run side by side needs. A sample every few seconds; a
step too short for one has no load fields. Linux only: elsewhere nothing is sampled.
"""
import threading
import time


def _cpu_times():
    with open("/proc/stat") as f:
        parts = f.readline().split()[1:]
    vals = [int(x) for x in parts]
    idle = vals[3] + (vals[4] if len(vals) > 4 else 0)  # idle + iowait
    return sum(vals), idle


def _mem_used_gb():
    info = {}
    with open("/proc/meminfo") as f:
        for line in f:
            k, _, v = line.partition(":")
            info[k] = int(v.split()[0])
    return (info["MemTotal"] - info["MemAvailable"]) / 1048576


def _load1():
    with open("/proc/loadavg") as f:
        return float(f.read().split()[0])


class _Acc:
    def __init__(self):
        self.n = 0
        self.seconds = 0.0
        self.cpu_sum = 0.0
        self.cpu_max = 0.0
        self.mem_peak = 0.0
        self.load_max = 0.0
        self.beside = set()

    def add(self, s, dt):
        self.n += 1
        self.seconds += dt
        self.cpu_sum += s["cpu"]
        self.cpu_max = max(self.cpu_max, s["cpu"])
        self.mem_peak = max(self.mem_peak, s["mem"])
        self.load_max = max(self.load_max, s["load"])

    def fields(self):
        if not self.n:
            return {}
        return {"cpu_avg_pct": round(self.cpu_sum / self.n, 1), "cpu_max_pct": round(self.cpu_max, 1),
                "mem_peak_gb": round(self.mem_peak, 2), "load_max": round(self.load_max, 2)}


class LoadSampler:
    def __init__(self, interval=5.0):
        self.interval = interval
        self._lock = threading.Lock()
        self._running = set()
        self._steps = {}
        self._sets = {}
        self._stop = threading.Event()
        self._thread = None

    def start(self):
        try:
            _cpu_times(), _mem_used_gb(), _load1()
        except (OSError, ValueError, KeyError, IndexError):
            return  # no /proc: nothing sampled
        self._stop.clear()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self):
        if self._thread:
            self._stop.set()
            self._thread.join(self.interval + 2)
            self._thread = None

    def step_started(self, sid):
        with self._lock:
            self._running.add(sid)
            self._steps[sid] = _Acc()

    def step_ended(self, sid):
        """-> the step's load fields for its metrics line ({} when nothing was sampled)."""
        with self._lock:
            self._running.discard(sid)
            acc = self._steps.pop(sid, None)
        if not acc:
            return {}
        out = acc.fields()
        if out and acc.beside:
            out["beside"] = sorted(acc.beside)
        return out

    def take_overlaps(self):
        """-> one entry per set of two or more steps that ran at the same time, with its peaks;
        cleared, so each drive reports its own."""
        with self._lock:
            sets, self._sets = self._sets, {}
        return [dict(steps=sorted(k), seconds=round(a.seconds), **a.fields()) for k, a in sets.items() if a.n]

    def _loop(self):
        total0, idle0 = _cpu_times()
        t0 = time.monotonic()
        while not self._stop.wait(self.interval):
            try:
                total, idle = _cpu_times()
                s = {"mem": _mem_used_gb(), "load": _load1(),
                     "cpu": 100.0 * (1 - (idle - idle0) / (total - total0)) if total > total0 else 0.0}
            except (OSError, ValueError, KeyError, IndexError):
                continue
            total0, idle0 = total, idle
            now = time.monotonic()
            dt, t0 = now - t0, now
            with self._lock:
                running = frozenset(self._running)
                for sid in running:
                    acc = self._steps.get(sid)
                    if acc:
                        acc.add(s, dt)
                        acc.beside |= running - {sid}
                if len(running) > 1:
                    self._sets.setdefault(running, _Acc()).add(s, dt)
