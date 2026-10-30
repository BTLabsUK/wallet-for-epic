#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
"""tools/rel against the real release relay, without Telegram: the bot (gui-feedback-bot) runs a
second instance on 127.0.0.1 with its fake Bot API (scripts/fake_telegram.py), its own tokens and
data, never the production .env, token or port 8790. tools/rel runs a fake pipeline through it
and the admin's button presses are injected into the fake Telegram:

  1. a TEST run: live message, a failed step's alert with the known-failure hint, the publish
     gate (exit 10 while pending); Approve + Confirm → tools/rel gate exit 0 → publish → done
  2. Hold → exit 40, and tools/rel publish refuses
  3. the relay down while the gate is pending → exit 40 (fail closed), never approved
  4. the runner's producer token cannot approve its own gate

    <bot>/.venv/bin/python tools/rellib/tests/relay_e2e.py --bot <checkout of gui-feedback-bot>

Exit 0 when every check passed. Opt-in (not run by the unit tests): it needs the bot's code.
"""
import argparse
import asyncio
import json
import os
import secrets
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
ADMIN = 803516752


def port_free(port):
    with socket.socket() as s:
        return s.connect_ex(("127.0.0.1", port)) != 0


async def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bot", required=True)
    ap.add_argument("--tg-port", type=int, default=8789)
    ap.add_argument("--fleet-port", type=int, default=8781)
    a = ap.parse_args()
    bot = Path(a.bot).resolve()
    sys.path.insert(0, str(bot / "scripts"))
    from aiohttp import ClientSession, web
    from fake_telegram import FakeTelegram, make_app
    for p in (a.tg_port, a.fleet_port):
        if p == 8790 or not port_free(p):
            sys.exit(f"port {p} is in use or production")
    base = Path(tempfile.mkdtemp(prefix="rel-relay-e2e-", dir=os.environ.get("TMPDIR"))).resolve()
    os.umask(0o077)
    rel, appr, fleet = (secrets.token_urlsafe(32) for _ in range(3))
    (base / "telegram_token").write_text("123456:FAKE-TOKEN\n")
    (base / "fleet_token").write_text(fleet + "\n")
    (base / "relay_token").write_text(secrets.token_urlsafe(32) + "\n")
    (base / "relmsg_token").write_text(rel + "\n")
    env_file = base / "bot.env"
    env_file.write_text("\n".join([
        f"TELEGRAM_TOKEN_FILE={base / 'telegram_token'}", f"TELEGRAM_API_BASE=http://127.0.0.1:{a.tg_port}",
        f"ADMIN_TELEGRAM_USER_ID={ADMIN}", "FEEDBACK_GROUP_IDS=-1001", f"DATA_DIR={base / 'data'}",
        f"LOG_DIR={base / 'logs'}", "DIGEST_ENABLED=0", "VERTEX_PROJECT=", "ACK_MODE=react",
        "FLEET_API_HOST=127.0.0.1", f"FLEET_API_PORT={a.fleet_port}", f"FLEET_TOKEN_FILE={base / 'fleet_token'}",
        f"RELEASE_TOKEN={rel}", f"RELEASE_APPROVE_TOKEN={appr}", "RELAY_INBOUND_URL=",
        f"RELAY_INBOUND_TOKEN_FILE={base / 'relay_token'}"]) + "\n")
    # The runner's relmsg: the producer token only (no approve token file at all).
    wrapper = base / "relmsg"
    wrapper.write_text(f"#!/bin/sh\nRELMSG_URL=http://127.0.0.1:{a.fleet_port} RELMSG_TOKEN_FILE={base / 'relmsg_token'} "
                       f"RELMSG_APPROVE_TOKEN_FILE={base / 'none'} HOME={base} exec {sys.executable} {bot / 'cli/relmsg'} \"$@\"\n")
    wrapper.chmod(0o755)
    fake = FakeTelegram()
    r = web.AppRunner(make_app(fake), access_log=None)
    await r.setup()
    await web.TCPSite(r, "127.0.0.1", a.tg_port).start()
    clean = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": str(base), "BOT_ENV_FILE": str(env_file),
             "PYTHONUNBUFFERED": "1", "LANG": "C.UTF-8"}

    async def start_bot():
        out = open(base / "bot.log", "ab")
        return await asyncio.create_subprocess_exec(sys.executable, "-m", "feedbackbot.main", cwd=str(bot), env=clean,
                                                    stdout=out, stderr=out)

    # The fake pipeline of the unit tests, a src with its fake driver, a previous release folder.
    sys.path.insert(0, str(HERE))
    import support
    (base / "pipeline.toml").write_text(support.FAKE_PIPELINE)
    src = base / "src"
    src.mkdir()
    (src / "driver.sh").write_text(support.DRIVER)
    prev = base / "26.10.23"
    prev.mkdir()
    (base / "failures.toml").write_text("")
    state = base / "state"
    version = subprocess.run(["git", "-C", str(REPO), "show", "HEAD:app/pubspec.yaml"], capture_output=True,
                             text=True).stdout.split("version:")[1].split("+")[0].strip()
    env = dict(os.environ, REL_RELMSG=str(wrapper))
    env.pop("REL_STATE_ROOT", None)

    def rel_sync(*args):
        p = subprocess.run([str(REPO / "tools/rel"), "--json", "--state-root", str(state), "--pipeline",
                            str(base / "pipeline.toml"), "--hosts", str(base / "no-hosts.toml"), *args],
                           capture_output=True, text=True, env=env, timeout=300)
        try:
            obj = json.loads(p.stdout.strip().splitlines()[-1])
        except Exception:
            obj = {"raw": p.stdout[-500:], "err": p.stderr[-500:]}
        return p.returncode, obj

    async def rel(*args):
        # In a thread: the fake Telegram runs on this event loop and must keep answering the bot.
        return await asyncio.to_thread(rel_sync, *args)

    def msgs():
        return fake.chats.get(ADMIN, {})

    async def until(cond, timeout=20.0):
        end = time.monotonic() + timeout
        while time.monotonic() < end:
            if cond():
                return True
            await asyncio.sleep(0.2)
        return cond()

    async def press(mid, data):
        async with ClientSession() as s:
            async with s.post(f"http://127.0.0.1:{a.tg_port}/_control/callback",
                              json={"from_id": ADMIN, "message_id": mid, "data": data}) as resp:
                return await resp.json()

    failed = 0

    def check(cond, what):
        nonlocal failed
        print(("PASS " if cond else "FAIL ") + what, flush=True)
        failed += 0 if cond else 1

    def gate_msgs():
        return [m for _, m in sorted(msgs().items()) if "rg:" in json.dumps(m.get("reply_markup") or {})]

    def gate_msg(text_part):
        # The newest: a gate message sent again (after a timeout) makes the older one out of date.
        found = [m for m in gate_msgs() if text_part in m.get("text", "")]
        return found[-1] if found else None

    async def start(run_tag):
        return await rel("start", version, "--test", "--only", "android", "--set", "publish.manifests=false",
                   "--src", str(src), "--commit", "HEAD", "--previous", str(prev), "--set", f"publish.notes={run_tag}")

    proc = await start_bot()
    try:
        check(await until(lambda: not port_free(a.fleet_port), 30), "bot instance up on 127.0.0.1")
        # 1 -------------------------------------------------------------------------------------
        (src / "fail-notor").write_text("")
        code, obj = await start("one")
        check(code == 20, f"a failing build stops the run: exit {code}")
        live = [m for m in msgs().values() if m.get("text", "").startswith("🚀")]
        check(len(live) == 1 and "TEST" in live[0]["text"] and version in live[0]["text"],
              f"one live message, marked TEST ({len(live)})")
        check(await until(lambda: any("build-android-notor" in m.get("text", "") and "failed" in m.get("text", "")
                                      and m.get("_disable_notification") is False for m in msgs().values()), 15),
              "the failed step raised a notifying alert")
        (src / "fail-notor").unlink()
        code, obj = await rel("resume")
        check(code == 10, f"after the fix, resume runs to the publish gate and waits: exit {code}")
        check(await until(lambda: gate_msg("publish?") is not None, 15), "the gate message has Approve / Hold buttons")
        g = gate_msg("publish?")
        gid = json.dumps(g["reply_markup"]).split("rg:")[1].split(":")[0]
        code, obj = await rel("publish")
        check(code == 10, f"publish while the gate is pending refuses: exit {code}")
        p = await asyncio.to_thread(subprocess.run, [str(wrapper), "approve", gid], capture_output=True, text=True)
        check(p.returncode != 0, "the runner's producer token cannot approve its own gate")
        code, obj = await rel("gate")
        check(code == 10, f"still pending after the runner's own attempt: exit {code}")
        await press(g["message_id"], f"rg:{gid}:a")
        await asyncio.sleep(1)
        code, obj = await rel("gate")
        check(code == 10, "Approve alone is not enough (Confirm asked): exit %d" % code)
        await press(g["message_id"], f"rg:{gid}:c")
        for _ in range(20):
            code, obj = await rel("gate")
            if code != 10:
                break
            await asyncio.sleep(1)
        check(code == 0, f"Approve + Confirm opens the gate: exit {code} ({obj.get('message', '')[:120]})")
        code, obj = await rel("publish")
        check(code == 0, f"publish after approval (scratch target): exit {code}")
        check(await until(lambda: any("✅" in m.get("text", "") and "publish-downloads" in m.get("text", "")
                                      for m in msgs().values()), 15), "live message shows the publish steps")
        # 2 -------------------------------------------------------------------------------------
        code, obj = await start("two")
        check(code == 10, f"second run waits at its gate: exit {code}")
        check(await until(lambda: any(json.dumps(m["reply_markup"]).split("rg:")[1].split(":")[0] != gid
                                      for m in gate_msgs()), 15), "the second run's gate message arrived")
        g2 = [m for m in gate_msgs() if json.dumps(m["reply_markup"]).split("rg:")[1].split(":")[0] != gid][-1]
        gid2 = json.dumps(g2["reply_markup"]).split("rg:")[1].split(":")[0]
        await press(g2["message_id"], f"rg:{gid2}:h")
        for _ in range(20):
            code, obj = await rel("gate")
            if code != 10:
                break
            await asyncio.sleep(1)
        check(code == 40, f"Hold closes the gate: exit {code}")
        code, obj = await rel("publish")
        check(code == 40, f"publish refuses a held gate: exit {code}")
        # 3 -------------------------------------------------------------------------------------
        code, obj = await start("three")
        check(code == 10, f"third run waits at its gate: exit {code}")
        proc.terminate()
        await proc.wait()
        code, obj = await rel("gate")
        check(code == 40, f"relay down: the gate counts as closed (fail closed): exit {code}")
        code, obj = await rel("publish")
        check(code in (40, 10), f"publish refuses with the relay down: exit {code}")
    finally:
        if proc.returncode is None:
            proc.terminate()
            await proc.wait()
        await r.cleanup()
    print(f"instance dir: {base}")
    print("ALL PASSED" if not failed else f"{failed} FAILED")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
