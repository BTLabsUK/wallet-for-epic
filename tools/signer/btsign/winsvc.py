# SPDX-License-Identifier: Apache-2.0
"""Runs the signer as a Windows service with nothing but ctypes (no pywin32): the service
control manager starts `python.exe btsign.py service --data <dir>` as the btsigner account,
this module registers the control handler, reports RUNNING, and stops on STOP or SHUTDOWN."""
from __future__ import annotations

import ctypes
import logging
import threading
from ctypes import wintypes

log = logging.getLogger("btsign.service")

SERVICE_WIN32_OWN_PROCESS = 0x10
SERVICE_STOPPED, SERVICE_START_PENDING, SERVICE_STOP_PENDING, SERVICE_RUNNING = 1, 2, 3, 4
SERVICE_ACCEPT_STOP, SERVICE_ACCEPT_SHUTDOWN = 0x1, 0x4
SERVICE_CONTROL_STOP, SERVICE_CONTROL_INTERROGATE, SERVICE_CONTROL_SHUTDOWN = 1, 4, 5
NO_ERROR, ERROR_CALL_NOT_IMPLEMENTED = 0, 120


class SERVICE_STATUS(ctypes.Structure):
    _fields_ = [("dwServiceType", wintypes.DWORD), ("dwCurrentState", wintypes.DWORD),
                ("dwControlsAccepted", wintypes.DWORD), ("dwWin32ExitCode", wintypes.DWORD),
                ("dwServiceSpecificExitCode", wintypes.DWORD), ("dwCheckPoint", wintypes.DWORD),
                ("dwWaitHint", wintypes.DWORD)]


SERVICE_MAIN = ctypes.WINFUNCTYPE(None, wintypes.DWORD, ctypes.POINTER(wintypes.LPWSTR))
HANDLER_EX = ctypes.WINFUNCTYPE(wintypes.DWORD, wintypes.DWORD, wintypes.DWORD,
                                wintypes.LPVOID, wintypes.LPVOID)


class SERVICE_TABLE_ENTRYW(ctypes.Structure):
    _fields_ = [("lpServiceName", wintypes.LPWSTR), ("lpServiceProc", SERVICE_MAIN)]


def run(name: str, start, stop) -> None:
    """start(): begin serving (returns quickly). stop(): ask it to stop. Blocks until stopped."""
    advapi = ctypes.WinDLL("advapi32", use_last_error=True)
    advapi.RegisterServiceCtrlHandlerExW.restype = wintypes.HANDLE
    advapi.RegisterServiceCtrlHandlerExW.argtypes = [wintypes.LPCWSTR, HANDLER_EX, wintypes.LPVOID]
    advapi.SetServiceStatus.argtypes = [wintypes.HANDLE, ctypes.POINTER(SERVICE_STATUS)]
    advapi.StartServiceCtrlDispatcherW.argtypes = [ctypes.POINTER(SERVICE_TABLE_ENTRYW)]
    stopped = threading.Event()
    state = {"handle": None, "checkpoint": 0}

    def report(current, exit_code=NO_ERROR, wait_hint=0):
        st = SERVICE_STATUS(SERVICE_WIN32_OWN_PROCESS, current,
                            0 if current == SERVICE_START_PENDING else SERVICE_ACCEPT_STOP | SERVICE_ACCEPT_SHUTDOWN,
                            exit_code, 0, 0, wait_hint)
        if current in (SERVICE_START_PENDING, SERVICE_STOP_PENDING):
            state["checkpoint"] += 1
            st.dwCheckPoint = state["checkpoint"]
        advapi.SetServiceStatus(state["handle"], ctypes.byref(st))

    def handler(control, event_type, event_data, context):
        if control in (SERVICE_CONTROL_STOP, SERVICE_CONTROL_SHUTDOWN):
            report(SERVICE_STOP_PENDING, wait_hint=10000)
            stopped.set()
            return NO_ERROR
        if control == SERVICE_CONTROL_INTERROGATE:
            return NO_ERROR
        return ERROR_CALL_NOT_IMPLEMENTED

    handler_cb = HANDLER_EX(handler)

    def main(argc, argv):
        state["handle"] = advapi.RegisterServiceCtrlHandlerExW(name, handler_cb, None)
        if not state["handle"]:
            log.error("RegisterServiceCtrlHandlerExW failed (%d)", ctypes.get_last_error())
            return
        report(SERVICE_START_PENDING, wait_hint=30000)
        try:
            start()
        except Exception:
            log.exception("the signer did not start")
            report(SERVICE_STOPPED, exit_code=1066)  # ERROR_SERVICE_SPECIFIC_ERROR
            return
        report(SERVICE_RUNNING)
        log.info("service %s running", name)
        stopped.wait()
        try:
            stop()
        finally:
            report(SERVICE_STOPPED)
            log.info("service %s stopped", name)

    main_cb = SERVICE_MAIN(main)
    table = (SERVICE_TABLE_ENTRYW * 2)(SERVICE_TABLE_ENTRYW(name, main_cb), SERVICE_TABLE_ENTRYW(None, SERVICE_MAIN()))
    if not advapi.StartServiceCtrlDispatcherW(table):
        raise OSError(f"StartServiceCtrlDispatcherW failed ({ctypes.get_last_error()}); "
                      "run `serve` to start the signer outside the service manager")
