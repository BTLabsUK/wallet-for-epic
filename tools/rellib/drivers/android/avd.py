"""The Android trust lane's AVD (wfe_trust_<variant>): made on first use, and what making one needs.
No imports beyond the standard library: tools/rel preflight loads it to check a lane's inputs."""
import os
import subprocess

SDK = os.environ.get("ANDROID_SDK_ROOT") or os.path.expanduser("~/Android/Sdk")
AVD_HOME = os.environ.get("ANDROID_AVD_HOME") or os.path.expanduser("~/.android/avd")

# A lane's AVD, made on first use: Pixel 7, API 36 Google APIs x86_64 (adb root works), the
# hardware the tor lane was proven on.
AVD_IMAGE = "system-images;android-36;google_apis;x86_64"
AVD_DEVICE = "pixel_7"
AVD_HW = {"hw.ramSize": "3G", "hw.cpu.ncore": "4", "disk.dataPartition.size": "6G", "vm.heapSize": "228M",
          "hw.keyboard": "yes", "hw.gpu.enabled": "no", "PlayStore.enabled": "no"}


def avd_name(variant):
    return "wfe_trust_%s" % variant


def avd_missing_input():
    """What creating a lane AVD needs and this machine lacks, or None."""
    if not os.path.isfile(os.path.join(SDK, "cmdline-tools", "latest", "bin", "avdmanager")):
        return "no avdmanager under %s/cmdline-tools/latest" % SDK
    if not os.path.isdir(os.path.join(SDK, *AVD_IMAGE.split(";"))):
        return "system image %s not installed in %s" % (AVD_IMAGE, SDK)
    if not os.path.isfile(os.path.join(SDK, "emulator", "emulator")):
        return "no emulator under %s/emulator" % SDK
    return None


def create_avd(name):
    """Create AVD `name` with the lane hardware; None when made, else what went wrong."""
    err = avd_missing_input()
    if err:
        return err
    r = subprocess.run([os.path.join(SDK, "cmdline-tools", "latest", "bin", "avdmanager"), "create", "avd", "-n", name,
                        "-k", AVD_IMAGE, "-d", AVD_DEVICE], input="no\n", capture_output=True, text=True, timeout=300,
                       env=dict(os.environ, ANDROID_SDK_ROOT=SDK, ANDROID_AVD_HOME=AVD_HOME))
    cfg = os.path.join(AVD_HOME, name + ".avd", "config.ini")
    if r.returncode != 0 or not os.path.isfile(cfg):
        return "avdmanager exit %d: %s" % (r.returncode, (r.stderr or r.stdout).strip()[-300:])
    lines = [l for l in open(cfg).read().splitlines() if l.split("=", 1)[0] not in AVD_HW]
    lines += ["%s=%s" % kv for kv in AVD_HW.items()]
    with open(cfg, "w") as f:
        f.write("\n".join(lines) + "\n")
    return None


def avd_problem(name):
    """None when the lane can boot AVD `name` (it is there, or can be made), else why not."""
    if not os.path.isfile(os.path.join(SDK, "emulator", "emulator")):
        return "no emulator under %s/emulator" % SDK
    if os.path.isdir(os.path.join(AVD_HOME, name + ".avd")):
        return None
    err = avd_missing_input()
    return "no AVD %s in %s, and it cannot be made: %s" % (name, AVD_HOME, err) if err else None
